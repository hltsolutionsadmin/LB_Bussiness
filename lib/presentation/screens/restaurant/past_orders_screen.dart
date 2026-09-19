import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/core/utils/responsive.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/domain/repositories/orders/orders_repository.dart';
import 'package:local_basket_business/presentation/tabs/widgets/orders_tab_widgets/order_details_dialog.dart';

/// Order history for the store — delivered orders only, across all days.
/// The live "Orders" tab is a today-only board; this is where past,
/// completed orders live. Store-admin/restaurant-owner only (see the
/// Profile menu entry that opens this screen).
class PastOrdersScreen extends StatefulWidget {
  const PastOrdersScreen({super.key});

  @override
  State<PastOrdersScreen> createState() => _PastOrdersScreenState();
}

class _PastOrdersScreenState extends State<PastOrdersScreen> {
  final List<Map<String, dynamic>> _orders = [];
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  bool _initialLoading = true;
  bool _hasNext = true;
  int _page = 0;
  final int _size = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasNext) {
        _loadPage();
      }
    });
    _loadPage(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isDelivered(Map<String, dynamic> order) {
    final status = (order['orderStatus'] ?? order['status'] ?? '')
        .toString()
        .toUpperCase();
    return status.contains('DELIVER');
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (_loading) return;

    final storeId = sl<SessionStore>().storeId;
    if (storeId.isEmpty) {
      if (mounted) setState(() => _initialLoading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      if (refresh) {
        _page = 0;
        _hasNext = true;
        _orders.clear();
      }

      if (!_hasNext) return;

      final repo = sl<OrdersRepository>();
      final collected = <Map<String, dynamic>>[];
      var page = _page;
      var hasNext = _hasNext;

      // Orders come back store-wide and are filtered to DELIVERED here, so
      // most pages may hold none. Walk forward until we've gathered about a
      // screenful of delivered orders or hit the true end — otherwise the
      // footer just spins on a store with lots of non-delivered orders.
      var guard = 0;
      while (hasNext && collected.length < _size && guard < 30) {
        guard++;
        final pageData = await repo.getOrdersByStore(
          storeId: storeId,
          page: page,
          size: _size,
        );
        collected.addAll(pageData.items.where(_isDelivered));
        hasNext = pageData.hasNext;
        page = pageData.page + 1;
      }

      if (!mounted) return;
      setState(() {
        _orders.addAll(collected);
        _hasNext = hasNext;
        _page = page;
      });
    } catch (e) {
      if (mounted && _orders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load past orders: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialLoading = false;
        });
      }
    }
  }

  void _showDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (_) => OrderDetailsDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Past Orders'),
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(refresh: true),
        child: _initialLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildList(context),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_orders.isEmpty) {
      // No delivered orders found yet, but there may be more pages to scan.
      final moreToCheck = _hasNext;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 96),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 44,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    moreToCheck
                        ? 'No delivered orders in recent orders'
                        : 'No delivered orders yet',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  if (moreToCheck) ...[
                    const SizedBox(height: 16),
                    _loading
                        ? const CircularProgressIndicator()
                        : OutlinedButton.icon(
                            onPressed: () => _loadPage(),
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text('Check older orders'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF97316),
                              side: const BorderSide(color: Color(0xFFF97316)),
                            ),
                          ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 12,
      ),
      itemCount: _orders.length + 1,
      itemBuilder: (context, index) {
        if (index >= _orders.length) {
          if (_loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_hasNext) {
            // Idle with more pages to scan — a tap, not a forever-spinner.
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () => _loadPage(),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Load older orders'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF97316),
                    side: const BorderSide(color: Color(0xFFF97316)),
                  ),
                ),
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No more orders to show',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final order = _orders[index];
        return _PastOrderCard(
          order: order,
          onTap: () => _showDetails(order),
        );
      },
    );
  }
}

class _PastOrderCard extends StatelessWidget {
  const _PastOrderCard({required this.order, required this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  String get _formattedDate {
    final raw = order['createdDate'] ?? order['createdAt'];
    final dt = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order['orderNumber'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['username']?.toString() ?? '-',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${order['totalAmount'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.25),
                      ),
                    ),
                    child: const Text(
                      'Delivered',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
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
