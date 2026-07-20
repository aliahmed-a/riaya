import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/doctor_schedule_model.dart';

class DoctorScheduleRepository {
  final DioClient _dioClient;

  DoctorScheduleRepository(this._dioClient);

  /// Fetch all schedules
  Future<List<DoctorScheduleModel>> getAllSchedules() async {
    try {
      final response = await _dioClient.dio.get('doctorschedules');

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data,
            (json) => json as List<dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((json) => DoctorScheduleModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleDioError(e, 'Failed to fetch schedules');
    }
  }

  /// Create a new schedule slot for a doctor
  Future<DoctorScheduleModel> createSchedule(CreateDoctorScheduleRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        'doctorschedules',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
            (json) => json,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return DoctorScheduleModel.fromJson(apiResponse.data as Map<String, dynamic>);
      } else {
        throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Could not create schedule.');
      }
    } catch (e) {
      throw _handleDioError(e, 'Failed to create schedule');
    }
  }

  /// Delete a schedule by ID
  Future<bool> deleteSchedule(int id) async {
    try {
      final response = await _dioClient.dio.delete('doctorschedules/$id');
      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
            (json) => json,
      );
      return apiResponse.success;
    } catch (e) {
      throw _handleDioError(e, 'Failed to delete schedule');
    }
  }

  Exception _handleDioError(dynamic e, String defaultMessage) {
    if (e is DioException) {
      String serverError = defaultMessage;
      if (e.response?.data is Map<String, dynamic>) {
        final rawJson = e.response!.data as Map<String, dynamic>;
        if (rawJson['message'] != null) serverError = rawJson['message'].toString();
      }
      return Exception(serverError);
    }
    return Exception(e.toString().replaceAll('Exception: ', ''));
  }
}

final doctorScheduleRepositoryProvider = Provider<DoctorScheduleRepository>((ref) {
  return DoctorScheduleRepository(ref.watch(dioClientProvider));
});