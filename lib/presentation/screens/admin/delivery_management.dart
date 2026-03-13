import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_basket_business/theme/app_colors.dart';
import 'package:local_basket_business/widgets/glass_card.dart';
import 'package:local_basket_business/widgets/search_bar_widget.dart';
import 'package:local_basket_business/presentation/screens/admin/add_delivery_partner_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:local_basket_business/data/datasources/delivery/delivery_remote_data_source.dart';

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

  final List<String> _filters = const ['All', 'Active', 'Available'];
  final List<_Partner> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _loading = true);
    try {
      final ds = GetIt.I<DeliveryRemoteDataSource>();
      List<Map<String, dynamic>> list;
      if (_selectedFilter == 'Active') {
        list = await ds.listActivePartnersPaged(page: 0, size: 50);
      } else if (_selectedFilter == 'Available') {
        list = await ds.listAvailablePartners(page: 0, size: 50);
      } else {
        list = await ds.listPartnersPaged(page: 0, size: 50);
      }

      String str(dynamic v) => v?.toString() ?? '';
      bool toBool(dynamic v) {
        if (v is bool) return v;
        final s = str(v).toLowerCase();
        return s == 'true' || s == '1' || s == 'yes';
      }

      int toInt(dynamic v) {
        if (v is num) return v.toInt();
        return int.tryParse(str(v)) ?? 0;
      }

      final mapped = list.map<_Partner>((m) {
        final id = toInt(m['id']);
        final name = str(m['fullName'] ?? m['name']).isNotEmpty
            ? str(m['fullName'] ?? m['name'])
            : (id != 0 ? 'Partner #$id' : 'Partner');
        final vehicleNumber = str(m['vehicleNumber']);
        final mobileNumber = str(m['mobileNumber'] ?? m['primaryContact']);
        final available = toBool(m['available']);
        final active = toBool(m['active'] ?? m['enabled']);
        final status = active ? 'Active' : 'Inactive';
        return _Partner(
          id: id,
          name: name,
          vehicleNumber: vehicleNumber.isNotEmpty ? vehicleNumber : '—',
          mobileNumber: mobileNumber.isNotEmpty ? mobileNumber : '—',
          status: status,
          active: active,
          available: available,
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
        const SnackBar(content: Text('Failed to load delivery partners')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partners = _filtered();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddDeliveryPartnerScreen()),
          );
          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Delivery partner added successfully'),
              ),
            );
            _loadPartners();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Partner'),
      ),
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : partners.isEmpty
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
                          onTap: () => widget.onNavigate(
                            'delivery-reports:${partners[index].id}',
                          ),
                          onUpdated: _loadPartners,
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
              onSelected: (_) {
                setState(() => _selectedFilter = filter);
                _loadPartners();
              },
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
  final VoidCallback onUpdated;
  final int index;
  const _PartnerCard({
    required this.data,
    required this.onTap,
    required this.onUpdated,
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
                    child: const Icon(Icons.person, color: AppColors.orange600),
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
                          data.vehicleNumber,
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
                          Icons.phone,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data.mobileNumber,
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
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (data.id == 0) return;
                  try {
                    final ds = GetIt.I<DeliveryRemoteDataSource>();
                    if (value == 'block') {
                      await ds.blockPartner(partnerId: data.id);
                    } else if (value == 'unblock') {
                      await ds.unblockPartner(partnerId: data.id);
                    }
                    if (context.mounted) {
                      onUpdated();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value == 'block'
                                ? 'Partner blocked'
                                : 'Partner unblocked',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Action failed')),
                      );
                    }
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];
                  if (data.active) {
                    items.add(
                      const PopupMenuItem(value: 'block', child: Text('Block')),
                    );
                  } else {
                    items.add(
                      const PopupMenuItem(
                        value: 'unblock',
                        child: Text('Unblock'),
                      ),
                    );
                  }
                  return items;
                },
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
  final int id;
  final String name;
  final String vehicleNumber;
  final String status;
  final String mobileNumber;
  final bool active;
  final bool available;
  _Partner({
    required this.id,
    required this.name,
    required this.vehicleNumber,
    required this.status,
    required this.mobileNumber,
    required this.active,
    required this.available,
  });
}
