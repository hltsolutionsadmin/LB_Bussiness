import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/routes/app_router.dart';

class DioClient {
  DioClient(this._dio, this.baseUrl, [AppSecureStorage? storage])
      : _storage = storage ?? AppSecureStorage() {
    final String normalizedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

    // A dependency-free Dio used only to call /auth/refresh. It has no
    // interceptors, so a 401 from the refresh call can never recurse back
    // into the rotation logic below.
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: normalizedBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio
      ..options = BaseOptions(
        baseUrl: normalizedBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      )
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (kDebugMode) {
              debugPrint('[DIO] baseUrl=${_dio.options.baseUrl}');
              debugPrint('[REQ] ${options.method} ${options.uri}');
              if (options.data != null) debugPrint('DATA: ${options.data}');
            }
            handler.next(options);
          },
          onResponse: (response, handler) {
            if (kDebugMode) {
              debugPrint(
                '[RES] ${response.statusCode} ${response.requestOptions.uri}',
              );
              try {
                debugPrint('BODY: ${response.data}');
              } catch (_) {
                debugPrint('BODY: <non-printable>');
              }
            }
            handler.next(response);
          },
          onError: (e, handler) async {
            if (kDebugMode) {
              debugPrint('[ERR] ${e.response?.statusCode} ${e.message}');
              if (e.response != null) {
                debugPrint('URL:: ${e.response!.requestOptions.uri}');
                try {
                  debugPrint('ERR BODY: ${e.response!.data}');
                } catch (_) {
                  debugPrint('ERR BODY: <non-printable>');
                }
              }
            }

            final int? status = e.response?.statusCode;
            final dynamic data = e.response?.data;
            final headers = e.response?.headers;
            final req = e.requestOptions;

            final bool isBytes = req.responseType == ResponseType.bytes;
            final String contentType =
                e.response?.headers.value('content-type') ?? '';
            final String wwwAuth = headers?.value('www-authenticate') ?? '';

            final String wwwAuthLc = wwwAuth.toLowerCase();
            bool dataHintsInvalid = false;
            if (data is Map) {
              final map = Map<Object?, Object?>.from(data);
              final code = map['code']?.toString().toLowerCase() ?? '';
              final err = map['error']?.toString().toLowerCase() ?? '';
              dataHintsInvalid =
                  code.contains('token') ||
                  err.contains('token') ||
                  err.contains('unauthorize');
            }
            final bool serverSaysInvalid =
                wwwAuthLc.contains('invalid_token') ||
                wwwAuthLc.contains('expired') ||
                dataHintsInvalid;

            final String ct = contentType.toLowerCase();
            final bool isBinaryResponse =
                isBytes ||
                ct.contains('octet-stream') ||
                ct.contains('application/vnd.openxmlformats-officedocument');

            final bool isAuthEndpoint = req.path.contains('/auth/');
            final bool alreadyRetried = req.extra[_retriedKey] == true;

            // Access token likely expired: rotate the refresh token once and
            // replay the failed request with the fresh access token.
            if (status == 401 &&
                !isAuthEndpoint &&
                !alreadyRetried &&
                !isBinaryResponse) {
              try {
                final String newAccessToken = await _refreshToken();
                req.extra[_retriedKey] = true;
                req.headers['Authorization'] = 'Bearer $newAccessToken';
                final Response<dynamic> replay = await _dio.fetch<dynamic>(req);
                return handler.resolve(replay);
              } catch (err) {
                if (kDebugMode) {
                  debugPrint('[DIO] token refresh failed: $err');
                }
                await _handleLogoutOnTokenExpiry();
                return handler.next(e);
              }
            }

            if (status == 401 && serverSaysInvalid && !isBinaryResponse) {
              _handleLogoutOnTokenExpiry();
            }
            handler.next(e);
          },
        ),
      );
  }

  final Dio _dio;
  final String baseUrl;
  final AppSecureStorage _storage;
  late final Dio _refreshDio;
  Dio get dio => _dio;

  static const String _retriedKey = '__token_retried__';

  // Ensures concurrent 401s trigger only a single /auth/refresh round-trip;
  // every caller awaits the same in-flight rotation.
  Future<String>? _refreshInFlight;

  Future<String> refreshToken() {
    return _refreshInFlight ??=
        _performRefresh().whenComplete(() => _refreshInFlight = null);
  }

  // Kept private alias for readability at call sites inside the interceptor.
  Future<String> _refreshToken() => refreshToken();

  Future<String> _performRefresh() async {
    final String? refreshToken = await _storage.readRefreshToken();
    final String? deviceId = await _storage.readDeviceId();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No refresh token available');
    }

    final Response<dynamic> res = await _refreshDio.post<dynamic>(
      '/auth/refresh',
      data: {
        'refreshToken': refreshToken,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      },
    );

    final Map<String, dynamic> body = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : Map<String, dynamic>.from(res.data as Map);

    final String newAccessToken = body['accessToken'] as String;
    final String newRefreshToken = body['refreshToken'] as String;
    final int expiresIn = (body['expiresIn'] as num).toInt();

    await _storage.saveAccessToken(newAccessToken);
    await _storage.saveRefreshToken(newRefreshToken);
    await _storage.saveExpiresIn(expiresIn);
    await _storage.saveTokenExpiry(
      DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch,
    );
    final tokenType = body['tokenType'];
    if (tokenType is String && tokenType.isNotEmpty) {
      await _storage.saveTokenType(tokenType);
    }

    if (kDebugMode) debugPrint('[DIO] token rotated via /auth/refresh');
    return newAccessToken;
  }

  static bool _loggingOut = false;
  Future<void> _handleLogoutOnTokenExpiry() async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } catch (_) {
      // ignore
    } finally {
      _loggingOut = false;
    }
  }
}
