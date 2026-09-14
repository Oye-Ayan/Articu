import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  static SupabaseService get instance => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  DateTime? _lastKeepAlivePing;

  /// Lightweight keep-alive health check to prevent Supabase auto-pause.
  /// Throttled to at most once every 12 hours per active session.
  Future<bool> pingDatabaseHealthCheck({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastKeepAlivePing != null &&
        now.difference(_lastKeepAlivePing!).inHours < 12) {
      return true;
    }

    try {
      final response = await client
          .from(AppConstants.therapistsTable)
          .select('id')
          .limit(1);
      _lastKeepAlivePing = now;
      debugPrint('Supabase keep-alive ping succeeded at $now');
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Supabase keep-alive ping failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // User Profiles & Data
  // ---------------------------------------------------------------------------

  /// Fetch full user profile by UID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from(AppConstants.userProfilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (response != null) return response;

      // Fallback to legacy users_data table
      final legacy = await client
          .from(AppConstants.usersDataTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      return legacy;
    } catch (e) {
      debugPrint('getUserProfile error: $e');
      return null;
    }
  }

  /// Upsert full user profile into user_profiles and sync users_data
  Future<void> saveUserProfile({
    String? id,
    String? userId,
    required String email,
    String? username,
    String? fullName,
    String? profileImgUrl,
    String? role,
    String? phoneNumber,
    String? qualifications,
    bool? notificationEnabled,
    String? reminderTime,
  }) async {
    try {
      final effectiveId = id ?? userId ?? '';
      final effectiveUsername = username ??
          (fullName != null && fullName.isNotEmpty
              ? fullName
              : email.split('@').first);

      final data = <String, dynamic>{
        'id': effectiveId,
        'email': email,
        'username': effectiveUsername,
        if (fullName != null) 'full_name': fullName,
        if (profileImgUrl != null) 'profile_img_url': profileImgUrl,
        if (role != null) 'role': role,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (notificationEnabled != null)
          'notification_enabled': notificationEnabled,
        if (reminderTime != null) 'reminder_time': reminderTime,
      };

      await client
          .from(AppConstants.userProfilesTable)
          .upsert(data, onConflict: 'id');

      // Also sync to legacy users_data table
      await client.from(AppConstants.usersDataTable).upsert({
        'id': effectiveId,
        'email': email,
        'username': effectiveUsername,
        if (profileImgUrl != null) 'profile_img_url': profileImgUrl,
        if (role != null) 'role': role,
        'firebase_user_id': effectiveId,
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('saveUserProfile error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Therapists Directory & Registration
  // ---------------------------------------------------------------------------

  /// Fetch therapists ordered by superhero_points / creation date
  Future<List<Map<String, dynamic>>> fetchTherapists() async {
    try {
      final response = await client
          .from(AppConstants.therapistsTable)
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('fetchTherapists error: $e');
      return [];
    }
  }

  /// Register a therapist in public.therapists
  Future<void> registerTherapist({
    required String name,
    required String email,
    required String qualifications,
    required String userId,
    int superheroPoints = 20,
  }) async {
    try {
      await client.from(AppConstants.therapistsTable).insert({
        'name': name,
        'email': email,
        'qualifications': qualifications,
        'user_id': userId,
        'superhero_points': superheroPoints,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('registerTherapist error: $e');
      rethrow;
    }
  }

  /// Fetch list of available training video files directly from Supabase Storage
  Future<List<String>> fetchTrainingVideoFileNames() async {
    try {
      final response = await client.storage
          .from(AppConstants.trainingVideosBucket)
          .list();
      final names = response
          .map((f) => f.name)
          .where((name) => name.endsWith('.mp4') || name.endsWith('.m4v'))
          .toList();
      if (names.isNotEmpty) return names;
    } catch (e) {
      debugPrint('fetchTrainingVideoFileNames error from training-videos: $e');
    }

    try {
      final response = await client.storage
          .from(AppConstants.speechRecordingsBucket)
          .list(path: 'training_videos');
      return response
          .map((f) => f.name)
          .where((name) => name.endsWith('.mp4') || name.endsWith('.m4v'))
          .toList();
    } catch (e) {
      debugPrint('fetchTrainingVideoFileNames error from speech_recordings: $e');
      return [];
    }
  }

  /// Get public URL for a video from Supabase Storage
  String getVideoPublicUrl(String fileName) {
    final cleanName = Uri.decodeComponent(fileName.split('/').last);
    final encodedFileName = Uri.encodeComponent(cleanName);
    return client.storage
        .from(AppConstants.trainingVideosBucket)
        .getPublicUrl(encodedFileName);
  }

  /// Fetch user training progress (all days, or filtered by dayNumber)
  Future<List<Map<String, dynamic>>> fetchUserTrainingProgress({
    required String userId,
    int? dayNumber,
  }) async {
    try {
      var query = client
          .from(AppConstants.userTrainingTable)
          .select()
          .eq('user_id', userId);
      if (dayNumber != null) {
        query = query.eq('day_number', dayNumber);
      }
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('fetchUserTrainingProgress error: $e');
      return [];
    }
  }


  /// Save or update progress for an individual exercise
  Future<void> saveExerciseProgress({
    required String userId,
    required int dayNumber,
    required int exerciseIndex,
    required bool completed,
    int points = 10,
  }) async {
    try {
      final existing = await client
          .from(AppConstants.userTrainingTable)
          .select()
          .eq('user_id', userId)
          .eq('day_number', dayNumber)
          .eq('exercise_index', exerciseIndex)
          .maybeSingle();

      final now = DateTime.now().toUtc().toIso8601String();
      final data = {
        'user_id': userId,
        'day_number': dayNumber,
        'exercise_index': exerciseIndex,
        'completed': completed,
        'points': points,
        'completed_at': completed ? now : null,
        'updated_at': now,
      };

      if (existing != null) {
        await client
            .from(AppConstants.userTrainingTable)
            .update(data)
            .eq('id', existing['id']);
      } else {
        data['created_at'] = now;
        await client.from(AppConstants.userTrainingTable).insert(data);
      }
    } catch (e) {
      debugPrint('saveExerciseProgress error: $e');
    }
  }

  /// Fetch day completion records for user
  Future<List<Map<String, dynamic>>> fetchUserDayProgress(String userId) async {
    try {
      final response = await client
          .from(AppConstants.userDayProgressTable)
          .select()
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('fetchUserDayProgress error: $e');
      return [];
    }
  }

  /// Record day completion timestamp
  Future<void> saveDayCompletion({
    required String userId,
    required int dayNumber,
  }) async {
    try {
      final existing = await client
          .from(AppConstants.userDayProgressTable)
          .select()
          .eq('user_id', userId)
          .eq('day_number', dayNumber)
          .maybeSingle();

      final now = DateTime.now().toUtc().toIso8601String();
      final data = {
        'user_id': userId,
        'day_number': dayNumber,
        'completed_at': now,
        'updated_at': now,
      };

      if (existing != null) {
        await client
            .from(AppConstants.userDayProgressTable)
            .update(data)
            .eq('id', existing['id']);
      } else {
        data['created_at'] = now;
        await client.from(AppConstants.userDayProgressTable).insert(data);
      }
    } catch (e) {
      debugPrint('saveDayCompletion error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Speech Samples & Audio Storage
  // ---------------------------------------------------------------------------

  /// Upload binary file (image or audio) to specified bucket
  Future<String> uploadBinaryFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    await client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final publicUrl = client.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }

  /// Fetch recorded speech samples strictly for the authenticated user
  Future<List<Map<String, dynamic>>> fetchSpeechSamples({
    required String userId,
    String? username,
  }) async {
    try {
      if (userId.isEmpty) return [];

      var query = client.from(AppConstants.speechSamplesTable).select();

      if (username != null && username.isNotEmpty) {
        // Matches user's UID or legacy recordings made under this exact username where user_id was null
        query = query.or('user_id.eq.$userId,and(user_id.is.null,username.eq.$username)');
      } else {
        query = query.eq('user_id', userId);
      }

      final response = await query.order('timestamp', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('fetchSpeechSamples error: $e');
      return [];
    }
  }

  /// Save speech sample record in database
  Future<void> saveSpeechSample({
    required String audioUrl,
    required String username,
    String? userId,
    String? durationSeconds,
    String? filePath,
    String? analysisResult,
  }) async {
    try {
      await client.from(AppConstants.speechSamplesTable).insert({
        'audioUrl': audioUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'username': username,
        if (userId != null) 'user_id': userId,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (filePath != null) 'file_path': filePath,
        if (analysisResult != null) 'analysis_result': analysisResult,
      });
    } catch (e) {
      debugPrint('saveSpeechSample error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Daily Progress & Risk Assessments
  // ---------------------------------------------------------------------------

  /// Fetch user daily progress streak records
  Future<List<Map<String, dynamic>>> fetchDailyProgress(String userId) async {
    try {
      final response = await client
          .from(AppConstants.dailyProgressTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('fetchDailyProgress error: $e');
      return [];
    }
  }

  /// Fetch completed risk assessments
  Future<List<Map<String, dynamic>>> fetchRiskAssessments(String userId) async {
    try {
      final response = await client
          .from(AppConstants.riskAssessmentsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('fetchRiskAssessments error: $e');
      return [];
    }
  }

  /// Save risk assessment record
  Future<void> saveRiskAssessment({
    required String userId,
    required Map<String, dynamic> answers,
    required int score,
    required String riskLevel,
    bool isCompleted = true,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await client.from(AppConstants.riskAssessmentsTable).insert({
        'user_id': userId,
        'answers': answers,
        'score': score,
        'risk_level': riskLevel,
        'is_completed': isCompleted,
        'created_at': now,
        'completed_at': now,
      });
    } catch (e) {
      debugPrint('saveRiskAssessment error: $e');
    }
  }
}
