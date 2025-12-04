import 'package:flutter/material.dart';
import 'package:local_basket_business/core/utils/responsive.dart';

class OrderDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isNewOrder;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const OrderDetailsDialog({
    super.key,
    required this.order,
    this.isNewOrder = false,
    this.onAccept,
    this.onReject,
  });

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

  bool _isNewOrderStatus(String status) {
    final s = status.toLowerCase();
    return s.contains('new') ||
        s.contains('place') ||
        (s.contains('pending') && !s.contains('accept'));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: Responsive.isTablet(context) ? 600 : 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(context), _buildContent(context)],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Order #${order['orderNumber'] ?? ''}',
              style: TextStyle(
                fontSize: Responsive.headingFontSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Flexible(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNewOrder) ...[
              _buildDetailSection('Order Summary', [
                _buildDetailRow(
                  'Order Number',
                  order['orderNumber']?.toString() ?? '-',
                ),
                _buildDetailRow(
                  'Customer',
                  order['username']?.toString() ?? '-',
                ),
                _buildDetailRow(
                  'Total Amount',
                  '₹${order['totalAmount'] ?? 0}',
                  isBold: true,
                ),
              ]),
              const SizedBox(height: 16),

              // Order Items (main focus for new orders)
              _buildDetailSection('Order Items', [
                if (order['orderItems'] != null && order['orderItems'] is List)
                  ...((order['orderItems'] as List)
                      .map((item) => _buildOrderItem(item))
                      .toList())
                else
                  const Text(
                    'No items available',
                    style: TextStyle(color: Colors.grey),
                  ),
              ]),
            ] else ...[
              // Full details for existing orders
              // Customer Information
              _buildDetailSection('Customer Information', [
                _buildDetailRow('Name', order['username']?.toString() ?? '-'),
                _buildDetailRow(
                  'Mobile',
                  order['mobileNumber']?.toString() ?? '-',
                ),
                if (order['userAddress'] != null)
                  _buildAddressRow(order['userAddress']),
              ]),
              const SizedBox(height: 16),

              // Order Information
              _buildDetailSection('Order Information', [
                _buildDetailRow(
                  'Order Number',
                  order['orderNumber']?.toString() ?? '-',
                ),
                _buildDetailRow(
                  'Created Date',
                  order['createdDate']?.toString().split('.').first ?? '-',
                ),
                _buildDetailRow(
                  'Updated Date',
                  order['updatedDate']?.toString().split('.').first ?? '-',
                ),
                _buildDetailRow(
                  'Order Status',
                  _label(order['orderStatus']?.toString() ?? ''),
                ),
                _buildDetailRow(
                  'Payment Status',
                  _label(order['paymentStatus']?.toString() ?? ''),
                ),
                _buildDetailRow(
                  'Delivery Status',
                  _label(order['deliveryStatus']?.toString() ?? ''),
                ),
                if (order['notes'] != null &&
                    order['notes'].toString().isNotEmpty)
                  _buildDetailRow('Notes', order['notes']?.toString() ?? '-'),
              ]),
              const SizedBox(height: 16),

              // Order Items
              _buildDetailSection('Order Items', [
                if (order['orderItems'] != null && order['orderItems'] is List)
                  ...((order['orderItems'] as List)
                      .map((item) => _buildOrderItem(item))
                      .toList())
                else
                  const Text(
                    'No items available',
                    style: TextStyle(color: Colors.grey),
                  ),
              ]),
              const SizedBox(height: 16),

              // Pricing Details
              _buildDetailSection('Pricing Details', [
                _buildDetailRow(
                  'Total Tax',
                  '₹${order['totalTaxAmount'] ?? 0}',
                ),
                _buildDetailRow(
                  'Tax Inclusive',
                  order['taxInclusive'] == true ? 'Yes' : 'No',
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  'Total Amount',
                  '₹${order['totalAmount'] ?? 0}',
                  isBold: true,
                ),
              ]),
              const SizedBox(height: 16),

              // Delivery Partner Information
              if (order['deliveryPartnerId'] != null)
                Column(
                  children: [
                    _buildDetailSection('Delivery Partner', [
                      _buildDetailRow(
                        'Partner ID',
                        order['deliveryPartnerId']?.toString() ?? '-',
                      ),
                      _buildDetailRow(
                        'Name',
                        order['deliveryPartnerName']?.toString() ?? '-',
                      ),
                      _buildDetailRow(
                        'Mobile',
                        order['deliveryPartnerMobileNumber']?.toString() ?? '-',
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],
                ),

              // Business Information
              if (order['businessAddress'] != null)
                _buildDetailSection('Business Address', [
                  _buildBusinessAddressRow(order['businessAddress']),
                ]),
            ],

            // Accept/Reject buttons for new orders only
            if ((isNewOrder ||
                    _isNewOrderStatus(
                      order['orderStatus']?.toString() ?? '',
                    )) &&
                (onAccept != null || onReject != null))
              Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.new_releases,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'New Order - Action Required',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (onAccept != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: onAccept,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Accept Order'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            if (onAccept != null && onReject != null)
                              const SizedBox(width: 12),
                            if (onReject != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: onReject,
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Reject Order'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final taxAmount = item['taxAmount'] ?? 0;
    final totalAmount = item['totalAmount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item['productName']?.toString() ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '₹${item['price'] ?? 0}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity: ${item['quantity'] ?? 0}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (taxAmount > 0)
                Text(
                  'Tax: ₹$taxAmount',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          if (totalAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Item Total: ₹$totalAmount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF97316),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(Map<String, dynamic> address) {
    final addressLine1 = address['addressLine1']?.toString() ?? '';
    final addressLine2 = address['addressLine2']?.toString() ?? '';
    final street = address['street']?.toString() ?? '';
    final city = address['city']?.toString() ?? '';
    final state = address['state']?.toString() ?? '';
    final postalCode = address['postalCode']?.toString() ?? '';
    final country = address['country']?.toString() ?? '';

    final fullAddress = [
      if (addressLine1.isNotEmpty) addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (postalCode.isNotEmpty) postalCode,
      if (country.isNotEmpty) country,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fullAddress.isNotEmpty ? fullAddress : '-',
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessAddressRow(Map<String, dynamic> address) {
    final addressLine1 = address['addressLine1']?.toString() ?? '';
    final city = address['city']?.toString() ?? '';
    final state = address['state']?.toString() ?? '';
    final postalCode = address['postalCode']?.toString() ?? '';
    final country = address['country']?.toString() ?? '';

    final fullAddress = [
      if (addressLine1.isNotEmpty) addressLine1,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (postalCode.isNotEmpty) postalCode,
      if (country.isNotEmpty) country,
    ].join(', ');

    return Text(
      fullAddress.isNotEmpty ? fullAddress : '-',
      style: const TextStyle(fontSize: 14),
    );
  }
}
