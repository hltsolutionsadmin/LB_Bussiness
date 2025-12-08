import 'package:flutter/material.dart';
import 'package:local_basket_business/presentation/screens/restaurant/splash_screen.dart';
import 'package:local_basket_business/presentation/screens/restaurant/mobile_login.dart';
import 'package:local_basket_business/presentation/screens/restaurant/otp_verification.dart';
import 'package:local_basket_business/presentation/screens/restaurant/dashboard.dart';
import 'package:local_basket_business/presentation/screens/admin/admin_home.dart';

// Global navigator key to allow navigation from services (e.g., Dio interceptors)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String dashboard = '/dashboard';
  static const String admin = '/admin';
}

class AppRouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (context) => Scaffold(body: LoginScreen()),
          settings: settings,
        );

      case AppRoutes.otp:
        final args = settings.arguments as Map<String, dynamic>?;
        final phone = args?['phoneNumber'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OTPScreen(phoneNumber: phone),
          settings: settings,
        );

      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => DashboardScreen(),
          settings: settings,
        );

      case AppRoutes.admin:
        return MaterialPageRoute(
          builder: (_) => const AdminHomeScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
