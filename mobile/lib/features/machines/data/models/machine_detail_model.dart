import '../../domain/entities/machine_detail_entity.dart';
import 'machine_model.dart';

class ActiveSessionModel {
  final String id;
  final String patient;
  final String sessionDate;
  final String status;

  const ActiveSessionModel({
    required this.id,
    required this.patient,
    required this.sessionDate,
    required this.status,
  });

  factory ActiveSessionModel.fromJson(Map<String, dynamic> json) {
    return ActiveSessionModel(
      id: json['id'] as String? ?? '',
      patient: json['patient'] as String? ?? '',
      sessionDate: json['session_date'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  ActiveSessionEntity toEntity() {
    return ActiveSessionEntity(
      id: id,
      patient: patient,
      sessionDate: sessionDate,
      status: status,
    );
  }
}

class MachineDetailModel {
  final MachineModel machine;
  final ActiveSessionModel? activeSession;

  const MachineDetailModel({required this.machine, this.activeSession});

  factory MachineDetailModel.fromJson(Map<String, dynamic> json) {
    return MachineDetailModel(
      machine: MachineModel.fromJson(json),
      activeSession: json['active_session'] != null
          ? ActiveSessionModel.fromJson(
              json['active_session'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  MachineDetailEntity toEntity() {
    return MachineDetailEntity(
      machine: machine.toEntity(),
      activeSession: activeSession?.toEntity(),
    );
  }
}
