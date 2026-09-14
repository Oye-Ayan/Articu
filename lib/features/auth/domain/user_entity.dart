enum UserRole {
  patient,
  caregiver,
  therapist;

  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.caregiver:
        return 'Caregiver';
      case UserRole.therapist:
        return 'Therapist';
    }
  }

  String toDatabaseValue() {
    switch (this) {
      case UserRole.patient:
        return 'Normal User';
      case UserRole.caregiver:
        return 'Caregiver';
      case UserRole.therapist:
        return 'Therapist';
    }
  }

  static UserRole fromString(String? val) {
    if (val == null) return UserRole.patient;
    final clean = val.toLowerCase().trim();
    if (clean.contains('therapist')) return UserRole.therapist;
    if (clean.contains('caregiver')) return UserRole.caregiver;
    return UserRole.patient;
  }

  bool get isTherapist => this == UserRole.therapist;
  bool get isCaregiver => this == UserRole.caregiver;
  bool get isPatient => this == UserRole.patient;
}

class UserEntity {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final bool isVerified;
  final String? qualifications;
  final String? phoneNumber;
  final int streakDays;
  final int audioDrillsCount;
  final double pronunciationScore;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = UserRole.patient,
    this.isVerified = false,
    this.qualifications,
    this.phoneNumber,
    this.streakDays = 0,
    this.audioDrillsCount = 0,
    this.pronunciationScore = 0.0,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    bool? isVerified,
    String? qualifications,
    String? phoneNumber,
    int? streakDays,
    int? audioDrillsCount,
    double? pronunciationScore,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      qualifications: qualifications ?? this.qualifications,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      streakDays: streakDays ?? this.streakDays,
      audioDrillsCount: audioDrillsCount ?? this.audioDrillsCount,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
    );
  }
}
