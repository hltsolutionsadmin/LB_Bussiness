import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';

class BusinessRemoteDataSource {
  BusinessRemoteDataSource(this._client, this._storage);

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

  int? _parseId(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  int? _extractBusinessId(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final direct = _parseId(
        map['id'] ?? map['businessId'] ?? map['restaurantId'],
      );
      if (direct != null) return direct;

      final inner = map['data'];
      if (inner is Map) {
        final innerMap = Map<String, dynamic>.from(inner);
        return _parseId(
          innerMap['id'] ?? innerMap['businessId'] ?? innerMap['restaurantId'],
        );
      }
    }
    return null;
  }

  Future<void> blockBusiness({required int businessId}) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Block Business -> PUT /usermgmt/business/block/$businessId',
      );
    }
    await _client.dio.put(
      '/usermgmt/business/block/$businessId',
      options: _authOptions(token),
    );
  }

  Future<void> unblockBusiness({required int businessId}) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Unblock Business -> PUT /usermgmt/business/unblock/$businessId',
      );
    }
    await _client.dio.put(
      '/usermgmt/business/unblock/$businessId',
      options: _authOptions(token),
    );
  }

  Future<void> setBusinessEnabled({
    required int businessId,
    required bool enabled,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Business Status -> PUT /usermgmt/business/$businessId/status?enabled=$enabled',
      );
    }
    await _client.dio.put(
      '/usermgmt/business/$businessId/status',
      queryParameters: {'enabled': enabled},
      options: _authOptions(token),
    );
  }

  Future<int?> onboardBusiness({
    required String businessName,
    required String addressLine1,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    required String latitude,
    required String longitude,
    required String contactNumber,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Onboard Business -> POST /usermgmt/business/onboard');
    }

    final form = FormData();
    form.fields
      ..add(MapEntry('businessName', businessName))
      ..add(const MapEntry('categoryId', '1'))
      ..add(MapEntry('addressLine1', addressLine1))
      ..add(MapEntry('city', city))
      ..add(MapEntry('state', state))
      ..add(MapEntry('country', country))
      ..add(MapEntry('postalCode', postalCode))
      ..add(MapEntry('latitude', latitude))
      ..add(MapEntry('longitude', longitude))
      ..add(MapEntry('contactNumber', contactNumber));

    final res = await _client.dio.post(
      '/usermgmt/business/onboard',
      data: form,
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    return _extractBusinessId(res.data);
  }

  Future<void> approveBusiness({required int businessId}) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Approve Business -> PUT /usermgmt/business/approve/$businessId',
      );
    }
    await _client.dio.put(
      '/usermgmt/business/approve/$businessId',
      options: _authOptions(token),
    );
  }

  Future<List<Map<String, dynamic>>> listBusinesses() async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] List Businesses -> GET /usermgmt/business/list');
    }
    final res = await _client.dio.get(
      '/usermgmt/business/list',
      options: _authOptions(token),
    );
    final data = res.data;
    List list;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        list = data['data'] as List;
      } else if (data['content'] is List) {
        list = data['content'] as List;
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
}
