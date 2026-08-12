class PatientSessionEntity {
  final String id;
  final String? sessionDate;
  final String status;
  final int duration;
  final String? machineId;

  const PatientSessionEntity({
    required this.id,
    this.sessionDate,
    required this.status,
    required this.duration,
    this.machineId,
  });
}
