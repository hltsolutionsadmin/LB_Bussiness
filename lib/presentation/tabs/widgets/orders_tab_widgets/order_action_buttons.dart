import 'package:flutter/material.dart';
import 'package:local_basket_business/core/utils/order_status.dart';

class OrderActionButtons extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, dynamic>, String) onUpdateStatus;
  final bool isUpdating;

  const OrderActionButtons({
    super.key,
    required this.order,
    required this.onUpdateStatus,
    this.isUpdating = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = (order['orderStatus'] ?? order['status'] ?? '').toString();

    switch (merchantStage(status)) {
      // Two taps: Accept (→ CONFIRMED → PREPARING) then Mark as Ready (→ READY).
      case 'new':
        return _buildSingleButton(
          label: 'Accept Order',
          newStatus: 'CONFIRMED',
          color: Colors.green,
        );
      case 'confirmed':
      case 'preparing':
        return _buildSingleButton(
          label: 'Mark as Ready',
          newStatus: 'READY',
          color: const Color(0xFF10B981),
        );
      case 'ready':
      case 'cancelled':
      default:
        // READY (and anything the backend reports afterwards): no action
        // button — the card already exposes "View Order Details".
        return const SizedBox.shrink();
    }
  }

  Widget _buildSingleButton({
    required String label,
    required String newStatus,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isUpdating
            ? null
            : () => onUpdateStatus(order, newStatus),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isUpdating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }
}
