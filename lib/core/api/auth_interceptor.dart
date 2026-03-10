import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Get requiresAuth extra - default to false if not provided
    final bool requiresAuth = options.extra['requiresAuth'] ?? false;
    
    debugPrint('AuthInterceptor: Checking request for ${options.path}');
    debugPrint('AuthInterceptor: requiresAuth = $requiresAuth');

    if (!requiresAuth) {
      return handler.next(options);
    }

    // 2. Get access token from secure storage
    final token = await _storage.getAccessToken();
    debugPrint('AuthInterceptor: Found token = ${token != null && token.isNotEmpty}');

    // 3. Attach token to header if it exists
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      debugPrint('AuthInterceptor: Successfully attached Bearer token');
    } else {
      debugPrint('AuthInterceptor: WARNING - Request requires auth but token is NULL or EMPTY');
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 4. Check if error is 401 (Unauthorized) and it's an authenticated request
    if (err.response?.statusCode == 401 && err.requestOptions.extra['requiresAuth'] == true) {
      final refreshToken = await _storage.getRefreshToken();

      // Only attempt refresh if refreshToken exists and is not empty
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // 5. Attempt to refresh token using a NEW Dio to avoid recursion via interceptor
          final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
          final response = await refreshDio.post('/app/auth/refresh', data: {
            'refreshToken': refreshToken,
          });

          if (response.statusCode == 200) {
            final newAccessToken = response.data['accessToken'] ?? response.data['token'];
            final newRefreshToken = response.data['refreshToken'] ?? refreshToken;

            // 6. Save new tokens
            await _storage.saveTokens(
              access: newAccessToken,
              refresh: newRefreshToken,
            );

            // 7. Retry the original request
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            
            final retryResponse = await _dio.fetch(opts);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          // Refresh failed - we stop retrying and let it propagate.
          // Optional: Clear tokens only if we are STUCK on invalid refresh token.
          // For now, let's keep it minimal and just pass on the error.
        }
      }
    }
    return handler.next(err);
  }
}
