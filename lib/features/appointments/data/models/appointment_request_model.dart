class CreateAppointmentRequest {
  final int doctorId;
  final int patientId;
  final int? clinicRoomId;
  final DateTime appointmentDate;
  final int? durationMinutes;

  CreateAppointmentRequest({
    required this.doctorId,
    required this.patientId,
    this.clinicRoomId,
    required this.appointmentDate,
    this.durationMinutes = 30,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'clinicRoomId': clinicRoomId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }
}