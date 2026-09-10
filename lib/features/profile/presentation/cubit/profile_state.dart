class ProfileState {
  final String username;
  final String email;
  final String? profileImgUrl;
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
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      isUpdating: isUpdating ?? this.isUpdating,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      practiceReminderTime: practiceReminderTime ?? this.practiceReminderTime,
      message: message,
      error: error,
    );
  }
}
