import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:local_basket_business/domain/repositories/auth/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthState.initial());

  final AuthRepository _repo;

  Future<void> sendOtp(String phone) async {
    emit(
      state.copyWith(status: AuthStatus.sendingOtp, phone: phone, error: null),
    );
    try {
      await _repo.triggerOtp(otpType: 'SIGNIN', primaryContact: phone);
      emit(state.copyWith(status: AuthStatus.otpSent));
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, error: 'Failed to send OTP'),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    emit(state.copyWith(status: AuthStatus.verifyingOtp, error: null));
    try {
      final token = await _repo.loginWithOtp(
        otp: otp,
        primaryContact: state.phone!,
      );
      await _repo.saveToken(token);
      final user = await _repo.getUserDetails();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: 'Invalid OTP or login failed',
        ),
      );
    }
  }

  Future<void> bootstrap() async {
    emit(state.copyWith(status: AuthStatus.checking));
    final token = await _repo.getToken();
    if (token != null) {
      try {
        final user = await _repo.getUserDetails();
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
        return;
      } catch (_) {}
    }
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }
}
