import 'package:flutter/material.dart';
import 'package:local_basket_business/presentation/screens/admin/admin_dashboard.dart';
import 'package:local_basket_business/presentation/screens/admin/restaurants_management.dart';
import 'package:local_basket_business/presentation/screens/admin/restaurant_onboarding.dart';
import 'package:local_basket_business/presentation/screens/admin/delivery_management.dart';
import 'package:local_basket_business/presentation/screens/admin/delivery_partner_reports.dart';
import 'package:local_basket_business/presentation/screens/admin/offers_management.dart';
import 'package:local_basket_business/presentation/screens/admin/admin_settings.dart';
import 'package:local_basket_business/widgets/bottom_nav_bar.dart';
import 'package:local_basket_business/presentation/screens/admin/orders_reports_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_currentIndex) {
      case 0:
        body = AdminDashboardScreen(
          onNavigate: (route) {
            if (route == 'onboarding') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RestaurantOnboardingScreen(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              );
              return;
            }
            if (route == 'delivery') {
              setState(() => _currentIndex = 2);
              return;
            }
            if (route == 'restaurant-reports') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrdersReportsScreen()),
              );
              return;
            }
            if (route == 'offers') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OffersManagementScreen(
                    onBack: () => Navigator.of(context).pop(),
                    businessId: 0,
                  ),
                ),
              );
              return;
            }
          },
        );
        break;
      case 1:
        body = RestaurantManagementScreen(
          onNavigate: (route) {
            if (route == 'onboarding') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RestaurantOnboardingScreen(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            }
          },
        );
        break;
      case 2:
        body = DeliveryManagementScreen(
          onNavigate: (route) {
            final parts = route.split(':');
            final name = parts.isNotEmpty ? parts.first : route;
            final partnerId = parts.length > 1 ? int.tryParse(parts[1]) : null;

            if (name == 'delivery-reports') {
              if (partnerId == null || partnerId <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid delivery partner id')),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeliveryPartnerReportsScreen(
                    onBack: () => Navigator.of(context).pop(),
                    partnerId: partnerId,
                  ),
                ),
              );
            }
          },
        );
        break;
      default:
        body = const AdminSettingsScreen();
        break;
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
