import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../routes/app_routes.dart';
import '../../data/services/db_service.dart';
import '../../data/models/food_models.dart';
import '../auth/provider/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for the animation to play a bit
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // The AuthNotifier constructor already called _restoreSession().
    // We wait until the state is not Initial (restoration in progress)
    // or until we get a result.
    final authState = ref.read(authProvider);

    if (authState is AuthAuthenticated) {
      _syncAndNavigate(authState);
    } else {
      // If it's still initial, it might be restoring. 
      // Let's wait a bit more or check if we should go to onboarding.
      Navigator.pushReplacementNamed(context, AppRoutes.initialRoute);
    }
  }

  void _syncAndNavigate(AuthAuthenticated auth) {
    // Sync the legacy provider
    CartProviderScope.of(context).updateUserProfile(
      UserProfile(
        name: auth.user.fullName,
        email: auth.user.email,
        phone: auth.user.phoneNumber,
        profileImage: 'assets/images/image copy 2.png',
      ),
    );
    
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo imageSSS
                Image.asset(
                  'assets/images/logowithoutback.png',
                  width: 350,
                  height: 350,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image is missing
                    return const Icon(
                      Icons.set_meal,
                      size: 100,
                      color: Color(0xFF38B24D),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
