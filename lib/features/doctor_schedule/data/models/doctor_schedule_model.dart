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
    // Safely parse ints from either int or String
    int safelyParseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // 🟢 ADDED: Handles integers, nulls, Capitalized Keys, AND string names like "Monday"
    int parseDayOfWeek(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        // If it's a string number like "2"
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;

        // If the backend is sending text like "Monday" instead of an integer
        final lower = value.toLowerCase();
        if (lower.startsWith('sun')) return 0;
        if (lower.startsWith('mon')) return 1;
        if (lower.startsWith('tue')) return 2;
        if (lower.startsWith('wed')) return 3;
        if (lower.startsWith('thu')) return 4;
        if (lower.startsWith('fri')) return 5;
        if (lower.startsWith('sat')) return 6;
      }
      return 0;
    }

    return DoctorScheduleModel(
      // Checking both camelCase and PascalCase just in case the .NET serializer flips it
      id: safelyParseInt(json['id'] ?? json['Id']),
      doctorId: safelyParseInt(json['doctorId'] ?? json['DoctorId']),
      doctorName: json['doctorName'] ?? json['DoctorName']?.toString() ?? '',
      specializationName: json['specializationName'] ?? json['SpecializationName']?.toString() ?? '',
      dayOfWeek: parseDayOfWeek(json['dayOfWeek'] ?? json['DayOfWeek']),
      startTime: json['startTime'] ?? json['StartTime']?.toString() ?? '',
      endTime: json['endTime'] ?? json['EndTime']?.toString() ?? '',
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