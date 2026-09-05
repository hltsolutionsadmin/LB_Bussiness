import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket_business/core/config/api_config.dart';
import 'package:local_basket_business/core/env/env.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/data/models/auth/auth_models.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client, this._storage, this._apiConfig);

  final DioClient _client;
  final AppSecureStorage _storage;
  final ApiConfig _apiConfig;

  Options _authOptions({String? bearer}) {
    final token = bearer ?? EnvConfig.seedBearer;
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<void> triggerOtp(TriggerOtpRequest req) async {
    if (kDebugMode) debugPrint('[API] Request: ${req.toJson()}');
    await _client.dio
        .post(
          _apiConfig.endpoints.triggerOtp,
          data: req.toJson(),
          options: _authOptions(),
        )
        .then((res) {
          if (kDebugMode) {
            debugPrint('[API] Trigger OTP Response: ${res.statusCode}');
          }
        });
  }

  Future<Map<String, dynamic>> triggerOtpWithResponse(TriggerOtpRequest req) async {
    if (kDebugMode) debugPrint('[API] Request: ${req.toJson()}');
    final res = await _client.dio.post(
      _apiConfig.endpoints.triggerOtp,
      data: req.toJson(),
      options: _authOptions(),
    );
    if (kDebugMode) debugPrint('[API] Trigger OTP Response: ${res.statusCode}');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{'data': data};
  }

  Future<String> login(LoginRequest req) async {
    if (kDebugMode) {
      debugPrint('[API] Login -> POST ${_apiConfig.endpoints.login}');
    }
    final res = await _client.dio.post(
      _apiConfig.endpoints.login,
      data: req.toJson(),
      options: _authOptions(),
    );
    if (kDebugMode) debugPrint('[API] Login Response: ${res.statusCode}');

    final loginResponse = LoginResponse.fromJson(res.data as Map<String, dynamic>);

    await _storage.saveAccessToken(loginResponse.accessToken);
    await _storage.saveRefreshToken(loginResponse.refreshToken);
    await _storage.saveDeviceId(req.deviceId);
    await _storage.saveExpiresIn(loginResponse.expiresIn);
    final expiresAt = DateTime.now()
        .add(Duration(seconds: loginResponse.expiresIn))
        .millisecondsSinceEpoch;
    await _storage.saveTokenExpiry(expiresAt);
    await _storage.saveTokenType(loginResponse.tokenType);
    return loginResponse.accessToken;
  }

  /// Rotates the stored refresh token via `/auth/refresh` and returns the new
  /// access token. Concurrent callers share a single round-trip. Throws if no
  /// refresh token is stored or the server rejects it.
  Future<String> refresh() => _client.refreshToken();

  Future<Map<String, dynamic>> userDetails({String? bearer}) async {
    final token = bearer ?? await _storage.readAccessToken();
    if (kDebugMode) {
      debugPrint('[API] User Details -> GET ${_apiConfig.endpoints.userDetails}');
    }
    final res = await _client.dio.get(
      _apiConfig.endpoints.userDetails,
      options: _authOptions(bearer: token),
    );
    if (kDebugMode) {
      debugPrint('[API] User Details Response: ${res.statusCode}');
    }
    return (res.data as Map<String, dynamic>);
  }
}
