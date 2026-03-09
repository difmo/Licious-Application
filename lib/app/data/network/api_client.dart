import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/api/auth_interceptor.dart';
import '../../../core/storage/secure_storage_service.dart';

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
  final dio = Dio(BaseOptions(
    baseUrl: dotenv.get('API_BASE_URL'),
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    contentType: Headers.jsonContentType,
  ));

  final storage = SecureStorageService();
  dio.interceptors.addAll([
    AuthInterceptor(dio, storage),
    LogInterceptor(requestBody: true, responseBody: true),
  ]);

  return ApiClient(dio);
});

class ApiClient {
  // ── Production Base URLs (Relative to API_BASE_URL) ────────────────────────
  static const String baseUrl = '/app';
  static const String riderBaseUrl = '/rider';
  static const String otpBaseUrl = '/otp';
  static const String walletBaseUrl = '/wallet';
  static const String paymentBaseUrl = '/payment';
  static const String subscriptionBaseUrl = '/subscription';
  static const String reviewBaseUrl = '/reviews';

  final Dio _dio;

  ApiClient([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: dotenv.get('API_BASE_URL'),
              connectTimeout: const Duration(seconds: 30),
            ));

  // ── HTTP Methods ───────────────────────────────────────────────────────────

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, bool requiresAuth = false}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data, bool requiresAuth = false}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data, bool requiresAuth = false}) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data, bool requiresAuth = false}) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String path, {dynamic data, bool requiresAuth = false}) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ?? e.message;
      return ApiException(statusCode: e.response?.statusCode, message: message.toString());
    }
    return ApiException(message: e.message ?? 'Network error');
  }

  // ── Helper static methods for token access ──────────────────────────────
  static Future<String?> getToken() async => await SecureStorageService().getAccessToken();
  static Future<void> saveToken(String token) async => await SecureStorageService().saveTokens(access: token, refresh: ''); // Adjust as needed
  static Future<void> clearToken() async => await SecureStorageService().clearAll();
}
