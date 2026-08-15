class StaffKpis {
  final int total;
  final int activeCount;
  final int adminCount;

  const StaffKpis({
    required this.total,
    required this.activeCount,
    this.adminCount = 0,
  });
}

class StaffEntity {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String address;
  final String role;
  final String specialite;
  final bool etat;
  final String statusLabel;
  final String memberSince;
  final String seniorityLabel;
  final String bio;
  final String formation;
  final String experience;
  final String fullName;
  final String assignedDoctorsText;

  const StaffEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    required this.specialite,
    required this.etat,
    required this.statusLabel,
    required this.memberSince,
    required this.seniorityLabel,
    required this.bio,
    required this.formation,
    required this.experience,
    required this.fullName,
    this.assignedDoctorsText = '',
  });
}

class StaffListResult {
  final List<StaffEntity> items;
  final StaffKpis kpis;
  final String? generatedPassword;

  const StaffListResult({
    required this.items,
    required this.kpis,
    this.generatedPassword,
  });
}
