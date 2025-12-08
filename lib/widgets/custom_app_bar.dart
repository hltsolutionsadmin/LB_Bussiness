import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:local_basket_business/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentScreen;

  const CustomAppBar({super.key, required this.currentScreen});

  String _getTitle() {
    switch (currentScreen) {
      case 'dashboard':
        return 'Dashboard';
      case 'onboarding':
        return 'Restaurant Onboarding';
      case 'restaurants':
        return 'Restaurants';
      case 'restaurant-reports':
        return 'Restaurant Reports';
      case 'delivery':
        return 'Delivery Partners';
      case 'delivery-reports':
        return 'Delivery Reports';
      case 'settings':
        return 'Settings';
      default:
        return 'Local Basket Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(_getTitle()),
            ],
          ),
          backgroundColor: AppColors.glass,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // Handle notifications
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
