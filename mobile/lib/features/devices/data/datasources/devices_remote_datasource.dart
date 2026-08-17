import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/device_entity.dart';
import '../models/device_model.dart';

class DevicesRemoteDatasource {
  final ApiClient _apiClient;

  DevicesRemoteDatasource(this._apiClient);

  Future<DevicesResult> getDevices() async {
    final response = await _apiClient.get(ApiEndpoints.devices);
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      final raw = data['data'];
      final devices = raw is List
          ? DeviceModel.listFromJson(raw)
          : <DeviceEntity>[];
      final statsRaw = data['stats'] as Map<String, dynamic>? ?? {};
      final machinesRaw = data['machines'];
      final machines = machinesRaw is List
          ? DeviceModel.machineListFromJson(machinesRaw)
          : <DeviceMachineRef>[];
      final assigned = <int>[];
      final assignedRaw = data['assigned_machine_ids'];
      if (assignedRaw is List) {
        for (final id in assignedRaw) {
          if (id is num) assigned.add(id.toInt());
        }
      }
      final stats = DeviceModel.statsFromJson(statsRaw);
      return DevicesResult(
        devices: devices,
        stats: DeviceStats(
          total: stats.total > 0 ? stats.total : devices.length,
          assigned: stats.assigned,
          free: stats.free,
          inactive: stats.inactive,
        ),
        machines: machines,
        assignedMachineIds: assigned,
      );
    }
    throw ApiException('Format de réponse invalide pour les appareils');
  }

  Future<void> addDevice({
    required String raspiId,
    String description = '',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.devices,
      data: {'raspi_id': raspiId, 'description': description},
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) return;
    throw ApiException(
      data is Map<String, dynamic>
          ? (data['error']?.toString() ?? 'Impossible d\'ajouter l\'appareil')
          : 'Impossible d\'ajouter l\'appareil',
    );
  }

  Future<void> assignMachine({
    required String deviceId,
    int? machineId,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.devices}$deviceId/assign/',
      data: {'machine_id': machineId},
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) return;
    throw ApiException(
      data is Map<String, dynamic>
          ? (data['error']?.toString() ?? 'Assignation impossible')
          : 'Assignation impossible',
    );
  }
}
