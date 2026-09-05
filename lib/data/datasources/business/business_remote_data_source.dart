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

  Future<Map<String, dynamic>> createStore({
    required String name,
    required String code,
  }) async {
    final token = await _storage.readToken();
    final payload = {
      'b2bUnitType': 'FOOD_DELIVERY',
      'code': code,
      'enableStockCheck': false,
      'name': name,
      'storeRole': 'MANAGED_PARTNER',
      'storeType': 'B2C',
    };
    if (kDebugMode) {
      debugPrint('[API] Create Store -> POST /api/stores');
      debugPrint('[API] Payload: $payload');
    }

    final res = await _client.dio.post(
      '/api/stores',
      data: payload,
      options: _authOptions(token),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getStoreDetails({
    required String storeId,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Store Details -> GET /api/stores/$storeId');
    }

    final res = await _client.dio.get(
      '/api/stores/$storeId',
      options: _authOptions(token),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return {'data': data};
  }

  Future<Map<String, dynamic>> updateStoreLocation({
    required String storeId,
    required String name,
    required String code,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _storage.readToken();
    final payload = {
      'code': code,
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
    };
    if (kDebugMode) {
      debugPrint('[API] Update Store Location -> PUT /api/stores/$storeId');
      debugPrint('[API] Payload: $payload');
    }

    final res = await _client.dio.put(
      '/api/stores/$storeId',
      data: payload,
      options: _authOptions(token),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> setStoreActive({
    required String storeId,
    required String name,
    required String code,
    required bool active,
  }) async {
    final token = await _storage.readToken();
    final payload = {'code': code, 'name': name, 'active': active};
    if (kDebugMode) {
      debugPrint('[API] Store Status -> PUT /api/stores/$storeId');
      debugPrint('[API] Payload: $payload');
    }

    final res = await _client.dio.put(
      '/api/stores/$storeId',
      data: payload,
      options: _authOptions(token),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createStoreWithLocation({
    required String name,
    required String code,
    required double latitude,
    required double longitude,
  }) async {
    final created = await createStore(name: name, code: code);
    final storeId = created['id']?.toString() ?? '';
    if (storeId.isEmpty) {
      throw StateError('Store created without an id');
    }

    return updateStoreLocation(
      storeId: storeId,
      name: name,
      code: code,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> deleteStore({required String storeId}) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Delete Store -> DELETE /api/stores/$storeId');
    }

    await _client.dio.delete(
      '/api/stores/$storeId',
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

  Future<List<Map<String, dynamic>>> searchStores({
    required String b2bUnitId,
    String searchTerm = '',
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Search Stores -> GET /api/stores/search');
      debugPrint('[API] Query: searchTerm=$searchTerm, b2bUnitId=$b2bUnitId');
    }
    final res = await _client.dio.get(
      '/api/stores/search',
      queryParameters: {'searchTerm': searchTerm, 'b2bUnitId': b2bUnitId},
      options: _authOptions(token),
    );
    final data = res.data;
    List list;
    if (data is Map<String, dynamic>) {
      if (data['content'] is List) {
        list = data['content'] as List;
      } else if (data['data'] is Map<String, dynamic> &&
          (data['data'] as Map<String, dynamic>)['content'] is List) {
        list = (data['data'] as Map<String, dynamic>)['content'] as List;
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
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
