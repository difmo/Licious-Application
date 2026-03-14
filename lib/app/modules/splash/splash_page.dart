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
  bool _minimumTimePassed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Trigger session restoration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).init();
    });

    // Enforce a minimum display time for the splash screen (3 seconds)
    // and then navigate based on current state.
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _minimumTimePassed = true);
      _handleNavigation(ref.read(authProvider));
    });
  }

  void _handleNavigation(AuthState state) {
    if (!mounted || _navigated) return;

    if (state is AuthAuthenticated) {
      _navigated = true;
      _syncAndNavigate(state);
    } else if (state is AuthUnauthenticated || state is AuthError) {
      _navigated = true;
      Navigator.pushReplacementNamed(context, AppRoutes.initialRoute);
    } else if (state is AuthSuccess) {
      // Success state from registration or forgot password usually goes to login
      _navigated = true;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _syncAndNavigate(AuthAuthenticated auth) {
    // Sync the legacy provider for UI components that rely on it
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
    // Watch state change to navigate immediately if the minimum delay has passed
    ref.listen<AuthState>(authProvider, (previous, next) {
      // If we already navigated or are still in a loading/initial state, wait
      if (_navigated) return;

      // We only navigate automatically if the minimum display time has passed
      if (next is AuthAuthenticated ||
          next is AuthUnauthenticated ||
          next is AuthError) {
        if (_minimumTimePassed) {
          _handleNavigation(next);
        }
      }
    });

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
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.set_meal,
                    size: 100,
                    color: Color(0xFF38B24D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
