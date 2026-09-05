import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/data/datasources/auth/auth_remote_data_source.dart';
import 'package:local_basket_business/data/models/auth/auth_models.dart';
import 'package:local_basket_business/domain/repositories/auth/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);
  final AuthRemoteDataSource _remote;
  final AppSecureStorage _storage;

  String _normalizePrimaryContact(String primaryContact) {
    final value = primaryContact.trim();
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) return digits;
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits.substring(2);
    }

    return value;
  }

  @override
  Future<void> triggerOtp({required String primaryContact}) {
    return _remote.triggerOtp(
      TriggerOtpRequest(
        primaryContact: _normalizePrimaryContact(primaryContact),
      ),

    );
  }

  @override
  Future<Map<String, dynamic>> triggerOtpWithResponse({
    required String primaryContact,
  }) {
    return _remote.triggerOtpWithResponse(
      TriggerOtpRequest(
        primaryContact: _normalizePrimaryContact(primaryContact),
      ),
    );
  }

  @override
  Future<String> loginWithOtp({
    required String otp,
    required String primaryContact,
    required String fullName,
    required String deviceId,
  }) {
    return _remote.login(
      LoginRequest(
        otp: otp,
        primaryContact: _normalizePrimaryContact(primaryContact),

        fullName: fullName,
        deviceId: deviceId,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> getUserDetails({String? bearer}) {
    return _remote.userDetails(bearer: bearer);
  }

  @override
  Future<void> saveToken(String token) => _storage.saveToken(token);

  @override
  Future<String?> getToken() => _storage.readToken();
}
