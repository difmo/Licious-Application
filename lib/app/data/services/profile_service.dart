import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl = 'https://shrimpbite-backend.vercel.app/api/app';

  Future<Map<String, dynamic>> fetchProfile({required String token}) async {
    final url = Uri.parse('$baseUrl/profile');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decodedData['success'] == true) {
          return {'success': true, 'data': decodedData['data']};
        }
      }

      return {
        'success': false,
        'message': decodedData['message'] ?? 'Failed to fetch profile',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
