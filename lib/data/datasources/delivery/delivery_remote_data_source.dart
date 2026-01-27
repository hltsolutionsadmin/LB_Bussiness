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

  Future<Map<String, dynamic>> addPartner({
    required String vehicleNumber,
    required String status,
    required bool active,
    required bool available,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Add Delivery Partner -> POST /delivery/api/partners');
      debugPrint(
        'Payload: {vehicleNumber: $vehicleNumber, status: $status, active: $active, available: $available}',
      );
    }
    final res = await _client.dio.post(
      '/delivery/api/partners',
      data: {
        'vehicleNumber': vehicleNumber,
        'status': status,
        'active': active,
        'available': available,
      },
      options: _authOptions(token),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return {'success': true, 'data': data};
  }
}
