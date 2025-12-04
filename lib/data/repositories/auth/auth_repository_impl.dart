import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/data/datasources/auth/auth_remote_data_source.dart';
import 'package:local_basket_business/data/models/auth/auth_models.dart';
import 'package:local_basket_business/domain/repositories/auth/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);
  final AuthRemoteDataSource _remote;
  final AppSecureStorage _storage;

  @override
  Future<void> triggerOtp({
    required String otpType,
    required String primaryContact,
  }) {
    return _remote.triggerOtp(
      TriggerOtpRequest(otpType: otpType, primaryContact: primaryContact),
    );
  }

  @override
  Future<String> loginWithOtp({
    required String otp,
    required String primaryContact,
  }) {
    return _remote.login(
      LoginRequest(otp: otp, primaryContact: primaryContact),
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
