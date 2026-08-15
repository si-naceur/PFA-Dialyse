import '../../domain/entities/machine_detail_entity.dart';
import '../../domain/entities/machine_entity.dart';
import '../../domain/repositories/machine_repository.dart';
import '../datasources/machine_remote_datasource.dart';

class MachineRepositoryImpl implements MachineRepository {
  final MachineRemoteDatasource _remoteDatasource;

  MachineRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<MachineEntity>> getMachines({
    String search = '',
    String status = '',
    String location = '',
  }) async {
    final models = await _remoteDatasource.getMachines(
      search: search,
      status: status,
      location: location,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<MachineDetailEntity> getMachine(int machineId) async {
    final model = await _remoteDatasource.getMachine(machineId);
    return model.toEntity();
  }

  @override
  Future<MachineDetailEntity> configureMachine(
    int machineId, {
    required String status,
    String? raspiId,
  }) async {
    final model = await _remoteDatasource.configureMachine(
      machineId,
      status: status,
      raspiId: raspiId,
    );
    return model.toEntity();
  }

  @override
  Future<void> createMachine({
    required String machineId,
    required String model,
    required String location,
  }) {
    return _remoteDatasource.createMachine(
      machineId: machineId,
      model: model,
      location: location,
    );
  }
}
