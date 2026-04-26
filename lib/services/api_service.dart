import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/api_config.dart';
import 'auth_service.dart';

/// Centralized HTTP client with automatic JWT injection.
///
/// Every authenticated request passes through the interceptor that
/// reads the stored token from [AuthService] and attaches it as a
/// Bearer header. If a 401 is received, the token is cleared.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  late final Dio _dio;
  bool _initialized = false;

  /// Must be called once at app startup.
  void init() {
    if (_initialized) return;
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthService.instance.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token is invalid/expired — clear it
          await AuthService.instance.clearSession();
        }
        return handler.next(error);
      },
    ));

    _initialized = true;
    debugPrint('[ApiService] Initialized → ${ApiConfig.baseUrl}');
  }

  Dio get dio {
    if (!_initialized) init();
    return _dio;
  }

  // ── Convenience Methods ──

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }
}
