import 'machine_entity.dart';

class ActiveSessionEntity {
  final String id;
  final String patient;
  final String sessionDate;
  final String status;

  const ActiveSessionEntity({
    required this.id,
    required this.patient,
    required this.sessionDate,
    required this.status,
  });
}

class MachineDetailEntity {
  final MachineEntity machine;
  final ActiveSessionEntity? activeSession;

  const MachineDetailEntity({required this.machine, this.activeSession});
}
