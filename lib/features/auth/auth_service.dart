import 'package:dio/dio.dart';
import 'package:local_basket_business/core/config/api_config.dart';
import 'package:local_basket_business/core/env/env.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';

class AuthService {
  AuthService({Dio? dio, AppSecureStorage? storage, String? baseUrl})
    : _client = DioClient(dio ?? Dio(), baseUrl ?? _getDefaultBaseUrl()),
      _storage = storage ?? AppSecureStorage();

  final DioClient _client;
  final AppSecureStorage _storage;
  
  static String _getDefaultBaseUrl() {
    return EnvConfig.baseUrl.isNotEmpty
        ? EnvConfig.baseUrl
        : 'https://api-service.happybush-7c5a2823.centralindia.azurecontainerapps.io/api';
  }

  Options _authOptions({String? bearer}) {
    final token = bearer ?? EnvConfig.seedBearer;
    print('bearer token : $token');
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<void> triggerOtp({
    required String otpType,
    required String primaryContact,
  }) async {
    print(
      '[API] Request: {otpType: $otpType, primaryContact: $primaryContact}',
    );
    await _client.dio
        .post(
          ApiConfig.endpointsV1.triggerOtp,
          queryParameters: {'triggerOtp': 'false'},
          data: {'otpType': otpType, 'primaryContact': primaryContact},
          options: _authOptions(),
        )
        .then((res) {
          print('[API] Trigger OTP Response: ${res.statusCode}');
          print('[API] Body: ${res.data}');
        });
  }

  Future<String> loginWithOtp({
    required String otp,
    required String primaryContact,
  }) async {
    print('[API] Login -> POST /usermgmt/auth/login');
    print('[API] Request: {otp: $otp, primaryContact: $primaryContact}');
    final res = await _client.dio.post(
      ApiConfig.endpointsV1.login,
      data: {'otp': otp, 'primaryContact': primaryContact},
      options: _authOptions(),
    );
    print('[API] Login Response: ${res.statusCode}');
    print('[API] Headers: ${res.headers.map}');
    print('[API] Body: ${res.data}');

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
      ApiConfig.endpointsV1.userDetails,
      options: _authOptions(bearer: token),
    );
    print('[API] User Details Response: ${res.statusCode}');
    print('[API] Body: ${res.data}');
    return (res.data as Map<String, dynamic>);
  }

  Future<void> logout() => _storage.clearToken();
}
