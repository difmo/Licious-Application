import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:licius_application/app/routes/app_routes.dart';
import '../../data/models/food_models.dart';
import '../../data/services/db_service.dart';
import '../../widgets/common_button.dart';
import 'provider/auth_provider.dart';
import 'widgets/input_field.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_profile_page.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    // Show "verified" toast only when arriving from OTP verification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['verified'] == true) {
        _showSnackBar(
          'User register successful please login',
          backgroundColor: Colors.green.shade600,
          icon: Icons.check_circle,
        );
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
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

  // ── Login action ─────────────────────────────────────────────────────────

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill all fields',
          backgroundColor: Colors.orange.shade700);
      return;
    }

    if (!_agreeToTerms) {
      _showSnackBar('Please agree to the Terms & Conditions',
          backgroundColor: Colors.red);
      return;
    }

    // Trigger Riverpod login action
    await ref
        .read(authProvider.notifier)
        .login(phoneNumber: phone, password: password);

    if (!mounted) return;

    // React to new state
    final authState = ref.read(authProvider);

    if (authState is AuthAuthenticated) {
      // Update legacy CartProvider profile (kept for rest of UI compatibility)
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

      _showSnackBar('Welcome back!',
          backgroundColor: Colors.green.shade600, icon: Icons.check_circle);

      if (authState.user.role == 'rider') {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.riderHome, (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
      }
    } else if (authState is AuthError) {
      _showSnackBar(authState.message, backgroundColor: Colors.red);
      ref.read(authProvider.notifier).reset();
    } else if (authState is AuthSuccess) {
      _showSnackBar(authState.message,
          backgroundColor: Colors.green.shade600, icon: Icons.check_circle);
      // AuthSuccess might not have user object directly in some versions of provider
      // but usually redirects to home. We'll stick to home as fallback.
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.home, (route) => false);
    }
  }

  // ── Google Sign-In action ────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    try {
      debugPrint('[GOOGLE AUTH] Sign-in process started...');
      // Cancel any previous sign-in first to avoid stale data
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled the sign-in
        return;
      }

      // ── LOG GOOGLE SIGN-IN SUCCESS ──────────────────────────────────────────
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════╗');
      debugPrint('║              GOOGLE SIGN-IN SUCCESS                          ║');
      debugPrint('╟──────────────────────────────────────────────────────────────╢');
      debugPrint('║  Name  : ${account.displayName?.padRight(44) ?? "N/A"}║');
      debugPrint('║  Email : ${account.email.padRight(44)}║');
      debugPrint('║  ID    : ${account.id.padRight(44)}║');
      debugPrint('╚══════════════════════════════════════════════════════════════╝');
      debugPrint('');
      // ───────────────────────────────────────────────────────────────────────

      // Success! Navigate to the detail page (or perform backend sync)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GoogleProfilePage(account: account),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════╗');
      debugPrint('║              GOOGLE SIGN-IN FAILED                           ║');
      debugPrint('╟──────────────────────────────────────────────────────────────╢');
      debugPrint('║  Error: ${e.toString().padRight(52)}║');
      debugPrint('╚══════════════════════════════════════════════════════════════╝');
      debugPrint('Stacktrace: $stackTrace');
      debugPrint('');

      if (mounted) {
        _showSnackBar(
          'Google Sign-In Failed: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch auth state to drive loading indicator
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

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
            Container(
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
                    'Sign in to your account',
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
                  const SizedBox(height: 20),

                  // Password field
                  InputField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: 12),

                  // Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/forgot-password'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                          text: const TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey, height: 1.5),
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                    color: Color(0xFF0EA5E9),
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                  text: ' and ',
                                  style: TextStyle(color: Colors.grey)),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                    color: Color(0xFF0EA5E9),
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Login button
                  CommonButton(
                    text: 'Login',
                    onPressed: _login,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),

                  // ── Divider ──
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Google Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: Colors.grey.shade200, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google_logo.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sign up link
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.signup),
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account ? ",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
