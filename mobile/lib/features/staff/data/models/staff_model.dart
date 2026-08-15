import '../../domain/entities/staff_entity.dart';

class StaffModel {
  const StaffModel._();

  static StaffEntity fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    return StaffEntity(
      id: idRaw is num ? idRaw.toInt() : int.tryParse('$idRaw') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      role: json['role']?.toString() ?? json['roleLabel']?.toString() ?? '',
      specialite:
          json['specialite']?.toString() ??
          json['speciality']?.toString() ??
          '',
      etat: json['etat'] as bool? ?? false,
      statusLabel: json['status_label']?.toString() ?? '',
      memberSince: json['member_since']?.toString() ?? '',
      seniorityLabel: json['seniority_label']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      formation: json['formation']?.toString() ?? '',
      experience: json['experience']?.toString() ??
          '${json['experienceYears'] ?? ''}',
      fullName:
          json['fullName']?.toString() ??
          json['firstName']?.toString() ??
          json['username']?.toString() ??
          '',
      assignedDoctorsText: json['assignedDoctorsText']?.toString() ?? '',
    );
  }
}
