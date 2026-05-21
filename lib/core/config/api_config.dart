class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    required this.endpoints,
  });

  final String baseUrl;
  final ApiEndpoints endpoints;

  static const ApiEndpoints endpointsV1 = ApiEndpoints(
    triggerOtp: '/auth/otp/send',
    login: '/auth/otp/login',
    userDetails: '/api/users/me',
  );
}

class ApiEndpoints {
  const ApiEndpoints({
    required this.triggerOtp,
    required this.login,
    required this.userDetails,
  });

  final String triggerOtp;
  final String login;
  final String userDetails;
}
