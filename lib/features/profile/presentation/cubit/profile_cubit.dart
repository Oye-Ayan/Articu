import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/firebase_service.dart';
import '../../../../core/network/supabase_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final FirebaseService _firebaseService;
  final SupabaseService _supabaseService;

  ProfileCubit({
    FirebaseService? firebaseService,
    SupabaseService? supabaseService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _supabaseService = supabaseService ?? SupabaseService(),
        super(const ProfileState()) {
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      String? photoUrl = user.photoURL;

      try {
        final supabaseData = await _supabaseService.getUserData(user.uid);
        if (supabaseData != null && supabaseData['profile_img_url'] != null) {
          photoUrl = supabaseData['profile_img_url'];
        }
      } catch (_) {}

      emit(state.copyWith(
        username: user.displayName ?? 'User',
        email: user.email ?? '',
        profileImgUrl: photoUrl,
      ));
    }
  }

  Future<void> updateUsername(String newName) async {
    final user = _firebaseService.currentUser;
    if (user == null) return;

    emit(state.copyWith(isUpdating: true, error: null));
    try {
      await _firebaseService.updateDisplayName(newName);
      await _supabaseService.saveUserData(
        id: user.uid,
        email: user.email ?? '',
        username: newName,
        profileImgUrl: state.profileImgUrl,
      );

      emit(state.copyWith(
        username: newName,
        isUpdating: false,
        message: 'Profile name updated successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        error: 'Failed to update username: $e',
      ));
    }
  }

  Future<void> pickAndUploadAvatar() async {
    final user = _firebaseService.currentUser;
    if (user == null) return;

    // Check permission
    final photoStatus = await Permission.photos.request();
    final cameraStatus = await Permission.camera.request();

    if (!photoStatus.isGranted && !cameraStatus.isGranted) {
      // Still attempt with image_picker as Android 13+ handles photo picker without storage permission
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (picked == null) return;

      emit(state.copyWith(isUploadingAvatar: true, error: null));

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final storagePath =
          'avatars/${user.uid}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final publicUrl = await _supabaseService.uploadBinaryFile(
        bucket: AppConstants.profileImagesBucket,
        path: storagePath,
        bytes: bytes,
      );

      await _supabaseService.saveUserData(
        id: user.uid,
        email: user.email ?? '',
        username: state.username,
        profileImgUrl: publicUrl,
      );

      emit(state.copyWith(
        profileImgUrl: publicUrl,
        isUploadingAvatar: false,
        message: 'Profile photo updated successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(
        isUploadingAvatar: false,
        error: 'Could not upload profile picture: $e',
      ));
    }
  }

  void toggleNotifications(bool val) {
    emit(state.copyWith(
      notificationsEnabled: val,
      message: val ? 'Daily practice notifications enabled' : 'Notifications paused',
    ));
  }

  void setPracticeReminder(String timeStr) {
    emit(state.copyWith(
      practiceReminderTime: timeStr,
      message: 'Daily reminder set for $timeStr',
    ));
  }
}
