import 'package:flutter/material.dart';
import 'dart:async';
import 'package:local_basket_business/core/utils/responsive.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/domain/repositories/orders/orders_repository.dart';
import 'widgets/orders_tab_widgets/order_filters.dart';
import 'widgets/orders_tab_widgets/order_card.dart';
import 'widgets/orders_tab_widgets/order_details_dialog.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  String _selectedFilter = 'all';
  String? _expandedOrderId;
  final List<Map<String, dynamic>> _orders = [];
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  bool _hasNext = true;
  int _page = 0;
  final int _size = 10;

  Timer? _refreshTimer;
  Set<String> _previousOrderIds = <String>{};
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _startAutoRefresh();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasNext) {
        _loadPage();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _silentRefresh();
    });
  }

  Future<void> _silentRefresh() async {
    if (_loading) return;

    final businessId = _getBusinessId();
    if (businessId == null) return;

    try {
      final repo = sl<OrdersRepository>();
      final pageData = await repo.getOrdersByBusiness(
        businessId: businessId,
        page: 0,
        size: _size,
      );

      final newOrderIds = pageData.items
          .map((order) => order['id'].toString())
          .toSet();

      // Background popup/sound handled by global OrdersPoller now

      _previousOrderIds = newOrderIds;
      _isInitialLoad = false;

      // Update the orders list silently
      if (mounted) {
        setState(() {
          _orders.clear();
          _orders.addAll(pageData.items);
          _hasNext = pageData.hasNext;
          _page = 1; // Reset to next page
        });
      }
    } catch (e) {
      // Silent failure - don't show error to user during background refresh
      debugPrint('Silent refresh failed: $e');
    }
  }

  // Sound/popups are handled globally.

  // Helper methods
  int? _getBusinessId() {
    final user = sl<SessionStore>().user;
    return (user != null && user['b2bUnit'] is Map<String, dynamic>)
        ? (user['b2bUnit']['id'] as int?)
        : null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _stage(String status) {
    final s = status.toLowerCase();
    if (s.contains('ready')) return 'ready';
    if (s.contains('prepar')) return 'preparing';
    if (s.contains('new') || s.contains('place') || s.contains('accept')) {
      return 'new';
    }
    return s;
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (_loading) return;

    final businessId = _getBusinessId();
    if (businessId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('Business ID not found');
      });
      return;
    }

    setState(() => _loading = true);

    try {
      if (refresh) {
        _page = 0;
        _hasNext = true;
        _orders.clear();
        _isInitialLoad = true;
        _previousOrderIds.clear();
      }

      if (!_hasNext) return;

      final repo = sl<OrdersRepository>();
      final pageData = await repo.getOrdersByBusiness(
        businessId: businessId,
        page: _page,
        size: _size,
      );

      setState(() {
        _orders.addAll(pageData.items);
        _hasNext = pageData.hasNext;
        _page = pageData.page + 1;

        // Initialize previous order IDs on first load
        if (_isInitialLoad) {
          _previousOrderIds = _orders
              .map((order) => order['id'].toString())
              .toSet();
          _isInitialLoad = false;
        }
      });
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnackBar('Failed to load orders: $e');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateOrderStatus(
    Map<String, dynamic> order,
    String newStatus, {
    String notes = '0',
  }) async {
    final repo = sl<OrdersRepository>();
    final orderNumber = order['orderNumber']?.toString();
    if (orderNumber == null || orderNumber.isEmpty) {
      _showSnackBar('Order number missing');
      return;
    }

    try {
      await repo.updateOrderStatus(
        orderNumber: orderNumber,
        status: newStatus,
        notes: notes,
      );
      if (!mounted) return;
      setState(() {
        // Update the backing list instance too
        order['orderStatus'] = newStatus;
      });
      _showSnackBar('Updated to ${_label(newStatus)}');
    } catch (e) {
      _showSnackBar('Failed to update: $e');
    }
  }

  String _label(String status) {
    return status.isEmpty
        ? '—'
        : status
              .toString()
              .toLowerCase()
              .replaceAll('_', ' ')
              .split(' ')
              .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
              .join(' ');
  }

  void _showOrderDetailsDialog(
    Map<String, dynamic> order, {
    bool isNewOrder = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => OrderDetailsDialog(order: order, isNewOrder: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _selectedFilter == 'all'
        ? _orders
        : _orders
              .where(
                (o) =>
                    _stage(o['orderStatus']?.toString() ?? '') ==
                    _selectedFilter,
              )
              .toList();

    return Container(
      color: Colors.white.withOpacity(0.5),
      child: Column(
        children: [
          OrderFilters(
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadPage(refresh: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                ),
                itemCount: filteredOrders.isEmpty
                    ? 1
                    : filteredOrders.length +
                          ((_hasNext && _selectedFilter == 'all') ? 1 : 0),
                itemBuilder: (context, index) {
                  // Empty state when no items in current filter
                  if (filteredOrders.isEmpty) {
                    final title = _selectedFilter == 'all'
                        ? 'No orders yet'
                        : 'No ${_selectedFilter} orders';
                    final subtitle = _selectedFilter == 'all'
                        ? 'Orders will appear here as customers place them.'
                        : 'Try switching filters or refresh to check again.';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 56),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.inbox_outlined,
                              size: 36,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _loadPage(refresh: true),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Refresh'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF97316),
                              side: const BorderSide(color: Color(0xFFF97316)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Bottom loader only when viewing 'all'
                  if (index >= filteredOrders.length &&
                      _selectedFilter == 'all') {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final order = filteredOrders[index];
                  final isExpanded = _expandedOrderId == order['id'].toString();

                  return OrderCard(
                    order: order,
                    isExpanded: isExpanded,
                    onTap: () {
                      setState(() {
                        _expandedOrderId = isExpanded
                            ? null
                            : order['id'].toString();
                      });
                    },
                    onShowDetails: _showOrderDetailsDialog,
                    onUpdateStatus: _updateOrderStatus,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
