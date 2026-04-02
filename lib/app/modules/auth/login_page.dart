import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common_button.dart';
import 'provider/auth_provider.dart';
import 'otp_verification_page.dart';
import '../../routes/app_routes.dart';

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
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
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
    final trimmed = raw.replaceAll(RegExp(r'\D'), '');
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
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!mounted) return;
      if (next is AuthAuthenticated) {
        if (next.user.role == 'rider') {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.riderHome, (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.home, (route) => false);
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Top Header with Brand Image ──
            Stack(
              children: [
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/image copy 5.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF114F3B),
                      child: const Center(
                        child: Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Form Content ──
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Premium Seafresh\nDelivered To You',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF114F3B),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter your mobile number to get started with OTP verification.',
                        style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.4),
                      ),
                      const SizedBox(height: 40),

                      // Phone Number Input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '98765 43210',
                            hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 1.5),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 8),
                              child: Text(
                                '+91 ',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Terms & Conditions Checkbox
                      GestureDetector(
                        onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _agreeToTerms,
                                onChanged: (v) =>
                                    setState(() => _agreeToTerms = v ?? false),
                                activeColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                side: BorderSide(
                                    color: Colors.grey.shade300, width: 2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree to the ',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                      height: 1.5),
                                  children: [
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: const TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.bold),
                                      recognizer: _termsRecognizer,
                                    ),
                                    const TextSpan(
                                        text: ' and ',
                                        style: TextStyle(color: Colors.black54)),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.bold),
                                      recognizer: _privacyRecognizer,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 44),

                      // Continue button
                      CommonButton(
                        text: 'Send OTP',
                        onPressed: _continue,
                        isLoading: _isChecking,
                        backgroundColor: const Color(0xFF2E7D32),
                        borderRadius: 28,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Trust indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _trustItem(Icons.verified_user_outlined, 'Secure'),
                          const SizedBox(width: 24),
                          _trustItem(Icons.speed_outlined, 'Fast'),
                          const SizedBox(width: 24),
                          _trustItem(Icons.local_shipping_outlined, 'Fresh'),
                        ],
                      ),
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

  Widget _trustItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
