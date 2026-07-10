class DoctorScheduleModel {
  final int id;
  final int doctorId;
  final String doctorName;
  final String specializationName;
  final int dayOfWeek; // 0 = Sunday, 1 = Monday, etc.
  final String startTime; // Format: "HH:mm:ss"
  final String endTime; // Format: "HH:mm:ss"

  DoctorScheduleModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specializationName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json) {
    // 🟢 ADDED: Bulletproof helper to safely parse ints from either int or String
    int safelyParseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return DoctorScheduleModel(
      id: safelyParseInt(json['id']),
      doctorId: safelyParseInt(json['doctorId']),
      doctorName: json['doctorName'] as String? ?? '',
      specializationName: json['specializationName'] as String? ?? '',
      dayOfWeek: safelyParseInt(json['dayOfWeek']),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
    );
  }
}

class CreateDoctorScheduleRequest {
  final int doctorId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  CreateDoctorScheduleRequest({
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}