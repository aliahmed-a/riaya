class AuthResponse {
  final String userId;
  final int? doctorId; // 🟢 ADDED: Stores the database integer ID
  final String token;
  final String refreshToken;
  final DateTime refreshTokenExpiresAtUtc;
  final String email;
  final String fullName;
  final List<String> roles;

  AuthResponse({
    required this.userId,
    this.doctorId,
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
      doctorId: json['doctorId'] as int?, // 🟢 ADDED
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
      'doctorId': doctorId, // 🟢 ADDED
      'token': token,
      'refreshToken': refreshToken,
      'refreshTokenExpiresAtUtc': refreshTokenExpiresAtUtc.toIso8601String(),
      'email': email,
      'fullName': fullName,
      'roles': roles,
    };
  }

  bool get isDoctor => roles.any((role) => role.toLowerCase() == 'doctor');

  // 🟢 ADDED: Allows safely updating the object after fetching the profile
  AuthResponse copyWith({
    int? doctorId,
  }) {
    return AuthResponse(
      userId: userId,
      doctorId: doctorId ?? this.doctorId,
      token: token,
      refreshToken: refreshToken,
      refreshTokenExpiresAtUtc: refreshTokenExpiresAtUtc,
      email: email,
      fullName: fullName,
      roles: roles,
    );
  }
}