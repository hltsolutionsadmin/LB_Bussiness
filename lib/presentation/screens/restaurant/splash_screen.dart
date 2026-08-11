import 'package:flutter/material.dart';
import 'package:local_basket_business/routes/app_router.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/data/datasources/business/business_remote_data_source.dart';
import 'package:local_basket_business/domain/repositories/auth/auth_repository.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _goNext();
  }

  Future<bool> _isTokenExpired() async {
    final expiryMs = await sl<AppSecureStorage>().readTokenExpiry();
    if (expiryMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= expiryMs;
  }

  Future<Map<String, dynamic>> _withStoreDetails(
    Map<String, dynamic> user,
  ) async {
    final storeId = user['storeId']?.toString() ?? '';
    if (storeId.isEmpty || user['store'] is Map<String, dynamic>) return user;

    try {
      final store = await sl<BusinessRemoteDataSource>().getStoreDetails(
        storeId: storeId,
      );
      return {...user, 'store': store};
    } catch (_) {
      return user;
    }
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    try {
      final repo = sl<AuthRepository>();
      final token = await repo.getToken();
      print('token:::==> $token');
      if (token != null && token.isNotEmpty) {
        if (await _isTokenExpired()) {
          await sl<AppSecureStorage>().clearToken();
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.login,
            arguments: {'showSessionExpired': true},
          );
          return;
        }

        // Debug print token from Splash (mask in production)
        final masked = token.length > 12
            ? '${token.substring(0, 6)}...${token.substring(token.length - 6)}'
            : token;
        // ignore: avoid_print
        print('[AUTH][SPLASH] TOKEN: $masked');

        try {
          final details = await _withStoreDetails(await repo.getUserDetails());
          sl<SessionStore>().setUser(details);
        } catch (_) {
          await sl<AppSecureStorage>().clearToken();
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          return;
        }
        if (!mounted) return;
        final roles = sl<SessionStore>().roleNames;
        if (roles.contains('ROLE_BUSINESS_ADMIN') ||
            roles.contains('ROLE_USER_ADMIN')) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.admin);
          return;
        }
        if (roles.contains('ROLE_STORE_ADMIN') ||
            roles.contains('ROLE_RESTAURANT_OWNER')) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
          return;
        }
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }
    } catch (_) {}
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.storefront_rounded,
                size: 72,
                color: Color(0xFFFFD700),
              ),
              SizedBox(height: 16),
              Text(
                'Local Basket Business',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 120,
                height: 4,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
