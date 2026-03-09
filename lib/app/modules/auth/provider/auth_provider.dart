import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/network/api_client.dart';
import '../../../data/services/auth_service.dart';
import '../../../../core/storage/secure_storage_service.dart';

// ── Provider for AuthService ───────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(client: ref.watch(apiClientProvider));
});

final secureStorageProvider = Provider((ref) => SecureStorageService());

// ── Auth State ─────────────────────────────────────────────────────────────

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
  final String token;

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

// ── Notifier ───────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthLoading();
  }

  Future<void> _restoreSession() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final token = await storage.getAccessToken();

      if (token != null && token.isNotEmpty) {
        final response = await ref.read(authServiceProvider).getProfile();
        
        if (response.success && response.data != null) {
          state = AuthAuthenticated(
            user: response.data!,
            token: token,
          );
        } else {
          await logout();
        }
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    state = const AuthLoading();
    final response = await ref.read(authServiceProvider).register(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (response.success) {
      state = AuthSuccess(message: response.message);
    } else {
      state = AuthError(response.message);
    }
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AuthLoading();
    final response = await ref.read(authServiceProvider).login(
      phoneNumber: phoneNumber,
      password: password,
    );
    
    if (response.success && response.data != null && response.token != null) {
      await ref.read(secureStorageProvider).saveTokens(
        access: response.token!,
        refresh: response.refreshToken ?? '', // Backend should provide this
      );
      
      state = AuthAuthenticated(
        user: response.data!,
        token: response.token!,
      );
    } else {
      state = AuthError(response.message);
    }
  }

  Future<void> sendOtp({required String phoneNumber}) async {
    state = const AuthLoading();
    final response = await ref.read(authServiceProvider).sendOtp(phoneNumber: phoneNumber);
    if (response.success) {
      state = AuthSuccess(message: response.message, otp: response.otp);
    } else {
      state = AuthError(response.message);
    }
  }

  Future<void> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    state = const AuthLoading();
    final response = await ref.read(authServiceProvider).verifyOtp(
      phoneNumber: phoneNumber,
      otp: otp,
    );
    if (response.success) {
      state = AuthSuccess(message: response.message);
    } else {
      state = AuthError(response.message);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    state = const AuthLoading();
    final response = await ref.read(authServiceProvider).forgotPassword(email: email);
    if (response.success) {
      state = AuthSuccess(message: response.message);
    } else {
      state = AuthError(response.message);
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    await ref.read(secureStorageProvider).clearAll();
    state = const AuthUnauthenticated();
  }

  void reset() => state = const AuthInitial();
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// ── Convenience selector providers ────────────────────────────────────────
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated ? authState.user : null;
});
