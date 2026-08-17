import '../../domain/entities/device_entity.dart';

class DeviceModel {
  const DeviceModel._();

  static DeviceMachineRef machineRefFromJson(Map<String, dynamic> json) {
    return DeviceMachineRef(
      id: (json['id'] as num?)?.toInt() ?? 0,
      machineId: json['machine_id']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }

  static DeviceEntity fromJson(Map<String, dynamic> json) {
    DeviceMachineRef? machine;
    final raw = json['machine'];
    if (raw is Map<String, dynamic>) {
      machine = machineRefFromJson(raw);
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

  static List<DeviceEntity> listFromJson(List<dynamic> json) {
    return json
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  static List<DeviceMachineRef> machineListFromJson(List<dynamic> json) {
    return json
        .map((e) => machineRefFromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  static DeviceStats statsFromJson(Map<String, dynamic> json) {
    return DeviceStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      assigned: (json['assigned'] as num?)?.toInt() ?? 0,
      free: (json['free'] as num?)?.toInt() ?? 0,
      inactive: (json['inactive'] as num?)?.toInt() ?? 0,
    );
  }
}