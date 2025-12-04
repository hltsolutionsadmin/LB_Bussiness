import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/data/models/orders/orders_models.dart';

class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._client, this._storage);

  final DioClient _client;
  final AppSecureStorage _storage;

  Options _authOptions(String? bearer) {
    return Options(
      headers: {
        if (bearer != null && bearer.isNotEmpty)
          'Authorization': 'Bearer $bearer',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<OrdersPage> getOrdersByBusiness({
    required int businessId,
    required int page,
    required int size,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] List Orders -> GET /order/api/orders/business/$businessId?page=$page&size=$size',
      );
    }
    final res = await _client.dio.get(
      '/order/api/orders/business/$businessId',
      queryParameters: {'page': page, 'size': size},
      options: _authOptions(token),
    );
    final data = res.data;

    List list;
    int totalPages = 0;
    int number = page;

    if (data is Map<String, dynamic>) {
      // Handle {content: [...], totalPages, number}
      if (data['content'] is List) {
        list = data['content'] as List;
        totalPages = (data['totalPages'] as int?) ?? 0;
        number = (data['number'] as int?) ?? page;
      }
      // Handle wrapper { success, message, data: {...}}
      else if (data['data'] is Map<String, dynamic>) {
        final inner = data['data'] as Map<String, dynamic>;
        list = (inner['content'] is List) ? inner['content'] as List : const [];
        totalPages = (inner['totalPages'] as int?) ?? 0;
        number = (inner['number'] as int?) ?? page;
      }
      // Handle wrapper { success, message, data: [...] }
      else if (data['data'] is List) {
        list = data['data'] as List;
      } else {
        list = [];
      }
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    final items = list.whereType<Map>().map<Map<String, dynamic>>((raw) {
      final m = Map<String, dynamic>.from(raw);
      double toDouble(dynamic v) {
        if (v is num) return v.toDouble();
        final s = v?.toString();
        return double.tryParse(s ?? '') ?? 0.0;
      }

      String str(dynamic v) => v?.toString() ?? '';
      // Pass-through full fields when present so UI can render complete details
      return {
        'id': m['id'],
        // Common fields
        'orderNumber': str(m['orderNumber'] ?? m['code']),
        'status': str(m['status'] ?? m['orderStatus']),
        'total': toDouble(m['total'] ?? m['grandTotal'] ?? m['totalAmount']),
        'createdAt': m['createdAt'] ?? m['orderDate'] ?? m['createdDate'],
        'customerName': str(
          m['customerName'] ?? m['name'] ?? m['username'] ?? m['userName'],
        ),
        'itemsCount':
            m['itemsCount'] ??
            (m['items'] is List ? (m['items'] as List).length : 0),

        // Fields used by UI directly
        'orderStatus': str(m['orderStatus'] ?? m['status']),
        'username': str(
          m['username'] ?? m['userName'] ?? m['customerName'] ?? m['name'],
        ),
        'createdDate': m['createdDate'] ?? m['createdAt'] ?? m['orderDate'],
        'updatedDate': m['updatedDate'] ?? m['updatedAt'],
        'totalAmount': toDouble(
          m['totalAmount'] ?? m['total'] ?? m['grandTotal'],
        ),

        // Additional fields from API response
        'mobileNumber': str(m['mobileNumber']),
        'notes': str(m['notes']),
        'paymentStatus': str(m['paymentStatus']),
        'deliveryStatus': str(m['deliveryStatus']),
        'totalTaxAmount': toDouble(m['totalTaxAmount']),
        'taxInclusive': m['taxInclusive'] == true,
        'selfOrder': m['selfOrder'] == true,

        // Delivery partner info
        'deliveryPartnerId': str(m['deliveryPartnerId']),
        'deliveryPartnerName': str(m['deliveryPartnerName']),
        'deliveryPartnerMobileNumber': str(m['deliveryPartnerMobileNumber']),

        // Addresses (pass-through maps if present)
        'userAddress': (m['userAddress'] is Map)
            ? Map<String, dynamic>.from(m['userAddress'] as Map)
            : null,
        'businessAddress': (m['businessAddress'] is Map)
            ? Map<String, dynamic>.from(m['businessAddress'] as Map)
            : null,

        // Order items (list of maps)
        'orderItems': (m['orderItems'] is List)
            ? List<Map<String, dynamic>>.from(
                (m['orderItems'] as List).whereType<Map>().map(
                  (e) => Map<String, dynamic>.from(e),
                ),
              )
            : null,
      };
    }).toList();

    if (kDebugMode && items.isNotEmpty) {
      debugPrint('[API] Orders normalized sample: ${items.first}');
    }

    final hasNext = totalPages == 0
        ? items.length == size
        : (number + 1) < totalPages;

    return OrdersPage(items: items, hasNext: hasNext, page: number, size: size);
  }

  Future<void> updateOrderStatus({
    required String orderNumber,
    required String status,
    String? notes,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Update Order Status -> POST /order/api/orders/status/$orderNumber status=$status notes=${notes ?? ''}',
      );
    }
    final payload = <String, dynamic>{
      'status': status,
      'updatedBy': '',
      if (notes != null) 'notes': notes,
    };
    if (kDebugMode) {
      debugPrint('[API] Update Order Status Payload: $payload');
    }
    await _client.dio.post(
      '/order/api/orders/status/$orderNumber',
      data: payload,
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
    );
  }
}
