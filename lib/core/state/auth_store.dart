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
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      otp: otp ?? this.otp,
      verificationId: verificationId ?? this.verificationId,
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
      setUnauthenticated(error: reason);
    });

    ref.onDispose(() {
      _logoutSubscription?.cancel();
    });

    return AuthState.initial();
  }

  Future<void> init() async {
    if (state.status != AuthStatus.loading) {
      state = AuthState.loading();
    }

    try {
      final String? token = await _storage.getAccessToken();
      final String? cachedUserJson = await _storage.getUser();

      if (token != null && token.isNotEmpty) {
         debugPrint('AuthStore: Token detected. Attempting profile fetch...');
        
        final response = await ref.read(authServiceProvider).getProfile();

        if (response.success && response.data != null) {
          debugPrint('AuthStore: Session verified online.');
          // Update cache
          await _storage.saveUser(jsonEncode(response.data!.toJson()));
          state = AuthState.authenticated(response.data!);
        } else {
          debugPrint('AuthStore: Online verification failed: ${response.message}');
          
          if (response.message.contains('401') || response.message.contains('Unauthorized')) {
            debugPrint('AuthStore: Credentials invalid. Clearing session.');
            await logout();
          } else if (cachedUserJson != null) {
            // OPTIMISTIC RESTORE: We have a token that isn't definitely 401, 
            // and we have a cached user. Let's log them in.
            debugPrint('AuthStore: Possible network error. Restoring from cache...');
            final user = UserModel.fromJson(jsonDecode(cachedUserJson));
            state = AuthState.authenticated(user);
          } else {
            state = AuthState.unauthenticated(error: response.message);
          }
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      debugPrint('AuthStore: Fatal recovery error $e');
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

  /// Calls the detection API. Returns the action ("password" or "otp").
  /// Does NOT change auth state — it's a pure lookup.
  Future<CheckUserResponseModel?> checkUser({required String phoneNumber}) async {
    try {
      return await ref.read(authServiceProvider).checkUser(phoneNumber: phoneNumber);
    } catch (e) {
      debugPrint('AuthStore.checkUser error: $e');
      return null;
    }
  }

  Future<void> login({required String phone, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null, successMessage: null);
    try {
      final fcmToken = await FCMService().getToken();
      final response = await ref.read(authServiceProvider).login(
            phoneNumber: phone,
            password: password,
            fcmToken: fcmToken,
          );

      if (response.success && response.data != null && response.token != null) {
        await _persistAuth(
          response.data!,
          response.token!,
          response.refreshToken ?? '',
        );
        unawaited(FCMService.sendTokenToBackend());
      } else {
        state = AuthState.unauthenticated(error: response.message);
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> sendOtp({required String phoneNumber}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      String formattedPhone = phoneNumber.trim();
      if (formattedPhone.length == 10) {
        formattedPhone = '+91$formattedPhone';
      } else if (formattedPhone.length == 12 &&
          formattedPhone.startsWith('91')) {
        formattedPhone = '+$formattedPhone';
      }

      debugPrint('AuthStore: Requesting OTP for $formattedPhone');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Automatic SMS code retrieval or instant verification
          debugPrint('AuthStore: Phone verification completed automatically.');
          await _signInWithFirebaseCredential(formattedPhone, credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
              'AuthStore: Phone verification failed: ${e.code} - ${e.message}');
          state = AuthState.unauthenticated(
              error: e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint(
              'AuthStore: OTP code sent. Verification ID: $verificationId');
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
        debugPrint('AuthStore: OTP verification result - SUCCESS');
        
        final user = response.data ?? UserModel.placeholder(phoneNumber);
        // Map token with a fallback (it might be needed for subsequent requests)
        final access = response.token ?? ''; 
        final refresh = response.refreshToken ?? '';

        await _persistAuth(user, access, refresh);
        unawaited(syncFcmToken());
      } else {
        debugPrint('AuthStore: verification result - FAILED: ${response.message}');
        state = AuthState.unauthenticated(error: response.message);
      }
    } catch (e) {
      debugPrint('AuthStore: Error finalizing Firebase sign-in: $e');
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
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final fcmToken = await FCMService().getToken();
      final response = await ref.read(authServiceProvider).register(
            fullName: fullName,
            email: email,
            phoneNumber: phoneNumber,
            password: password,
            confirmPassword: confirmPassword,
            fcmToken: fcmToken,
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

  Future<void> googleAuth(
      {required String idToken,
      String? accessToken,
      String? phoneNumber}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      String finalToken = idToken;

      // ── Firebase Token Exchange ──────────────────────────────────────────
      // Backends usually require a *Firebase* ID Token, not a plain *Google* ID Token.
      if (accessToken != null) {
        debugPrint('AuthStore: Exchanging Google token for Firebase token...');
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final firebaseIdToken = await userCredential.user?.getIdToken();

        if (firebaseIdToken != null) {
          finalToken = firebaseIdToken;
          debugPrint('AuthStore: Firebase token exchange successful.');
        }
      }

      final fcmToken = await FCMService().getToken();
      final response = await ref.read(authServiceProvider).googleAuth(
            idToken: finalToken,
            phoneNumber: phoneNumber,
            fcmToken: fcmToken,
          );

      if (response.success && response.data != null && response.token != null) {
        await _persistAuth(
          response.data!,
          response.token!,
          response.refreshToken ?? '',
        );
        unawaited(FCMService.sendTokenToBackend());
      } else {
        state = AuthState.unauthenticated(error: response.message);
      }
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> verifyOtp(
      {required String phoneNumber, required String otp}) async {
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

  Future<void> forgotPassword({required String email}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
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
