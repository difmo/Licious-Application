import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common_button.dart';
import 'provider/auth_provider.dart';
import '../../data/models/food_models.dart';
import '../../data/services/db_service.dart';
import '../../routes/app_routes.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationPage({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  static const int _otpLength = 6;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _isSendingOtp = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp();
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Send / Resend OTP ─────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    setState(() {
      _isSendingOtp = true;
      for (var c in _controllers) {
        c.clear();
      }
    });

    await ref
        .read(authProvider.notifier)
        .sendOtp(phoneNumber: widget.phoneNumber);

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    final authState = ref.read(authProvider);

    if (authState is AuthSuccess) {
      _showSnackBar('OTP has been sent to your phone via SMS',
          backgroundColor: Colors.green);
      ref.read(authProvider.notifier).reset();
    } else if (authState is AuthError) {
      debugPrint('[OTP ERROR] ${authState.message}');
      _showSnackBar(authState.message, backgroundColor: Colors.red);
      ref.read(authProvider.notifier).reset();
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((e) => e.text).join();
    if (otp.length < _otpLength) {
      _showSnackBar('Please enter the complete $_otpLength-digit OTP');
      return;
    }

    debugPrint('[OTP] User submitting OTP: $otp for ${widget.phoneNumber}');

    setState(() => _isVerifying = true);

    await ref.read(authProvider.notifier).verifyOtp(
          phoneNumber: widget.phoneNumber,
          otp: otp,
        );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    final authState = ref.read(authProvider);

    if (authState is AuthSuccess) {
      debugPrint('[OTP] Verification successful!');
      ref.read(authProvider.notifier).reset();
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
        arguments: {'verified': true},
      );
    } else if (authState is AuthAuthenticated) {
      debugPrint('[OTP] Instant login successful!');

      // Update legacy CartProvider profile (kept for rest of UI compatibility)
      try {
        final cartProvider = CartProviderScope.of(context);
        cartProvider.updateUserProfile(
          UserProfile(
            name: authState.user.fullName,
            email: authState.user.email,
            phone: authState.user.phoneNumber,
            profileImage: 'assets/images/image copy 2.png',
          ),
        );
        // Sync cart immediately after login
        cartProvider.loadCartFromApi();
      } catch (e) {
        debugPrint('Failed to update CartProvider profile: $e');
      }

      if (authState.user.role == 'rider') {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.riderHome, (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
      }
    } else if (authState is AuthError) {
      debugPrint('[OTP] Verification failed: ${authState.message}');
      _showSnackBar(authState.message, backgroundColor: Colors.red);
      ref.read(authProvider.notifier).reset();
    }
  }

  // ── Snack bar helper ──────────────────────────────────────────────────────

  void _showSnackBar(String message, {Color backgroundColor = Colors.black87}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              const Text(
                'Verification Code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We have sent the verification code to your\nphone number ${widget.phoneNumber}',
                style: const TextStyle(
                    fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 8),
              // ── Info Hint ───────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF64B5F6)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sms_outlined, size: 14, color: Color(0xFF1976D2)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We have sent an SMS with a 6-digit verification code to your phone. Please enter it below.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── 6 OTP boxes ─────────────────────────────────────────────
              if (_isSendingOtp)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_otpLength, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 46,
                      height: 54,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF2E7D32), width: 2),
                          ),
                          fillColor: Colors.grey.shade50,
                          filled: true,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (index < _otpLength - 1) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              _focusNodes[index].unfocus();
                            }
                          } else {
                            if (index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          }
                        },
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 36),

              // ── Resend ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the code? ",
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                  GestureDetector(
                    onTap: _isSendingOtp ? null : _sendOtp,
                    child: Text(
                      'Resend',
                      style: TextStyle(
                        color: _isSendingOtp
                            ? Colors.grey
                            : const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Confirm Button ───────────────────────────────────────────
              CommonButton(
                text: 'Confirm',
                onPressed: _verifyOtp,
                backgroundColor: const Color(0xFF2E7D32),
                borderRadius: 28,
                isLoading: _isVerifying,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
