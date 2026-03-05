import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_profile_page.dart';

/// Real Google Sign-In instance
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      // Cancel any previous sign-in first
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled the sign-in
        return;
      }

      // Sign-in succeeded — navigate to the Google profile page
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GoogleProfilePage(account: account),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(
          context,
          'Google Sign-In Failed',
          'Could not sign in with Google.\n\nMake sure you have configured a valid OAuth 2.0 Client ID in Google Cloud Console and added the REVERSED_CLIENT_ID to ios/Runner/Info.plist.\n\nError: $e',
        );
      }
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 26),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF555555),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Branded logo hero section ──
            Container(
              height: screenHeight * 0.42,
              width: double.infinity,
              decoration: const BoxDecoration(color: Color(0xFFFFF4EE)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/shrimpbite_logo.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App name
                  const Text(
                    'Shrimpbite',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE85C1A),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fresh Seafood, Delivered Fast 🦐',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── White card ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              transform: Matrix4.translationValues(0, -28, 0),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Shrimpbite',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Order fresh shrimp, prawns & premium seafood — delivered straight to your door.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Real Google Sign-In button ──
                  _googleSignInButton(context),
                  const SizedBox(height: 14),

                  // ── Create account button ──
                  _createAccountButton(context),
                  const SizedBox(height: 24),

                  // ── Login link ──
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account ? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFAAAAAA),
                          ),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleSignInButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: () => _handleGoogleSignIn(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _GoogleLogo(size: 24),
            SizedBox(width: 12),
            Text(
              'Continue with google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _createAccountButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/signup'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_outline, size: 20),
            SizedBox(width: 10),
            Text(
              'Create an account',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Real Google "G" logo from asset ───────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
