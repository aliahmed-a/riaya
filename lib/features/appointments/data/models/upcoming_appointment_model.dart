class UpcomingAppointment {
  final int id;
  final DateTime appointmentDate;
  final int durationMinutes;
  final String status;
  final int doctorId;
  final String doctorName;
  final String specializationName;
  final int patientId;
  final String patientName;
  final int? clinicRoomId;
  final String? clinicRoomName;

  UpcomingAppointment({
    required this.id,
    required this.appointmentDate,
    required this.durationMinutes,
    required this.status,
    required this.doctorId,
    required this.doctorName,
    required this.specializationName,
    required this.patientId,
    required this.patientName,
    this.clinicRoomId,
    this.clinicRoomName,
  });

  factory UpcomingAppointment.fromJson(Map<String, dynamic> json) {
    return UpcomingAppointment(
      id: json['id'] as int,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      durationMinutes: json['durationMinutes'] as int,
      status: json['status'] as String? ?? 'Pending',
      doctorId: json['doctorId'] as int,
      doctorName: json['doctorName'] as String? ?? '',
      specializationName: json['specializationName'] as String? ?? '',
      patientId: json['patientId'] as int,
      patientName: json['patientName'] as String? ?? '',
      clinicRoomId: json['clinicRoomId'] as int?,
      clinicRoomName: json['clinicRoomName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentDate': appointmentDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specializationName': specializationName,
      'patientId': patientId,
      'patientName': patientName,
      'clinicRoomId': clinicRoomId,
      'clinicRoomName': clinicRoomName,
    };
  }
}