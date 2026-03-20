import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';

class DeliveryRemoteDataSource {
  DeliveryRemoteDataSource(this._client, this._storage);

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

  Future<List<Map<String, dynamic>>> listPartnersPaged({
    int page = 0,
    int size = 10,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] List Partners -> GET /delivery/api/partners/paged');
    }
    final res = await _client.dio.get(
      '/delivery/api/partners/paged',
      queryParameters: {'page': page, 'size': size},
      options: _authOptions(token),
    );
    if (kDebugMode) {
      debugPrint('[API] List Partners <- ${res.statusCode}');
      final d = res.data;
      if (d is Map<String, dynamic>) {
        debugPrint('[API] List Partners keys=${d.keys.toList()}');
        final nested = d['data'];
        if (nested is Map<String, dynamic>) {
          debugPrint('[API] List Partners data.keys=${nested.keys.toList()}');
        }
      } else {
        debugPrint('[API] List Partners dataType=${d.runtimeType}');
      }
    }
    return _extractList(res.data);
  }

  Future<List<Map<String, dynamic>>> listActivePartnersPaged({
    int page = 0,
    int size = 10,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] List Active Partners -> GET /delivery/api/partners/active/paged',
      );
    }
    final res = await _client.dio.get(
      '/delivery/api/partners/active/paged',
      queryParameters: {'page': page, 'size': size},
      options: _authOptions(token),
    );
    return _extractList(res.data);
  }

  Future<List<Map<String, dynamic>>> listAvailablePartners({
    int page = 0,
    int size = 10,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] List Available Partners -> GET /delivery/api/partners/available',
      );
    }
    final res = await _client.dio.get(
      '/delivery/api/partners/available',
      queryParameters: {'page': page, 'size': size},
      options: _authOptions(token),
    );
    return _extractList(res.data);
  }

  Future<void> blockPartner({required int partnerId}) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Block Partner -> PUT /delivery/api/partners/$partnerId/block',
      );
    }
    await _client.dio.put(
      '/delivery/api/partners/$partnerId/block',
      options: _authOptions(token),
    );
  }

  Future<void> unblockPartner({required int partnerId}) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Unblock Partner -> PUT /delivery/api/partners/$partnerId/unblock',
      );
    }
    await _client.dio.put(
      '/delivery/api/partners/$partnerId/unblock',
      options: _authOptions(token),
    );
  }

  Future<dynamic> getDeliveryPartnerReport({
    required int partnerId,
    required String period,
    required String from,
    required String to,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Partner Report -> GET /delivery/api/admin/reports/delivery-partners/$partnerId/$period?from=$from&to=$to',
      );
    }
    final res = await _client.dio.get(
      '/delivery/api/admin/reports/delivery-partners/$partnerId/$period',
      queryParameters: {'from': from, 'to': to},
      options: _authOptions(token),
    );
    final d = res.data;
    if (kDebugMode) {
      if (d is Map<String, dynamic>) {
        debugPrint('[API] Partner Report keys=${d.keys.toList()}');
        final nested = d['data'];
        if (nested is Map<String, dynamic>) {
          debugPrint('[API] Partner Report data.keys=${nested.keys.toList()}');
        }
      } else {
        debugPrint('[API] Partner Report dataType=${d.runtimeType}');
      }
    }
    return d;
  }

  Future<Map<String, dynamic>> addPartner({
    required String vehicleNumber,
    required bool available,
    required String mobileNumber,
    required String fullName,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Add Delivery Partner -> POST /delivery/api/partners');
      debugPrint(
        'Payload: {vehicleNumber: $vehicleNumber, available: $available, mobileNumber: $mobileNumber}',
      );
    }
    final res = await _client.dio.post(
      '/delivery/api/partners',
      data: {
        'vehicleNumber': vehicleNumber,
        'available': available,
        'mobileNumber': mobileNumber,
        'fullName': fullName,
        // 'dedicatedForOffers': false,
      },
      options: _authOptions(token),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return {'success': true, 'data': data};
  }
}
