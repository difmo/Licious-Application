import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../network/api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(client: ref.watch(apiClientProvider));
});

/// Service layer for authentication.
class AuthService {
  final ApiClient _client;

  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  // ── Update Name (Requested Endpoint) ──────────────────────────────────────
  Future<AuthResponseModel> updateName({required String fullName}) async {
    try {
      final json = await _client.put(
        '${ApiClient.baseUrl}/update-name',
        data: {'fullName': fullName},
        requiresAuth: true,
      );
      return AuthResponseModel.fromJson(json);
    } on ApiException catch (e) {
      return AuthResponseModel(success: false, message: e.message);
    } catch (e) {
      return AuthResponseModel(success: false, message: e.toString());
    }
  }

  // ── Check User (Detect role and readiness) ────────────────────────────
  Future<CheckUserResponseModel> checkUser({
    required String phoneNumber,
  }) async {
    try {
      final data = await _client.post(
        '${ApiClient.baseUrl}/check-user',
        data: {'phoneNumber': phoneNumber},
      );
      return CheckUserResponseModel.fromJson(data);
    } on ApiException catch (e) {
      return CheckUserResponseModel(
          success: false, message: e.message, action: null);
    } catch (e) {
      return CheckUserResponseModel(
          success: false, message: e.toString(), action: null);
    }
  }

  Future<AuthResponseModel> sendOtp({
    required String phoneNumber,
    String? fcmToken,
  }) async {
    try {
      final data = await _client.post(
        '${ApiClient.otpBaseUrl}/send',
        data: {
          'phoneNumber': phoneNumber,
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
      );
      return AuthResponseModel.fromJson(data);
    } on ApiException catch (e) {
      return AuthResponseModel(success: false, message: e.message);
    } catch (e) {
      return AuthResponseModel(
          success: false, message: 'Unexpected error: ${e.toString()}');
    }
  }

  Future<AuthResponseModel> resendOtp({required String phoneNumber}) async {
    return sendOtp(phoneNumber: phoneNumber);
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<AuthResponseModel> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final data = await _client.post(
        '${ApiClient.otpBaseUrl}/verify',
        data: {'phoneNumber': phoneNumber, 'otp': otp},
      );
      final response = AuthResponseModel.fromJson(data);
      if (response.success &&
          response.token != null &&
          response.token!.isNotEmpty) {
        await ApiClient.saveToken(response.token!);
      }
      return response;
    } on ApiException catch (e) {
      return AuthResponseModel(success: false, message: e.message);
    } catch (e) {
      return AuthResponseModel(
          success: false, message: 'Unexpected error: ${e.toString()}');
    }
  }

  // ── Verify Firebase OTP (Preferred) ───────────────────────────────────────────
  Future<AuthResponseModel> verifyFirebaseOtp({
    required String phoneNumber,
    required String idToken,
    String? fcmToken,
  }) async {
    try {
      final data = await _client.post(
        '${ApiClient.otpBaseUrl}/verify-firebase',
        data: {
          'phoneNumber': phoneNumber,
          'idToken': idToken,
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
      );
      final response = AuthResponseModel.fromJson(data);
      if (response.success &&
          response.token != null &&
          response.token!.isNotEmpty) {
        await ApiClient.saveToken(response.token!);
      }
      return response;
    } on ApiException catch (e) {
      return AuthResponseModel(success: false, message: e.message);
    } catch (e) {
      return AuthResponseModel(
          success: false, message: 'Unexpected error: ${e.toString()}');
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<AuthResponseModel> getProfile() async {
    try {
      final data = await _client.get(
        '${ApiClient.baseUrl}/profile',
        requiresAuth: true,
      );
      return AuthResponseModel.fromJson(data);
    } on ApiException catch (e) {
      return AuthResponseModel(success: false, message: e.message);
    } catch (e) {
      return AuthResponseModel(
          success: false, message: 'Unexpected error: ${e.toString()}');
    }
  }

  Future<AuthResponseModel> updateProfile({
    String? fullName,
    String? email,
  }) async {
    try {
      final data = await _client.put(
        '${ApiClient.baseUrl}/profile',
        data: {
          if (fullName != null) 'fullName': fullName,
          if (email != null) 'email': email,
        },
        requiresAuth: true,
      );
      return AuthResponseModel.fromJson(data);
    } on ApiException catch (e) {
      return AuthResponseModel(success: false, message: e.message);
    } catch (e) {
      return AuthResponseModel(
          success: false, message: 'Unexpected error: ${e.toString()}');
    }
  }

  // ── Update FCM Token ─────────────────────────────────────────────────────
  Future<AuthResponseModel> updateFcmToken({required String fcmToken}) async {
    try {
      final data = await _client.post(
        '${ApiClient.baseUrl}/update-fcm-token',
        data: {'fcmToken': fcmToken},
        requiresAuth: true,
      );
      return AuthResponseModel.fromJson(data);
    } on ApiException catch (e) {
      return AuthResponseModel(success: false, message: e.message);
    } catch (e) {
      return AuthResponseModel(success: false, message: e.toString());
    }
  }

  // ── Update Email ────────────────────────────────────────────────────────
  Future<AuthResponseModel> updateEmail({required String email}) async {
    try {
      final json = await _client.put(
        '${ApiClient.baseUrl}/auth/update-email',
        data: {'email': email},
        requiresAuth: true,
      );
      return AuthResponseModel.fromJson(json);
    } on ApiException catch (e) {
      return AuthResponseModel(success: false, message: e.message);
    } catch (e) {
      return AuthResponseModel(success: false, message: e.toString());
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await ApiClient.clearToken();
  }

  // ── Delete Account ─────────────────────────────────────────────────────────
  Future<AuthResponseModel> deleteAccount({
    required String name,
    required String email,
    required String reason,
  }) async {
    try {
      final json = await _client.post(
        '${ApiClient.baseUrl}/delete-account-request',
        data: {
          'name': name,
          'email': email,
          'region': reason,
        },
        requiresAuth: true,
      );
      return AuthResponseModel.fromJson(json);
    } on ApiException catch (e) {
      return AuthResponseModel(success: false, message: e.message);
    } catch (e) {
      return AuthResponseModel(success: false, message: e.toString());
    }
  }
}
