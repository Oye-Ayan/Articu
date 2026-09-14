import '../../../auth/domain/user_entity.dart';

class ProfileState {
  final String username;
  final String email;
  final String? profileImgUrl;
  final UserRole role;
  final int streakDays;
  final int audioDrillsCount;
  final int totalPoints;
  final String pronunciationScore;
  final bool isUploadingAvatar;
  final bool isUpdating;
  final bool notificationsEnabled;
  final String? practiceReminderTime;
  final String? message;
  final String? error;

  const ProfileState({
    this.username = 'User',
    this.email = '',
    this.profileImgUrl,
    this.role = UserRole.patient,
    this.streakDays = 0,
    this.audioDrillsCount = 0,
    this.totalPoints = 0,
    this.pronunciationScore = '0%',
    this.isUploadingAvatar = false,
    this.isUpdating = false,
    this.notificationsEnabled = true,
    this.practiceReminderTime = '09:00 AM',
    this.message,
    this.error,
  });

  ProfileState copyWith({
    String? username,
    String? email,
    String? profileImgUrl,
    UserRole? role,
    int? streakDays,
    int? audioDrillsCount,
    int? totalPoints,
    String? pronunciationScore,
    bool? isUploadingAvatar,
    bool? isUpdating,
    bool? notificationsEnabled,
    String? practiceReminderTime,
    String? message,
    String? error,
  }) {
    return ProfileState(
      username: username ?? this.username,
      email: email ?? this.email,
      profileImgUrl: profileImgUrl ?? this.profileImgUrl,
      role: role ?? this.role,
      streakDays: streakDays ?? this.streakDays,
      audioDrillsCount: audioDrillsCount ?? this.audioDrillsCount,
      totalPoints: totalPoints ?? this.totalPoints,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      isUpdating: isUpdating ?? this.isUpdating,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      practiceReminderTime: practiceReminderTime ?? this.practiceReminderTime,
      message: message,
      error: error,
    );
  }
}

