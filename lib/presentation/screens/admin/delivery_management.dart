import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_basket_business/theme/app_colors.dart';
import 'package:local_basket_business/widgets/glass_card.dart';
import 'package:local_basket_business/widgets/search_bar_widget.dart';

class DeliveryManagementScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const DeliveryManagementScreen({super.key, required this.onNavigate});

  @override
  State<DeliveryManagementScreen> createState() =>
      _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState extends State<DeliveryManagementScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = const ['All', 'Online', 'Busy', 'Offline'];

  // Dummy data
  final List<_Partner> _all = [
    _Partner(
      name: 'Ravi Kumar',
      vehicleType: 'Bike',
      vehicleNumber: 'KA 05 AB 1234',
      status: 'Online',
      rating: 4.8,
      totalDeliveries: 2200,
      earnings: 86500,
      imageUrl: '',
    ),
    _Partner(
      name: 'Asha R',
      vehicleType: 'Scooter',
      vehicleNumber: 'KA 03 CD 5678',
      status: 'Busy',
      rating: 4.5,
      totalDeliveries: 1450,
      earnings: 54500,
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
    ),
    _Partner(
      name: 'Imran Khan',
      vehicleType: 'Bike',
      vehicleNumber: 'KA 41 EF 9012',
      status: 'Offline',
      rating: 4.1,
      totalDeliveries: 780,
      earnings: 26500,
      imageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final partners = _filtered();
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child:
                    Column(
                          children: [
                            SearchBarWidget(
                              hintText: 'Search delivery partners...',
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                            ),
                            const SizedBox(height: 12),
                            _buildFilterChips(),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.2, end: 0, duration: 300.ms),
              ),
              Expanded(
                child: partners.isEmpty
                    ? const _EmptyState(
                        icon: Icons.delivery_dining,
                        title: 'No Delivery Partners Found',
                        message: 'No delivery partners registered yet',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: partners.length,
                        itemBuilder: (context, index) => _PartnerCard(
                          data: partners[index],
                          onTap: () => widget.onNavigate('delivery-reports'),
                          index: index,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_Partner> _filtered() {
    var list = List<_Partner>.from(_all);
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_selectedFilter != 'All') {
      list = list.where((p) => p.status == _selectedFilter).toList();
    }
    return list;
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              backgroundColor: AppColors.glass,
              selectedColor: AppColors.orange600,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.orange600 : AppColors.glassBorder,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange600.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.orange600),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final _Partner data;
  final VoidCallback onTap;
  final int index;
  const _PartnerCard({
    required this.data,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: onTap,
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.orange600.withOpacity(0.2),
                    backgroundImage: data.imageUrl.isNotEmpty
                        ? NetworkImage(data.imageUrl)
                        : null,
                    child: data.imageUrl.isEmpty
                        ? const Icon(Icons.person, color: AppColors.orange600)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _StatusDot(status: data.status),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.two_wheeler,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data.vehicleType} • ${data.vehicleNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${data.totalDeliveries} deliveries',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_formatEarnings(data.earnings)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Earnings',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideX(begin: 0.2, end: 0, duration: 300.ms);
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Online':
        color = AppColors.success;
        break;
      case 'Busy':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.error;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _Partner {
  final String name;
  final String vehicleType;
  final String vehicleNumber;
  final String status;
  final double rating;
  final int totalDeliveries;
  final double earnings;
  final String imageUrl;
  _Partner({
    required this.name,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.status,
    required this.rating,
    required this.totalDeliveries,
    required this.earnings,
    required this.imageUrl,
  });
}

String _formatEarnings(double earnings) {
  if (earnings >= 100000) {
    return '${(earnings / 100000).toStringAsFixed(1)}L';
  } else if (earnings >= 1000) {
    return '${(earnings / 1000).toStringAsFixed(1)}K';
  }
  return earnings.toStringAsFixed(0);
}
