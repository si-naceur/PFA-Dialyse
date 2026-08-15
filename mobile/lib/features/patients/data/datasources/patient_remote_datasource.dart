import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/patient_detail_model.dart';
import '../models/patient_model.dart';

class PatientRemoteDatasource {
  final ApiClient _apiClient;

  PatientRemoteDatasource(this._apiClient);

  Future<({List<PatientModel> items, int total})> getPatients({
    String search = '',
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.patients,
      queryParameters: search.trim().isEmpty
          ? null
          : {'search': search.trim()},
    );

    final data = response.data;

    if (data is Map<String, dynamic> && data['success'] == true) {
      final rawList = data['data'];

      if (rawList is List) {
        final items = rawList
            .whereType<Map<String, dynamic>>()
            .map(PatientModel.fromJson)
            .toList();

        final total =
            (data['count'] as num?)?.toInt() ?? items.length;

        return (
          items: items,
          total: total,
        );
      }
    }

    throw ApiException(
      'Format de réponse invalide pour la liste des patients',
    );
  }

  Future<PatientDetailModel> createPatient(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiEndpoints.patients,
      data: data,
    );
    final body = response.data;
    if (body is Map<String, dynamic> &&
        body['success'] == true &&
        body['data'] is Map<String, dynamic>) {
      return PatientDetailModel.fromJson(
        body['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Format de réponse invalide pour la création');
  }

  Future<PatientDetailModel> getPatient(String patientId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.patientDetail}$patientId/',
    );

    final data = response.data;

    if (data is Map<String, dynamic> &&
        data['success'] == true &&
        data['data'] is Map<String, dynamic>) {
      return PatientDetailModel.fromJson(
        data['data'] as Map<String, dynamic>,
      );
    }

    throw ApiException(
      'Format de réponse invalide pour le patient',
    );
  }

  Future<PatientDetailModel> updatePatient(
    String patientId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.patientDetail}$patientId/',
      data: data,
    );

    final body = response.data;

    if (body is Map<String, dynamic> &&
        body['success'] == true &&
        body['data'] is Map<String, dynamic>) {
      return PatientDetailModel.fromJson(
        body['data'] as Map<String, dynamic>,
      );
    }

    throw ApiException(
      'Format de réponse invalide pour la modification',
    );
  }

  Future<void> deletePatient(String patientId) async {
    await _apiClient.delete(
      '${ApiEndpoints.patientDetail}$patientId/',
    );
  }
}
