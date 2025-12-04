abstract class AuthRepository {
  Future<void> triggerOtp({
    required String otpType,
    required String primaryContact,
  });
  Future<String> loginWithOtp({
    required String otp,
    required String primaryContact,
  });
  Future<Map<String, dynamic>> getUserDetails({String? bearer});
  Future<void> saveToken(String token);
  Future<String?> getToken();
}
