import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';

class DeliveryRemoteDataSource {
  DeliveryRemoteDataSource(this._client, this._storage);

  final DioClient _client;
  final AppSecureStorage _storage;

  String? _extractStoreId(dynamic data) {
    if (data is Map<String, dynamic>) {
      final directStoreId = data['storeId']?.toString();
      if (directStoreId != null && directStoreId.isNotEmpty) {
        return directStoreId;
      }

      final nested = data['data'];
      if (nested != null) {
        final nestedId = _extractStoreId(nested);
        if (nestedId != null && nestedId.isNotEmpty) {
          return nestedId;
        }
      }

      final store = data['store'];
      if (store != null) {
        final storeId = _extractStoreId(store);
        if (storeId != null && storeId.isNotEmpty) {
          return storeId;
        }
      }

      if (data['items'] is List) {
        for (final item in data['items'] as List) {
          if (item is Map<String, dynamic>) {
            final storeId = _extractStoreId(item);
            if (storeId != null && storeId.isNotEmpty) {
              return storeId;
            }
          }
        }
      }
    } else if (data is List) {
      for (final item in data) {
        final storeId = _extractStoreId(item);
        if (storeId != null && storeId.isNotEmpty) {
          return storeId;
        }
      }
    }

    return null;
  }

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
      } else if (data['items'] is List) {
        list = data['items'] as List;
      } else if (data['data'] is Map<String, dynamic>) {
        final nested = data['data'] as Map<String, dynamic>;
        if (nested['content'] is List) {
          list = nested['content'] as List;
        } else if (nested['data'] is List) {
          list = nested['data'] as List;
        } else if (nested['items'] is List) {
          list = nested['items'] as List;
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

  Future<List<Map<String, dynamic>>> listAgentsByB2b({
    required String b2bUnitId,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] List Agents -> GET /api/agents/b2b/$b2bUnitId');
    }

    final res = await _client.dio.get(
      '/api/agents/b2b/$b2bUnitId',
      options: _authOptions(token),
    );
    return _extractList(res.data);
  }

  Future<Map<String, dynamic>> getAgentDetails({
    required String agentId,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Agent Details -> GET /api/agents/$agentId');
    }

    final res = await _client.dio.get(
      '/api/agents/$agentId',
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

  Future<void> blockPartner({required String partnerId}) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Deactivate Agent -> PUT /api/agents/$partnerId/deactivate',
      );
    }
    await _client.dio.put(
      '/api/agents/$partnerId/deactivate',
      options: _authOptions(token),
    );
  }

  Future<void> unblockPartner({required String partnerId}) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Activate Agent -> PUT /api/agents/$partnerId/activate');
    }
    await _client.dio.put(
      '/api/agents/$partnerId/activate',
      options: _authOptions(token),
    );
  }

  Future<dynamic> getDeliveryPartnerReport({
    required String partnerId,
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

  Future<String?> resolveStoreId({
    required String b2bUnitId,
    String searchTerm = '',
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Search Stores -> GET /api/stores/search');
      debugPrint('Query: {searchTerm: $searchTerm, b2bUnitId: $b2bUnitId}');
    }

    final res = await _client.dio.get(
      '/api/stores/search',
      queryParameters: {'searchTerm': searchTerm, 'b2bUnitId': b2bUnitId},
      options: _authOptions(token),
    );

    return _extractStoreId(res.data);
  }

  Future<Map<String, dynamic>> addPartner({
    required String vehicleNumber,
    required String mobileNumber,
    required String fullName,
    String? storeId,
    String? b2bUnitId,
    String? displayName,
    String? bio,
    String vehicleType = 'Two wheeler',
    String specializations = '',
    String sessionMode = '',
    int maxConcurrentAssignments = 1,
  }) async {
    final token = await _storage.readToken();
    final payload = {
      'mobileNumber': mobileNumber,
      'fullName': fullName,
      if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
      if (b2bUnitId != null && b2bUnitId.isNotEmpty) 'b2bUnitId': b2bUnitId,
      'agentType': 'DELIVERY_BOY',
      'displayName': displayName ?? fullName,
      'bio': bio ?? '',
      'maxConcurrentAssignments': maxConcurrentAssignments,
      'vehicleRegistration': vehicleNumber,
      'vehicleType': vehicleType,
      'specializations': specializations,
      'sessionMode': sessionMode,
    };
    if (kDebugMode) {
      debugPrint('[API] Add Delivery Partner -> POST /api/agents');
      debugPrint('Payload: $payload');
    }

    final res = await _client.dio.post(
      '/api/agents',
      data: payload,
      options: _authOptions(token),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return {'success': true, 'data': data};
  }

  Future<Map<String, dynamic>> verifyAgent({required String agentId}) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Verify Agent -> PUT /api/agents/$agentId/verify');
    }

    final res = await _client.dio.put(
      '/api/agents/$agentId/verify',
      options: _authOptions(token),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return {'success': true, 'data': data};
  }
}
