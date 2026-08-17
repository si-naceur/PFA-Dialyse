import '../../domain/entities/device_entity.dart';

abstract class DevicesRepository {
  Future<DevicesResult> getDevices();

  Future<void> addDevice({
    required String raspiId,
    String description = '',
  });

  Future<void> assignMachine({
    required String deviceId,
    int? machineId,
  });
}