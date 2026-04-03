import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../widgets/common_button.dart';
import 'package:flutter/services.dart';
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

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage>
    with CodeAutoFill {
  static const int _otpLength = 6;
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  bool _isSendingOtp = false;
  bool _isVerifying = false;

  @override
  void codeUpdated() {
    setState(() {
      _pinController.text = code!;
    });
    if (code!.length == _otpLength) {
      _verifyOtp();
    }
  }

  @override
  void initState() {
    super.initState();
    listenForCode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp();
    });
  }

  @override
  void dispose() {
    cancel(); 
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSendingOtp = true;
      _pinController.clear();
    });

    await ref
        .read(authProvider.notifier)
        .sendOtp(phoneNumber: widget.phoneNumber);

    if (!mounted) return;
    setState(() => _isSendingOtp = false);
    
    // Note: We don't check authState here because sendOtp completes 
    // when the request starts, not when the code is actually sent.
    // The UI will react via ref.listen in build().
  }

  Future<void> _verifyOtp() async {
    final otp = _pinController.text;
    if (otp.length < _otpLength) {
      _showSnackBar('Please enter the complete $_otpLength-digit OTP');
      return;
    }

    final cartProvider = CartProviderScope.of(context);
    setState(() => _isVerifying = true);

    await ref.read(authProvider.notifier).verifyOtp(
          phoneNumber: widget.phoneNumber,
          otp: otp,
        );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    final authState = ref.read(authProvider);

    if (authState is AuthAuthenticated) {
      try {
        cartProvider.updateUserProfile(
          UserProfile(
            name: authState.user.fullName,
            email: authState.user.email,
            phone: authState.user.phoneNumber,
            profileImage: 'assets/images/image copy 2.png',
          ),
        );
        cartProvider.loadCartFromApi();
      } catch (e) {
        debugPrint('Failed to update profile: $e');
      }

      if (authState.user.role == 'rider') {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.riderHome, (route) => false);
      } else {
        // Direct to Home. Contextual location handled later.
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
      }
    } else if (authState is AuthError) {
      setState(() {
        _isVerifying = false;
      });
      _pinController.clear();
      _pinFocusNode.requestFocus();
    }
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.black87}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to show feedback
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthSuccess) {
        _showSnackBar(next.message, backgroundColor: Colors.green);
      } else if (next is AuthError) {
        _showSnackBar(next.message, backgroundColor: Colors.red);
      }
    });

    final defaultPinTheme = PinTheme(
      width: 50, height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: const Color(0xFF2E7D32), width: 2)));
    final errorPinTheme = defaultPinTheme.copyWith(decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: Colors.redAccent, width: 2)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black54), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('OTP Verification', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF114F3B))),
              const SizedBox(height: 15),
              Text('We have sent the verification code to your\nphone number ${widget.phoneNumber}', style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5)),
              const SizedBox(height: 32),
              Center(
                child: Pinput(
                  length: _otpLength,
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  errorPinTheme: errorPinTheme,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  hapticFeedbackType: HapticFeedbackType.lightImpact,
                  onCompleted: (pin) => _verifyOtp(),
                  cursor: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Container(margin: const EdgeInsets.only(bottom: 9), width: 22, height: 1, color: const Color(0xFF2E7D32))]),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSendingOtp) ...[
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 2)),
                    const SizedBox(width: 8),
                    const Text("Requesting OTP...", style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.bold)),
                  ] else ...[
                    const Text("Didn't receive the code? ", style: TextStyle(color: Colors.black54, fontSize: 13)),
                    GestureDetector(onTap: _sendOtp, child: const Text('Resend', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ],
              ),
              const SizedBox(height: 48),
              Consumer(
                builder: (context, ref, child) {
                  final isBusy = _isVerifying || _isSendingOtp;
                  return CommonButton(
                    text: 'Verify & Proceed',
                    onPressed: isBusy ? null : _verifyOtp,
                    backgroundColor: const Color(0xFF2E7D32),
                    borderRadius: 28,
                    isLoading: isBusy,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
