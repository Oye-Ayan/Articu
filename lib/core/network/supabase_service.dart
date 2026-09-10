import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// Fetch user profile data by ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final response = await client
          .from(AppConstants.usersDataTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  /// Upsert user profile record
  Future<void> saveUserData({
    required String id,
    required String email,
    required String username,
    String? profileImgUrl,
  }) async {
    try {
      final existing = await getUserData(id);
      if (existing == null) {
        await client.from(AppConstants.usersDataTable).insert({
          'id': id,
          'email': email,
          'username': username,
          'profile_img_url': profileImgUrl ?? '',
        });
      } else {
        await client.from(AppConstants.usersDataTable).update({
          'email': email,
          'username': username,
          'profile_img_url': profileImgUrl ?? existing['profile_img_url'] ?? '',
        }).eq('id', id);
      }
    } catch (e) {
      // Allow graceful offline fallback
      rethrow;
    }
  }

  /// Upload binary file (e.g. image or audio) to specified bucket
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

  /// Save speech sample record in database
  Future<void> saveSpeechSample({
    required String audioUrl,
    required String username,
  }) async {
    await client.from(AppConstants.speechSamplesTable).insert({
      'audioUrl': audioUrl,
      'timestamp': DateTime.now().toIso8601String(),
      'username': username,
    });
  }
}
