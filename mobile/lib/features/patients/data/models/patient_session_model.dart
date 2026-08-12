import '../../domain/entities/patient_session_entity.dart';

class PatientSessionModel {
  final String id;
  final String? sessionDate;
  final String status;
  final int duration;
  final String? machineId;

  const PatientSessionModel({
    required this.id,
    this.sessionDate,
    required this.status,
    required this.duration,
    this.machineId,
  });

  factory PatientSessionModel.fromJson(Map<String, dynamic> json) {
    return PatientSessionModel(
      id: json['id']?.toString() ?? '',
      sessionDate: json['session_date'] as String?,
      status: json['status'] as String? ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      machineId: json['machine__machine_id']?.toString(),
    );
  }

  PatientSessionEntity toEntity() {
    return PatientSessionEntity(
      id: id,
      sessionDate: sessionDate,
      status: status,
      duration: duration,
      machineId: machineId,
    );
  }
}
