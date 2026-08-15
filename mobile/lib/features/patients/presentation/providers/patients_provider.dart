import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/datasources/patient_remote_datasource.dart';
import '../../data/repositories/patient_repository_impl.dart';
import '../../domain/entities/patient_detail_entity.dart';
import '../../domain/entities/patient_list_result.dart';
import '../../domain/repositories/patient_repository.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PatientRepositoryImpl(PatientRemoteDatasource(apiClient));
});

/// Patients list backed by GET /api/patients/?search=<query>.
class PatientListNotifier extends AsyncNotifier<PatientListResult> {
  String _query = '';
  // Total patient count from the backend, kept stable while searching
  // (mirrors Django's "Patients Totaux" KPI that ignores the search filter).
  int _totalCount = 0;

  @override
  Future<PatientListResult> build() => _fetch();

  Future<PatientListResult> _fetch() async {
    final repository = ref.watch(patientRepositoryProvider);
    final result = await repository.getPatients(search: _query);
    if (_query.isEmpty) {
      _totalCount = result.totalCount;
    }
    if (_totalCount == 0) {
      _totalCount = result.totalCount;
    }
    return PatientListResult(
      patients: result.patients,
      totalCount: _totalCount,
    );
  }

  Future<void> search(String query) async {
    final nextQuery = query.trim();
    if (_query == nextQuery) return;
    _query = nextQuery;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

final patientsProvider =
    AsyncNotifierProvider<PatientListNotifier, PatientListResult>(
      PatientListNotifier.new,
    );

/// Patient dossier backed by GET /api/patients/<id>/.
final patientDetailProvider = FutureProvider.family<PatientDetailEntity, String>((
  ref,
  patientId,
) {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getPatient(patientId);
});

final patientUpdateProvider =
    Provider<Future<PatientDetailEntity> Function(
  String,
  Map<String, dynamic>,
)>((ref) {
  final repository = ref.watch(patientRepositoryProvider);

  return (patientId, data) {
    return repository.updatePatient(patientId, data);
  };
});
