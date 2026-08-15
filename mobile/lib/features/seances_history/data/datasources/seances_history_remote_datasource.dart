import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/seance_history_entity.dart';
import '../models/seance_history_model.dart';

class SeancesHistoryRemoteDatasource {
  final ApiClient _apiClient;

  SeancesHistoryRemoteDatasource(this._apiClient);

  /// GET /api/sessions/ — optional status / date / search / date range filters.
  Future<List<SeanceHistoryEntity>> getSessions({
    String status = '',
    String date = '',
    String search = '',
    String dateFrom = '',
    String dateTo = '',
  }) async {
    final queryParams = <String, dynamic>{};
    if (status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }
    if (date.trim().isNotEmpty) {
      queryParams['date'] = date.trim();
    }
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (dateFrom.trim().isNotEmpty) {
      queryParams['date_from'] = dateFrom.trim();
    }
    if (dateTo.trim().isNotEmpty) {
      queryParams['date_to'] = dateTo.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.sessions,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      final list = data['data'];
      if (list is List) {
        return SeanceHistoryModel.listFromJson(list);
      }
    }
    throw ApiException('Format de réponse invalide pour les séances');
  }
}
