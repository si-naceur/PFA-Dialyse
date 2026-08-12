import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/machine_detail_model.dart';
import '../models/machine_model.dart';

class MachineRemoteDatasource {
  final ApiClient _apiClient;

  MachineRemoteDatasource(this._apiClient);

  /// GET /api/machines/?search=<query>&status=<status>&location=<location>
  Future<List<MachineModel>> getMachines({
    String search = '',
    String status = '',
    String location = '',
  }) async {
    final queryParams = <String, dynamic>{};
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }
    if (location.trim().isNotEmpty) {
      queryParams['location'] = location.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.machines,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      final rawList = data['data'];
      if (rawList is List) {
        return rawList
            .whereType<Map<String, dynamic>>()
            .map(MachineModel.fromJson)
            .toList();
      }
    }
    throw ApiException('Format de réponse invalide pour la liste des machines');
  }

  /// GET /api/machines/<id>/
  Future<MachineDetailModel> getMachine(int machineId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.machineDetail}$machineId/',
    );
    final data = response.data;
    if (data is Map<String, dynamic> &&
        data['success'] == true &&
        data['data'] is Map<String, dynamic>) {
      return MachineDetailModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw ApiException('Format de réponse invalide pour la machine');
  }
}
