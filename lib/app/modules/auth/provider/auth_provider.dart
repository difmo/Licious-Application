import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/network/api_client.dart';
import '../../../data/services/auth_service.dart';

// ── Provider for AuthService ───────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(client: ref.watch(apiClientProvider));
});

// ── Auth State ─────────────────────────────────────────────────────────────

/// Represents all possible authentication states in the app.
sealed class AuthState {
  const AuthState();
}

/// Initial / unauthenticated state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading — an async auth operation is in flight
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Logged-in and the user object is available
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;

  const AuthAuthenticated({required this.user, required this.token});
}

/// Operation succeeded but the user is not yet logged in
/// (e.g. after registration, OTP sent, OTP verified)
class AuthSuccess extends AuthState {
  final String message;
  final String? otp; // dev/dummy mode: OTP echoed back by the server

  const AuthSuccess({required this.message, this.otp});
}

/// Any error / failure from the API or network
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

// ── Notifier ───────────────────────────────────────────────────────────────

/// Manages all authentication side-effects.
///
/// Consumers watch [authProvider] and rebuild whenever state changes.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthInitial()) {
    _restoreSession();
  }

  // ── Session restore on app start ──────────────────────────────────────────
  Future<void> _restoreSession() async {
    final token = await ApiClient.getToken();
    if (token != null && token.isNotEmpty) {
      final response = await _service.getProfile();
      if (response.success && response.data != null) {
        state = AuthAuthenticated(
          user: response.data!,
          token: token,
        );
      } else {
        // Token invalid or expired — clear it.
        await logout();
      }
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    state = const AuthLoading();
    final response = await _service.register(
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

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AuthLoading();
    final response = await _service.login(
      phoneNumber: phoneNumber,
      password: password,
    );
    if (response.success && response.data != null && response.token != null) {
      state = AuthAuthenticated(
        user: response.data!,
        token: response.token!,
      );
    } else if (response.success) {
      // Success but no user object — fall back to generic success
      state = AuthSuccess(message: response.message);
    } else {
      state = AuthError(response.message);
    }
  }

  // ── Send / Resend OTP ─────────────────────────────────────────────────────
  Future<void> sendOtp({required String phoneNumber}) async {
    state = const AuthLoading();
    final response = await _service.sendOtp(phoneNumber: phoneNumber);
    if (response.success) {
      state = AuthSuccess(message: response.message, otp: response.otp);
    } else {
      state = AuthError(response.message);
    }
  }

  Future<void> resendOtp({required String phoneNumber}) async {
    state = const AuthLoading();
    final response = await _service.resendOtp(phoneNumber: phoneNumber);
    if (response.success) {
      state = AuthSuccess(message: response.message, otp: response.otp);
    } else {
      state = AuthError(response.message);
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<void> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    state = const AuthLoading();
    final response = await _service.verifyOtp(
      phoneNumber: phoneNumber,
      otp: otp,
    );
    if (response.success) {
      state = AuthSuccess(message: response.message);
    } else {
      state = AuthError(response.message);
    }
  }

  // ── Forgot / Change Password ───────────────────────────────────────────────
  Future<void> forgotPassword({required String email}) async {
    state = const AuthLoading();
    final response = await _service.forgotPassword(email: email);
    if (response.success) {
      state = AuthSuccess(message: response.message);
    } else {
      state = AuthError(response.message);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = const AuthLoading();
    final response = await _service.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    if (response.success) {
      state = AuthSuccess(message: response.message);
    } else {
      state = AuthError(response.message);
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<void> updateProfile({
    required String fullName,
    required String email,
  }) async {
    state = const AuthLoading();
    final response = await _service.updateProfile(
      fullName: fullName,
      email: email,
    );
    if (response.success && response.data != null) {
      // Update local state if token is present
      final currentToken = await ApiClient.getToken();
      if (currentToken != null) {
        state = AuthAuthenticated(user: response.data!, token: currentToken);
      } else {
        state = AuthSuccess(message: response.message);
      }
    } else if (response.success) {
      state = AuthSuccess(message: response.message);
    } else {
      state = AuthError(response.message);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _service.logout();
    state = const AuthInitial();
  }

  // ── Reset to initial (after consuming error/success state) ───────────────
  void reset() => state = const AuthInitial();
}

// ── Global provider ────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// ── Convenience selector providers ────────────────────────────────────────
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider);
  return state is AuthAuthenticated ? state.user : null;
});

final authTokenProvider = Provider<String?>((ref) {
  final state = ref.watch(authProvider);
  return state is AuthAuthenticated ? state.token : null;
});
