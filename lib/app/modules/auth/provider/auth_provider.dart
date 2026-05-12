import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/auth_models.dart';
import '../../../../core/state/auth_store.dart' as core;
export '../../../data/models/auth_models.dart' show CheckUserResponseModel;

// Expose the core providers for convenience
final authStoreProvider = core.authStoreProvider;
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

  Future<CheckUserResponseModel?> checkUser({required String phoneNumber}) async {
    return await ref.read(core.authStoreProvider.notifier).checkUser(phoneNumber: phoneNumber);
  }

  Future<void> sendOtp({required String phoneNumber, bool force = false}) async {
    await ref.read(core.authStoreProvider.notifier).sendOtp(phoneNumber: phoneNumber, force: force);
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

  Future<void> logout() async {
    await ref.read(core.authStoreProvider.notifier).logout();
  }

  Future<void> init() async {
     await ref.read(core.authStoreProvider.notifier).init();
  }
  
  void reset() => ref.invalidate(core.authStoreProvider);

  Future<bool> deleteAccount({String? reason}) async {
    final response = await ref
        .read(core.authStoreProvider.notifier)
        .deleteAccount(reason: reason);
    return response.success;
  }
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

final userProfileProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  // Watch the core store directly for instant reactivity
  final authCore = ref.watch(core.authStoreProvider);
  final user = authCore.user;

  // If we already have a user in memory, use it immediately
  if (authCore.status == core.AuthStatus.authenticated && user != null) {
    if (user.id != 'placeholder') {
      return user;
    }
    // If it's a placeholder, we still return it but don't stop there
  }
  
  // Fallback: Fetch latest data from server
  final response = await ref.watch(authServiceProvider).getProfile();
  if (response.success && response.data != null) {
    return response.data!;
  }
  
  // Final fallback: Use memory user if fetch fails
  if (user != null) return user;
  
  throw Exception(response.message);
});

