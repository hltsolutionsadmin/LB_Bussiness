import 'package:flutter/material.dart';

/// Minimal, dependency-light "new order arrived" alert shown by [OrdersPoller].
/// Deliberately simple so it can never fail to render over the app.
class NewOrderAlertDialog extends StatelessWidget {
  const NewOrderAlertDialog({
    super.key,
    required this.order,
    required this.acceptLabel,
    required this.onAccept,
  });

  final Map<String, dynamic> order;
  final String acceptLabel;
  final Future<void> Function() onAccept;

  String get _orderNo =>
      (order['orderNumber'] ?? order['id'] ?? '').toString();
  String get _customer =>
      (order['username'] ?? order['customerName'] ?? '').toString();
  String get _total =>
      (order['totalAmount'] ?? order['total'] ?? order['totalPrice'] ?? 0)
          .toString();
  int get _itemCount {
    final items = order['orderItems'] ?? order['orderItems'];
    if (items is List) return items.length;
    final c = order['itemsCount'];
    return c is int ? c : int.tryParse('$c') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFF97316),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'New Order',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Order', _orderNo.isEmpty ? '-' : '#$_orderNo'),
          if (_customer.isNotEmpty) _row('Customer', _customer),
          _row('Items', '$_itemCount'),
          _row('Total', '₹$_total', bold: true),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(acceptLabel),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
