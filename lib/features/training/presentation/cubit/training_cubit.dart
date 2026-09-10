import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/training_lesson.dart';
import 'training_state.dart';

class TrainingCubit extends Cubit<TrainingState> {
  TrainingCubit() : super(const TrainingState()) {
    _loadInitialLessons();
  }

  void _loadInitialLessons() {
    final defaultLessons = [
      const TrainingLesson(
        id: 'lesson-1',
        title: 'Introduction & Vocal Warmup',
        description: 'Diaphragmatic breathing and gentle vocal cord relaxation.',
        durationMinutes: '3 mins',
        isCompleted: true,
        isLocked: false,
        techniquePrompt:
            'Take a deep breath into your belly. Exhale slowly producing a steady "Aaaah" sound for 6 seconds.',
      ),
      const TrainingLesson(
        id: 'lesson-2',
        title: 'Flexible Rate Technique',
        description: 'Slowing down initial syllable transitions to prevent blocks.',
        durationMinutes: '2 mins',
        isCompleted: true,
        isLocked: false,
        techniquePrompt:
            'Pronounce each word by gently extending the primary vowel: "Sss-uuun-shiiine", "Mmm-oorr-niiing".',
      ),
      const TrainingLesson(
        id: 'lesson-3',
        title: 'Syllable Counting & Pacing',
        description: 'Establish a rhythmic cadence with finger-tapping pacing.',
        durationMinutes: '2 mins',
        isCompleted: false,
        isLocked: false,
        techniquePrompt:
            'Tap your index finger on your knee for every syllable: "Ar-ti-cu-li-Care leads to con-fi-dence".',
      ),
      const TrainingLesson(
        id: 'lesson-4',
        title: 'Light Articulatory Contacts',
        description: 'Soft touch on plosive consonants (P, B, T, D, K, G).',
        durationMinutes: '3 mins',
        isCompleted: false,
        isLocked: false,
        techniquePrompt:
            'Touch your lips together as softly as a feather when saying: "Peter baked fresh bread peacefully".',
      ),
      const TrainingLesson(
        id: 'lesson-5',
        title: 'Modeling & Echo Practice',
        description: 'Sentence shadowing with varied pitch and emphasis.',
        durationMinutes: '2 mins',
        isCompleted: false,
        isLocked: false,
        techniquePrompt:
            'Listen to the model phrase and repeat aloud matching intonation and pausing rhythm.',
      ),
      const TrainingLesson(
        id: 'lesson-6',
        title: 'Conversational Transfer',
        description: 'Applying smooth speech techniques in real conversation prompts.',
        durationMinutes: '3 mins',
        isCompleted: false,
        isLocked: true,
        techniquePrompt:
            'Describe your favorite vacation in 3 sentences using light articulatory contact.',
      ),
      const TrainingLesson(
        id: 'lesson-7',
        title: 'Session Summary & Mastery',
        description: 'Self-assessment and fluency milestone tracker.',
        durationMinutes: '1 min',
        isCompleted: false,
        isLocked: true,
        techniquePrompt:
            'Rate your ease of speaking on a 1-10 scale and review your daily streak.',
      ),
    ];

    emit(state.copyWith(
      lessons: defaultLessons,
      completedCount: defaultLessons.where((l) => l.isCompleted).length,
    ));
  }

  void selectDay(int day) {
    emit(state.copyWith(selectedDay: day));
  }

  void markLessonCompleted(String lessonId) {
    final updated = state.lessons.map((l) {
      if (l.id == lessonId) {
        return l.copyWith(isCompleted: true);
      }
      return l;
    }).toList();

    emit(state.copyWith(
      lessons: updated,
      completedCount: updated.where((l) => l.isCompleted).length,
    ));
  }
}
