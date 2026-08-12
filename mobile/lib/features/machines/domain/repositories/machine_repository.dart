import '../entities/machine_detail_entity.dart';
import '../entities/machine_entity.dart';

abstract class MachineRepository {
  Future<List<MachineEntity>> getMachines({
    String search = '',
    String status = '',
    String location = '',
  });

  Future<MachineDetailEntity> getMachine(int machineId);
}
