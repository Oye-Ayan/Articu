import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/training_lesson.dart';
import 'training_state.dart';

class TrainingCubit extends Cubit<TrainingState> {
  final SupabaseService _supabaseService;
  final FirebaseAuth _firebaseAuth;
  StreamSubscription<User?>? _authSubscription;

  TrainingCubit({
    SupabaseService? supabaseService,
    FirebaseAuth? firebaseAuth,
  })  : _supabaseService = supabaseService ?? SupabaseService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(const TrainingState()) {
    initLessons();
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        refreshUserProgress();
      } else {
        clear();
      }
    });
  }

  /// Clears user training progress and resets to initial uncompleted drills on sign-out
  void clear() {
    final resetLessons =
        state.lessons.map((l) => l.copyWith(isCompleted: false)).toList();
    emit(state.copyWith(
      lessons: resetLessons,
      completedCount: 0,
      totalPoints: 0,
      selectedDay: 1,
      dayCompletionTimes: const {},
    ));
  }

  static const List<Map<String, String>> _videoCatalog = [
    {
      'title': 'Introduction & Posture Warmup',
      'fileName': 'Introduction.mp4',
      'duration': '40 secs',
      'description': 'Foundational posture alignment and diaphragmatic breathing preparation.',
      'techniquePrompt': 'Sit upright with shoulders relaxed. Take a steady deep breath into your diaphragm.',
    },
    {
      'title': 'Balloon Blowing Exercise',
      'fileName': 'Ballon Blowing.mp4',
      'duration': '10 secs',
      'description': 'Strengthening intraoral breath pressure and lip closure support.',
      'techniquePrompt': 'Gently inhale through your nose and blow out steadily with rounded lips as if inflating a balloon.',
    },
    {
      'title': "Let's Say the K Sound",
      'fileName': 'Lets Say the K sound.mp4',
      'duration': '30 secs',
      'description': 'Posterior velar tongue placement drill for crisp plosive articulation.',
      'techniquePrompt': 'Place the back of your tongue against your soft palate and release with a light burst: "K-K-K".',
    },
    {
      'title': "Let's Say the L Sound",
      'fileName': 'Lets say the L sound.mp4',
      'duration': '30 secs',
      'description': 'Alveolar ridge tongue-tip contact and lateral airflow practice.',
      'techniquePrompt': 'Gently place the tip of your tongue against the upper gum ridge behind your front teeth: "La-La-La".',
    },
    {
      'title': "Let's Say the S Sound",
      'fileName': 'Lets say the S sound.mp4',
      'duration': '30 secs',
      'description': 'Central grooved airflow and light friction articulation drill.',
      'techniquePrompt': 'Lightly align teeth and blow a steady continuous stream of air down the center of your tongue: "Sssss".',
    },
    {
      'title': 'Lip Trace Drill',
      'fileName': 'Lip Trace.mp4',
      'duration': '10 secs',
      'description': 'Orbicularis oris muscle flexibility and gentle lip seal awareness.',
      'techniquePrompt': 'Circle the tip of your tongue around your lips slowly, clockwise then counterclockwise.',
    },
    {
      'title': 'Tongue Clicks & Elevation',
      'fileName': 'Tongue Clicks.mp4',
      'duration': '10 secs',
      'description': 'Palatal suction release to build lingual strength and coordination.',
      'techniquePrompt': 'Suction the blade of your tongue to the roof of your mouth and pop it down with a crisp click.',
    },
    {
      'title': 'Tongue Lip Myofunctional Drill',
      'fileName': 'Tongue Lip myo.mp4',
      'duration': '10 secs',
      'description': 'Coordinated speech motor rate and articulatory endurance exercise.',
      'techniquePrompt': 'Alternate lip rounding with a wide gentle smile, coordinating with rhythmic breathing.',
    },
  ];

  Future<void> initLessons() async {
    emit(state.copyWith(isLoading: true));

    final baseLessons = <TrainingLesson>[];
    for (int i = 0; i < _videoCatalog.length; i++) {
      final item = _videoCatalog[i];
      final videoUrl = _supabaseService.getVideoPublicUrl(item['fileName']!);

      baseLessons.add(TrainingLesson(
        id: 'lesson_${state.selectedDay}_$i',
        title: item['title']!,
        description: item['description']!,
        durationMinutes: item['duration']!,
        videoFileName: item['fileName']!,
        videoUrl: videoUrl,
        points: 10,
        dayNumber: state.selectedDay,
        exerciseIndex: i,
        techniquePrompt: item['techniquePrompt']!,
        isCompleted: false,
        isLocked: false,
      ));
    }

    emit(state.copyWith(
      lessons: baseLessons,
      isLoading: false,
    ));

    await refreshUserProgress();
  }

  Future<void> refreshUserProgress() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch user training records for the selected day
      final progressRecords = await _supabaseService.fetchUserTrainingProgress(
        userId: user.uid,
        dayNumber: state.selectedDay,
      );

      final completedIndices = <int, bool>{};
      int pointsEarned = 0;

      for (final r in progressRecords) {
        final idx = r['exercise_index'] as int? ?? -1;
        final completed = r['completed'] as bool? ?? false;
        final pts = r['points'] as int? ?? 0;
        if (completed && idx >= 0) {
          completedIndices[idx] = true;
          pointsEarned += pts;
        }
      }

      // 2. Fetch day completion timestamps
      final dayRecords = await _supabaseService.fetchUserDayProgress(user.uid);
      final dayMap = <int, DateTime>{};
      for (final d in dayRecords) {
        final dayNum = d['day_number'] as int? ?? 1;
        final compAtStr = d['completed_at'] as String?;
        if (compAtStr != null) {
          final dt = DateTime.tryParse(compAtStr);
          if (dt != null) {
            dayMap[dayNum] = dt.toLocal();
          }
        }
      }

      // Update lessons completion status
      final updated = state.lessons.map((l) {
        final isDone = completedIndices[l.exerciseIndex] ?? false;
        return l.copyWith(isCompleted: isDone);
      }).toList();

      final completedCount = updated.where((l) => l.isCompleted).length;

      emit(state.copyWith(
        lessons: updated,
        completedCount: completedCount,
        totalPoints: pointsEarned,
        dayCompletionTimes: dayMap,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not sync progress: $e'));
    }
  }

  Future<void> selectDay(int day) async {
    emit(state.copyWith(selectedDay: day));
    await initLessons();
  }

  Future<void> markLessonCompleted(int exerciseIndex, {int points = 10}) async {
    final user = _firebaseAuth.currentUser;

    // Optimistically update UI
    final updated = state.lessons.map((l) {
      if (l.exerciseIndex == exerciseIndex) {
        return l.copyWith(isCompleted: true);
      }
      return l;
    }).toList();

    final completedCount = updated.where((l) => l.isCompleted).length;
    emit(state.copyWith(
      lessons: updated,
      completedCount: completedCount,
      totalPoints: state.totalPoints + points,
    ));

    if (user != null) {
      await _supabaseService.saveExerciseProgress(
        userId: user.uid,
        dayNumber: state.selectedDay,
        exerciseIndex: exerciseIndex,
        completed: true,
        points: points,
      );

      // Check if day is fully finished
      if (completedCount == updated.length && updated.isNotEmpty) {
        await _supabaseService.saveDayCompletion(
          userId: user.uid,
          dayNumber: state.selectedDay,
        );
        final map = Map<int, DateTime>.from(state.dayCompletionTimes);
        map[state.selectedDay] = DateTime.now();
        emit(state.copyWith(dayCompletionTimes: map));
      }
    }
  }

  bool isDayUnlocked(int dayNumber) {
    if (dayNumber <= 1) return true;
    final prevCompletedAt = state.dayCompletionTimes[dayNumber - 1];
    if (prevCompletedAt == null) return false;

    // Unlocked once previous day is marked complete or after cooldown
    return true;
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
