import 'package:dio/dio.dart';
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
    print('[API] Request: ${req.toJson()}');
    await _client.dio
        .post(
          _apiConfig.endpoints.triggerOtp,
          data: req.toJson(),
          options: _authOptions(),
        )
        .then((res) {
          print('[API] Trigger OTP Response: ${res.statusCode}');
          print('[API] Body: ${res.data}');
        });
  }

  Future<Map<String, dynamic>> triggerOtpWithResponse(TriggerOtpRequest req) async {
    print('[API] Request: ${req.toJson()}');
    final res = await _client.dio.post(
      _apiConfig.endpoints.triggerOtp,
      data: req.toJson(),
      options: _authOptions(),
    );
    print('[API] Trigger OTP Response: ${res.statusCode}');
    print('[API] Body: ${res.data}');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{'data': data};
  }

  Future<String> login(LoginRequest req) async {
    print('[API] Login -> POST ${_apiConfig.endpoints.login}');
    print('[API] Request: ${req.toJson()}');
    final res = await _client.dio.post(
      _apiConfig.endpoints.login,
      data: req.toJson(),
      options: _authOptions(),
    );
    print('[API] Login Response: ${res.statusCode}');
    print('[API] Headers: ${res.headers.map}');
    print('[API] Body: ${res.data}');
    
    final loginResponse = LoginResponse.fromJson(res.data as Map<String, dynamic>);
    
    await _storage.saveAccessToken(loginResponse.accessToken);
    await _storage.saveRefreshToken(loginResponse.refreshToken);
    await _storage.saveExpiresIn(loginResponse.expiresIn);
    final expiresAt = DateTime.now()
        .add(Duration(seconds: loginResponse.expiresIn))
        .millisecondsSinceEpoch;
    await _storage.saveTokenExpiry(expiresAt);
    await _storage.saveTokenType(loginResponse.tokenType);
    
    final masked = loginResponse.accessToken.length > 12
        ? '${loginResponse.accessToken.substring(0, 6)}...${loginResponse.accessToken.substring(loginResponse.accessToken.length - 6)}'
        : '***';
    print('[API] Parsed access token: $masked');
    
    return loginResponse.accessToken;
  }

  Future<Map<String, dynamic>> userDetails({String? bearer}) async {
    final token = bearer ?? await _storage.readAccessToken();
    final masked = (token ?? '').length > 12
        ? '${(token ?? '').substring(0, 6)}...${(token ?? '').substring((token ?? '').length - 6)}'
        : (token == null ? 'null' : '***');
    print('[API] User Details -> GET ${_apiConfig.endpoints.userDetails}');
    print('[API] Using bearer: $masked');
    final res = await _client.dio.get(
      _apiConfig.endpoints.userDetails,
      options: _authOptions(bearer: token),
    );
    print('[API] User Details Response: ${res.statusCode}');
    print('[API] Body: ${res.data}');
    return (res.data as Map<String, dynamic>);
  }
}
