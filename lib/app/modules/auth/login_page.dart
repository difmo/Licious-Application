import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common_button.dart';
import 'provider/auth_provider.dart';
import 'widgets/input_field.dart';
import 'otp_verification_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();

  bool _agreeToTerms = false;
  bool _isChecking = false;

  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap =
          () => _launchURL('https://shrimpbite.in/index.php/terms-conditions/');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap =
          () => _launchURL('https://shrimpbite.in/index.php/privacy-policy/');

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    // Show "verified" toast only when arriving from OTP verification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['verified'] == true) {
        _showSnackBar(
          'Login successful!',
          backgroundColor: Colors.green.shade600,
          icon: Icons.check_circle,
        );
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _showSnackBar(
    String message, {
    Color backgroundColor = Colors.black87,
    IconData? icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Format phone for backend (+91 prefix) ─────────────────────────────────

  String _formatPhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('+')) return trimmed;
    if (trimmed.length == 10) return '+91$trimmed';
    if (trimmed.length == 12 && trimmed.startsWith('91')) return '+$trimmed';
    return trimmed;
  }

  // ── Continue action ──────────────────────────────────────────────────────

  Future<void> _continue() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showSnackBar('Please enter your phone number',
          backgroundColor: Colors.orange.shade700);
      return;
    }

    if (!_agreeToTerms) {
      _showSnackBar('Please agree to the Terms & Conditions',
          backgroundColor: Colors.red);
      return;
    }

    final formatted = _formatPhone(phone);

    setState(() => _isChecking = true);

    final result =
        await ref.read(authProvider.notifier).checkUser(phoneNumber: formatted);

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (result == null || !result.success) {
      _showSnackBar(result?.message ?? 'Could not connect. Try again.',
          backgroundColor: Colors.red);
      return;
    }

    // All users (customer and rider) now use Firebase OTP flow
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationPage(phoneNumber: formatted),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Could not open the link: $url',
          backgroundColor: Colors.red);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Top food image ──
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Image.asset(
                'assets/images/image copy 5.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            // ── Form card ──
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back !',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your phone number to continue',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                      const SizedBox(height: 28),

                      // Phone Number field
                      InputField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: 'Enter your phone number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 28),

                      // Terms & Conditions Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (v) =>
                                  setState(() => _agreeToTerms = v ?? false),
                              activeColor: const Color(0xFF0EA5E9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(
                                  color: Colors.grey.shade400, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    height: 1.5),
                                children: [
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: const TextStyle(
                                        color: Color(0xFF0EA5E9),
                                        fontWeight: FontWeight.bold),
                                    recognizer: _termsRecognizer,
                                  ),
                                  const TextSpan(
                                      text: ' and ',
                                      style: TextStyle(color: Colors.grey)),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                        color: Color(0xFF0EA5E9),
                                        fontWeight: FontWeight.bold),
                                    recognizer: _privacyRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Continue button
                      CommonButton(
                        text: 'Continue',
                        onPressed: _continue,
                        isLoading: _isChecking,
                      ),
                      const SizedBox(height: 28),

                      // ── How it works callout ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFBAE6FD), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Color(0xFF0284C7), size: 15),
                                SizedBox(width: 6),
                                Text(
                                  'How it works',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _hintRow('🛒', 'Customers receive an OTP via SMS'),
                            _hintRow(
                                '🏍️', 'Riders also receive an OTP via SMS'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Sign up flow is now built-in to 'Continue' button
                      // If you are new, backend will return action: "otp"

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hintRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF0369A1), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
