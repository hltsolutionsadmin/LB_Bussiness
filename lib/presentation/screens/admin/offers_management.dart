import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:local_basket_business/data/datasources/offers/offers_remote_data_source.dart';
import 'package:local_basket_business/data/models/offers/offer_models.dart';
import 'package:local_basket_business/presentation/screens/admin/save_offer_screen.dart';
import 'package:local_basket_business/theme/app_colors.dart';
import 'package:local_basket_business/widgets/glass_card.dart';

class OffersManagementScreen extends StatefulWidget {
  final VoidCallback onBack;
  final int businessId;

  const OffersManagementScreen({
    super.key,
    required this.onBack,
    this.businessId = 0,
  });

  @override
  State<OffersManagementScreen> createState() => _OffersManagementScreenState();
}

class _OffersManagementScreenState extends State<OffersManagementScreen> {
  bool _activeOnly = true;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 0;
  final int _size = 10;
  int _totalPages = 0;
  final List<Offer> _items = [];
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 280) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 0;
        _totalPages = 0;
        _items.clear();
      });
    }

    try {
      final ds = GetIt.I<OffersRemoteDataSource>();
      final res = await ds.listOffers(
        businessId: widget.businessId,
        active: _activeOnly,
        page: _page,
        size: _size,
      );
      if (!mounted) return;
      setState(() {
        _totalPages = res.totalPages;
        _items.addAll(res.items);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load offers')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore) return;
    if (_totalPages != 0 && (_page + 1) >= _totalPages) return;

    setState(() {
      _loadingMore = true;
      _page += 1;
    });

    try {
      final ds = GetIt.I<OffersRemoteDataSource>();
      final res = await ds.listOffers(
        businessId: widget.businessId,
        active: _activeOnly,
        page: _page,
        size: _size,
      );
      if (!mounted) return;
      setState(() {
        _totalPages = res.totalPages;
        _items.addAll(res.items);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _page = _page > 0 ? _page - 1 : 0);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SaveOfferScreen(businessId: widget.businessId),
      ),
    );
    if (created == true && mounted) {
      await _load(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Create Offer'),
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child:
                    GlassCard(
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: widget.onBack,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Offers',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              _ActiveToggle(
                                value: _activeOnly,
                                onChanged: (v) async {
                                  setState(() => _activeOnly = v);
                                  await _load(reset: true);
                                },
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 250.ms)
                        .slideX(begin: -0.1, end: 0, duration: 250.ms),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () => _load(reset: true),
                        child: _items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                      'No offers found',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                controller: _scroll,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  96,
                                ),
                                itemCount:
                                    _items.length + (_loadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _items.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }
                                  return _OfferCard(data: _items[index])
                                      .animate()
                                      .fadeIn(duration: 200.ms)
                                      .slideY(
                                        begin: 0.05,
                                        end: 0,
                                        duration: 200.ms,
                                      );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer data;
  const _OfferCard({required this.data});

  String _date(DateTime? d) {
    if (d == null) return '—';
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.name.isNotEmpty ? data.name : 'Offer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _StatusPill(active: data.active),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    label: data.offerType.isNotEmpty ? data.offerType : 'TYPE',
                  ),
                  _MetaChip(
                    label: 'Value: ${data.value.isNotEmpty ? data.value : '—'}',
                  ),
                  _MetaChip(
                    label: 'Min: ₹${data.minOrderValue.toStringAsFixed(0)}',
                  ),
                  if (data.couponCode.isNotEmpty)
                    _MetaChip(label: data.couponCode),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data.description.isNotEmpty ? data.description : '—',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Start: ${_date(data.startDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'End: ${_date(data.endDate)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool active;
  const _StatusPill({required this.active});

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? AppColors.success.withOpacity(0.15)
        : AppColors.error.withOpacity(0.12);
    final fg = active ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ActiveToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Active',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.orange600,
          ),
        ],
      ),
    );
  }
}
