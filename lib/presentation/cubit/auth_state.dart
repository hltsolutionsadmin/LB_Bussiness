part of 'auth_cubit.dart';

enum AuthStatus {
  initial,
  checking,
  unauthenticated,
  sendingOtp,
  otpSent,
  verifyingOtp,
  authenticated,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? phone;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({required this.status, this.phone, this.user, this.error});

  const AuthState.initial() : this(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    String? phone,
    Map<String, dynamic>? user,
    String? error,
  }) => AuthState(
    status: status ?? this.status,
    phone: phone ?? this.phone,
    user: user ?? this.user,
    error: error,
  );

  @override
  List<Object?> get props => [status, phone, user, error];
}
