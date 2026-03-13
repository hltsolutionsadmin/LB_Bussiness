import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_basket_business/theme/app_colors.dart';
import 'package:local_basket_business/widgets/glass_card.dart';
import 'package:local_basket_business/widgets/stat_card.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:local_basket_business/data/datasources/orders/orders_remote_data_source.dart';
import 'package:local_basket_business/data/datasources/business/business_remote_data_source.dart';
import 'package:local_basket_business/data/datasources/delivery/delivery_remote_data_source.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const AdminDashboardScreen({super.key, required this.onNavigate});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loadingStats = true;
  int _totalOrders = 0;
  double _revenue = 0;
  int _restaurants = 0;
  int _partners = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 7));

      final ordersDs = GetIt.I<OrdersRemoteDataSource>();
      final businessDs = GetIt.I<BusinessRemoteDataSource>();
      final deliveryDs = GetIt.I<DeliveryRemoteDataSource>();

      final summary = await ordersDs.getAdminOverallReport(
        period: 'weekly',
        fromDate: _fmt(from),
        toDate: _fmt(now),
      );

      num toNum(dynamic v) {
        if (v is num) return v;
        return num.tryParse(v?.toString() ?? '') ?? 0;
      }

      final revenue = summary.fold<double>(
        0,
        (sum, e) =>
            sum +
            toNum(e['revenue'] ?? e['totalRevenue'] ?? e['amount']).toDouble(),
      );
      final ordersCount = summary.fold<int>(
        0,
        (sum, e) =>
            sum +
            toNum(e['ordersCount'] ?? e['orderCount'] ?? e['count']).toInt(),
      );

      final businesses = await businessDs.listBusinesses();
      final partners = await deliveryDs.listPartnersPaged(page: 0, size: 1);

      if (!mounted) return;
      setState(() {
        _revenue = revenue;
        _totalOrders = ordersCount;
        _restaurants = businesses.length;
        // We don't have totalElements yet; show at least current page size.
        _partners = partners.length;
      });
    } catch (_) {
      // keep prior values
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadStats();
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
                    Text(
                      'Welcome Back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
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
    final w = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.textScalerOf(context).scale(14);
    final ratio = (w < 360 || textScale > 1.1) ? 0.98 : 1.1;

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
          childAspectRatio: ratio,
          children: [
            StatCard(
              title: 'Total Orders',
              value: _loadingStats ? '—' : _formatNumber(_totalOrders),
              icon: Icons.shopping_bag,
              iconColor: AppColors.orange600,
              subtitle: '+12%',
            ),
            StatCard(
              title: 'Revenue',
              value: _loadingStats
                  ? '—'
                  : '₹${_formatNumber(_revenue.toInt())}',
              icon: Icons.currency_rupee,
              iconColor: AppColors.success,
              subtitle: '+23%',
            ),
            StatCard(
              title: 'Restaurants',
              value: _loadingStats ? '—' : '$_restaurants',
              icon: Icons.restaurant,
              iconColor: AppColors.info,
            ),
            StatCard(
              title: 'Delivery Partners',
              value: _loadingStats ? '—' : '$_partners',
              icon: Icons.delivery_dining,
              iconColor: AppColors.warning,
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
                    onTap: () => widget.onNavigate('onboarding'),
                  ),
                  const Divider(color: Color(0x33FFFFFF), height: 1),
                  _buildActionTile(
                    icon: Icons.person_add,
                    title: 'Add Delivery Partner',
                    subtitle: 'Register a new delivery partner',
                    onTap: () => widget.onNavigate('delivery'),
                  ),
                  const Divider(color: Color(0x33FFFFFF), height: 1),
                  _buildActionTile(
                    icon: Icons.assessment,
                    title: 'View Reports',
                    subtitle: 'Check detailed analytics and reports',
                    onTap: () => widget.onNavigate('restaurant-reports'),
                  ),
                  const Divider(color: Color(0x33FFFFFF), height: 1),
                  _buildActionTile(
                    icon: Icons.local_offer,
                    title: 'Offers',
                    subtitle: 'Create and manage promotional offers',
                    onTap: () => widget.onNavigate('offers'),
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
                    style: TextStyle(
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
              color: Colors.white70,
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
                  _ActivityItem(
                    icon: Icons.restaurant,
                    title: 'New Restaurant Added',
                    subtitle: 'Spice Garden joined the platform',
                    time: '2 hours ago',
                    color: AppColors.success,
                  ),
                  Divider(color: Color(0x33FFFFFF), height: 1),
                  _ActivityItem(
                    icon: Icons.delivery_dining,
                    title: 'Delivery Partner Joined',
                    subtitle: 'Vijay Kumar registered as delivery partner',
                    time: '4 hours ago',
                    color: AppColors.info,
                  ),
                  Divider(color: Color(0x33FFFFFF), height: 1),
                  _ActivityItem(
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
