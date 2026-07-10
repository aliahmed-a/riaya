import 'package:intl/intl.dart';

class PatientModel {
  final int id;
  final String fullName;
  final String phoneNumber;
  final DateTime dateOfBirth;
  final String gender;

  PatientModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      gender: json['gender'] as String? ?? 'Other',
    );
  }
}

class CreatePatientRequest {
  final String fullName;
  final String phoneNumber;
  final DateTime dateOfBirth;
  final String gender;

  CreatePatientRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
    };
  }
}