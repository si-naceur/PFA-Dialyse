import '../../../../core/network/api_client.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/repositories/devices_repository.dart';
import '../datasources/devices_remote_datasource.dart';

class DevicesRepositoryImpl implements DevicesRepository {
  final DevicesRemoteDatasource _datasource;

  DevicesRepositoryImpl(this._datasource);

  DevicesRepositoryImpl.fromClient(ApiClient apiClient)
    : _datasource = DevicesRemoteDatasource(apiClient);

  @override
  Future<DevicesResult> getDevices() => _datasource.getDevices();

  @override
  Future<void> addDevice({
    required String raspiId,
    String description = '',
  }) {
    return _datasource.addDevice(raspiId: raspiId, description: description);
  }

  @override
  Future<void> assignMachine({
    required String deviceId,
    int? machineId,
  }) {
    return _datasource.assignMachine(deviceId: deviceId, machineId: machineId);
  }
}