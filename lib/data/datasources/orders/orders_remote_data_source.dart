import 'package:dio/dio.dart';
import 'dart:io';
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
        'Accept': 'application/json',
      },
    );
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    List list;
    if (data is Map<String, dynamic>) {
      if (data['content'] is List) {
        list = data['content'] as List;
      } else if (data['data'] is List) {
        list = data['data'] as List;
      } else if (data['data'] is Map<String, dynamic>) {
        final nested = data['data'] as Map<String, dynamic>;
        if (nested['content'] is List) {
          list = nested['content'] as List;
        } else if (nested['data'] is List) {
          list = nested['data'] as List;
        } else {
          list = [];
        }
      } else {
        list = [];
      }
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAdminOverallReport({
    required String period,
    required String fromDate,
    required String toDate,
  }) async {
    final token = await _storage.readToken();
    final p = period.toLowerCase();
    if (kDebugMode) {
      debugPrint(
        '[API] Admin Overall Report -> GET /order/report/admin/overall/$p?from=$fromDate&to=$toDate',
      );
    }
    final res = await _client.dio.get(
      '/order/report/admin/overall/$p',
      queryParameters: {'from': fromDate, 'to': toDate},
      options: _authOptions(token),
    );
    return _extractList(res.data);
  }

  Future<List<Map<String, dynamic>>> getAdminBusinessReport({
    required int businessId,
    required String period,
    required String fromDate,
    required String toDate,
  }) async {
    final token = await _storage.readToken();
    final p = period.toLowerCase();
    if (kDebugMode) {
      debugPrint(
        '[API] Admin Business Report -> GET /order/report/admin/business/$businessId/$p?from=$fromDate&to=$toDate',
      );
    }
    final res = await _client.dio.get(
      '/order/report/admin/business/$businessId/$p',
      queryParameters: {'from': fromDate, 'to': toDate},
      options: _authOptions(token),
    );
    return _extractList(res.data);
  }

  Future<OrdersPage> getOrdersByStore({
    required String storeId,
    required int page,
    required int size,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] List Orders -> GET /api/orders/store/$storeId?page=$page&size=$size',
      );
    }
    final res = await _client.dio.get(
      '/api/orders/store/$storeId',
      queryParameters: {'page': page, 'size': size, 'sort': 'createdDate,desc'},
      options: _authOptions(token),
    );
    final data = res.data;

    List list;
    int totalPages = 0;
    int number = page;

    if (data is Map<String, dynamic>) {
      if (data['content'] is List) {
        list = data['content'] as List;
        totalPages = (data['totalPages'] as int?) ?? 0;
        number = (data['number'] as int?) ?? page;
      } else if (data['data'] is Map<String, dynamic>) {
        final inner = data['data'] as Map<String, dynamic>;
        list = (inner['content'] is List) ? inner['content'] as List : const [];
        totalPages = (inner['totalPages'] as int?) ?? 0;
        number = (inner['number'] as int?) ?? page;
      } else if (data['data'] is List) {
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

      final idStr = str(m['id']);
      final shortId = idStr.length > 8 ? idStr.substring(0, 8).toUpperCase() : idStr.toUpperCase();

      final lineItems = (m['lineItems'] is List)
          ? List<Map<String, dynamic>>.from(
              (m['lineItems'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
          : <Map<String, dynamic>>[];

      return {
        'id': m['id'],
        'orderNumber': shortId,
        'status': str(m['status']),
        'total': toDouble(m['totalPrice'] ?? m['subTotal']),
        'createdAt': m['createdDate'],
        'customerName': str(m['userId']),
        'itemsCount': lineItems.length,

        'orderStatus': str(m['status']),
        'username': str(m['userId']),
        'createdDate': m['createdDate'],
        'updatedDate': m['updatedDate'],
        'totalAmount': toDouble(m['totalPrice'] ?? m['subTotal']),

        'mobileNumber': str(m['mobileNumber']),
        'notes': str(m['notes']),
        'paymentStatus': str(m['paymentStatus']),
        'deliveryStatus': str(m['fulfillmentStatus'] ?? m['status']),
        'totalTaxAmount': toDouble(m['totalTax']),
        'taxInclusive': m['taxInclusive'] == true,
        'selfOrder': m['selfOrder'] == true,
        'orderType': str(m['orderType']),
        'subTotal': toDouble(m['subTotal']),
        'totalDiscount': toDouble(m['totalDiscount']),

        'deliveryPartnerId': str(m['deliveryPartnerId']),
        'deliveryPartnerName': str(m['deliveryPartnerName']),
        'deliveryPartnerMobileNumber': str(m['deliveryPartnerMobileNumber']),

        'userAddress': (m['userAddress'] is Map)
            ? Map<String, dynamic>.from(m['userAddress'] as Map)
            : null,
        'businessAddress': (m['businessAddress'] is Map)
            ? Map<String, dynamic>.from(m['businessAddress'] as Map)
            : null,

        'orderItems': lineItems.map<Map<String, dynamic>>((item) {
          return {
            'productName': item['productName'],
            'productCode': item['productCode'],
            'quantity': item['quantity'],
            'unitPrice': toDouble(item['unitPrice']),
            'totalPrice': toDouble(item['totalPrice']),
            'discountPrice': toDouble(item['discountPrice']),
            'taxAmount': toDouble(item['taxAmount']),
            'status': item['status'],
            'fulfillmentStatus': item['fulfillmentStatus'],
            'price': toDouble(item['unitPrice']),
            'totalAmount': toDouble(item['totalPrice']),
          };
        }).toList(),
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

  Future<Map<String, dynamic>> getBusinessKpi({required int businessId}) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Business KPI -> GET /order/api/orders/business/$businessId/kpi',
      );
    }
    final res = await _client.dio.get(
      '/order/api/orders/business/$businessId/kpi',
      options: _authOptions(token),
    );
    final body = res.data;
    final map = _extractMap(body);
    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }
    return map;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Update Order Status -> PUT /api/orders/$orderId/status?status=$status',
      );
    }
    await _client.dio.put(
      '/api/orders/$orderId/status',
      queryParameters: {'status': status},
      options: _authOptions(token),
    );
  }

  Future<Map<String, dynamic>> getOrdersReportView({
    required String frequency,
    required String status,
    required int businessId,
    required String fromDate,
    required String toDate,
    int page = 0,
    int size = 10,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Orders Report View -> GET /order/api/orders/user/filter?frequency=$frequency&status=$status&businessId=$businessId&fromDate=$fromDate&toDate=$toDate&page=$page&size=$size',
      );
    }
    final res = await _client.dio.get(
      '/order/api/orders/user/filter',
      queryParameters: {
        'frequency': frequency,
        'status': status,
        'businessId': businessId,
        'fromDate': fromDate,
        'toDate': toDate,
        'page': page,
        'size': size,
      },
      options: _authOptions(token),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }

  Future<String> downloadOrdersExcel({
    required String orderStatus,
    required String frequency,
    required String fromDate,
    required String toDate,
    int? businessId,
    int page = 0,
    int size = 1000,
  }) async {
    final token = await _storage.readToken();
    final int? effectiveBusinessId = (businessId != null && businessId > 0)
        ? businessId
        : null;
    if (kDebugMode) {
      debugPrint(
        '[API] Download Orders Excel -> GET /order/api/orders/user/filter/excel?orderStatus=$orderStatus&frequency=$frequency&fromDate=$fromDate&toDate=$toDate&page=$page&size=$size&businessId=${effectiveBusinessId ?? ''}',
      );
    }
    final res = await _client.dio.get(
      '/order/api/orders/user/filter/excel',
      queryParameters: {
        // Keep legacy keys that the backend may still be using
        'orderStatus': orderStatus,
        'fromDate': fromDate,
        'toDate': toDate,
        'page': page,
        'size': size,
        if (effectiveBusinessId != null) 'restaurantId': effectiveBusinessId,

        // Send the same keys as the on-screen report endpoint
        'frequency': frequency,
        'status': orderStatus,
        if (effectiveBusinessId != null) 'businessId': effectiveBusinessId,
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept':
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/octet-stream',
        },
      ),
    );

    final bytes = res.data as List<int>;
    final dir = Directory.systemTemp.createTempSync('lb_reports_');
    final path =
        '${dir.path}/orders_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
