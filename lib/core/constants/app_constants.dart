class AppConstants {
  AppConstants._();

  static const String appName = 'ArticuliCare';
  static const String appTagline = 'Precision Articulation & Speech Therapy';

  // Supabase Configuration
  static const String supabaseUrl = 'https://ptgzwiosneqdksjclxzz.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0Z3p3aW9zbmVxZGtzamNseHp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4MDcyNjcsImV4cCI6MjA1MzM4MzI2N30.72atrlPnd6H9xa1Sntkk8K-ZFt1JuBJty2EP7893oXw';

  // Routes
  static const String splashRoute = '/splash';
  static const String authGateRoute = '/auth_gate';
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
  static const String trainingVideosBucket = 'training-videos';

  // Supabase Tables
  static const String usersDataTable = 'users_data';
  static const String userProfilesTable = 'user_profiles';
  static const String speechSamplesTable = 'speech_samples';
  static const String therapistsTable = 'therapists';
  static const String dailyProgressTable = 'daily_progress';
  static const String riskAssessmentsTable = 'risk_assessments';
  static const String userTrainingTable = 'user_training';
  static const String userDayProgressTable = 'user_day_progress';

  // External APIs & Portals
  static const String zenQuotesApiUrl = 'https://zenquotes.io/api/random';
  static const String marhamConsultationUrl =
      'https://www.marham.pk/doctors/speech-therapist';
}
