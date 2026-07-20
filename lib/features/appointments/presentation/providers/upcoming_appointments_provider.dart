import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/upcoming_appointment_model.dart';
import '../../data/repositories/appointment_repository.dart';

/// Tracks how far a single "finalize consultation" submission has gotten,
/// so that if it fails partway through and the caller retries with the same
/// [ConsultationProgress] instance, already-persisted work (the visit
/// record, and any prescriptions already saved against it) isn't recreated.
class ConsultationProgress {
  int? visitId;
  int prescriptionsSaved = 0;
}

class UpcomingAppointmentsNotifier extends AsyncNotifier<List<UpcomingAppointment>> {
  /// Neither dashboard has any push channel from the backend, so the queue
  /// only ever reflects reality via this background poll or the actions
  /// below that explicitly refetch after a mutation. If a second device
  /// changes an appointment's status, this is how the gap gets closed.
  static const _pollInterval = Duration(seconds: 20);

  @override
  FutureOr<List<UpcomingAppointment>> build() async {
    final timer = Timer.periodic(_pollInterval, (_) => _pollQueue());
    ref.onDispose(timer.cancel);
    return _fetchQueue();
  }

  Future<List<UpcomingAppointment>> _fetchQueue() async {
    final repository = ref.read(appointmentRepositoryProvider);
    return repository.getUpcomingAppointments(days: 7);
  }

  /// Background poll tick: refetches quietly and only swaps in the new list
  /// on success. A transient network hiccup shouldn't flash the whole queue
  /// into a loading/error state while someone's mid-click on it.
  Future<void> _pollQueue() async {
    try {
      final freshData = await _fetchQueue();
      state = AsyncValue.data(freshData);
    } catch (_) {
      // Keep showing the last known-good queue; the next tick will retry.
    }
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
    required ConsultationProgress progress,
  }) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);

      // 1. Post diagnosis payload details to /api/v1/Visits and get the new Visit ID.
      // Skip this on a retry (progress.visitId already set) so a transient
      // failure later in this method can't create a second duplicate visit.
      progress.visitId ??= await repository.recordClinicalVisit(
        appointmentId: appointmentId,
        symptoms: symptoms,
        diagnosis: diagnosis,
        notes: notes,
      );

      final visitId = progress.visitId;
      if (visitId == null) {
        return 'Could not submit clinical visit records. Visit ID was null.';
      }

      // 2. Loop through and save all prescriptions (if any) tied to the new VisitId.
      // Resume from the first one not yet confirmed saved, so a retry doesn't
      // re-submit prescriptions that already succeeded.
      for (var i = progress.prescriptionsSaved; i < prescriptions.length; i++) {
        final p = prescriptions[i];
        await repository.createPrescription(
          visitId: visitId,
          medicationName: p['medicationName'],
          dosage: p['dosage'],
          instructions: p['instructions'],
          durationInDays: p['durationInDays'],
        );
        progress.prescriptionsSaved = i + 1;
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
AsyncNotifierProvider.autoDispose<UpcomingAppointmentsNotifier, List<UpcomingAppointment>>(() {
  return UpcomingAppointmentsNotifier();
});