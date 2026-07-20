import 'package:flutter/foundation.dart';
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

  /// 🟢 UPDATED: Fetches the full doctor profile to return both ID and Specialization
  Future<Map<String, dynamic>?> getDoctorProfileData() async {
    try {
      final response = await _dioClient.dio.get('doctors/me');

      if (response.data is Map<String, dynamic>) {
        // Strip the API wrapper if it exists (e.g., if the backend sends {"data": {...}})
        final data = response.data['data'] ?? response.data;

        // Look for either 'id' or 'doctorId'
        final rawId = data['id'] ?? data['doctorId'];
        final specialization = data['specializationName'] as String?;

        int? parsedId;
        if (rawId != null) {
          // Safely parse it whether the backend sent an int or a String
          if (rawId is int) parsedId = rawId;
          if (rawId is String) parsedId = int.tryParse(rawId);
        }

        return {
          'doctorId': parsedId,
          'specializationName': specialization,
        };
      }

      if (kDebugMode) {
        debugPrint('Warning: Doctor profile fetched, but properties were not structured correctly.');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to fetch doctor profile: $e');
      }
      return null;
    }
  }
}