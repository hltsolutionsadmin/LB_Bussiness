import 'package:flutter/material.dart';

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

  String _stage(String status) {
    final s = status.toLowerCase();
    if (s.contains('created') ||
        s.contains('new') ||
        s.contains('place') ||
        s.contains('pending')) {
      return 'new';
    }
    if (s.contains('confirm') || s.contains('accept')) return 'confirmed';
    if (s.contains('prepar')) return 'preparing';
    if (s.contains('ready')) return 'ready';
    if (s.contains('picked')) return 'picked_up';
    if (s.contains('delivered')) return 'delivered';
    if (s.contains('in_delivery')) return 'in_delivery';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final status = (order['orderStatus'] ?? '').toString();
    final stage = _stage(status);

    switch (stage) {
      case 'new':
        return _buildNewOrderButtons();
      case 'confirmed':
        return _buildSingleButton(
          label: 'Start Preparing',
          newStatus: 'PREPARING',
          color: const Color(0xFFF59E0B),
        );
      case 'preparing':
        return _buildSingleButton(
          label: 'Ready to Pick Up',
          newStatus: 'IN_DELIVERY',
          color: const Color(0xFF06B6D4),
        );
      default:
        return _buildStatusOnly(status);
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

  Widget _buildStatusOnly(String status) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _label(status),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNewOrderButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isUpdating
                ? null
                : () => onUpdateStatus(order, 'CONFIRMED'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
                : const Text('Accept Order'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isUpdating
                ? null
                : () => onUpdateStatus(order, 'REJECTED'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
                : const Text('Reject'),
          ),
        ),
      ],
    );
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
