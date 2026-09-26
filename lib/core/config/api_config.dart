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
    refresh: '/auth/refresh',
    userDetails: '/api/users/me',
    fcmToken: '/api/users/me/fcm-token',
  );
}

class ApiEndpoints {
  const ApiEndpoints({
    required this.triggerOtp,
    required this.login,
    required this.refresh,
    required this.userDetails,
    required this.fcmToken,
  });

  final String triggerOtp;
  final String login;
  final String refresh;
  final String userDetails;
  final String fcmToken;
}
