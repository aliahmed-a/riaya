import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/upcoming_appointment_model.dart';
import '../../data/repositories/appointment_repository.dart';

class UpcomingAppointmentsNotifier extends AsyncNotifier<List<UpcomingAppointment>> {
  @override
  FutureOr<List<UpcomingAppointment>> build() async {
    return _fetchQueue();
  }

  Future<List<UpcomingAppointment>> _fetchQueue() async {
    final repository = ref.read(appointmentRepositoryProvider);
    return repository.getUpcomingAppointments(days: 7);
  }

  /// Pull-to-refresh
  Future<void> refreshQueue() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchQueue());
  }

  /// Interactively updates status to Checked-in via API.
  /// Returns null if successful, or the server validation error string if it fails.
  Future<String?> processPatientCheckIn(int appointmentId) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final isSuccess = await repository.checkInAppointment(appointmentId);
      if (isSuccess) {
        state = await AsyncValue.guard(() => _fetchQueue());
        return null; // Return null means no error occurred
      }
      return 'Failed to execute check-in transition.';
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Interactively updates status to No-Show via API.
  /// Returns null if successful, or the server validation error string if it fails.
  // 🟢 FIX: this was previously an orphaned local function nested inside
  // finalizeClinicalConsultation() — dead code, never called. Promoted to a
  // proper method on the notifier, alongside processPatientCheckIn.
  Future<String?> markPatientNoShow(int appointmentId) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final isSuccess = await repository.markNoShow(appointmentId);
      if (isSuccess) {
        state = await AsyncValue.guard(() => _fetchQueue());
        return null; // Return null means no error occurred
      }
      return 'Failed to execute no-show transition.';
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Logs the diagnosis record encounter, saves prescriptions, and updates status to complete.
  /// Returns null if successful, or the server validation error string if it fails.
  Future<String?> finalizeClinicalConsultation({
    required int appointmentId,
    required String symptoms,
    required String diagnosis,
    String? notes,
    required List<Map<String, dynamic>> prescriptions,
  }) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);

      // 1. Post diagnosis payload details to /api/v1/Visits and get the new Visit ID
      final visitId = await repository.recordClinicalVisit(
        appointmentId: appointmentId,
        symptoms: symptoms,
        diagnosis: diagnosis,
        notes: notes,
      );

      if (visitId == null) {
        return 'Could not submit clinical visit records. Visit ID was null.';
      }

      // 2. Loop through and save all prescriptions (if any) tied to the new VisitId
      for (var p in prescriptions) {
        await repository.createPrescription(
          visitId: visitId,
          medicationName: p['medicationName'],
          dosage: p['dosage'],
          instructions: p['instructions'],
          durationInDays: p['durationInDays'],
        );
      }

      // 3. Mark appointment as completed in state engine
      final appointmentCompleted = await repository.completeAppointment(appointmentId);
      if (appointmentCompleted) {
        state = await AsyncValue.guard(() => _fetchQueue());
        return null; // Success
      }
      return 'Visit and prescriptions logged, but failed to complete appointment state.';
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}


final upcomingAppointmentsProvider =
AsyncNotifierProvider<UpcomingAppointmentsNotifier, List<UpcomingAppointment>>(() {
  return UpcomingAppointmentsNotifier();
});