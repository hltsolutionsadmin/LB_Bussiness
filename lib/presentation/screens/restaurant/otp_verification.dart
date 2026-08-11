import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:local_basket_business/routes/app_router.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/data/datasources/business/business_remote_data_source.dart';
import 'package:local_basket_business/domain/repositories/auth/auth_repository.dart';
import 'package:local_basket_business/core/session/session_store.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  final String? debugOtp;

  const OTPScreen({super.key, required this.phoneNumber, this.debugOtp});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  // Focus nodes for the actual TextFields
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  // Separate focus nodes for the Focus wrappers used to intercept key events
  final List<FocusNode> _wrapperFocusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );
  final ScrollController _scrollController = ScrollController();

  String? _errorText;
  String? _debugOtp;
  int _timer = 30;
  Timer? _countdownTimer;
  bool _isSubmitting = false;

  String get _primaryContact {
    final value = widget.phoneNumber.trim();
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) return digits;
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits.substring(2);
    }

    return value;
  }

  String get _displayPhoneNumber => '+91 $_primaryContact';

  Future<Map<String, dynamic>> _withStoreDetails(
    Map<String, dynamic> user,
  ) async {
    final storeId = user['storeId']?.toString() ?? '';
    if (storeId.isEmpty || user['store'] is Map<String, dynamic>) return user;

    try {
      final store = await sl<BusinessRemoteDataSource>().getStoreDetails(
        storeId: storeId,
      );
      return {...user, 'store': store};
    } catch (_) {
      return user;
    }
  }

  @override
  void initState() {
    super.initState();
    _debugOtp = widget.debugOtp;
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNodes.first.requestFocus();
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
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
      final session = sl<SessionStore>();
      final deviceId = const Uuid().v4();
      session.clear();
      final token = await repo.loginWithOtp(
        otp: otp,
        primaryContact: _primaryContact,
        fullName: 'User',
        deviceId: deviceId,
      );
      print('[AUTH] OTP Verified. Primary contact: $_primaryContact');
      print('[AUTH] TOKEN: $token');

      final userDetailsMap = await _withStoreDetails(
        await repo.getUserDetails(),
      );
      session.setUser(userDetailsMap);

      if (!mounted) return;

      final roles = session.roleNames;
      print('Roles: $roles');

      if (roles.contains('ROLE_BUSINESS_ADMIN')) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.admin, (_) => false);
        return;
      }
      if (roles.contains('ROLE_STORE_ADMIN')) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
        return;
      }

      setState(() {
        _errorText = 'You are not allowed. You are not an admin.';
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
      final res = await sl<AuthRepository>().triggerOtpWithResponse(
        primaryContact: _primaryContact,
      );

      final otp = res['otp']?.toString();
      if (mounted && otp != null && otp.isNotEmpty) {
        setState(() => _debugOtp = otp);
      } else {
        if (mounted) setState(() => _debugOtp = null);
      }

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
                controller: _scrollController,
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
                                      _displayPhoneNumber,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if ((_debugOtp ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        child: Text(
                                          'OTP: ${_debugOtp!}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 32),

                                    // OTP Fields
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(6, (index) {
                                        return Focus(
                                          focusNode: _wrapperFocusNodes[index],
                                          onKey: (node, event) {
                                            if (event is RawKeyDownEvent &&
                                                event.logicalKey ==
                                                    LogicalKeyboardKey
                                                        .backspace) {
                                              // If current field is empty, move to previous
                                              // and clear it. This allows repeated backspace
                                              // presses to walk left clearing one by one.
                                              if (_controllers[index]
                                                  .text
                                                  .isEmpty) {
                                                if (index > 0) {
                                                  _controllers[index - 1]
                                                      .clear();
                                                  _focusNodes[index - 1]
                                                      .requestFocus();
                                                  return KeyEventResult.handled;
                                                }
                                              } else {
                                                // Let the field handle deleting its own char
                                                _controllers[index].clear();
                                                return KeyEventResult.handled;
                                              }
                                            }
                                            return KeyEventResult.ignored;
                                          },
                                          child: SizedBox(
                                            width: 48,
                                            height: 56,
                                            child: TextField(
                                              controller: _controllers[index],
                                              focusNode: _focusNodes[index],
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  TextInputType.number,
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
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFF97316,
                                                            ),
                                                            width: 2,
                                                          ),
                                                    ),
                                              ),
                                              onChanged: (v) {
                                                if (v.isNotEmpty) {
                                                  if (index < 5) {
                                                    _focusNodes[index + 1]
                                                        .requestFocus();
                                                  }
                                                }
                                                _scrollToBottom();
                                                setState(
                                                  () => _errorText = null,
                                                );
                                              },
                                            ),
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
                                            0xFFEF865F,
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
                                                  color: Colors.white,
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
    _scrollController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
