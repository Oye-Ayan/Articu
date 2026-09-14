import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/firebase_service.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/user_entity.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseService _firebaseService;
  final SupabaseService _supabaseService;
  StreamSubscription<User?>? _authSubscription;

  AuthCubit({
    FirebaseService? firebaseService,
    SupabaseService? supabaseService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _supabaseService = supabaseService ?? SupabaseService(),
        super(const AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = _firebaseService.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          final profileData = await _supabaseService.getUserProfile(user.uid);
          final photoUrl = profileData?['profile_img_url'] ?? user.photoURL;
          final roleStr = profileData?['role'] as String?;
          final userRole = UserRole.fromString(roleStr);
          final qualifications = profileData?['qualifications'] as String?;
          final phone = profileData?['phone_number'] as String?;
          final displayName = profileData?['username'] ??
              profileData?['full_name'] ??
              user.displayName ??
              'User';

          emit(Authenticated(UserEntity(
            id: user.uid,
            email: user.email ?? '',
            displayName: displayName,
            photoUrl: photoUrl,
            role: userRole,
            qualifications: qualifications,
            phoneNumber: phone,
            isVerified: userRole.isTherapist || (profileData?['is_verified'] ?? false),
          )));
        } catch (e) {
          debugPrint('Error syncing profile in _init: $e');
          emit(Authenticated(UserEntity(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            role: UserRole.patient,
          )));
        }
      } else {
        emit(const Unauthenticated());
      }
    });
  }

  Future<void> loginWithEmail(String email, String password) async {
    emit(const AuthLoading());
    try {
      final cred = await _firebaseService.signInWithEmail(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        final profile = await _supabaseService.getUserProfile(cred.user!.uid);
        final role = UserRole.fromString(profile?['role']);

        emit(Authenticated(UserEntity(
          id: cred.user!.uid,
          email: cred.user!.email ?? '',
          displayName: profile?['username'] ?? cred.user!.displayName ?? 'User',
          photoUrl: profile?['profile_img_url'] ?? cred.user!.photoURL,
          role: role,
          qualifications: profile?['qualifications'],
          phoneNumber: profile?['phone_number'],
        )));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseAuthError(e)));
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String username,
    UserRole role = UserRole.patient,
    String? fullName,
    String? qualifications,
    String? phoneNumber,
  }) async {
    emit(const AuthLoading());
    try {
      final cred = await _firebaseService.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );

      final user = cred.user;
      if (user != null) {
        final roleStr = role.toDatabaseValue();

        try {
          // 1. Save profile to public.user_profiles & users_data
          await _supabaseService.saveUserProfile(
            id: user.uid,
            email: email,
            username: username,
            fullName: fullName ?? username,
            role: roleStr,
            qualifications: qualifications,
            phoneNumber: phoneNumber,
            notificationEnabled: true,
          );

          // 2. If registering as therapist, register in public.therapists
          if (role == UserRole.therapist) {
            await _supabaseService.registerTherapist(
              name: fullName ?? username,
              email: email,
              qualifications: qualifications ?? 'Certified Speech Specialist',
              userId: user.uid,
              superheroPoints: 25,
            );
          }
        } catch (dbErr) {
          debugPrint('Profile save error on registration: $dbErr');
        }

        emit(Authenticated(UserEntity(
          id: user.uid,
          email: email,
          displayName: username,
          role: role,
          qualifications: qualifications,
          phoneNumber: phoneNumber,
          isVerified: role == UserRole.therapist,
        )));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseAuthError(e)));
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final cred = await _firebaseService.signInWithGoogle();
      if (cred == null) {
        emit(const Unauthenticated());
        return;
      }
      if (cred.user != null) {
        final u = cred.user!;
        Map<String, dynamic>? profile;
        try {
          profile = await _supabaseService.getUserProfile(u.uid);
          if (profile == null) {
            await _supabaseService.saveUserProfile(
              id: u.uid,
              email: u.email ?? '',
              username: u.displayName ?? 'User',
              fullName: u.displayName ?? 'User',
              profileImgUrl: u.photoURL,
              role: UserRole.patient.toDatabaseValue(),
            );
          }
        } catch (_) {}

        final role = UserRole.fromString(profile?['role']);

        emit(Authenticated(UserEntity(
          id: u.uid,
          email: u.email ?? '',
          displayName: u.displayName ?? 'User',
          photoUrl: profile?['profile_img_url'] ?? u.photoURL,
          role: role,
          qualifications: profile?['qualifications'],
        )));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseAuthError(e)));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ApiException: 10') ||
          msg.contains(' 10:') ||
          msg.contains(': 10')) {
        emit(const AuthError(
          'Google Sign-In developer error: SHA-1 fingerprint needs to be added in Firebase Console for this device.',
        ));
      } else {
        emit(AuthError('Google sign in failed: $msg'));
      }
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _firebaseService.sendPasswordResetEmail(email);
      emit(PasswordResetSent(email));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseAuthError(e)));
    } catch (e) {
      emit(AuthError('Could not send reset link: ${e.toString()}'));
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _firebaseService.signOut();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('Error signing out: ${e.toString()}'));
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password or email credentials.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password is too weak. Must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network connection issue. Please check your internet.';
      default:
        return e.message ?? 'An unexpected authentication error occurred.';
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
