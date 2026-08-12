import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';
import 'http_client_adapter_stub.dart'
    if (dart.library.html) 'http_client_adapter_web.dart'
    if (dart.library.js_interop) 'http_client_adapter_web.dart'
    as http_adapter;

class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storageService;

  ApiClient(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        extra: {if (kIsWeb) 'withCredentials': true},
      ),
    );

    http_adapter.configureHttpClientAdapter(_dio);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (kIsWeb) {
            options.extra['withCredentials'] = true;
          }

          final cookie = await _storageService.getSessionCookie();
          if (cookie != null && cookie.isNotEmpty) {
            final sessionMatch = RegExp(
              r'sessionid=([^;]+)',
            ).firstMatch(cookie);
            if (sessionMatch != null && sessionMatch.groupCount >= 1) {
              // Allowed on Flutter Web (unlike the Cookie header). Django
              // api_login_required loads the same session from this header.
              options.headers['X-Session-Id'] = sessionMatch.group(1);
            }

            if (!kIsWeb) {
              options.headers['Cookie'] = cookie;
              final csrfMatch = RegExp(r'csrftoken=([^;]+)').firstMatch(cookie);
              if (csrfMatch != null && csrfMatch.groupCount >= 1) {
                options.headers['X-CSRFToken'] = csrfMatch.group(1);
              }
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          if (!kIsWeb) {
            final cookies = response.headers['set-cookie'];
            if (cookies != null && cookies.isNotEmpty) {
              final cookieHeader = _extractCookieHeader(cookies);
              if (cookieHeader.isNotEmpty) {
                await _storageService.saveUserSession(
                  userId: await _storageService.getUserId() ?? 0,
                  username: await _storageService.getUsername() ?? '',
                  email: null,
                  role: await _storageService.getUserRole() ?? '',
                  cookie: cookieHeader,
                );
              }
            }
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final body = e.response?.data;
          var message = e.message ?? 'An unknown error occurred';
          if (body is Map<String, dynamic>) {
            message = body['message'] ?? body['error'] ?? message;
          }
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: ApiException(message, statusCode: e.response?.statusCode),
              response: e.response,
              type: e.type,
            ),
          );
        },
      ),
    );
  }

  static String _extractCookieHeader(List<String> setCookieHeaders) {
    final parts = <String>[];
    for (final header in setCookieHeaders) {
      final first = header.split(';').first.trim();
      if (first.contains('=')) {
        parts.add(first);
      }
    }
    return parts.join('; ');
  }

  Dio get client => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ApiException(e.message ?? 'Network error');
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ApiException(e.message ?? 'Network error');
    }
  }
}
