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
    final result = await _remoteDatasource.login(username, password);
    final userModel = result.user;

    await _storageService.saveUserSession(
      userId: userModel.id,
      username: userModel.username,
      email: userModel.email,
      role: userModel.role,
      phone: userModel.phone,
      address: userModel.address,
      specialite: userModel.specialite,
      firstLogin: userModel.firstLogin,
      // Persist Django session key so ApiClient can authenticate monitoring
      // and every other protected call (including Flutter Web).
      cookie: result.sessionId != null && result.sessionId!.isNotEmpty
          ? 'sessionid=${result.sessionId}'
          : null,
    );

    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    await _remoteDatasource.logout();
    await _storageService.clearSession();
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _remoteDatasource.requestPasswordReset(email);
  }

  @override
  Future<void> markFirstLoginDone() async {
    await _storageService.saveUserSession(
      userId: await _storageService.getUserId() ?? 0,
      username: await _storageService.getUsername() ?? '',
      email: await _storageService.getUserEmail(),
      role: await _storageService.getUserRole() ?? '',
      phone: await _storageService.getUserPhone(),
      address: await _storageService.getUserAddress(),
      specialite: await _storageService.getUserSpecialite(),
      firstLogin: false,
      cookie: await _storageService.getSessionCookie(),
    );
  }

  @override
  Future<UserEntity?> checkAutoLogin() async {
    final userId = await _storageService.getUserId();
    final username = await _storageService.getUsername();
    final role = await _storageService.getUserRole();
    final cookie = await _storageService.getSessionCookie();

    if (userId == null ||
        username == null ||
        role == null ||
        cookie == null ||
        cookie.isEmpty) {
      return null;
    }

    return UserEntity(
      id: userId,
      username: username,
      email: await _storageService.getUserEmail(),
      role: role,
      phone: await _storageService.getUserPhone(),
      address: await _storageService.getUserAddress(),
      specialite: await _storageService.getUserSpecialite(),
      firstLogin: await _storageService.getFirstLogin(),
    );
  }
}
