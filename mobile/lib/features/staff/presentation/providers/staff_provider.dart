import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/datasources/staff_remote_datasource.dart';
import '../../data/repositories/staff_repository_impl.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepositoryImpl(StaffRemoteDatasource(ref.watch(apiClientProvider)));
});

class DoctorsListNotifier extends AsyncNotifier<StaffListResult> {
  String _search = '';
  String _role = '';
  String _status = '';

  @override
  Future<StaffListResult> build() => _fetch();

  Future<StaffListResult> _fetch() {
    return ref.read(staffRepositoryProvider).getDoctors(
      search: _search,
      role: _role,
      status: _status,
    );
  }

  Future<void> setFilters({String? search, String? role, String? status}) async {
    _search = search?.trim() ?? _search;
    _role = role?.trim() ?? _role;
    _status = status?.trim() ?? _status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

final doctorsProvider =
    AsyncNotifierProvider<DoctorsListNotifier, StaffListResult>(
      DoctorsListNotifier.new,
    );

class NursesListNotifier extends AsyncNotifier<StaffListResult> {
  String _search = '';
  String _status = '';

  @override
  Future<StaffListResult> build() => _fetch();

  Future<StaffListResult> _fetch() {
    return ref.read(staffRepositoryProvider).getNurses(
      search: _search,
      status: _status,
    );
  }

  Future<void> setFilters({String? search, String? status}) async {
    _search = search?.trim() ?? _search;
    _status = status?.trim() ?? _status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

final nursesProvider =
    AsyncNotifierProvider<NursesListNotifier, StaffListResult>(
      NursesListNotifier.new,
    );

final doctorDetailProvider = FutureProvider.family<StaffEntity, int>((
  ref,
  id,
) {
  return ref.watch(staffRepositoryProvider).getDoctor(id);
});

final nurseDetailProvider = FutureProvider.family<StaffEntity, int>((ref, id) {
  return ref.watch(staffRepositoryProvider).getNurse(id);
});
