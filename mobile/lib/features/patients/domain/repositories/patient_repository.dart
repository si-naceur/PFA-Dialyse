import '../entities/patient_detail_entity.dart';
import '../entities/patient_list_result.dart';

abstract class PatientRepository {
  Future<PatientListResult> getPatients({String search = ''});

  Future<PatientDetailEntity> createPatient(Map<String, dynamic> data);

  Future<PatientDetailEntity> getPatient(String patientId);

  Future<PatientDetailEntity> updatePatient(
    String patientId,
    Map<String, dynamic> data,
  );

  Future<void> deletePatient(String patientId);
}
