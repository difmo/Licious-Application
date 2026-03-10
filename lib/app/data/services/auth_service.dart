import '../models/auth_models.dart';
import '../network/api_client.dart';

/// Service layer for authentication.
///
/// Uses [ApiClient] for raw HTTP and returns typed [AuthResponseModel] objects.
/// All network errors are caught here and surfaced via [AuthResponseModel.success] == false.
class AuthService {
  final ApiClient _client;

  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  // ── Register ──────────────────────────────────────────────────────────────
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final data = await _client.post(
        '${ApiClient.baseUrl}/register',
        data: {
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'confirmPassword': confirmPassword,
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

  // ── Login (phone + password) ───────────────────────────────────────────────
  Future<AuthResponseModel> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final data = await _client.post(
        '${ApiClient.baseUrl}/login',
        data: {'phoneNumber': phoneNumber, 'password': password},
      );
      final response = AuthResponseModel.fromJson(data);
      // Persist token for future authenticated requests
      if (response.success && response.token != null) {
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

  // ── Send / Resend OTP ─────────────────────────────────────────────────────
  Future<AuthResponseModel> sendOtp({required String phoneNumber}) async {
    try {
      final data = await _client.post(
        '${ApiClient.otpBaseUrl}/send',
        data: {'phoneNumber': phoneNumber},
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
    // Usually the same as sendOtp, but explicitly named for clarity in UI
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
      if (response.success && response.token != null && response.token!.isNotEmpty) {
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

  // ── Forgot / Change Password ───────────────────────────────────────────────
  Future<AuthResponseModel> forgotPassword({
    required String email,
  }) async {
    try {
      final data = await _client.post(
        '${ApiClient.baseUrl}/forgot-password',
        data: {'email': email},
      );
      return AuthResponseModel.fromJson(data);
    } on ApiException catch (e) {
      return AuthResponseModel(success: false, message: e.message);
    } catch (e) {
      return AuthResponseModel(
          success: false, message: 'Unexpected error: ${e.toString()}');
    }
  }

  Future<AuthResponseModel> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final data = await _client.put(
        '${ApiClient.baseUrl}/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
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
    required String fullName,
    required String email,
  }) async {
    try {
      final data = await _client.put(
        '${ApiClient.baseUrl}/profile',
        data: {
          'fullName': fullName,
          'email': email,
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

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await ApiClient.clearToken();
  }
}
