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
    if (s.contains('new') || s.contains('place') || s.contains('accept')) {
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
    final s = (order['orderStatus']?.toString() ?? '').toLowerCase();
    final isAccepted = s.contains('accept');

    if (isAccepted) {
      // After accepted, show Start Preparing and Reject
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => onUpdateStatus(order, 'PREPARING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Preparing'),
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

    // Initial: Accept or Reject
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => onUpdateStatus(order, 'ACCEPTED'),
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
