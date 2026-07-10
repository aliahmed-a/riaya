import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riaya/core/utils/storage_service.dart';
import 'package:riaya/features/auth/data/models/auth_response_model.dart';
import 'package:riaya/features/auth/presentation/providers/auth_provider.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref);
});

class DioClient {
  final Ref _ref;
  final Dio _dio;

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: "http://10.0.2.2:5173/api/v1/",
  );

  DioClient(this._ref)
      : _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  ) {
    _initializeInterceptors();
  }

  Dio get dio => _dio;

  void _initializeInterceptors() {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenStorage.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // 🚨 CRITICAL: The Session Guard
          // If the backend says the JWT is expired (401), execute automated renewal
          if (e.response?.statusCode == 401) {
            final refreshToken = TokenStorage.refreshToken;
            final userId = TokenStorage.userId;

            // 🟢 FIX: refresh now requires userId, not the old access token
            if (refreshToken != null && userId != null) {
              try {
                // Spin up an isolated secondary Dio instance to bypass these interceptors
                final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));

                // 🟢 FIX: backend's RefreshTokenRequestDto requires
                // { userId, refreshToken } — sending "token" here caused every
                // refresh attempt to 400, silently logging users out.
                final response = await refreshDio.post('auth/refresh', data: {
                  'userId': userId,
                  'refreshToken': refreshToken,
                });

                if (response.statusCode == 200 && response.data != null) {
                  // Unpack the ApiResponse envelope to get the raw model data
                  final success = response.data['success'] as bool? ?? false;

                  if (success) {
                    final newAuthData = response.data['data'] as Map<String, dynamic>;
                    final newAuthResponse = AuthResponse.fromJson(newAuthData);

                    // 1. Update in-memory interceptor bridges (now including userId)
                    TokenStorage.storeTokens(newAuthResponse.token, newAuthResponse.refreshToken, newAuthResponse.userId);

                    // 2. Persist safely to SharedPreferences disk storage immediately
                    final storage = _ref.read(storageServiceProvider);
                    await storage.saveUserSession(jsonEncode(newAuthResponse.toJson()));

                    // 3. Retry the ORIGINAL failed API request using the shiny new JWT
                    final opts = e.requestOptions;
                    opts.headers['Authorization'] = 'Bearer ${newAuthResponse.token}';
                    final retryResponse = await _dio.fetch(opts);

                    // Force a successful resolution! The user's screen never sees the error.
                    return handler.resolve(retryResponse);
                  }
                }
              } catch (refreshError) {
                // If the refresh token itself is dead/expired, boot them back to the login screen
                _ref.read(authProvider.notifier).logout();
                return handler.reject(e);
              }
            } else {
              _ref.read(authProvider.notifier).logout();
            }
          }

          // ----------------------------------------------------
          // Standard Global Error Processing (400, 404, 500, etc)
          // ----------------------------------------------------
          String errorMessage = 'An unexpected connection error occurred';

          if (e.response != null && e.response?.data is Map) {
            final data = e.response!.data as Map;
            errorMessage = data['message'] ?? data['detail'] ?? data['title'] ?? errorMessage;

            if (e.response?.statusCode == 409) {
              errorMessage = "Conflict 409: $errorMessage";
            }
          } else if (e.type == DioExceptionType.connectionTimeout) {
            errorMessage = 'Server connection timed out. Please check your network connection.';
          } else if (e.type == DioExceptionType.connectionError) {
            errorMessage = 'Cannot reach backend server. Ensure it is running locally.';
          }

          final customException = DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: errorMessage,
          );

          return handler.reject(customException);
        },
      ),
    );
  }
}