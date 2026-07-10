import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global provider exposing the storage service.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Initialize SharedPreferences inside main first');
});

class StorageService {
  final SharedPreferences _prefs;
  static const String _userSessionKey = 'riaya_user_session';

  StorageService(this._prefs);

  /// Persists the full serialized user session context string post-login
  Future<void> saveUserSession(String jsonString) async {
    await _prefs.setString(_userSessionKey, jsonString);
  }

  /// Retrieves the active serialized session metadata safely
  String? getUserSession() {
    return _prefs.getString(_userSessionKey);
  }

  /// Evaluates if an active session string resides on disk
  bool hasActiveSession() => getUserSession() != null;

  /// Destroys the persistent session registry on explicit logout
  Future<void> clearSession() async {
    await _prefs.remove(_userSessionKey);
  }
}