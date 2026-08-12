import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/datasources/machine_remote_datasource.dart';
import '../../data/repositories/machine_repository_impl.dart';
import '../../domain/entities/machine_detail_entity.dart';
import '../../domain/entities/machine_entity.dart';
import '../../domain/repositories/machine_repository.dart';

final machineRepositoryProvider = Provider<MachineRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MachineRepositoryImpl(MachineRemoteDatasource(apiClient));
});

/// Machines list backed by GET /api/machines/ with search/status/location filters.
class MachineListNotifier extends AsyncNotifier<List<MachineEntity>> {
  String _search = '';
  String _status = '';
  String _location = '';

  @override
  Future<List<MachineEntity>> build() => _fetch();

  Future<List<MachineEntity>> _fetch() async {
    final repository = ref.read(machineRepositoryProvider);
    return repository.getMachines(
      search: _search,
      status: _status,
      location: _location,
    );
  }

  Future<void> setFilters({
    String? search,
    String? status,
    String? location,
  }) async {
    _search = search?.trim() ?? _search;
    _status = status?.trim() ?? _status;
    _location = location?.trim() ?? _location;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

final machinesProvider =
    AsyncNotifierProvider<MachineListNotifier, List<MachineEntity>>(
      MachineListNotifier.new,
    );

/// Machine dossier backed by GET /api/machines/<id>/.
final machineDetailProvider = FutureProvider.family<MachineDetailEntity, int>((
  ref,
  machineId,
) {
  final repository = ref.watch(machineRepositoryProvider);
  return repository.getMachine(machineId);
});
