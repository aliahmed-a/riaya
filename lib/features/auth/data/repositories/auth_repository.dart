import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riaya/core/network/api_response.dart';
import 'package:riaya/core/network/dio_client.dart';
import '../models/auth_response_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepository(dioClient);
});

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<AuthResponse> login(String email, String password) async {
    final response = await _dioClient.dio.post(
      'auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final apiResponse = ApiResponse<AuthResponse>.fromJson(
      response.data as Map<String, dynamic>,
          (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Invalid credentials or clinical access denied.');
    }
  }

  // 🟢 ADDED: Fetches the doctor profile to get the integer ID safely
  Future<int?> getDoctorProfileId() async {
    try {
      final response = await _dioClient.dio.get('doctors/me');

      // 🟢 Temporary debug print so you can see exactly what the backend sent
      print('=== DOCTOR PROFILE RAW JSON ===');
      print(response.data);

      if (response.data is Map<String, dynamic>) {
        // Strip the API wrapper if it exists (e.g., if the backend sends {"data": {...}})
        final data = response.data['data'] ?? response.data;

        // Look for either 'id' or 'doctorId'
        final rawId = data['id'] ?? data['doctorId'];

        if (rawId != null) {
          // Safely parse it whether the backend sent an int or a String
          if (rawId is int) return rawId;
          if (rawId is String) return int.tryParse(rawId);
        }
      }

      print('Warning: Doctor profile fetched, but ID was not found in the JSON.');
      return null;
    } catch (e) {
      print('Failed to fetch doctor profile: $e');
      return null;
    }
  }
}