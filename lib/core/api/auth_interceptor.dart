import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final SecureStorageService _storage;
  
  // Stream to notify UI of forced logout
  static final _logoutController = StreamController<String>.broadcast();
  static Stream<String> get onForceLogoutStream => _logoutController.stream;
  
  static bool _isRefreshing = false;
  late final Dio _refreshDio;

  AuthInterceptor(this._dio, this._storage) {
    _refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
    // Log for refresh requests selectively or via logger
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

    // Only attempt refresh if it's a 401 on an authenticated request, AND it's not the refresh request itself
    if (is401 && requiresAuth && !err.requestOptions.path.contains('/auth/refresh')) {
      final refreshToken = await _storage.getRefreshToken();
      
      if (refreshToken == null || refreshToken.isEmpty) {
        _performLogout('No refresh token available');
        return handler.next(err);
      }

      try {
        String? newAccessToken;

        if (!_isRefreshing) {
          _isRefreshing = true;
          try {
            AppLogger.d('AuthInterceptor: Refreshing access token...');
            // In many backends, it's /app/auth/refresh or /auth/refresh
            final response = await _refreshDio.post('/app/auth/refresh', data: {
              'refreshToken': refreshToken,
            });

            if (response.statusCode == 200) {
              final data = response.data;
              newAccessToken = data['accessToken'] ?? data['access_token'];
              final newRefreshToken = data['refreshToken'] ?? data['refresh_token'] ?? refreshToken;

              await _storage.saveTokens(
                access: newAccessToken!,
                refresh: newRefreshToken,
              );
              AppLogger.i('AuthInterceptor: Token refresh successful.');
            } else {
              throw Exception('Refresh failed with status: ${response.statusCode}');
            }
          } finally {
            _isRefreshing = false;
          }
        } else {
          // Wait for the on-going refresh
          AppLogger.d('AuthInterceptor: Waiting for existing refresh to complete...');
          while (_isRefreshing) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
          newAccessToken = await _storage.getAccessToken();
        }

        if (newAccessToken != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          
          // Retry the original request
          final retryResponse = await _dio.fetch(opts);
          return handler.resolve(retryResponse);
        } else {
          _performLogout('Token refresh failed');
          return handler.next(err);
        }
      } catch (e) {
        AppLogger.e('AuthInterceptor: Token refresh exception', e);
        _performLogout('Session expired or refresh failed');
        return handler.next(err);
      }
    }
    return handler.next(err);
  }

  static bool _isLoggingOut = false;

  void _performLogout(String reason) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    
    try {
      AppLogger.w('AuthInterceptor: Logout triggered - $reason');
      await _storage.clearAll();
      _logoutController.add(reason);
    } finally {
      // Reset after a delay to allow UI to transition
      Future.delayed(const Duration(seconds: 2), () => _isLoggingOut = false);
    }
  }
}



