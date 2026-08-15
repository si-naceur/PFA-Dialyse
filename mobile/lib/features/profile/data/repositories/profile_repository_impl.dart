import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _remote;

  ProfileRepositoryImpl(this._remote);

  @override
  Future<ProfileEntity> getProfile() => _remote.getProfile();

  @override
  Future<ProfileEntity> updateProfile(Map<String, dynamic> data) =>
      _remote.updateProfile(data);
}
