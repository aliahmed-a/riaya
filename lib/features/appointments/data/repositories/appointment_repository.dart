import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/upcoming_appointment_model.dart';

class AppointmentRepository {
  final DioClient _dioClient;

  AppointmentRepository(this._dioClient);

  /// Consumes GET api/v1/appointments/upcoming
  Future<List<UpcomingAppointment>> getUpcomingAppointments({int days = 7}) async {
    try {
      final response = await _dioClient.dio.get(
        'appointments/upcoming',
        queryParameters: {'days': days},
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
            (json) => json,
      );

      if (apiResponse.success && apiResponse.data != null) {
        final List<dynamic> rawList = apiResponse.data as List<dynamic>;
        return rawList
            .map((item) => UpcomingAppointment.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Failed to load appointments');
      }
    } catch (e) {
      throw Exception('Network error while fetching queue workspace: $e');
    }
  }

  /// Consumes PATCH api/v1/appointments/{id}/check-in
  Future<bool> checkInAppointment(int id) async {
    try {
      final response = await _dioClient.dio.patch(
        'appointments/$id/check-in',
        data: {},
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
            (json) => json,
      );

      return apiResponse.success;
    } catch (e) {
      throw _handleDioError(e, 'Check-in transaction rejected by server.');
    }
  }

  /// Consumes PATCH api/v1/appointments/{id}/complete
  Future<bool> completeAppointment(int id) async {
    try {
      final response = await _dioClient.dio.patch(
        'appointments/$id/complete',
        data: {},
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
            (json) => json,
      );

      return apiResponse.success;
    } catch (e) {
      throw _handleDioError(e, 'Completion transaction rejected by server.');
    }
  }

  /// Consumes PATCH api/v1/appointments/{id}/confirm
  Future<bool> confirmAppointment(int id) async {
    try {
      final response = await _dioClient.dio.patch(
        'appointments/$id/confirm',
        data: {},
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
            (json) => json,
      );

      return apiResponse.success;
    } catch (e) {
      throw _handleDioError(e, 'Confirmation rejected by server.');
    }
  }

  /// Consumes PATCH api/v1/appointments/{id}/cancel
  Future<bool> cancelAppointment(int id) async {
    try {
      final response = await _dioClient.dio.patch(
        'appointments/$id/cancel',
        data: {},
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
            (json) => json,
      );

      return apiResponse.success;
    } catch (e) {
      throw _handleDioError(e, 'Cancellation transaction rejected by server.');
    }
  }

  /// Consumes PATCH api/v1/appointments/{id}/no-show
  Future<bool> markNoShow(int id) async {
    try {
      final response = await _dioClient.dio.patch(
        'appointments/$id/no-show',
        data: {},
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>, (json) => json,
      );

      return apiResponse.success;
    } catch (e) {
      throw _handleDioError(e, 'Failed to mark as no-show.');
    }
  }

  /// Consumes POST api/v1/Visits
  /// Returns the ID of the newly created visit, or null if it fails.
  Future<int?> recordClinicalVisit({
    required int appointmentId,
    required String symptoms,
    required String diagnosis,
    String? notes,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        'visits',
        data: {
          'appointmentId': appointmentId,
          'symptoms': symptoms,
          'diagnosis': diagnosis,
          'notes': notes ?? '',
        },
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
            (json) => json,
      );

      if (apiResponse.success && apiResponse.data != null) {
        final dataMap = apiResponse.data as Map<String, dynamic>;
        return dataMap['id'] as int?;
      } else {
        throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Could not submit clinical visit records.');
      }
    } catch (e) {
      throw _handleDioError(e, 'Visit recording failed');
    }
  }

  /// Consumes POST api/v1/Prescriptions
  Future<bool> createPrescription({
    required int visitId,
    required String medicationName,
    required String dosage,
    required String instructions,
    required int durationInDays,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        'prescriptions',
        data: {
          'visitId': visitId,
          'medicationName': medicationName,
          'dosage': dosage,
          'instructions': instructions,
          'durationInDays': durationInDays,
        },
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>, (json) => json,
      );
      return apiResponse.success;
    } catch (e) {
      throw _handleDioError(e, 'Failed to create prescription.');
    }
  }

  /// Consumes GET api/v1/Patients/{id}/history
  Future<Map<String, dynamic>> getPatientHistory(int patientId) async {
    try {
      final response = await _dioClient.dio.get('patients/$patientId/history');
      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>, (json) => json,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data as Map<String, dynamic>;
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to load patient history: $e');
    }
  }

  /// Consumes POST api/v1/Appointments
  Future<bool> createAppointment({
    required int doctorId,
    required int patientId,
    int? clinicRoomId,
    required DateTime appointmentDate,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        'appointments',
        data: {
          'doctorId': doctorId,
          'patientId': patientId,
          'clinicRoomId': clinicRoomId,
          'appointmentDate': appointmentDate.toIso8601String(),
        },
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
            (json) => json,
      );

      return apiResponse.success;
    } catch (e) {
      throw _handleDioError(e, 'Appointment creation failed');
    }
  }

  // Helper method to clean up Dio exceptions
  Exception _handleDioError(dynamic e, String defaultMessage) {
    if (e is DioException) {
      String serverError = defaultMessage;
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        final rawJson = e.response!.data as Map<String, dynamic>;
        if (rawJson.containsKey('message') && rawJson['message'] != null && rawJson['message'].toString().isNotEmpty) {
          serverError = rawJson['message'].toString();
        }
      } else if (e.error != null && e.error.toString().isNotEmpty) {
        serverError = e.error.toString();
      } else if (e.message != null) {
        serverError = e.message!;
      }
      return Exception(serverError);
    }
    return Exception(e.toString().replaceAll('Exception: ', ''));
  }
}

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AppointmentRepository(dioClient);
});