import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/data/models/auth_models.dart';
import '../../app/data/services/auth_service.dart';
import '../storage/secure_storage_service.dart';
import '../api/auth_interceptor.dart';
import '../../app/data/network/api_client.dart';

// Unified Auth Provider for the app
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(client: ref.watch(apiClientProvider));
});

final secureStorageProvider = Provider((ref) => SecureStorageService());

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final String? successMessage;
  final String? otp;

  AuthState(
      {required this.status,
      this.user,
      this.error,
      this.successMessage,
      this.otp});

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserModel user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated({String? error}) =>
      AuthState(status: AuthStatus.unauthenticated, error: error);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    String? successMessage,
    String? otp,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      otp: otp ?? this.otp,
    );
  }
}

class AuthStore extends Notifier<AuthState> {
  late final SecureStorageService _storage;
  StreamSubscription<String>? _logoutSubscription;

  @override
  AuthState build() {
    _storage = ref.watch(secureStorageProvider);

    // Listen for force logout events from the interceptor
    _logoutSubscription?.cancel();
    _logoutSubscription = AuthInterceptor.onForceLogoutStream.listen((reason) {
      setUnauthenticated(error: reason);
    });

    ref.onDispose(() {
      _logoutSubscription?.cancel();
    });

    return AuthState.initial();
  }

  /// App Launch: Check if tokens exist and validate/refresh access token.
  Future<void> init() async {
    state = AuthState.loading();
    try {
      final String? token = await _storage.getAccessToken();
      final String? refreshToken = await _storage.getRefreshToken();

      if (token != null && token.isNotEmpty) {
        // Validate by fetching profile
        final response = await ref.read(authServiceProvider).getProfile();
        if (response.success && response.data != null) {
          state = AuthState.authenticated(response.data!);
        } else if (refreshToken != null && refreshToken.isNotEmpty) {
          // Profile failed but we have refresh token - attempt explicit refresh if interceptor hasn't yet
          // Normally interceptor handles 401, but for initial load:
          state = AuthState.unauthenticated(error: "Session expired");
        } else {
          await logout();
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> login({required String phone, required String password}) async {
    state = AuthState.loading();
    try {
      final response = await ref.read(authServiceProvider).login(
            phoneNumber: phone,
            password: password,
          );

      if (response.success && response.data != null && response.token != null) {
        // Save tokens securely
        await _storage.saveTokens(
          access: response.token!,
          refresh: response.refreshToken ?? '',
        );
        state = AuthState.authenticated(response.data!);
      } else {
        state = AuthState.unauthenticated(error: response.message);
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> sendOtp({required String phoneNumber}) async {
    state = AuthState.loading();
    try {
      final response =
          await ref.read(authServiceProvider).sendOtp(phoneNumber: phoneNumber);
      if (!response.success) {
        state = AuthState.unauthenticated(error: response.message);
      } else {
        state = state.copyWith(
          status: AuthStatus.initial,
          successMessage: response.message,
          otp: response.otp,
        );
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    state = AuthState.loading();
    try {
      final response = await ref.read(authServiceProvider).register(
            fullName: fullName,
            email: email,
            phoneNumber: phoneNumber,
            password: password,
            confirmPassword: confirmPassword,
          );
      if (response.success) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          successMessage: response.message,
        );
      } else {
        state = AuthState.unauthenticated(error: response.message);
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> verifyOtp(
      {required String phoneNumber, required String otp}) async {
    state = AuthState.loading();
    try {
      final response = await ref.read(authServiceProvider).verifyOtp(
            phoneNumber: phoneNumber,
            otp: otp,
          );
      if (!response.success) {
        state = AuthState.unauthenticated(error: response.message);
      } else {
        if (response.token != null &&
            response.data != null &&
            response.token!.isNotEmpty) {
          // Instant Auto-Login route
          await _storage.saveTokens(
            access: response.token!,
            refresh: response.refreshToken ?? '',
          );
          state = AuthState.authenticated(response.data!);
        } else {
          // Standard success without auto-login
          state = state.copyWith(
            status: AuthStatus.initial,
            successMessage: response.message,
          );
        }
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> forgotPassword({required String email}) async {
    state = AuthState.loading();
    try {
      final response =
          await ref.read(authServiceProvider).forgotPassword(email: email);
      if (!response.success) {
        state = AuthState.unauthenticated(error: response.message);
      } else {
        state = AuthState.initial();
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    try {
      await ref.read(authServiceProvider).logout();
    } catch (_) {}
    await _storage.clearAll();
    state = AuthState.unauthenticated();
  }

  void setUnauthenticated({String? error}) {
    _storage.clearAll();
    state = AuthState.unauthenticated(error: error);
  }
}

final authStoreProvider = NotifierProvider<AuthStore, AuthState>(() {
  return AuthStore();
});

// Provide easy access to authenticated status
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStoreProvider).status == AuthStatus.authenticated;
});
