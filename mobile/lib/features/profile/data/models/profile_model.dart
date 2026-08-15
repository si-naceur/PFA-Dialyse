import '../../domain/entities/profile_entity.dart';

class ProfileModel {
  const ProfileModel._();

  static ProfileEntity fromJson(Map<String, dynamic> json) {
    return ProfileEntity(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      specialite: json['specialite']?.toString() ?? '',
      etat: json['etat'] as bool? ?? false,
      statusLabel: json['status_label']?.toString() ?? '',
      memberSince: json['member_since']?.toString(),
      seniorityLabel: json['seniority_label']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      formation: json['formation']?.toString() ?? '',
      experience: json['experience']?.toString() ?? '',
      firstLogin: json['first_login'] as bool? ?? false,
      photoUrl: json['photo_url']?.toString() ?? '',
    );
  }
}
