import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:articulicare/core/constants/app_constants.dart';
import 'package:articulicare/core/theme/app_colors.dart';
import 'package:articulicare/features/auth/domain/user_entity.dart';
import 'package:articulicare/features/training/domain/training_lesson.dart';
import 'package:articulicare/features/speech_recording/domain/recording_model.dart';
import 'package:articulicare/features/home/presentation/screens/splash_screen.dart';
import 'package:articulicare/features/home/presentation/cubit/home_cubit.dart';

void main() {
  group('App Constants & Configuration', () {
    test('App constants and theme verification', () {
      expect(AppConstants.appName, equals('ArticuliCare'));
      expect(AppColors.primary, isNotNull);
      expect(AppConstants.trainingVideosBucket, equals('training-videos'));
      expect(AppConstants.speechRecordingsBucket, equals('speech_recordings'));
      expect(AppConstants.userProfilesTable, equals('user_profiles'));
      expect(AppConstants.marhamConsultationUrl,
          contains('marham.pk/doctors/speech-therapist'));
    });
  });

  group('User Role & Permissions', () {
    test('UserRole parsing and display names', () {
      expect(UserRole.fromString('patient'), equals(UserRole.patient));
      expect(UserRole.fromString('Normal User'), equals(UserRole.patient));
      expect(UserRole.fromString('caregiver'), equals(UserRole.caregiver));
      expect(UserRole.fromString('therapist'), equals(UserRole.therapist));
      expect(UserRole.fromString('Speech Therapist'), equals(UserRole.therapist));
      expect(UserRole.fromString(null), equals(UserRole.patient));

      expect(UserRole.patient.displayName, equals('Patient'));
      expect(UserRole.caregiver.displayName, equals('Caregiver'));
      expect(UserRole.therapist.displayName, equals('Therapist'));

      expect(UserRole.patient.toDatabaseValue(), equals('Normal User'));
      expect(UserRole.caregiver.toDatabaseValue(), equals('Caregiver'));
      expect(UserRole.therapist.toDatabaseValue(), equals('Therapist'));

      expect(UserRole.therapist.isTherapist, isTrue);
      expect(UserRole.caregiver.isCaregiver, isTrue);
      expect(UserRole.patient.isPatient, isTrue);
    });

    test('UserEntity default and copyWith behavior', () {
      const entity = UserEntity(
        id: 'test_uid',
        email: 'test@articulicare.com',
        displayName: 'Ayan Tester',
        role: UserRole.therapist,
      );
      expect(entity.role.isTherapist, isTrue);
      expect(entity.streakDays, equals(0));

      final updated = entity.copyWith(streakDays: 7, audioDrillsCount: 15);
      expect(updated.streakDays, equals(7));
      expect(updated.audioDrillsCount, equals(15));
      expect(updated.displayName, equals('Ayan Tester'));
    });
  });

  group('Training Lesson Video Mapping', () {
    test('TrainingLesson video and points integrity', () {
      const lesson = TrainingLesson(
        id: 'd1_e1',
        title: 'Introduction to Articulation',
        description: 'Basics of breath control and posture',
        durationMinutes: '3 mins',
        techniquePrompt: 'Breathe deeply and say "Ah"',
        dayNumber: 1,
        exerciseIndex: 0,
        videoFileName: 'Introduction.mp4',
        points: 10,
      );

      expect(lesson.videoFileName, equals('Introduction.mp4'));
      expect(lesson.dayNumber, equals(1));
      expect(lesson.points, equals(10));
      expect(lesson.isCompleted, isFalse);

      final completed = lesson.copyWith(isCompleted: true);
      expect(completed.isCompleted, isTrue);
    });
  });

  group('Speech Recording Model', () {
    test('SpeechSampleModel instantiation and serialization', () {
      final now = DateTime.now();
      final sample = SpeechSampleModel(
        id: '123',
        userId: 'user_xyz',
        username: 'Ayan Tester',
        audioUrl: 'https://storage.supabase.co/bucket/sample.m4a',
        timestamp: now,
        duration: const Duration(seconds: 15),
        analysisResult: 'Clear articulation (92%)',
      );

      expect(sample.title, equals('Speech Sample #123'));
      expect(sample.duration.inSeconds, equals(15));
      expect(sample.analysisResult, contains('92%'));

      final map = sample.toMap();
      expect(map['id'], equals('123'));
      expect(map['username'], equals('Ayan Tester'));

      final fromMap = SpeechSampleModel.fromMap(map);
      expect(fromMap.id, equals('123'));
      expect(fromMap.duration.inSeconds, equals(15));
    });
  });

  group('SplashScreen Widget Test', () {
    testWidgets('SplashScreen renders branding, tag, and equalizer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, child) {
            return const MaterialApp(
              home: SplashScreen(),
            );
          },
        ),
      );

      // Initial pump
      await tester.pump();

      // Verify branding text exists
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('CLINICAL SPEECH INTELLIGENCE'), findsOneWidget);
      expect(find.text('Precision Articulation & Speech Therapy'), findsOneWidget);

      // Advance timer partially to see animations
      await tester.pump(const Duration(milliseconds: 500));

      // Clean up widget tree to dispose controllers and cancel timers
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Session State Management on Logout', () {
    test('HomeCubit resets active tab and practice minutes on session clear', () {
      final cubit = HomeCubit();
      cubit.setTabIndex(4);
      cubit.incrementPracticeMinutes(25);

      expect(cubit.state.selectedIndex, equals(4));
      expect(cubit.state.minutesPracticed, equals(37));

      cubit.reset();

      expect(cubit.state.selectedIndex, equals(0));
      expect(cubit.state.minutesPracticed, equals(0));
    });
  });
}
