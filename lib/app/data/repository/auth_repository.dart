import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  Future<CheckUserResponseModel?> checkUser({required String phoneNumber}) async {
    return await _authService.checkUser(phoneNumber: phoneNumber);
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
