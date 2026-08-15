class ProfileEntity {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String address;
  final String role;
  final String specialite;
  final bool etat;
  final String statusLabel;
  final String? memberSince;
  final String seniorityLabel;
  final String bio;
  final String formation;
  final String experience;
  final bool firstLogin;
  final String photoUrl;

  const ProfileEntity({
    required this.id,
    required this.username,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.role = '',
    this.specialite = '',
    this.etat = false,
    this.statusLabel = '',
    this.memberSince,
    this.seniorityLabel = '',
    this.bio = '',
    this.formation = '',
    this.experience = '',
    this.firstLogin = false,
    this.photoUrl = '',
  });
}
