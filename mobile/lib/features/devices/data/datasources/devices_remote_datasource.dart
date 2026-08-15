import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/device_entity.dart';

class DevicesRemoteDatasource {
  final ApiClient _apiClient;

  DevicesRemoteDatasource(this._apiClient);

  Future<DevicesResult> getDevices() async {
    final response = await _apiClient.get(ApiEndpoints.devices);
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      final raw = data['data'];
      final devices = <DeviceEntity>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            devices.add(_device(item));
          }
        }
      }
      final statsRaw = data['stats'] as Map<String, dynamic>? ?? {};
      final machinesRaw = data['machines'];
      final machines = <DeviceMachineRef>[];
      if (machinesRaw is List) {
        for (final m in machinesRaw) {
          if (m is Map<String, dynamic>) {
            machines.add(
              DeviceMachineRef(
                id: (m['id'] as num).toInt(),
                machineId: m['machine_id']?.toString() ?? '',
                location: m['location']?.toString() ?? '',
              ),
            );
          }
        }
      }
      final assigned = <int>[];
      final assignedRaw = data['assigned_machine_ids'];
      if (assignedRaw is List) {
        for (final id in assignedRaw) {
          if (id is num) assigned.add(id.toInt());
        }
      }
      return DevicesResult(
        devices: devices,
        stats: DeviceStats(
          total: (statsRaw['total'] as num?)?.toInt() ?? devices.length,
          assigned: (statsRaw['assigned'] as num?)?.toInt() ?? 0,
          free: (statsRaw['free'] as num?)?.toInt() ?? 0,
          inactive: (statsRaw['inactive'] as num?)?.toInt() ?? 0,
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

  DeviceEntity _device(Map<String, dynamic> json) {
    DeviceMachineRef? machine;
    final raw = json['machine'];
    if (raw is Map<String, dynamic>) {
      machine = DeviceMachineRef(
        id: (raw['id'] as num).toInt(),
        machineId: raw['machine_id']?.toString() ?? '',
      );
    }
    return DeviceEntity(
      id: json['id']?.toString() ?? '',
      raspiId: json['raspi_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? false,
      lastSeen: json['last_seen'] as String?,
      machine: machine,
    );
  }
}
