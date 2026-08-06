import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keySessionCookie = 'session_cookie';

  Future<void> saveUserSession({
    required int userId,
    required String username,
    required String? email,
    required String role,
    String? cookie,
  }) async {
    await _storage.write(key: _keyUserId, value: userId.toString());
    await _storage.write(key: _keyUsername, value: username);
    if (email != null) {
      await _storage.write(key: _keyUserEmail, value: email);
    }
    await _storage.write(key: _keyUserRole, value: role);
    if (cookie != null) {
      await _storage.write(key: _keySessionCookie, value: cookie);
    }
  }

  Future<int?> getUserId() async {
    final val = await _storage.read(key: _keyUserId);
    return val != null ? int.tryParse(val) : null;
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _keyUsername);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  Future<String?> getSessionCookie() async {
    return await _storage.read(key: _keySessionCookie);
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
