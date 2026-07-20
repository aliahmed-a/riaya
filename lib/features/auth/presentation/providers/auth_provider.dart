import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riaya/core/utils/storage_service.dart';
import 'package:riaya/features/auth/data/models/auth_response_model.dart';
import 'package:riaya/features/auth/data/repositories/auth_repository.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final AuthResponse? user;
  final String? errorMessage;

  AuthState({required this.status, this.user, this.errorMessage});
  factory AuthState.initial() => AuthState(status: AuthStatus.unauthenticated);
}

class TokenStorage {
  static String? _accessToken;
  static String? _refreshToken;
  static String? _userId;

  static void storeTokens(String? token, String? refreshToken, [String? userId]) {
    _accessToken = token;
    _refreshToken = refreshToken;
    _userId = userId;
  }

  static String? get token => _accessToken;
  static String? get refreshToken => _refreshToken;
  static String? get userId => _userId;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    try {
      // Preloaded synchronously in main() before runApp so this can restore
      // the session without turning the whole auth provider async.
      final savedSession = ref.read(initialSessionProvider);

      if (savedSession != null && savedSession.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(savedSession);
        final restoredUser = AuthResponse.fromJson(userMap);

        TokenStorage.storeTokens(restoredUser.token, restoredUser.refreshToken, restoredUser.userId);

        return AuthState(status: AuthStatus.authenticated, user: restoredUser);
      }
    } catch (e) {
      // Safely ignore and fall through
    }
    return AuthState.initial();
  }

  Future<bool> executeLogin(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final repository = ref.read(authRepositoryProvider);
      AuthResponse authResponse = await repository.login(email, password);

      // Inject tokens so the subsequent profile fetch request has auth headers
      TokenStorage.storeTokens(authResponse.token, authResponse.refreshToken, authResponse.userId);

      /// 🟢 UPDATED: Fetch doctor profile data data (ID + Specialization) right after login
      if (authResponse.isDoctor) {
        final profileData = await repository.getDoctorProfileData();
        if (profileData != null) {
          authResponse = authResponse.copyWith(
            doctorId: profileData['doctorId'] as int?,
            specializationName: profileData['specializationName'] as String?,
          );
        }
      }

      try {
        final storage = ref.read(storageServiceProvider);
        await storage.saveUserSession(jsonEncode(authResponse.toJson()));
      } catch (e) {
        if (kDebugMode) {
          debugPrint("Storage Warning: Could not save session to disk: $e");
        }
      }

      state = AuthState(status: AuthStatus.authenticated, user: authResponse);
      return true;
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      state = AuthState(status: AuthStatus.error, errorMessage: err);
      return false;
    }
  }

  void logout() {
    TokenStorage.storeTokens(null, null, null);
    // Fire-and-forget: clearing the on-disk session shouldn't block the UI
    // from immediately reflecting the logged-out state.
    ref.read(storageServiceProvider).clearSession().catchError((e) {
      if (kDebugMode) {
        debugPrint("Storage Warning: Could not clear session on logout: $e");
      }
    });
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});