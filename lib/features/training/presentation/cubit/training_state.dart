import '../../domain/training_lesson.dart';

class TrainingState {
  final int selectedDay;
  final List<TrainingLesson> lessons;
  final TrainingLesson? activeLesson;
  final int completedCount;
  final int streakDays;

  const TrainingState({
    this.selectedDay = 1,
    this.lessons = const [],
    this.activeLesson,
    this.completedCount = 2,
    this.streakDays = 5,
  });

  TrainingState copyWith({
    int? selectedDay,
    List<TrainingLesson>? lessons,
    TrainingLesson? activeLesson,
    int? completedCount,
    int? streakDays,
  }) {
    return TrainingState(
      selectedDay: selectedDay ?? this.selectedDay,
      lessons: lessons ?? this.lessons,
      activeLesson: activeLesson ?? this.activeLesson,
      completedCount: completedCount ?? this.completedCount,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}
