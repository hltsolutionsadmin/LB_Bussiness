import 'package:flutter/foundation.dart';

class AnalyticsStats {
  final int totalOrders;
  final double revenue;

  const AnalyticsStats({required this.totalOrders, required this.revenue});
}

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsStats? stats = const AnalyticsStats(
    totalOrders: 12450,
    revenue: 875432.75,
  );

  Future<void> refreshAnalytics() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Keep same dummy data for now
    notifyListeners();
  }
}
