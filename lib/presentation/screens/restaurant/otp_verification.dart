import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:local_basket_business/routes/app_router.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/domain/repositories/auth/auth_repository.dart';
import 'package:local_basket_business/core/session/session_store.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String? _errorText;
  int _timer = 30;
  Timer? _countdownTimer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timer > 0) {
        setState(() => _timer--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleVerify() async {
    final otp = _controllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() => _errorText = 'Please enter complete OTP');
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      final repo = sl<AuthRepository>();
      final token = await repo.loginWithOtp(
        otp: otp,
        primaryContact: widget.phoneNumber,
      );

      // ignore: avoid_print
      print('[AUTH] TOKEN: $token');

      try {
        final details = await repo.getUserDetails();
        sl<SessionStore>().setUser(details);
      } catch (_) {}

      if (!mounted) return;

      final roles = sl<SessionStore>().roleNames;

      if (roles.contains('ROLE_USER_ADMIN')) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.admin, (_) => false);
        return;
      }

      if (roles.contains('ROLE_RESTAURANT_OWNER')) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
        return;
      }

      setState(() {
        _errorText =
            'Your account does not have access. Please contact support.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Invalid or expired OTP');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleResend() async {
    if (_timer > 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await sl<AuthRepository>().triggerOtp(
        otpType: 'SIGNIN',
        primaryContact: widget.phoneNumber,
      );

      for (final c in _controllers) {
        c.clear();
      }

      _focusNodes.first.requestFocus();
      _startTimer();

      setState(() => _errorText = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to resend OTP');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF97316), Color(0xFFEA580C), Color(0xFFDC2626)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                reverse: true,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),

                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // OTP Card
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFED7AA),
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                      child: const Icon(
                                        Icons.shield_outlined,
                                        size: 32,
                                        color: Color(0xFFF97316),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Verify OTP',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Enter the 6-digit code sent to',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+91 ${widget.phoneNumber}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // OTP Fields
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(6, (index) {
                                        return SizedBox(
                                          width: 48,
                                          height: 56,
                                          child: TextField(
                                            controller: _controllers[index],
                                            focusNode: _focusNodes[index],
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            maxLength: 1,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            decoration: InputDecoration(
                                              counterText: '',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFF97316),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            onChanged: (v) {
                                              if (v.isNotEmpty && index < 5) {
                                                _focusNodes[index + 1]
                                                    .requestFocus();
                                              }
                                              setState(() => _errorText = null);
                                            },
                                          ),
                                        );
                                      }),
                                    ),

                                    if (_errorText != null) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorText!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 24),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : _handleVerify,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF97316,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: _isSubmitting
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              )
                                            : const Text(
                                                'Verify & Continue',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    _timer > 0
                                        ? Text(
                                            'Resend OTP in ${_timer}s',
                                            style: const TextStyle(
                                              color: Color(0xFF6B7280),
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: _handleResend,
                                            child: const Text(
                                              'Resend OTP',
                                              style: TextStyle(
                                                color: Color(0xFFF97316),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              const Text(
                                'Didn\'t receive the code?\nCheck your SMS or try resending',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFFFED7AA)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }
}
