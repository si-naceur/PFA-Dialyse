import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/profile_entity.dart';
import '../models/profile_model.dart';

class ProfileRemoteDatasource {
  final ApiClient _apiClient;

  ProfileRemoteDatasource(this._apiClient);

  Future<ProfileEntity> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    final data = response.data;
    if (data is Map<String, dynamic> &&
        data['success'] == true &&
        data['data'] is Map<String, dynamic>) {
      return ProfileModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw ApiException('Format de réponse invalide pour le profil');
  }

  Future<ProfileEntity> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.put(ApiEndpoints.profile, data: data);
    final body = response.data;
    if (body is Map<String, dynamic> &&
        body['success'] == true &&
        body['data'] is Map<String, dynamic>) {
      return ProfileModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw ApiException('Format de réponse invalide pour la mise à jour');
  }
}
