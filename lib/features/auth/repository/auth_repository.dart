import 'package:dio/dio.dart';
import '../models/auth_state.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get('/auth/profile');
    return UserModel.fromJson(response.data);
  }

  Future<void> logout() async {
    // Optional: Call logout endpoint if exists
    await _dio.post('/auth/logout');
  }
}
