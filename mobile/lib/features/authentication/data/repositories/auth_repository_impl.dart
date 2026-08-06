import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final SecureStorageService _storageService;

  AuthRepositoryImpl(this._remoteDatasource, this._storageService);

  @override
  Future<UserEntity> login(String username, String password) async {
    final userModel = await _remoteDatasource.login(username, password);

    await _storageService.saveUserSession(
      userId: userModel.id,
      username: userModel.username,
      email: userModel.email,
      role: userModel.role,
    );

    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    await _remoteDatasource.logout();
    await _storageService.clearSession();
  }

  @override
  Future<UserEntity?> checkAutoLogin() async {
    final userId = await _storageService.getUserId();
    final username = await _storageService.getUsername();
    final role = await _storageService.getUserRole();

    if (userId != null && username != null && role != null) {
      return UserEntity(id: userId, username: username, role: role);
    }
    return null;
  }
}
