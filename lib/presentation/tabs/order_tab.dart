import 'package:flutter/material.dart';
import 'dart:async';
import 'package:local_basket_business/core/utils/responsive.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/core/services/orders_poller.dart';
import 'package:local_basket_business/core/utils/order_status.dart';
import 'package:local_basket_business/domain/repositories/orders/orders_repository.dart';
import 'widgets/orders_tab_widgets/order_filters.dart';
import 'widgets/orders_tab_widgets/order_card.dart';
import 'widgets/orders_tab_widgets/order_card_shimmer.dart';
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
  bool _silentRefreshing = false;
  bool _hasNext = true;
  int _page = 0;
  final int _size = 10;

  Timer? _refreshTimer;
  Timer? _initialWaitTimer;
  int _initialWaitTicks = 0;
  Set<String> _previousOrderIds = <String>{};
  bool _isInitialLoad = true;
  String? _lastStoreId;
  final Set<String> _updatingOrderIds = <String>{};

  @override
  void initState() {
    super.initState();
    sl<SessionStore>().addListener(_onSessionChanged);
    // The popup can accept/reject an order while this tab is already mounted;
    // re-apply the merchant's status onto the visible list when that happens
    // so a card doesn't keep showing the old ("new") status.
    sl<OrdersPoller>().addListener(_onMerchantStatusChanged);
    _onSessionChanged();

    // In some cases the tab is built before userDetails finishes and
    // businessId isn't available yet. Wait briefly and auto-trigger load.
    _initialWaitTimer ??= Timer.periodic(const Duration(milliseconds: 500), (
      t,
    ) {
      _initialWaitTicks += 1;
      final sid = _getStoreId();
      if (sid != null && sid.isNotEmpty) {
        t.cancel();
        _initialWaitTimer = null;
        _initialWaitTicks = 0;
        _onSessionChanged();
        return;
      }
      // stop after ~10 seconds
      if (_initialWaitTicks >= 20) {
        t.cancel();
        _initialWaitTimer = null;
      }
    });

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
    _initialWaitTimer?.cancel();
    sl<SessionStore>().removeListener(_onSessionChanged);
    sl<OrdersPoller>().removeListener(_onMerchantStatusChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onMerchantStatusChanged() {
    if (!mounted) return;
    setState(_applyLocalStatus);
  }

  void _onSessionChanged() {
    final storeId = _getStoreId();
    if (storeId == null || storeId.isEmpty) return;

    // Start auto refresh only after storeId is available.
    if (_refreshTimer == null) {
      _startAutoRefresh();
    }

    // If storeId became available (or changed), force a refresh.
    if (_lastStoreId != storeId) {
      _lastStoreId = storeId;
      _loadPage(refresh: true);
      return;
    }

    // If we previously couldn't load (empty list), try once.
    if (_orders.isEmpty && !_loading) {
      _loadPage(refresh: true);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _silentRefresh();
    });
  }

  Future<void> _silentRefresh() async {
    if (_loading || _silentRefreshing) return;

    final storeId = _getStoreId();
    if (storeId == null || storeId.isEmpty) return;

    // Don't disrupt the user while they're scrolling through older pages.
    if (_scrollController.hasClients &&
        _scrollController.position.pixels > 40) {
      return;
    }

    _silentRefreshing = true;

    try {
      final repo = sl<OrdersRepository>();
      final pageData = await repo.getOrdersByStore(
        storeId: storeId,
        page: 0,
        size: _size,
      );

      // Only today's orders belong on this live board.
      final incoming = pageData.items.where(_isToday).toList();

      // If page 0 already spills into an earlier day, today's orders don't
      // even fill one page — so there's no next page of them to load, and the
      // footer should read "no more orders" rather than spin forever.
      final reachedEarlierDay = incoming.length < pageData.items.length;

      final newOrderIds = incoming
          .map((order) => order['id'].toString())
          .toSet();

      // Background popup/sound handled by global OrdersPoller now

      _previousOrderIds = newOrderIds;
      _isInitialLoad = false;

      // Update the orders list silently
      if (mounted) {
        setState(() {
          // Replace the first page without clearing everything
          if (_orders.isEmpty) {
            _orders.addAll(incoming);
          } else {
            final replaceCount = incoming.length < _orders.length
                ? incoming.length
                : _orders.length;
            for (int i = 0; i < replaceCount; i++) {
              _orders[i] = incoming[i];
            }
            if (incoming.length > _orders.length) {
              _orders.addAll(incoming.sublist(_orders.length));
            }
          }
          _hasNext = pageData.hasNext && !reachedEarlierDay;
          _page = 1; // Next page after refresh
          _applyLocalStatus();
        });
      }
    } catch (e) {
      // Silent failure - don't show error to user during background refresh
      debugPrint('Silent refresh failed: $e');
    } finally {
      _silentRefreshing = false;
    }

    // Evaluate against the freshly loaded list right away, using this screen's
    // live context so the popup is guaranteed to have somewhere to attach.
    if (mounted) {
      sl<OrdersPoller>().alertFromScreen(
        List<Map<String, dynamic>>.from(_orders),
        context,
      );
    }
  }

  // Sound/popups are handled globally.

  // Helper methods
  String? _getStoreId() {
    return sl<SessionStore>().storeId;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _stage(String status) => merchantStage(status);

  /// This screen is a live "today's orders" board — anything placed on an
  /// earlier day belongs in the Profile ▸ Past Orders history instead.
  bool _isToday(Map<String, dynamic> o) {
    final raw = o['createdDate'] ?? o['createdAt'] ?? o['created'];
    final dt = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// The merchant's own progression lives on the (singleton) OrdersPoller so
  /// the popup and this list agree. Once the merchant has acted, their choice
  /// is authoritative — the backend status (even ASSIGNED_TO_DELIVERY_PARTNER)
  /// is ignored.
  void _applyLocalStatus() {
    final local = sl<OrdersPoller>().merchantStatus;
    for (final o in _orders) {
      final s = local[o['id']?.toString()];
      if (s != null) o['orderStatus'] = s;
    }
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (_loading) return;

    final storeId = _getStoreId();
    if (storeId == null || storeId.isEmpty) return;

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
      final pageData = await repo.getOrdersByStore(
        storeId: storeId,
        page: _page,
        size: _size,
      );

      // Orders come back newest-first, so once a page contains an order from
      // an earlier day we've reached the end of "today" — stop paginating
      // rather than walking further back through history.
      final todayItems = pageData.items.where(_isToday).toList();
      final reachedEarlierDay = todayItems.length < pageData.items.length;

      setState(() {
        _orders.addAll(todayItems);
        _hasNext = pageData.hasNext && !reachedEarlierDay;
        _page = pageData.page + 1;

        // Initialize previous order IDs on first load
        if (_isInitialLoad) {
          _previousOrderIds = _orders
              .map((order) => order['id'].toString())
              .toSet();
          _isInitialLoad = false;
        }
        _applyLocalStatus();
      });

      if (mounted && _page <= 1) {
        sl<OrdersPoller>().alertFromScreen(
          List<Map<String, dynamic>>.from(pageData.items),
          context,
        );
      }
    } catch (e) {
      if (_orders.isEmpty) {
        // Nothing on screen yet — this is a real failure, surface it.
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSnackBar('Failed to load orders: $e');
          });

          // If initial load fails while the session is still settling, retry once.
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            if (!_loading) {
              _loadPage(refresh: true);
            }
          });
        }
      } else if (mounted) {
        // Orders are already showing — treat a failed "load more" as having
        // reached the end of the list instead of surfacing a raw Dio error.
        setState(() => _hasNext = false);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// One handler for the single button a card ever shows. The next backend
  /// status is derived from the order's *current* stage — one transition per
  /// tap: new → CONFIRMED → PREPARING → READY.
  Future<void> _updateOrderStatus(
    Map<String, dynamic> order,
    String _,
  ) async {
    final repo = sl<OrdersRepository>();
    final orderId = order['id']?.toString();
    if (orderId == null || orderId.isEmpty) {
      _showSnackBar('Order ID missing');
      return;
    }

    final current = (order['orderStatus'] ?? order['status'] ?? '').toString();
    final chain = nextOrderStatuses(current);
    if (chain == null || chain.isEmpty) return;

    if (mounted) {
      setState(() => _updatingOrderIds.add(orderId));
    }

    try {
      String? applied;
      for (final s in chain) {
        await repo.updateOrderStatus(orderId: orderId, status: s);
        applied = s;
        // Record each step as it lands, so a later failure never leaves the
        // card showing a status earlier than what actually went through.
        sl<OrdersPoller>().recordMerchantStatus(orderId, s);
      }
      if (!mounted) return;
      setState(() {
        order['orderStatus'] = applied;
      });
      _showSnackBar('Updated to ${merchantStatusLabel(applied!)}');
    } catch (e) {
      _showSnackBar('Failed to update: $e');
    } finally {
      if (mounted) {
        setState(() => _updatingOrderIds.remove(orderId));
      }
    }
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
                          (_selectedFilter == 'all' ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loader during initial load, empty state only after loading completes
                  if (filteredOrders.isEmpty) {
                    // Show loader during initial load
                    if (_loading && _isInitialLoad) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 56),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Loading orders...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // Show empty state only after loading completes
                    final title = _selectedFilter == 'all'
                        ? 'No orders yet'
                        : 'No $_selectedFilter orders';
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

                  // Bottom footer only when viewing 'all': a loader while more
                  // pages remain, or an end-of-list message once they don't
                  // (including when a "load more" fetch failed).
                  if (index >= filteredOrders.length &&
                      _selectedFilter == 'all') {
                    if (_hasNext) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
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

                  final order = filteredOrders[index];
                  final orderId = order['id']?.toString() ?? '';

                  // While a status change is in flight, show a skeleton rather
                  // than the card with its soon-to-be-stale status.
                  if (_updatingOrderIds.contains(orderId)) {
                    return const OrderCardShimmer();
                  }

                  final isExpanded = _expandedOrderId == order['id'].toString();

                  return OrderCard(
                    order: order,
                    isExpanded: isExpanded,
                    isUpdating: false,
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
