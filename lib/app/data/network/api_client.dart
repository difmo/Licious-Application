import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thrown when the server returns a non-2xx status or an error occurs.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  // ── Base URLs ──────────────────────────────────────────────────────────────
  // static const String baseUrl = 'https://shrimpbite-backend.vercel.app/api/app';
  // static const String riderBaseUrl = 'https://shrimpbite-backend.vercel.app/api/rider';
  // static const String otpBaseUrl =
  //     'https://shrimpbite-backend.vercel.app/api/otp';

  static const String baseUrl = 'https://shrimpbite-backend.vercel.app/api/app';
  static const String riderBaseUrl =
      'https://shrimpbite-backend.vercel.app/api/rider';
  static const String otpBaseUrl =
      'https://shrimpbite-backend.vercel.app/api/otp';
  static const String walletBaseUrl =
      'https://shrimpbite-backend.vercel.app/api/wallet';
  static const String paymentBaseUrl =
      'https://shrimpbite-backend.vercel.app/api/payment';
  static const String subscriptionBaseUrl =
      'https://shrimpbite-backend.vercel.app/api/subscription';
  static const String reviewBaseUrl =
      'https://shrimpbite-backend.vercel.app/api/reviews';

  late Dio _dio;

  // ── Token key ──────────────────────────────────────────────────────────────
  static const String _tokenKey = 'auth_token';

  ApiClient() {
    BaseOptions options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    );
    _dio = Dio(options);

    // ── Request / Response Logger ─────────────────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('');
        debugPrint('┌─── API REQUEST ────────────────────────────');
        debugPrint('│ ${options.method} ${options.uri}');
        if (options.data != null) debugPrint('│ Body: ${options.data}');
        debugPrint('└────────────────────────────────────────────');

        if (options.extra['requiresAuth'] == true) {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('');
        debugPrint('┌─── API RESPONSE ───────────────────────────');
        debugPrint('│ Status : ${response.statusCode}');
        debugPrint('│ URL    : ${response.requestOptions.uri}');
        debugPrint('│ Body   : ${response.data}');
        debugPrint('└────────────────────────────────────────────');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        debugPrint('');
        debugPrint('┌─── API ERROR ──────────────────────────────');
        debugPrint('│ Status : ${e.response?.statusCode}');
        debugPrint('│ URL    : ${e.requestOptions.uri}');
        debugPrint('│ Body   : ${e.response?.data}');
        debugPrint('└────────────────────────────────────────────');
        return handler.next(e);
      },
    ));
  }

  // ── Token helpers ──────────────────────────────────────────────────────────

  /// Persist a JWT token locally.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Retrieve the stored JWT token (null if not logged in).
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Remove the stored JWT token on logout.
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Error handler ──────────────────────────────────────────────────────────
  ApiException _handleError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return const ApiException(message: 'Connection timeout');
      } else if (error.type == DioExceptionType.badResponse) {
        final data = error.response?.data;
        String message =
            'Request failed with status ${error.response?.statusCode}';
        if (data is Map<String, dynamic> && data['message'] != null) {
          message = data['message'].toString();
        }
        return ApiException(
          statusCode: error.response?.statusCode,
          message: message,
        );
      } else if (error.error != null) {
        return ApiException(message: 'Unexpected error: ${error.error}');
      }
    }
    return ApiException(message: 'Unexpected error: ${error.toString()}');
  }

  // ── GET ────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> post(
    String url, {
    dynamic data,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── PUT ────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> put(
    String url, {
    dynamic data,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.put(
        url,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── PATCH ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> patch(
    String url, {
    dynamic data,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.patch(
        url,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.delete(
        url,
        queryParameters: queryParameters,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } catch (e) {
      throw _handleError(e);
    }
  }
}
