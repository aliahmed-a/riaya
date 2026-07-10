import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/doctor_schedule_model.dart';
import '../../data/repositories/doctor_schedule_repository.dart';

class DoctorScheduleNotifier extends AsyncNotifier<List<DoctorScheduleModel>> {

  @override
  FutureOr<List<DoctorScheduleModel>> build() async {
    final authState = ref.watch(authProvider);

    // 🟢 FIX: Read the integer directly, no more tryParse string errors!
    final currentDoctorId = authState.user?.doctorId;

    if (currentDoctorId == null) return [];

    final repository = ref.watch(doctorScheduleRepositoryProvider);
    final allSchedules = await repository.getAllSchedules();

    return allSchedules.where((s) => s.doctorId == currentDoctorId).toList();
  }

  Future<void> refreshSchedules() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {}
  }

  Future<String?> addNewScheduleSlot({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final authState = ref.read(authProvider);

    // 🟢 FIX: Read the integer directly here too
    final currentDoctorId = authState.user?.doctorId;

    if (currentDoctorId == null) {
      return 'Authentication error: Doctor ID missing. Please log out and back in.';
    }

    try {
      final repository = ref.read(doctorScheduleRepositoryProvider);

      final request = CreateDoctorScheduleRequest(
        doctorId: currentDoctorId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      );

      await repository.createSchedule(request);
      ref.invalidateSelf();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> removeScheduleSlot(int scheduleId) async {
    try {
      final repository = ref.read(doctorScheduleRepositoryProvider);
      final success = await repository.deleteSchedule(scheduleId);

      if (success) {
        ref.invalidateSelf();
        return null;
      } else {
        return 'The backend server declined the deletion instruction.';
      }
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}

final doctorScheduleProvider = AsyncNotifierProvider<DoctorScheduleNotifier, List<DoctorScheduleModel>>(
  DoctorScheduleNotifier.new,
);