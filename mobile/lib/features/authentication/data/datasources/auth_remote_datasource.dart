import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasource(this._apiClient);

  Future<UserModel> login(String username, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'username': username, 'password': password},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['success'] == true && data['user'] != null) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          data['message']?.toString() ?? 'Invalid username or password',
        );
      }
    }
    throw ApiException('Invalid server response format');
  }

  Future<void> logout() async {
    try {
      await _apiClient.get('/logout/');
    } catch (_) {
      // Best-effort logout trigger on backend
    }
  }
}
