import 'package:flutter/material.dart';
import 'package:local_basket_business/routes/app_router.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/core/services/orders_poller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final prefs = await SharedPreferences.getInstance();
  const firstRunKey = 'has_run_before_v1';
  final hasRunBefore = prefs.getBool(firstRunKey) ?? false;
  if (!hasRunBefore) {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    await prefs.setBool(firstRunKey, true);
  }
  await setupLocator();
  sl<OrdersPoller>().start();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = [Color(0xFFFF7A00), Color(0xFFFF5722)];
    final colorScheme = ColorScheme.light(
      primary: primary[0],
      secondary: primary[1],
    );
    return MaterialApp(
      title: 'LB Business',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          headerBackgroundColor: primary[0],
          headerForegroundColor: Colors.white,
          dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return null;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return primary[0];
            }
            return null;
          }),
          todayForegroundColor: WidgetStateProperty.resolveWith<Color?>((
            states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.orange[700];
          }),
          todayBorder: BorderSide(color: primary[0]),
          confirmButtonStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(primary[0]),
          ),
          cancelButtonStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(primary[0]),
          ),
        ),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouteGenerator.generateRoute,
    );
  }
}
