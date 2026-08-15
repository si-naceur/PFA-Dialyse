import '../entities/staff_entity.dart';

abstract class StaffRepository {
  Future<StaffListResult> getDoctors({
    String search = '',
    String role = '',
    String status = '',
  });

  Future<StaffEntity> getDoctor(int doctorId);

  Future<StaffListResult> createDoctor({
    required String fullName,
    required String email,
    String speciality = '',
    String phone = '',
  });

  Future<StaffListResult> getNurses({
    String search = '',
    String status = '',
  });

  Future<StaffEntity> getNurse(int nurseId);

  Future<StaffListResult> createNurse({
    required String nom,
    required String email,
    String telephone = '',
  });
}
