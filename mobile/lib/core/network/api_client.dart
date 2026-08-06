import 'package:dio/dio.dart';
import '../config/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

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
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final cookie = await _storageService.getSessionCookie();
          if (cookie != null && cookie.isNotEmpty) {
            options.headers['Cookie'] = cookie;

            // Extract csrftoken value if present for Django CSRF protection
            final csrfMatch = RegExp(r'csrftoken=([^;]+)').firstMatch(cookie);
            if (csrfMatch != null && csrfMatch.groupCount >= 1) {
              options.headers['X-CSRFToken'] = csrfMatch.group(1);
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // Store set-cookie header if present from Django response
          final cookies = response.headers['set-cookie'];
          if (cookies != null && cookies.isNotEmpty) {
            final cookieHeader = cookies.join('; ');
            await _storageService.saveUserSession(
              userId: await _storageService.getUserId() ?? 0,
              username: await _storageService.getUsername() ?? '',
              email: null,
              role: await _storageService.getUserRole() ?? '',
              cookie: cookieHeader,
            );
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final message =
              e.response?.data is Map && e.response?.data['message'] != null
              ? e.response?.data['message']
              : e.message ?? 'An unknown error occurred';
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
