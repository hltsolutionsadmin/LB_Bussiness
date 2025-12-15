import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_basket_business/presentation/screens/restaurant/otp_verification.dart';
import 'package:local_basket_business/presentation/screens/terms/terms_and_conditions.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/domain/repositories/auth/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  String? _errorText;
  bool _isSubmitting = false;
  bool _agreedToTerms = false;

  void _handleSubmit() async {
    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    if (_phoneController.text.length != 10) {
      setState(() {
        _errorText = 'Please enter a valid 10-digit mobile number';
        _isSubmitting = false;
      });
      return;
    }

    try {
      await sl<AuthRepository>().triggerOtp(
        otpType: 'SIGNIN',
        primaryContact: _phoneController.text,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(phoneNumber: _phoneController.text),
        ),
      );
    } catch (e) {
      setState(() {
        _errorText = 'Failed to send OTP';
        _isSubmitting = false;
      });
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 40,
                            color: Color(0xFFF97316),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Local Basket',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Restaurant Partner',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFED7AA),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Login Card
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Login to manage your restaurant',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Phone Label
                              const Text(
                                'Mobile Number',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Phone Input
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _errorText != null
                                        ? Colors.red
                                        : const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Icon(
                                        Icons.phone,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                    const Text(
                                      '+91',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Enter 10-digit mobile number',
                                          border: InputBorder.none,
                                          counterText: '',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (_errorText != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _errorText!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: (_isSubmitting || !_agreedToTerms)
                                      ? null
                                      : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Text(
                                              'Send OTP',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Icon(Icons.arrow_forward_rounded),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Terms
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: _agreedToTerms,
                                    onChanged: (v) => setState(
                                      () => _agreedToTerms = v ?? false,
                                    ),
                                  ),
                                  const Text(
                                    'I agree to ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TermsAndConditionsScreen(),
                                        ),
                                      );
                                      if (mounted) {
                                        setState(() => _agreedToTerms = true);
                                      }
                                    },
                                    child: const Text('Terms & Conditions'),
                                  ),
                                ],
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
    _phoneController.dispose();
    super.dispose();
  }
}
