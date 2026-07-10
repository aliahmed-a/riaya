import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_response.dart';

class BillingRepository {
  final DioClient _dioClient;

  BillingRepository(this._dioClient);

  /// Consumes POST api/v1/invoices
  /// Returns the ID of the newly created invoice.
  Future<int> createInvoice({
    required int patientId,
    int? appointmentId,
    int? visitId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        'invoices',
        data: {
          'patientId': patientId,
          'appointmentId': appointmentId,
          'visitId': visitId,
          'items': items,
        },
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
            (json) => json,
      );

      if (apiResponse.success && apiResponse.data != null) {
        final dataMap = apiResponse.data as Map<String, dynamic>;
        return dataMap['id'] as int;
      } else {
        throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Could not generate invoice.');
      }
    } catch (e) {
      throw _handleDioError(e, 'Invoice generation failed');
    }
  }

  /// Consumes POST api/v1/payments
  /// The [paymentMethod] maps to the backend Enum: 0 = Cash, 1 = Card, 2 = Transfer
  Future<bool> processPayment({
    required int invoiceId,
    required double amount,
    required int paymentMethod,
    String? notes,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        'payments',
        data: {
          'invoiceId': invoiceId,
          'amount': amount,
          'method': paymentMethod,
          'notes': notes ?? 'Processed via Front-Desk',
        },
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
            (json) => json,
      );

      return apiResponse.success;
    } catch (e) {
      throw _handleDioError(e, 'Payment processing failed');
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

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return BillingRepository(dioClient);
});