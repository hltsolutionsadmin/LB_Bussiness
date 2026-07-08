import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSecureStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresInKey = 'expires_in';
  static const _tokenExpiryKey = 'token_expiry';
  static const _tokenTypeKey = 'token_type';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveExpiresIn(int expiresIn) =>
      _storage.write(key: _expiresInKey, value: expiresIn.toString());
  Future<int?> readExpiresIn() async {
    final value = await _storage.read(key: _expiresInKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> saveTokenExpiry(int expiryMs) =>
      _storage.write(key: _tokenExpiryKey, value: expiryMs.toString());

  Future<int?> readTokenExpiry() async {
    final value = await _storage.read(key: _tokenExpiryKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> saveTokenType(String tokenType) =>
      _storage.write(key: _tokenTypeKey, value: tokenType);
  Future<String?> readTokenType() => _storage.read(key: _tokenTypeKey);

  Future<void> saveToken(String token) => saveAccessToken(token);
  Future<String?> readToken() => readAccessToken();

  Future<void> clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresInKey);
    await _storage.delete(key: _tokenExpiryKey);
    await _storage.delete(key: _tokenTypeKey);
  }

  Future<void> clearToken() => clearAll();
}
