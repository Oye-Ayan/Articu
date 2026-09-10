import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        // Sync user to Supabase
        try {
          final supabaseData = await _supabaseService.getUserData(user.uid);
          final photoUrl = supabaseData?['profile_img_url'] ?? user.photoURL;

          emit(Authenticated(UserEntity(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: photoUrl,
          )));
        } catch (_) {
          emit(Authenticated(UserEntity(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
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
      await _firebaseService.signInWithEmail(email: email, password: password);
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
  }) async {
    emit(const AuthLoading());
    try {
      final cred = await _firebaseService.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );

      // Upsert record in Supabase users_data
      if (cred.user != null) {
        try {
          await _supabaseService.saveUserData(
            id: cred.user!.uid,
            email: email,
            username: username,
          );
        } catch (_) {
          // Graceful fallback if offline
        }
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
        // User cancelled the prompt
        emit(const Unauthenticated());
        return;
      }
      if (cred.user != null) {
        try {
          await _supabaseService.saveUserData(
            id: cred.user!.uid,
            email: cred.user!.email ?? '',
            username: cred.user!.displayName ?? 'User',
            profileImgUrl: cred.user!.photoURL,
          );
        } catch (_) {}

        emit(Authenticated(UserEntity(
          id: cred.user!.uid,
          email: cred.user!.email ?? '',
          displayName: cred.user!.displayName ?? 'User',
          photoUrl: cred.user!.photoURL,
        )));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseAuthError(e)));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ApiException: 10') || msg.contains(' 10:') || msg.contains(': 10')) {
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
