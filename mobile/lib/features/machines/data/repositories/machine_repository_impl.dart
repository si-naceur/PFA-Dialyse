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
}
