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
}
