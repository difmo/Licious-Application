import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../../core/api/auth_interceptor.dart';
import '../../../core/api/api_provider.dart';
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
    baseUrl: dotenv.get('API_BASE_URL').trim(),
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    contentType: Headers.jsonContentType,
  ));

  final storage = ref.watch(storageServiceProvider);
  dio.interceptors.addAll([
    AuthInterceptor(dio, storage),
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    ),
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

  ApiClient([Dio? dio]) : _dio = dio ?? _createDefaultDio();

  static Dio _createDefaultDio() {
    final dio = Dio(BaseOptions(
      baseUrl: dotenv.get('API_BASE_URL').trim(),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ));

    final storage = SecureStorageService();
    dio.interceptors.addAll([
      AuthInterceptor(dio, storage),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
      ),
    ]);
    return dio;
  }

  String _buildUrl(String path) {
    if (path.startsWith('http')) return path;
    var base = dotenv.get('API_BASE_URL').trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    var p = path;
    if (!p.startsWith('/')) p = '/$p';
    return base + p;
  }

  // ── HTTP Methods ───────────────────────────────────────────────────────────

  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters,
      bool requiresAuth = false}) async {
    try {
      final response = await _dio.get(
        _buildUrl(path),
        queryParameters: queryParameters,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path,
      {dynamic data, bool requiresAuth = false}) async {
    try {
      final response = await _dio.post(
        _buildUrl(path),
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String path,
      {dynamic data, bool requiresAuth = false}) async {
    try {
      final response = await _dio.put(
        _buildUrl(path),
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> patch(String path,
      {dynamic data, bool requiresAuth = false}) async {
    try {
      final response = await _dio.patch(
        _buildUrl(path),
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String path,
      {dynamic data, bool requiresAuth = false}) async {
    try {
      final response = await _dio.delete(
        _buildUrl(path),
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
      final data = e.response?.data;
      String message = e.message ?? 'Server error';
      if (data is Map) {
        message = data['message']?.toString() ?? message;
      } else if (data is String && data.isNotEmpty) {
        // If it's a string but doesn't look like HTML, use it
        if (!data.contains('<html')) {
          message = data;
        }
      }
      return ApiException(
          statusCode: e.response?.statusCode, message: message);
    }
    return ApiException(message: e.message ?? 'Network error');
  }

  // ── Helper static methods for token access ──────────────────────────────
  static Future<String?> getToken() async =>
      await SecureStorageService().getAccessToken();
  static Future<void> saveToken(String token) async {
    final storage = SecureStorageService();
    final refresh = await storage.getRefreshToken();
    await storage.saveTokens(access: token, refresh: refresh ?? '');
  }

  static Future<void> clearToken() async =>
      await SecureStorageService().clearAll();
}
