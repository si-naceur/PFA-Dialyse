class DeviceMachineRef {
  final int id;
  final String machineId;
  final String location;

  const DeviceMachineRef({
    required this.id,
    required this.machineId,
    this.location = '',
  });
}

class DeviceEntity {
  final String id;
  final String raspiId;
  final String description;
  final bool isActive;
  final String? lastSeen;
  final DeviceMachineRef? machine;

  const DeviceEntity({
    required this.id,
    required this.raspiId,
    required this.description,
    required this.isActive,
    this.lastSeen,
    this.machine,
  });
}

class DeviceStats {
  final int total;
  final int assigned;
  final int free;
  final int inactive;

  const DeviceStats({
    required this.total,
    required this.assigned,
    required this.free,
    required this.inactive,
  });
}

class DevicesResult {
  final List<DeviceEntity> devices;
  final DeviceStats stats;
  final List<DeviceMachineRef> machines;
  final List<int> assignedMachineIds;

  const DevicesResult({
    required this.devices,
    required this.stats,
    required this.machines,
    required this.assignedMachineIds,
  });
}
