import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_remote_datasource.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDatasource _remote;

  StaffRepositoryImpl(this._remote);

  @override
  Future<StaffListResult> getDoctors({
    String search = '',
    String role = '',
    String status = '',
  }) => _remote.getDoctors(search: search, role: role, status: status);

  @override
  Future<StaffEntity> getDoctor(int doctorId) => _remote.getDoctor(doctorId);

  @override
  Future<StaffListResult> createDoctor({
    required String fullName,
    required String email,
    String speciality = '',
    String phone = '',
  }) => _remote.createDoctor(
    fullName: fullName,
    email: email,
    speciality: speciality,
    phone: phone,
  );

  @override
  Future<StaffListResult> getNurses({
    String search = '',
    String status = '',
  }) => _remote.getNurses(search: search, status: status);

  @override
  Future<StaffEntity> getNurse(int nurseId) => _remote.getNurse(nurseId);

  @override
  Future<StaffListResult> createNurse({
    required String nom,
    required String email,
    String telephone = '',
  }) => _remote.createNurse(nom: nom, email: email, telephone: telephone);
}
