import 'package:dio/dio.dart';
import 'package:pfa_dialyse/core/constants/app_constants.dart';
import 'package:pfa_dialyse/features/auth/data/models/user_model.dart';

class AuthRepository {
  AuthRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<UserModel> login({required String username, required String password}) async {
    final response = await _dio.post(
      '${AppConstants.apiBaseUrl}${AppConstants.loginEndpoint}',
      data: {'username': username, 'password': password},
    );

    if (response.statusCode != 200) {
      throw Exception('Authentication failed');
    }

    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Authentication failed');
    }

    return UserModel.fromJson(body['user'] as Map<String, dynamic>);
  }
}
