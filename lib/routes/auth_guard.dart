import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/providers/auth_notifier.dart';
import '../features/auth/models/auth_state.dart';

class AuthGuard extends ConsumerWidget {
  final Widget authenticatedRoute;
  final Widget unauthenticatedRoute;

  const AuthGuard({
    super.key,
    required this.authenticatedRoute,
    required this.unauthenticatedRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    switch (authState.status) {
      case AuthStatus.loading:
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return authenticatedRoute;
      case AuthStatus.unauthenticated:
        return unauthenticatedRoute;
    }
  }
}
