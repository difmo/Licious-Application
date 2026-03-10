import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';

// Interface so the interceptor can trigger a global logout
abstract class AuthLogoutCallback {
  void onForceLogout(String reason);
}

class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final SecureStorageService _storage;
  final AuthLogoutCallback? _logoutCallback;
  
  // Static stream for force logouts to be listened by AuthStore or UI
  static final _logoutController = StreamController<String>.broadcast();
  static Stream<String> get onForceLogoutStream => _logoutController.stream;
  
  // Track refresh progress to avoid parallel refresh attempts
  static bool _isRefreshing = false;
  
  // Custom Dio for refreshing to avoid interceptor recursion
  late final Dio _refreshDio;

  AuthInterceptor(this._dio, this._storage, {AuthLogoutCallback? logoutCallback}) 
      : _logoutCallback = logoutCallback {
    _refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
    _refreshDio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final bool requiresAuth = options.extra['requiresAuth'] ?? false;
    
    if (!requiresAuth) {
      return handler.next(options);
    }

    final String? token = await _storage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final bool requiresAuth = err.requestOptions.extra['requiresAuth'] ?? false;
    final bool is401 = err.response?.statusCode == 401;

    if (is401 && requiresAuth) {
      if (err.requestOptions.path.contains('/auth/refresh')) {
         return handler.next(err);
      }

      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _onRefreshFailed('No refresh token available');
        return handler.next(err);
      }

      try {
        String? newAccessToken;

        if (!_isRefreshing) {
          _isRefreshing = true;
          try {
            debugPrint('AuthInterceptor: Refreshing access token...');
            final response = await _refreshDio.post('/app/auth/refresh', data: {
              'refreshToken': refreshToken,
            });

            if (response.statusCode == 200) {
              newAccessToken = response.data['accessToken'] ?? response.data['token'];
              final newRefreshToken = response.data['refreshToken'] ?? refreshToken;

              await _storage.saveTokens(
                access: newAccessToken!,
                refresh: newRefreshToken,
              );
              debugPrint('AuthInterceptor: Refresh successful.');
            } else {
               throw Exception('Refresh failed status: ${response.statusCode}');
            }
          } finally {
            _isRefreshing = false;
          }
        } else {
          debugPrint('AuthInterceptor: Waiting for existing refresh...');
          for (int i = 0; i < 10; i++) {
             await Future.delayed(const Duration(milliseconds: 500));
             if (!_isRefreshing) break;
          }
          newAccessToken = await _storage.getAccessToken();
        }

        if (newAccessToken != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          
          final retryResponse = await _dio.fetch(opts);
          return handler.resolve(retryResponse);
        } else {
          _onRefreshFailed('Token refresh failed');
          return handler.next(err);
        }
      } catch (e) {
        debugPrint('AuthInterceptor: Refresh FAILED - $e');
        _onRefreshFailed('Exception during token refresh: $e');
        return handler.next(err);
      }
    }
    return handler.next(err);
  }

  void _onRefreshFailed(String reason) {
    debugPrint('AuthInterceptor: FORCE LOGOUT TRIGGERED - $reason');
    _storage.clearAll();
    _logoutController.add(reason);
    _logoutCallback?.onForceLogout(reason);
  }
}



