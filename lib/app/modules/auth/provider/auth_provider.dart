import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/auth_models.dart';
import '../../../../core/state/auth_store.dart' as core;

// Expose the core providers for convenience
final authServiceProvider = core.authServiceProvider;
final secureStorageProvider = core.secureStorageProvider;

// ── Auth State (Preserving for UI compatibility) ──────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token; // Token should ideally come from core or storage

  const AuthAuthenticated({required this.user, required this.token});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthSuccess extends AuthState {
  final String message;
  final String? otp;

  const AuthSuccess({required this.message, this.otp});
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

// ── Bridge Notifier ───────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Listen to core AuthStore and map to feature state
    final coreState = ref.watch(core.authStoreProvider);
    
    switch (coreState.status) {
      case core.AuthStatus.initial:
        if (coreState.successMessage != null) {
          return AuthSuccess(message: coreState.successMessage!, otp: coreState.otp);
        }
        return const AuthInitial();
      case core.AuthStatus.loading:
        return const AuthLoading();
      case core.AuthStatus.authenticated:
        return AuthAuthenticated(user: coreState.user!, token: ''); // token hidden in storage
      case core.AuthStatus.unauthenticated:
        if (coreState.successMessage != null) {
          return AuthSuccess(message: coreState.successMessage!);
        }
        if (coreState.error != null) {
          return AuthError(coreState.error!);
        }
        return const AuthUnauthenticated();
    }
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
     await ref.read(core.authStoreProvider.notifier).login(phone: phoneNumber, password: password);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    await ref.read(core.authStoreProvider.notifier).register(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  Future<void> sendOtp({required String phoneNumber}) async {
    await ref.read(core.authStoreProvider.notifier).sendOtp(phoneNumber: phoneNumber);
  }

  Future<void> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    await ref.read(core.authStoreProvider.notifier).verifyOtp(
          phoneNumber: phoneNumber,
          otp: otp,
        );
  }

  Future<void> googleAuth({required String idToken}) async {
    await ref.read(core.authStoreProvider.notifier).googleAuth(idToken: idToken);
  }

  Future<void> forgotPassword({required String email}) async {
    await ref.read(core.authStoreProvider.notifier).forgotPassword(email: email);
  }

  Future<void> logout() async {
    await ref.read(core.authStoreProvider.notifier).logout();
  }

  Future<void> init() async {
     await ref.read(core.authStoreProvider.notifier).init();
  }
  
  void reset() => ref.invalidate(core.authStoreProvider);
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// Alias existing providers
final isAuthenticatedProvider = core.isAuthenticatedProvider;
final currentUserProvider = Provider<UserModel?>((ref) {
  final coreState = ref.watch(core.authStoreProvider);
  return coreState.user;
});

