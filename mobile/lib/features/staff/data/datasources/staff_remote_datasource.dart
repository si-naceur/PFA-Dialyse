import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/staff_entity.dart';
import '../models/staff_model.dart';

class StaffRemoteDatasource {
  final ApiClient _apiClient;

  StaffRemoteDatasource(this._apiClient);

  Future<StaffListResult> getDoctors({
    String search = '',
    String role = '',
    String status = '',
  }) async {
    final query = <String, dynamic>{};
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    if (role.trim().isNotEmpty) query['role'] = role.trim();
    if (status.trim().isNotEmpty) query['status'] = status.trim();
    final response = await _apiClient.get(
      ApiEndpoints.doctors,
      queryParameters: query.isEmpty ? null : query,
    );
    return _parseList(response.data, doctors: true);
  }

  Future<StaffEntity> getDoctor(int doctorId) async {
    final response = await _apiClient.get('${ApiEndpoints.doctors}$doctorId/');
    return _parseOne(response.data);
  }

  Future<StaffListResult> createDoctor({
    required String fullName,
    required String email,
    String speciality = '',
    String phone = '',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.doctors,
      data: {
        'fullName': fullName,
        'email': email,
        'speciality': speciality,
        'phone': phone,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      final created = data['data'] is Map<String, dynamic>
          ? StaffModel.fromJson(data['data'] as Map<String, dynamic>)
          : null;
      return StaffListResult(
        items: created == null ? const [] : [created],
        kpis: const StaffKpis(total: 1, activeCount: 0),
        generatedPassword: data['generated_password']?.toString(),
      );
    }
    throw ApiException(_error(data, 'Impossible d\'ajouter le docteur'));
  }

  Future<StaffListResult> getNurses({
    String search = '',
    String status = '',
  }) async {
    final query = <String, dynamic>{};
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    if (status.trim().isNotEmpty) query['status'] = status.trim();
    final response = await _apiClient.get(
      ApiEndpoints.nurses,
      queryParameters: query.isEmpty ? null : query,
    );
    return _parseList(response.data, doctors: false);
  }

  Future<StaffEntity> getNurse(int nurseId) async {
    final response = await _apiClient.get('${ApiEndpoints.nurses}$nurseId/');
    return _parseOne(response.data);
  }

  Future<StaffListResult> createNurse({
    required String nom,
    required String email,
    String telephone = '',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.nurses,
      data: {'nom': nom, 'email': email, 'telephone': telephone},
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      final created = data['data'] is Map<String, dynamic>
          ? StaffModel.fromJson(data['data'] as Map<String, dynamic>)
          : null;
      return StaffListResult(
        items: created == null ? const [] : [created],
        kpis: const StaffKpis(total: 1, activeCount: 0),
        generatedPassword: data['generated_password']?.toString(),
      );
    }
    throw ApiException(_error(data, 'Impossible d\'ajouter l\'infirmier'));
  }

  StaffListResult _parseList(dynamic data, {required bool doctors}) {
    if (data is Map<String, dynamic> && data['success'] == true) {
      final raw = data['data'];
      final items = <StaffEntity>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            items.add(StaffModel.fromJson(item));
          }
        }
      }
      final kpisRaw = data['kpis'];
      StaffKpis kpis;
      if (kpisRaw is Map<String, dynamic>) {
        kpis = StaffKpis(
          total: doctors
              ? (kpisRaw['total_doctors'] as num?)?.toInt() ?? items.length
              : (kpisRaw['total_nurses'] as num?)?.toInt() ?? items.length,
          activeCount: doctors
              ? (kpisRaw['isActif_count'] as num?)?.toInt() ?? 0
              : (kpisRaw['kpi_active_nurses'] as num?)?.toInt() ?? 0,
          adminCount: (kpisRaw['isadmin_count'] as num?)?.toInt() ?? 0,
        );
      } else {
        kpis = StaffKpis(total: items.length, activeCount: 0);
      }
      return StaffListResult(items: items, kpis: kpis);
    }
    throw ApiException('Format de réponse invalide pour le personnel');
  }

  StaffEntity _parseOne(dynamic data) {
    if (data is Map<String, dynamic> &&
        data['success'] == true &&
        data['data'] is Map<String, dynamic>) {
      return StaffModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw ApiException('Format de réponse invalide pour le profil');
  }

  String _error(dynamic data, String fallback) {
    if (data is Map<String, dynamic>) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          fallback;
    }
    return fallback;
  }
}
