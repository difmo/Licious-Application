import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    return await _authService.register(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  Future<AuthResponseModel> login({
    required String phoneNumber,
    required String password,
  }) async {
    return await _authService.login(
      phoneNumber: phoneNumber,
      password: password,
    );
  }

  Future<AuthResponseModel> sendOtp({required String phoneNumber}) async {
    return await _authService.sendOtp(phoneNumber: phoneNumber);
  }

  Future<AuthResponseModel> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    return await _authService.verifyOtp(phoneNumber: phoneNumber, otp: otp);
  }

  Future<void> logout() async {
    // Clear local session / token as needed
  }
}
