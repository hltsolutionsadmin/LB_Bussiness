import 'package:flutter/material.dart';
import 'order_action_buttons.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isExpanded;
  final VoidCallback onTap;
  final Function(Map<String, dynamic>) onShowDetails;
  final Function(Map<String, dynamic>, String) onUpdateStatus;

  const OrderCard({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onTap,
    required this.onShowDetails,
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

  Color _getStatusColor(String status) {
    switch (_stage(status)) {
      case 'new':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (_stage(status)) {
      case 'new':
        return Icons.access_time;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
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
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildOrderHeader(),
            ),
          ),
          if (isExpanded) _buildExpandedDetails(),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LEFT SIDE (Expanded avoids overflow)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${order['orderNumber'] ?? ''}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order['username']?.toString() ?? '-',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                order['createdDate']?.toString() ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        /// RIGHT SIDE (fixed width)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${order['totalAmount'] ?? 0}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(order['orderStatus']?.toString() ?? ''),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _label(status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Details",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),

          // Order Details Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onShowDetails(order),
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Order Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF97316),
                side: const BorderSide(color: Color(0xFFF97316)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons based on order status
          OrderActionButtons(order: order, onUpdateStatus: onUpdateStatus),
        ],
      ),
    );
  }
}
