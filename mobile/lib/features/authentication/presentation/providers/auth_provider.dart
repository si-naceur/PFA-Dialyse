import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// Global SecureStorage Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Global ApiClient Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});

// Auth Datasource & Repository Providers
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDatasource(apiClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDs = ref.watch(authRemoteDatasourceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(remoteDs, storage);
});

// Auth State Definition
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthInitial()) {
    checkAutoLogin();
  }

  Future<void> checkAutoLogin() async {
    state = AuthLoading();
    try {
      final user = await _repository.checkAutoLogin();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (_) {
      state = AuthUnauthenticated();
    }
  }

  Future<void> login(String username, String password) async {
    state = AuthLoading();
    try {
      final user = await _repository.login(username, password);
      state = AuthAuthenticated(user);
    } catch (e) {
      final msg = e.toString().replaceAll('ApiException: ', '');
      state = AuthError(msg);
    }
  }

  Future<void> logout() async {
    state = AuthLoading();
    await _repository.logout();
    state = AuthUnauthenticated();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
