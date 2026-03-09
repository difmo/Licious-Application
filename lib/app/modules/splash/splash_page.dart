import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _navigated = false;

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

    // Start checking auth state after the splash animation begins.
    // We poll every 300ms so we react as soon as session restore completes.
    Future.delayed(const Duration(seconds: 2), _checkAuthAndNavigate);
  }

  void _checkAuthAndNavigate() {
    if (!mounted || _navigated) return;
    final authState = ref.read(authProvider);

    if (authState is AuthAuthenticated) {
      _navigated = true;
      _syncAndNavigate(authState);
    } else if (authState is AuthUnauthenticated ||
        authState is AuthError ||
        authState is AuthSuccess) {
      // Session restoration ended or terminal state reached → navigate to Login/Onboarding
      _navigated = true;
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.initialRoute);
      }
    } else if (authState is AuthLoading || authState is AuthInitial) {
      // Session is still being restored — check again shortly
      Future.delayed(const Duration(milliseconds: 300), _checkAuthAndNavigate);
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

    if (auth.user.role == 'rider') {
      Navigator.pushReplacementNamed(context, AppRoutes.riderHome);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
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
                Image.asset(
                  'assets/images/logowithoutback.png',
                  width: 350,
                  height: 350,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
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
