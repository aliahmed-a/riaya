import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Global provider exposing the storage service.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Initialize StorageService inside main first');
});

/// Seeded once at startup with whatever session (if any) was already on disk,
/// so [AuthNotifier] can restore synchronously without making the whole
/// provider tree async. See main.dart.
final initialSessionProvider = Provider<String?>((ref) {
  throw UnimplementedError('initialSessionProvider must be overridden in main()');
});

/// Persists the auth session (JWT + refresh token) in the platform secure
/// store (Keychain on iOS, Keystore-backed EncryptedSharedPreferences on
/// Android) instead of plain SharedPreferences, since this blob carries
/// live credentials for a medical records system.
class StorageService {
  final FlutterSecureStorage _secureStorage;
  static const String _userSessionKey = 'riaya_user_session';

  StorageService(this._secureStorage);

  /// Persists the full serialized user session context string post-login
  Future<void> saveUserSession(String jsonString) async {
    await _secureStorage.write(key: _userSessionKey, value: jsonString);
  }

  /// Retrieves the active serialized session metadata safely
  Future<String?> getUserSession() {
    return _secureStorage.read(key: _userSessionKey);
  }

  /// Evaluates if an active session string resides on disk
  Future<bool> hasActiveSession() async => (await getUserSession()) != null;

  /// Destroys the persistent session registry on explicit logout
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _userSessionKey);
  }
}
