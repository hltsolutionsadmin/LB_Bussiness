import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_basket_business/core/env/env.dart';

/// Fallback store links used when the remote config omits `storeUrl`.
const String _kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.localBasketBusiness';
const String _kAppStoreUrl = 'https://apps.apple.com/app/com.localBasketBusiness';

/// How urgently the user should update.
enum AppUpdateType { none, optional, forced }

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.type,
    required this.latestVersion,
    required this.storeUrl,
    this.releaseNotes = '',
  });

  final AppUpdateType type;
  final String latestVersion;
  final String storeUrl;
  final String releaseNotes;

  static const AppUpdateInfo none = AppUpdateInfo(
    type: AppUpdateType.none,
    latestVersion: '',
    storeUrl: '',
  );
}

/// Reads a small remote JSON file and decides whether the running build is
/// behind the latest published one.
///
/// Expected JSON shape (per-platform blocks are optional):
/// ```json
/// {
///   "android": {
///     "latestVersion": "1.0.2",
///     "latestBuild": 12,
///     "minBuild": 11,
///     "storeUrl": "https://play.google.com/store/apps/details?id=com.localBasketBusiness",
///     "releaseNotes": "Bug fixes and improvements"
///   },
///   "ios": {
///     "latestVersion": "1.0.2",
///     "latestBuild": 12,
///     "minBuild": 11,
///     "storeUrl": "https://apps.apple.com/app/idXXXXXXXXXX",
///     "releaseNotes": "Bug fixes and improvements"
///   }
/// }
/// ```
///
/// `minBuild` (or `minVersion`) is the lowest build allowed to keep running —
/// anything below it gets a non-dismissible dialog. A build that is between
/// `minBuild` and `latestBuild` gets a dismissible "update available" prompt.
class AppUpdateService {
  AppUpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<AppUpdateInfo> check() async {
    final url = EnvConfig.appUpdateConfigUrl;
    if (url.isEmpty) return AppUpdateInfo.none;

    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;
      final currentVersion = info.version;

      final res = await _dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final root = _asMap(res.data);
      final platformKey = Platform.isIOS ? 'ios' : 'android';
      final cfg = _asMap(root[platformKey] ?? root);
      if (cfg.isEmpty) return AppUpdateInfo.none;

      final latestVersion =
          (cfg['latestVersion'] ?? currentVersion).toString();
      final latestBuild = _asInt(cfg['latestBuild']);
      final minBuild = _asInt(cfg['minBuild']);
      final rawStoreUrl = (cfg['storeUrl'] ?? '').toString().trim();
      final storeUrl = rawStoreUrl.isNotEmpty
          ? rawStoreUrl
          : (Platform.isIOS ? _kAppStoreUrl : _kPlayStoreUrl);
      final releaseNotes = (cfg['releaseNotes'] ?? '').toString();

      // Prefer build-number comparison; fall back to semver strings.
      final behindLatest = latestBuild > 0
          ? currentBuild < latestBuild
          : _compareSemver(currentVersion, latestVersion) < 0;
      final belowMin = minBuild > 0
          ? currentBuild < minBuild
          : _compareSemver(
                  currentVersion,
                  (cfg['minVersion'] ?? currentVersion).toString()) <
              0;

      if (belowMin) {
        return AppUpdateInfo(
          type: AppUpdateType.forced,
          latestVersion: latestVersion,
          storeUrl: storeUrl,
          releaseNotes: releaseNotes,
        );
      }
      if (behindLatest) {
        return AppUpdateInfo(
          type: AppUpdateType.optional,
          latestVersion: latestVersion,
          storeUrl: storeUrl,
          releaseNotes: releaseNotes,
        );
      }
      return AppUpdateInfo.none;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] check failed: $e');
      return AppUpdateInfo.none;
    }
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String && v.trim().isNotEmpty) {
      try {
        return _asMap(jsonDecode(v));
      } catch (_) {}
    }
    return const {};
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Returns <0 if [a] < [b], 0 if equal, >0 if [a] > [b].
  static int _compareSemver(String a, String b) {
    final pa = a.split('+').first.split('.');
    final pb = b.split('+').first.split('.');
    for (var i = 0; i < 3; i++) {
      final na = i < pa.length ? int.tryParse(pa[i].trim()) ?? 0 : 0;
      final nb = i < pb.length ? int.tryParse(pb[i].trim()) ?? 0 : 0;
      if (na != nb) return na.compareTo(nb);
    }
    return 0;
  }
}
