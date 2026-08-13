import '../entities/patient_detail_entity.dart';
import '../entities/patient_list_result.dart';

abstract class PatientRepository {
  Future<PatientListResult> getPatients({String search = ''});

  Future<PatientDetailEntity> getPatient(int patientId);

  Future<PatientDetailEntity> updatePatient(
    int patientId,
    Map<String, dynamic> data,
  );

  Future<void> deletePatient(int patientId);
}