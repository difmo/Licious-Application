import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../app/data/models/auth_models.dart';
import '../../app/data/services/auth_service.dart';
import '../storage/secure_storage_service.dart';
import '../api/auth_interceptor.dart';
import '../../app/data/network/api_client.dart';
import '../../app/data/services/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

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
  final String? verificationId;

  AuthState(
      {required this.status,
      this.user,
      this.error,
      this.successMessage,
      this.otp,
      this.verificationId});

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
    String? verificationId,
    bool clearVerificationId = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      otp: otp ?? this.otp,
      verificationId:
          clearVerificationId ? null : (verificationId ?? this.verificationId),
    );
  }
}

class AuthStore extends Notifier<AuthState> {
  late SecureStorageService _storage;
  StreamSubscription<String>? _logoutSubscription;

  @override
  AuthState build() {
    _storage = ref.watch(secureStorageProvider);

    // Listen for force logout events from the interceptor
    _logoutSubscription?.cancel();
    _logoutSubscription = AuthInterceptor.onForceLogoutStream.listen((reason) {
      // Don't kill the session if we are in the middle of verifying (phone verification id exists)
      if (state.verificationId != null || state.status == AuthStatus.loading) {
        AppLogger.d('AuthStore: Ignoring force logout during active auth flow.');
        return;
      }
      AppLogger.w('AuthStore: Force logout triggered. Reason: $reason');
      setUnauthenticated(error: reason);
    });

    ref.onDispose(() {
      _logoutSubscription?.cancel();
    });

    return AuthState.initial();
  }

  Future<void> init() async {
    // Avoid double loading
    if (state.status == AuthStatus.loading) return;
    
    state = AuthState.loading();

    try {
      final String? token = await _storage.getAccessToken();
      final String? cachedUserJson = await _storage.getUser();

      if (token != null && token.isNotEmpty) {
        // OPTIMISTIC RESTORE: Use cached user if available to show Home instantly
        if (cachedUserJson != null) {
          try {
            final user = UserModel.fromJson(jsonDecode(cachedUserJson));
            state = AuthState.authenticated(user);
            AppLogger.d('AuthStore: Optimistic restore from cache successful.');
          } catch (e) {
            AppLogger.e('AuthStore: Failed to parse cached user: $e');
          }
        }

        // BACKGROUND REFRESH: Verify session and update profile data
        AppLogger.d('AuthStore: Refreshing profile in background...');
        final response = await ref.read(authServiceProvider).getProfile();

        if (response.success && response.data != null) {
          AppLogger.d('AuthStore: Profile refreshed successfully.');
          await _storage.saveUser(jsonEncode(response.data!.toJson()));
          state = AuthState.authenticated(response.data!);
        } else {
          AppLogger.e('AuthStore: Background refresh failed: ${response.message}');
          
          // If explicitly unauthorized, clear the session
          if (response.message.contains('401') || response.message.contains('Unauthorized')) {
            AppLogger.w('AuthStore: Credentials invalid. Clearing session.');
            await logout();
          }
          // Note: If it's a network error, we stay in the optimistic 'authenticated' state
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e, stack) {
      AppLogger.e('AuthStore: Fatal recovery error', e, stack);
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> _persistAuth(UserModel user, String access, String refresh) async {
    await _storage.saveTokens(access: access, refresh: refresh);
    await _storage.saveUser(jsonEncode(user.toJson()));
    state = AuthState.authenticated(user);
  }

  Future<void> updateUser(UserModel user) async {
    await _storage.saveUser(jsonEncode(user.toJson()));
    state = state.copyWith(user: user);
  }

  /// Calls the detection API. Returns the action ("otp" only now).
  /// Does NOT change auth state — it's a pure lookup.
  Future<CheckUserResponseModel?> checkUser({required String phoneNumber}) async {
    try {
      return await ref.read(authServiceProvider).checkUser(phoneNumber: phoneNumber);
    } catch (e) {
      debugPrint('AuthStore.checkUser error: $e');
      return null;
    }
  }

  Future<void> sendOtp({required String phoneNumber, bool force = false}) async {
    // Only skip if we already have a verificationId (OTP sent)
    // or if we are actively in a loading state specifically triggered by this store's auth flow
    if (state.status == AuthStatus.loading) {
      AppLogger.d('AuthStore: Skipping sendOtp (already loading).');
      return;
    }

    if (!force && state.verificationId != null) {
      AppLogger.d('AuthStore: Skipping redundant OTP request (session already active).');
      return;
    }

    state = state.copyWith(
        status: AuthStatus.loading, error: null, clearVerificationId: true);
    try {
      // 1. Sanitize: Remove all spaces, dashes, parentheses
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      // 2. Intelligent Auto-Prefixing for India (default)
      if (formattedPhone.length == 10 && !formattedPhone.startsWith('+')) {
        formattedPhone = '+91$formattedPhone';
      } else if (formattedPhone.length == 12 &&
          formattedPhone.startsWith('91')) {
        formattedPhone = '+$formattedPhone';
      } else if (!formattedPhone.startsWith('+')) {
        // Fallback: If it still lacks +, assume +91 or warn? 
        // For now, if it's missing +, we add + as a last resort if it looks like E.164 without prefix
        if (formattedPhone.length > 5) {
           formattedPhone = '+$formattedPhone';
        }
      }

      AppLogger.d('AuthStore: Requesting OTP for "$formattedPhone" (Length: ${formattedPhone.length})');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Automatic SMS code retrieval or instant verification
          AppLogger.i('AuthStore: Phone verification completed automatically.');
          await _signInWithFirebaseCredential(formattedPhone, credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          AppLogger.e(
              'AuthStore: Phone verification failed: ${e.code} - ${e.message}');
          state = AuthState.unauthenticated(
              error: e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          AppLogger.i('AuthStore: Code sent to $formattedPhone. Verification ID: $verificationId');
          state = state.copyWith(
            status: AuthStatus.initial,
            successMessage: 'OTP sent to your phone via SMS',
            verificationId: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  /// Private helper to finalize login with a Firebase credential
  Future<void> _signInWithFirebaseCredential(
      String phoneNumber, PhoneAuthCredential credential) async {
    // Prevent concurrent verification attempts
    if (state.status == AuthStatus.loading || state.status == AuthStatus.authenticated) {
       AppLogger.d('AuthStore: Ignoring verification request (already loading or authenticated).');
       return;
    }

    try {
      state = state.copyWith(status: AuthStatus.loading, error: null);

      // 1. Sign in to Firebase to get the idToken
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        state = AuthState.unauthenticated(error: 'Failed to access Firebase');
        return;
      }

      // 2. Verify on backend and get Shrimpbite JWT
      final fcmToken = await FCMService().getToken();
      final response = await ref.read(authServiceProvider).verifyFirebaseOtp(
            phoneNumber: phoneNumber,
            idToken: firebaseIdToken,
            fcmToken: fcmToken,
          );

      if (response.success) {
        AppLogger.i('AuthStore: Authentication SUCCESS for $phoneNumber');
        
        final user = response.data ?? UserModel.placeholder(phoneNumber);
        final access = response.token ?? ''; 
        final refresh = response.refreshToken ?? '';

        await _persistAuth(user, access, refresh);
        unawaited(syncFcmToken());
      } else {
        AppLogger.w('AuthStore: verification result - FAILED: ${response.message}');
        if (state.status != AuthStatus.authenticated) {
            state = AuthState.unauthenticated(error: _handleAuthError(response.message));
        }
      }
    } catch (e, stack) {
      AppLogger.e('AuthStore: Error finalizing Firebase sign-in', e, stack);
      if (state.status != AuthStatus.authenticated) {
          state = AuthState.unauthenticated(error: _handleAuthError(e));
      }
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-verification-code':
          return 'The OTP you entered is invalid. Please check and try again.';
        case 'session-expired':
          return 'This OTP session has expired. Please request a new one.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        default:
          return e.message ?? 'Authentication failed. Please try again.';
      }
    }
    
    final msg = e.toString();
    if (msg.contains('invalid-verification-code') || msg.contains('invalid OTP')) {
      return 'The OTP you entered is incorrect.';
    }
    if (msg.contains('session-expired')) {
      return 'OTP has expired. Please resend code.';
    }
    
    // Clean up generic Firebase prefix if present
    return msg.replaceFirst(RegExp(r'\[.*?\] '), '');
  }

  Future<void> verifyOtp(
      {required String phoneNumber, required String otp}) async {
    if (state.status == AuthStatus.authenticated || state.status == AuthStatus.loading) {
      AppLogger.d('AuthStore: Skipping verifyOtp (status: ${state.status}).');
      return;
    }

    final verificationId = state.verificationId;
    if (verificationId == null) {
      state = AuthState.unauthenticated(
          error: 'Session expired. Please request OTP again.');
      return;
    }

    // 1. Create credential from SMS code
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    // 2. Delegate to helper
    await _signInWithFirebaseCredential(phoneNumber, credential);
  }

  Future<void> logout() async {
    state = AuthStatus.loading != state.status ? AuthState.loading() : state;
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

  Future<void> syncFcmToken() async {
    final user = state.user;
    if (user == null || user.id == 'placeholder') return;
    
    final fcmToken = await FCMService().getToken();
    if (fcmToken != null) {
      await ref.read(authServiceProvider).updateFcmToken(fcmToken: fcmToken);
    }
  }
}

final authStoreProvider = NotifierProvider<AuthStore, AuthState>(() {
  return AuthStore();
});

// Provide easy access to authenticated status
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStoreProvider).status == AuthStatus.authenticated;
});
