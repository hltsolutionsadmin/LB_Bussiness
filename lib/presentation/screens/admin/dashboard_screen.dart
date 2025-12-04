import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/restaurant_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_card.dart';
import '../../theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await context.read<AnalyticsProvider>().refreshAnalytics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context),
              const SizedBox(height: 24),
              _buildQuickStats(context),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildRecentActivity(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return GlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '+23.5% this week',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.2, end: 0, duration: 300.ms);
  }

  Widget _buildQuickStats(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final restaurants = context.watch<RestaurantProvider>();
    final delivery = context.watch<DeliveryProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            StatCard(
              title: 'Total Orders',
              value: analytics.stats != null
                  ? _formatNumber(analytics.stats!.totalOrders)
                  : '0',
              icon: Icons.shopping_bag,
              iconColor: AppColors.orange600,
              subtitle: '+12%',
            ),
            StatCard(
              title: 'Revenue',
              value: analytics.stats != null
                  ? '₹${_formatNumber(analytics.stats!.revenue.toInt())}'
                  : '₹0',
              icon: Icons.currency_rupee,
              iconColor: AppColors.success,
              subtitle: '+23%',
            ),
            StatCard(
              title: 'Restaurants',
              value: '${restaurants.activeRestaurants}',
              icon: Icons.restaurant,
              iconColor: AppColors.info,
              onTap: () => onNavigate('restaurants'),
            ),
            StatCard(
              title: 'Delivery Partners',
              value: '${delivery.activePartners}',
              icon: Icons.delivery_dining,
              iconColor: AppColors.warning,
              onTap: () => onNavigate('delivery'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.add_business,
                    title: 'Onboard Restaurant',
                    subtitle: 'Add a new restaurant to the platform',
                    onTap: () => onNavigate('onboarding'),
                  ),
                  const Divider(color: AppColors.glassBorder, height: 1),
                  _buildActionTile(
                    icon: Icons.person_add,
                    title: 'Add Delivery Partner',
                    subtitle: 'Register a new delivery partner',
                    onTap: () => onNavigate('delivery'),
                  ),
                  const Divider(color: AppColors.glassBorder, height: 1),
                  _buildActionTile(
                    icon: Icons.assessment,
                    title: 'View Reports',
                    subtitle: 'Check detailed analytics and reports',
                    onTap: () => onNavigate('restaurant-reports'),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 100.ms, duration: 300.ms)
            .slideY(begin: 0.1, end: 0, duration: 300.ms),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange600.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.orange600, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
              child: Column(
                children: [
                  _buildActivityItem(
                    icon: Icons.restaurant,
                    title: 'New Restaurant Added',
                    subtitle: 'Spice Garden joined the platform',
                    time: '2 hours ago',
                    color: AppColors.success,
                  ),
                  const Divider(color: AppColors.glassBorder, height: 1),
                  _buildActivityItem(
                    icon: Icons.delivery_dining,
                    title: 'Delivery Partner Joined',
                    subtitle: 'Vijay Kumar registered as delivery partner',
                    time: '4 hours ago',
                    color: AppColors.info,
                  ),
                  const Divider(color: AppColors.glassBorder, height: 1),
                  _buildActivityItem(
                    icon: Icons.shopping_bag,
                    title: 'High Order Volume',
                    subtitle: '500+ orders completed today',
                    time: '6 hours ago',
                    color: AppColors.warning,
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 300.ms)
            .slideY(begin: 0.1, end: 0, duration: 300.ms),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
