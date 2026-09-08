import 'package:flutter/foundation.dart';

/// Shared source of truth for which dashboard bottom-nav tab is showing.
///
/// [DashboardScreen] listens and switches tabs whenever this changes;
/// services outside the widget tree (like [OrdersPoller], after the merchant
/// accepts/rejects a new order) can call [goToOrders] to jump the merchant
/// to the Orders tab regardless of which screen they were on.
class TabNavigationService extends ChangeNotifier {
  static const int ordersTabIndex = 1;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void goToOrders() => setIndex(ordersTabIndex);
}
