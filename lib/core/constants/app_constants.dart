class AppConstants {
  AppConstants._();

  static const String appName = 'ArticuliCare';
  static const String appTagline = 'Speak with Confidence, Improve Every Day';

  // Routes
  static const String splashRoute = '/splash';
  static const String authGateRoute = '/auth_gate';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String mainNavRoute = '/main';
  static const String speechRecordingRoute = '/speech_recording';
  static const String trainingRoute = '/training';
  static const String therapistRoute = '/therapist';
  static const String profileRoute = '/profile';
  static const String riskAssessmentRoute = '/risk_assessment';
  static const String progressRoute = '/progress';

  // Supabase Storage Buckets
  static const String profileImagesBucket = 'profile_images';
  static const String speechRecordingsBucket = 'speech_recordings';

  // Supabase Tables
  static const String usersDataTable = 'users_data';
  static const String speechSamplesTable = 'speech_samples';
  static const String therapistsTable = 'therapists';
  static const String dailyProgressTable = 'daily_progress';
  static const String riskAssessmentsTable = 'risk_assessments';
  static const String userTrainingTable = 'user_training';
}
