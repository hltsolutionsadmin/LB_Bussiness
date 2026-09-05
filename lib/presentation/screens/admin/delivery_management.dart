import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_basket_business/theme/app_colors.dart';
import 'package:local_basket_business/widgets/glass_card.dart';
import 'package:local_basket_business/widgets/search_bar_widget.dart';
import 'package:local_basket_business/presentation/screens/admin/add_delivery_partner_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:local_basket_business/core/session/session_store.dart';
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

  final List<String> _filters = const ['All', 'Active', 'Pending', 'Available'];
  final List<_Partner> _all = [];
  final Set<String> _updatingPartnerIds = {};
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
      final b2bUnitId = GetIt.I<SessionStore>().b2bUnitId;
      if (b2bUnitId.isEmpty) {
        throw StateError('B2B unit ID not found');
      }
      final list = await ds.listAgentsByB2b(b2bUnitId: b2bUnitId);

      String str(dynamic v) => v?.toString() ?? '';
      bool toBool(dynamic v) {
        if (v is bool) return v;
        final s = str(v).toLowerCase();
        return s == 'true' || s == '1' || s == 'yes';
      }

      final mapped = list.map<_Partner>((m) {
        final id = str(m['agentId'] ?? m['id'] ?? m['deliveryPartnerId']);
        final firstName = str(m['firstName']);
        final lastName = str(m['lastName']);
        final fullNameFromParts = [
          firstName,
          lastName,
        ].where((p) => p.isNotEmpty).join(' ');
        final nameValue = str(m['fullName'] ?? m['name'] ?? m['displayName']);
        final name = fullNameFromParts.isNotEmpty
            ? fullNameFromParts
            : nameValue.isNotEmpty
            ? nameValue
            : (id.isNotEmpty ? 'Partner ${_shortId(id)}' : 'Partner');
        final vehicleNumber = str(
          m['vehicleNumber'] ?? m['vehicleRegistration'],
        );
        final mobileNumber = str(m['mobileNumber'] ?? m['primaryContact']);
        final available = toBool(m['available']);
        final apiStatus = str(m['status']);
        final active =
            toBool(m['active'] ?? m['enabled']) ||
            apiStatus.toUpperCase() == 'ACTIVE';
        final status = active
            ? 'Active'
            : apiStatus == 'PENDING_VERIFICATION'
            ? 'Pending'
            : 'Inactive';
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
                          onTap: () => _showPartnerDetails(partners[index]),
                          onReports: () => widget.onNavigate(
                            'delivery-reports:${partners[index].id}',
                          ),
                          isUpdating: _updatingPartnerIds.contains(
                            partners[index].id,
                          ),
                          onActiveChanged: (active) =>
                              _setPartnerActive(partners[index], active),
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
      if (_selectedFilter == 'Available') {
        list = list.where((p) => p.available).toList();
      } else {
        list = list.where((p) => p.status == _selectedFilter).toList();
      }
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

  Future<void> _setPartnerActive(_Partner partner, bool active) async {
    if (partner.id.isEmpty || _updatingPartnerIds.contains(partner.id)) {
      return;
    }

    final old = partner.active;
    if (old == active) return;

    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inactive delivery partner?'),
          content: const Text(
            'Are you sure you want to inactive the delivery partner?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      partner.active = active;
      partner.status = active ? 'Active' : 'Inactive';
      _updatingPartnerIds.add(partner.id);
    });

    try {
      final ds = GetIt.I<DeliveryRemoteDataSource>();
      await ds.setAgentStatus(
        partnerId: partner.id,
        status: active ? 'ACTIVE' : 'INACTIVE',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Partner activated' : 'Partner inactivated'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        partner.active = old;
        partner.status = old ? 'Active' : 'Inactive';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update partner status')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingPartnerIds.remove(partner.id));
      }
    }
  }

  void _showPartnerDetails(_Partner partner) {
    if (partner.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery partner id not found')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PartnerDetailsSheet(partner: partner),
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
  final VoidCallback onReports;
  final bool isUpdating;
  final ValueChanged<bool> onActiveChanged;
  final int index;
  const _PartnerCard({
    required this.data,
    required this.onTap,
    required this.onReports,
    required this.isUpdating,
    required this.onActiveChanged,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final card = GlassCard(
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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PartnerStatusToggle(
                active: data.active,
                busy: isUpdating,
                onChanged: onActiveChanged,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'reports') onReports();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'reports', child: Text('Reports')),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return (data.active ? card : Opacity(opacity: 0.55, child: card))
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideX(begin: 0.2, end: 0, duration: 300.ms);
  }
}

class _PartnerStatusToggle extends StatelessWidget {
  final bool active;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _PartnerStatusToggle({
    required this.active,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          active ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: 11,
            color: active ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        Transform.scale(
          scale: 0.72,
          child: Switch(
            value: active,
            onChanged: busy ? null : onChanged,
            activeColor: AppColors.success,
            activeTrackColor: AppColors.success.withOpacity(0.35),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Active':
      case 'Online':
        color = AppColors.success;
        break;
      case 'Pending':
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

class _PartnerDetailsSheet extends StatefulWidget {
  final _Partner partner;

  const _PartnerDetailsSheet({required this.partner});

  @override
  State<_PartnerDetailsSheet> createState() => _PartnerDetailsSheetState();
}

class _PartnerDetailsSheetState extends State<_PartnerDetailsSheet> {
  Map<String, dynamic>? _details;
  bool _loading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final data = await GetIt.I<DeliveryRemoteDataSource>().getAgentDetails(
        agentId: widget.partner.id,
      );
      if (!mounted) return;
      setState(() => _details = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to load delivery partner details');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _str(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? '—' : text;
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  String _formatStatus(String value) {
    if (value.isEmpty || value == '—') return widget.partner.status;
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final details = _details ?? const <String, dynamic>{};
    final displayName = _str(details['displayName']) == '—'
        ? widget.partner.name
        : _str(details['displayName']);
    final status = _formatStatus(_str(details['status']));
    final verified = _boolValue(details['verified']);
    final profileImageUrl = _str(details['profileImageUrl']);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.orange600.withOpacity(0.15),
                    backgroundImage: profileImageUrl == '—'
                        ? null
                        : NetworkImage(profileImageUrl),
                    child: profileImageUrl == '—'
                        ? const Icon(
                            Icons.person,
                            color: AppColors.orange600,
                            size: 34,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _PartnerStatusPill(status: status),
                            _InfoPill(
                              label: verified ? 'Verified' : 'Not verified',
                              color: verified
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorText != null)
              GlassCard(
                child: Column(
                  children: [
                    Text(
                      _errorText!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadDetails,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Assignments',
                      value: _str(details['activeAssignmentCount']),
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'Completed',
                      value: _str(details['totalCompleted']),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'Rating',
                      value: _str(details['rating']),
                      icon: Icons.star_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    _PartnerDetailRow(
                      icon: Icons.badge_outlined,
                      label: 'Agent ID',
                      value: _str(details['id']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.person_outline,
                      label: 'User ID',
                      value: _str(details['userId']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.store_outlined,
                      label: 'B2B Unit',
                      value: _str(details['b2bUnitId']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.storefront_outlined,
                      label: 'Store ID',
                      value: _str(details['storeId']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.delivery_dining,
                      label: 'Agent Type',
                      value: _formatStatus(_str(details['agentType'])),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.two_wheeler,
                      label: 'Vehicle Type',
                      value: _str(details['vehicleType']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.pin_outlined,
                      label: 'Vehicle Registration',
                      value: _str(details['vehicleRegistration']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.groups_outlined,
                      label: 'Max Assignments',
                      value: _str(details['maxConcurrentAssignments']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.reviews_outlined,
                      label: 'Rating Count',
                      value: _str(details['ratingCount']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.work_outline,
                      label: 'Session Mode',
                      value: _str(details['sessionMode']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.tune,
                      label: 'Specializations',
                      value: _str(details['specializations']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.notes,
                      label: 'Bio',
                      value: _str(details['bio']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Created',
                      value: _formatDate(details['createdDate']),
                    ),
                    _PartnerDetailRow(
                      icon: Icons.update,
                      label: 'Updated',
                      value: _formatDate(details['updatedDate']),
                      bottomDivider: false,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: AppColors.info, size: 20),
          const SizedBox(height: 8),
          Text(
            value == '—' ? '0' : value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PartnerDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool bottomDivider;

  const _PartnerDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bottomDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
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
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (bottomDivider) const Divider(height: 1),
      ],
    );
  }
}

class _PartnerStatusPill extends StatelessWidget {
  final String status;

  const _PartnerStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final color = lower.contains('active')
        ? AppColors.success
        : lower.contains('pending')
        ? AppColors.warning
        : AppColors.error;
    return _InfoPill(label: status, color: color);
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Partner {
  final String id;
  final String name;
  final String vehicleNumber;
  String status;
  final String mobileNumber;
  bool active;
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

String _shortId(String value) {
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}
