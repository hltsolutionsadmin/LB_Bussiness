import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_basket_business/theme/app_colors.dart';
import 'package:local_basket_business/widgets/glass_card.dart';
import 'package:local_basket_business/widgets/search_bar_widget.dart';
import 'package:get_it/get_it.dart';
import 'package:local_basket_business/data/datasources/business/business_remote_data_source.dart';
import 'package:local_basket_business/presentation/screens/admin/orders_reports_screen.dart';

class RestaurantManagementScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const RestaurantManagementScreen({super.key, required this.onNavigate});

  @override
  State<RestaurantManagementScreen> createState() =>
      _RestaurantManagementScreenState();
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.orange600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RestaurantManagementScreenState
    extends State<RestaurantManagementScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = const ['All', 'Active', 'Pending', 'Inactive'];
  final List<_Restaurant> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() => _loading = true);
    try {
      final ds = GetIt.I<BusinessRemoteDataSource>();
      final list = await ds.listBusinesses();
      final mapped = list.map<_Restaurant>((raw) {
        final m = Map<String, dynamic>.from(raw);
        String str(dynamic v) => v?.toString() ?? '';
        double toDouble(dynamic v) {
          if (v is num) return v.toDouble();
          return double.tryParse(str(v)) ?? 0.0;
        }

        int toInt(dynamic v) {
          if (v is num) return v.toInt();
          return int.tryParse(str(v)) ?? 0;
        }

        final status = str(m['status']).isNotEmpty
            ? str(m['status'])
            : ((m['enabled'] == true) ? 'Active' : 'Inactive');
        final name =
            str(
              m['businessName'].toString().isNotEmpty
                  ? m['businessName']
                  : m['name'],
            ).isNotEmpty
            ? str(m['businessName'] ?? m['name'])
            : 'N/A';
        return _Restaurant(
          id: toInt(m['id']),
          name: name,
          cuisine: str(m['categoryName'] ?? m['cuisine']).isEmpty
              ? '—'
              : str(m['categoryName'] ?? m['cuisine']),
          status: status,
          rating: toDouble(m['rating']),
          totalOrders: toInt(m['totalOrders']),
          revenue: toDouble(m['revenue']),
          ownerName: str(m['ownerName'] ?? m['contactPerson']).isEmpty
              ? '—'
              : str(m['ownerName'] ?? m['contactPerson']),
          phone: str(m['contactNumber'] ?? m['phone']).isEmpty
              ? '—'
              : str(m['contactNumber'] ?? m['phone']),
          email: str(m['email']).isEmpty ? '—' : str(m['email']),
          address: str(m['addressLine1'] ?? m['address']).isEmpty
              ? '—'
              : str(m['addressLine1'] ?? m['address']),
          imageUrl: str(m['imageUrl']),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _all
          ..clear()
          ..addAll(mapped);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load restaurants')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = _filtered();
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
                              hintText: 'Search restaurants...',
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : restaurants.isEmpty
                    ? _EmptyState(
                        icon: Icons.restaurant,
                        title: 'No Restaurants Found',
                        message: _searchQuery.isNotEmpty
                            ? 'No restaurants match your search'
                            : 'Add your first restaurant to get started',
                        actionText: 'Add Restaurant',
                        onAction: () => widget.onNavigate('onboarding'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) => _RestaurantCard(
                          data: restaurants[index],
                          onNavigate: widget.onNavigate,
                          onUpdated: _loadRestaurants,
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

  List<_Restaurant> _filtered() {
    var list = List<_Restaurant>.from(_all);
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_selectedFilter != 'All') {
      list = list.where((r) => r.status == _selectedFilter).toList();
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

class _RestaurantCard extends StatelessWidget {
  final _Restaurant data;
  final Function(String) onNavigate;
  final VoidCallback onUpdated;
  final int index;
  const _RestaurantCard({
    required this.data,
    required this.onNavigate,
    required this.onUpdated,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => _showDetails(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.orange600.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: AppColors.orange600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _StatusBadge(status: data.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.cuisine,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
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
                            Icon(
                              Icons.shopping_bag,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${data.totalOrders} orders',
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
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0x33FFFFFF), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(
                    label: 'Revenue',
                    value: '₹${_formatRevenue(data.revenue)}',
                  ),
                  Container(width: 1, height: 30, color: AppColors.glassBorder),
                  _Stat(label: 'Owner', value: data.ownerName),
                  Container(width: 1, height: 30, color: AppColors.glassBorder),
                  _Stat(
                    label: 'Phone',
                    value: (data.phone.length > 10)
                        ? data.phone.substring(0, 10)
                        : data.phone,
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

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DetailsSheet(data: data, onUpdated: onUpdated),
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  final _Restaurant data;
  final VoidCallback onUpdated;
  const _DetailsSheet({required this.data, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.red950, AppColors.orange950],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          data.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.orange600.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: AppColors.orange600,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.cuisine,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _StatusBadge(status: data.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(
                    icon: Icons.person,
                    label: 'Owner',
                    value: data.ownerName,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: data.email,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: data.phone,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.location_on,
                    label: 'Address',
                    value: data.address,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final nav = Navigator.of(context, rootNavigator: true);
                      Navigator.of(context).pop();
                      Future.microtask(() {
                        nav.push(
                          MaterialPageRoute(
                            builder: (_) => OrdersReportsScreen(
                              initialBusinessId: data.id,
                              autoLoad: true,
                            ),
                          ),
                        );
                      });
                    },
                    icon: const Icon(Icons.assessment),
                    label: const Text('View Reports'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final shouldUnblock = data.status != 'Active';
                      try {
                        final ds = GetIt.I<BusinessRemoteDataSource>();
                        if (shouldUnblock) {
                          await ds.unblockBusiness(businessId: data.id);
                        } else {
                          await ds.blockBusiness(businessId: data.id);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          onUpdated();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                shouldUnblock
                                    ? 'Restaurant unblocked'
                                    : 'Restaurant blocked',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update status'),
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      data.status == 'Active' ? Icons.pause : Icons.play_arrow,
                    ),
                    label: Text(
                      data.status == 'Active' ? 'Deactivate' : 'Activate',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data.status == 'Active'
                          ? AppColors.error
                          : AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Active':
        color = AppColors.success;
        break;
      case 'Pending':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Restaurant {
  final int id;
  final String name;
  final String cuisine;
  final String status;
  final double rating;
  final int totalOrders;
  final double revenue;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String imageUrl;

  _Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.status,
    required this.rating,
    required this.totalOrders,
    required this.revenue,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.imageUrl,
  });
}

String _formatRevenue(double revenue) {
  if (revenue >= 100000) {
    return '${(revenue / 100000).toStringAsFixed(1)}L';
  } else if (revenue >= 1000) {
    return '${(revenue / 1000).toStringAsFixed(1)}K';
  }
  return revenue.toStringAsFixed(0);
}
