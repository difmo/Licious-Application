import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';

class AuthService {
  static const String baseUrl = 'https://shrimpbite-backend.vercel.app/api/app';

  Future<AuthResponseModel> register({
    required String fullName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'username': username,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponseModel.fromJson(decodedData);
      } else {
        // Handle error responses from the server
        return AuthResponseModel(
          success: false,
          message: decodedData['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      // Handle network or parsing errors
      return AuthResponseModel(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponseModel.fromJson(decodedData);
      } else {
        return AuthResponseModel(
          success: false,
          message: decodedData['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return AuthResponseModel(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<AuthResponseModel> forgotPassword({required String email}) async {
    final url = Uri.parse('$baseUrl/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponseModel.fromJson(decodedData);
      } else {
        return AuthResponseModel(
          success: false,
          message: decodedData['message'] ?? 'Request failed',
        );
      }
    } catch (e) {
      return AuthResponseModel(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
