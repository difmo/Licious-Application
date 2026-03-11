import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_store.dart';
import '../../app/routes/app_routes.dart';

/// A wrapper widget that ensures the user is authenticated before showing the child.
/// If not authenticated, it redirects to the login screen.
class AuthGuard extends ConsumerWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStoreProvider);

    if (authState.status == AuthStatus.authenticated) {
      return child;
    }

    if (authState.status == AuthStatus.loading || authState.status == AuthStatus.initial) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Use a post frame callback to navigate if not authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
