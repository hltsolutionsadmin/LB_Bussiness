import 'package:flutter/material.dart';

class OrderActionButtons extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, dynamic>, String) onUpdateStatus;

  const OrderActionButtons({
    super.key,
    required this.order,
    required this.onUpdateStatus,
  });

  String _stage(String status) {
    final s = status.toLowerCase();
    if (s.contains('ready')) return 'ready';
    if (s.contains('prepar')) return 'preparing';
    if (s.contains('accept')) return 'preparing';
    if (s.contains('new') || s.contains('place')) {
      return 'new';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final status = (order['orderStatus'] ?? '').toString();
    final stage = _stage(status);

    switch (stage) {
      case 'new':
        return _buildNewOrderButtons();
      case 'preparing':
        return _buildPreparingOrderButton();
      case 'ready':
        return _buildReadyOrderInfo();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNewOrderButtons() {
    // Initial: Accept or Reject (Accept moves directly to PREPARING)
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => onUpdateStatus(order, 'PREPARING'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Accept Order'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => onUpdateStatus(order, 'REJECTED'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reject'),
          ),
        ),
      ],
    );
  }

  Widget _buildPreparingOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => onUpdateStatus(order, 'READY_FOR_PICKUP'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Mark as Ready'),
      ),
    );
  }

  Widget _buildReadyOrderInfo() {
    return const Text(
      'Order is ready for pickup',
      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
    );
  }
}
