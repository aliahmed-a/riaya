import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riaya/core/network/dio_client.dart';
import 'package:riaya/core/network/api_response.dart';
import '../models/patient_model.dart';

abstract class PatientRepository {
  Future<List<PatientModel>> searchPatients({String? query});
  Future<PatientModel> createPatient(CreatePatientRequest request);
}

class PatientRepositoryImpl implements PatientRepository {
  final DioClient _dioClient;

  PatientRepositoryImpl(this._dioClient);

  @override
  Future<List<PatientModel>> searchPatients({String? query}) async {
    final trimmedQuery = query?.trim() ?? '';
    if (trimmedQuery.isEmpty) {
      return [];
    }

    try {
      // Uses the dedicated, unpaginated search endpoint (GET /Patients/search)
      // rather than the paginated GET /Patients (GetAll) endpoint — GetAll
      // returns a PagedResponse<T> wrapper, not a bare array, and would throw
      // a type-cast error here.
      final response = await _dioClient.dio.get(
        'Patients/search',
        queryParameters: {'name': trimmedQuery},
      );

      if (response.data is Map<String, dynamic>) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          response.data as Map<String, dynamic>,
              (json) => json,
        );

        if (apiResponse.success && apiResponse.data != null) {
          final List<dynamic> rawList = apiResponse.data as List<dynamic>;
          return rawList
              .map((item) => PatientModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Failed to filter patient records');
        }
      } else {
        throw Exception('Server returned an unexpected data structure.');
      }
    } on DioException catch (e) {
      String serverError = 'Network error while filtering patient profiles';
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        final rawJson = e.response!.data as Map<String, dynamic>;
        if (rawJson.containsKey('message') && rawJson['message'] != null) {
          serverError = rawJson['message'].toString();
          throw Exception(serverError);
        }
      }
      if (e.error != null && e.error.toString().isNotEmpty) {
        serverError = e.error.toString();
      } else {
        serverError = e.message ?? serverError;
      }
      throw Exception(serverError);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<PatientModel> createPatient(CreatePatientRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        'Patients',
        data: request.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        final apiResponse = ApiResponse<dynamic>.fromJson(
          response.data as Map<String, dynamic>,
              (json) => json,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return PatientModel.fromJson(apiResponse.data as Map<String, dynamic>);
        } else {
          throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Failed to compile intake record');
        }
      } else {
        throw Exception('Server returned an unexpected data structure.');
      }
    } on DioException catch (e) {
      String serverError = 'Patient registration operational transit failed';
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        final rawJson = e.response!.data as Map<String, dynamic>;
        if (rawJson.containsKey('message') && rawJson['message'] != null && rawJson['message'].toString().isNotEmpty) {
          serverError = rawJson['message'].toString();
          throw Exception(serverError);
        }
      }
      if (e.error != null) {
        serverError = e.error.toString();
      }
      throw Exception(serverError);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return PatientRepositoryImpl(dioClient);
});