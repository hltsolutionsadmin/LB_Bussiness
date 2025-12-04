import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket_business/core/env/env.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_basket_business/routes/app_router.dart';

class DioClient {
  DioClient(this._dio) {
    _dio
      ..options = BaseOptions(
        baseUrl: (EnvConfig.baseUrl.isNotEmpty)
            ? EnvConfig.baseUrl
            : 'https://kovela.app',
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      )
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (kDebugMode) {
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
          onError: (e, handler) {
            if (kDebugMode) {
              debugPrint('[ERR] ${e.response?.statusCode} ${e.message}');
              if (e.response != null) {
                debugPrint('URL: ${e.response!.requestOptions.uri}');
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
            final req = e.response?.requestOptions;

            final bool isBytes = req?.responseType == ResponseType.bytes;
            final String contentType =
                e.response?.headers.value('content-type') ?? '';
            final String wwwAuth = headers?.value('www-authenticate') ?? '';

            // Parse server hints
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

            if (status == 401 && serverSaysInvalid && !isBinaryResponse) {
              _handleLogoutOnTokenExpiry();
            }
            handler.next(e);
          },
        ),
      );
  }

  final Dio _dio;
  Dio get dio => _dio;

  static bool _loggingOut = false;
  Future<void> _handleLogoutOnTokenExpiry() async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
      // Navigate to login, clearing the stack
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } catch (_) {
      // ignore
    } finally {
      // allow future attempts after navigation completes
      _loggingOut = false;
    }
  }
}
