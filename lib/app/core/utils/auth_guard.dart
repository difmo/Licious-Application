import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/state/auth_store.dart';
import '../../modules/auth/login_page.dart';

class AuthGuard {
  /// Checks if the user is authenticated.
  /// If yes, executes [onAuthenticated].
  /// If no, shows the [LoginPage] as a modal bottom sheet.
  static void run(BuildContext context, WidgetRef ref, VoidCallback onAuthenticated) {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    
    if (isAuthenticated) {
      onAuthenticated();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AuthModalWrapper(),
      );
    }
  }
}

class AuthModalWrapper extends StatelessWidget {
  const AuthModalWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const LoginPage(),
          Positioned(
            top: 10,
            right: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
