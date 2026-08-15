import '../../domain/entities/patient_detail_entity.dart';
import '../../domain/entities/patient_list_result.dart';
import '../../domain/repositories/patient_repository.dart';
import '../datasources/patient_remote_datasource.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientRemoteDatasource _remoteDatasource;

  PatientRepositoryImpl(this._remoteDatasource);

  @override
  Future<PatientListResult> getPatients({String search = ''}) async {
    final response = await _remoteDatasource.getPatients(search: search);

    return PatientListResult(
      patients: response.items.map((model) => model.toEntity()).toList(),
      totalCount: response.total,
    );
  }

  @override
  Future<PatientDetailEntity> createPatient(Map<String, dynamic> data) async {
    final model = await _remoteDatasource.createPatient(data);
    return model.toEntity();
  }

  @override
  Future<PatientDetailEntity> getPatient(String patientId) async {
    final model = await _remoteDatasource.getPatient(patientId);
    return model.toEntity();
  }

  @override
  Future<PatientDetailEntity> updatePatient(
    String patientId,
    Map<String, dynamic> data,
  ) async {
    final model = await _remoteDatasource.updatePatient(
      patientId,
      data,
    );

    return model.toEntity();
  }

  @override
  Future<void> deletePatient(String patientId) async {
    await _remoteDatasource.deletePatient(patientId);
  }
}
