class AuthResponse {
  final String userId;
  final int? doctorId; // Stores the database integer ID
  final String? specializationName; // 🟢 ADDED: Stores the dynamic specialty string
  final String token;
  final String refreshToken;
  final DateTime refreshTokenExpiresAtUtc;
  final String email;
  final String fullName;
  final List<String> roles;

  AuthResponse({
    required this.userId,
    this.doctorId,
    this.specializationName, // 🟢 ADDED
    required this.token,
    required this.refreshToken,
    required this.refreshTokenExpiresAtUtc,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final rawId = json['userId'] ?? json['id'] ?? '';

    return AuthResponse(
      userId: rawId.toString(),
      doctorId: json['doctorId'] as int?,
      specializationName: json['specializationName'] as String?, // 🟢 ADDED
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      refreshTokenExpiresAtUtc: json['refreshTokenExpiresAtUtc'] != null
          ? DateTime.parse(json['refreshTokenExpiresAtUtc'])
          : DateTime.now(),
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'doctorId': doctorId,
      'specializationName': specializationName, // 🟢 ADDED
      'token': token,
      'refreshToken': refreshToken,
      'refreshTokenExpiresAtUtc': refreshTokenExpiresAtUtc.toIso8601String(),
      'email': email,
      'fullName': fullName,
      'roles': roles,
    };
  }

  bool get isDoctor => roles.any((role) => role.toLowerCase() == 'doctor');

  // Allows safely updating the object after fetching the profile data
  AuthResponse copyWith({
    int? doctorId,
    String? specializationName, // 🟢 ADDED
  }) {
    return AuthResponse(
      userId: userId,
      doctorId: doctorId ?? this.doctorId,
      specializationName: specializationName ?? this.specializationName, // 🟢 ADDED
      token: token,
      refreshToken: refreshToken,
      refreshTokenExpiresAtUtc: refreshTokenExpiresAtUtc,
      email: email,
      fullName: fullName,
      roles: roles,
    );
  }
}