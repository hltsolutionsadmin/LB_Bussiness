import 'package:dio/dio.dart';
import 'package:local_basket_business/core/env/env.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/data/models/auth/auth_models.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client, this._storage);

  final DioClient _client;
  final AppSecureStorage _storage;

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
    print(
      '[API] Trigger OTP -> POST /usermgmt/auth/jtuserotp/trigger/otp?triggerOtp=false',
    );
    print('[API] Request: ${req.toJson()}');
    await _client.dio
        .post(
          '/usermgmt/auth/jtuserotp/trigger/otp',
          queryParameters: {'triggerOtp': 'false'},
          data: req.toJson(),
          options: _authOptions(),
        )
        .then((res) {
          print('[API] Trigger OTP Response: ${res.statusCode}');
          print('[API] Body: ${res.data}');
        });
  }

  Future<String> login(LoginRequest req) async {
    print('[API] Login -> POST /usermgmt/auth/login');
    print('[API] Request: ${req.toJson()}');
    final res = await _client.dio.post(
      '/usermgmt/auth/login',
      data: req.toJson(),
      options: _authOptions(),
    );
    print('[API] Login Response: ${res.statusCode}');
    print('[API] Headers: ${res.headers.map}');
    print('[API] Body: ${res.data}');
    // Try to read token from body first, then fallback to Authorization header
    String? token;
    final data = res.data;
    if (data is Map<String, dynamic>) {
      token = data['token'] as String?;
    }
    token ??= res.headers['authorization']?.first;
    token ??= res.headers['Authorization']?.first;
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Token missing in response',
      );
    }
    final masked = token.length > 12
        ? '${token.substring(0, 6)}...${token.substring(token.length - 6)}'
        : '***';
    print('[API] Parsed token: $masked');
    await _storage.saveToken(token);
    return token;
  }

  Future<Map<String, dynamic>> userDetails({String? bearer}) async {
    final token = bearer ?? await _storage.readToken();
    final masked = (token ?? '').length > 12
        ? '${(token ?? '').substring(0, 6)}...${(token ?? '').substring((token ?? '').length - 6)}'
        : (token == null ? 'null' : '***');
    print('[API] User Details -> GET /usermgmt/user/userDetails');
    print('[API] Using bearer: $masked');
    final res = await _client.dio.get(
      '/usermgmt/user/userDetails',
      options: _authOptions(bearer: token),
    );
    print('[API] User Details Response: ${res.statusCode}');
    print('[API] Body: ${res.data}');
    return (res.data as Map<String, dynamic>);
  }
}
