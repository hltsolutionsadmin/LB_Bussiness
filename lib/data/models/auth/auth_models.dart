class TriggerOtpRequest {
  final String otpType;
  final String primaryContact;
  TriggerOtpRequest({required this.otpType, required this.primaryContact});
  Map<String, dynamic> toJson() => {
    'otpType': otpType,
    'primaryContact': primaryContact,
  };
}

class LoginRequest {
  final String otp;
  final String primaryContact;
  LoginRequest({required this.otp, required this.primaryContact});
  Map<String, dynamic> toJson() => {
    'otp': otp,
    'primaryContact': primaryContact,
  };
}
