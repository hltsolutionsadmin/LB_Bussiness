import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:local_basket_business/routes/app_router.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/data/datasources/business/business_remote_data_source.dart';
import 'package:local_basket_business/domain/repositories/auth/auth_repository.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/core/services/app_update_service.dart';
import 'package:local_basket_business/core/services/orders_poller.dart';
import 'package:local_basket_business/presentation/widgets/app_update_dialog.dart';

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
    _boot();
  }

  Future<void> _boot() async {
    final blocked = await _maybeShowUpdateDialog();
    // A forced update leaves the user on the splash screen with a
    // non-dismissible dialog; don't continue into the app.
    if (blocked || !mounted) return;
    await _goNext();
  }

  /// Returns `true` when a forced update is in effect (navigation must stop).
  Future<bool> _maybeShowUpdateDialog() async {
    try {
      final info = await sl<AppUpdateService>().check();
      if (!mounted || info.type == AppUpdateType.none) return false;
      await showAppUpdateDialog(context, info);
      return info.type == AppUpdateType.forced;
    } catch (_) {
      return false;
    }
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
      if (token != null && token.isNotEmpty) {
        try {
          final details = await _withStoreDetails(await repo.getUserDetails());
          sl<SessionStore>().setUser(details);
        } on DioException catch (e) {
          if (!mounted) return;
          if (e.response?.statusCode == 401) {
            await sl<AppSecureStorage>().clearToken();
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.login,
              arguments: {'showSessionExpired': true},
            );
          } else {
            // Network/timeout/etc. — keep the stored token, don't force logout.
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          }
          return;
        } catch (_) {
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
          sl<OrdersPoller>().start();
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
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/jpg/ic_launcher.jpg',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Local Basket Business',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
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
