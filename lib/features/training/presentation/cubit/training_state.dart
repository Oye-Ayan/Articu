import '../../domain/training_lesson.dart';

class TrainingState {
  final int selectedDay;
  final List<TrainingLesson> lessons;
  final TrainingLesson? activeLesson;
  final int completedCount;
  final int streakDays;
  final int totalPoints;
  final bool isLoading;
  final String? errorMessage;
  final Map<int, DateTime> dayCompletionTimes;

  const TrainingState({
    this.selectedDay = 1,
    this.lessons = const [],
    this.activeLesson,
    this.completedCount = 0,
    this.streakDays = 1,
    this.totalPoints = 0,
    this.isLoading = false,
    this.errorMessage,
    this.dayCompletionTimes = const {},
  });

  TrainingState copyWith({
    int? selectedDay,
    List<TrainingLesson>? lessons,
    TrainingLesson? activeLesson,
    int? completedCount,
    int? streakDays,
    int? totalPoints,
    bool? isLoading,
    String? errorMessage,
    Map<int, DateTime>? dayCompletionTimes,
  }) {
    return TrainingState(
      selectedDay: selectedDay ?? this.selectedDay,
      lessons: lessons ?? this.lessons,
      activeLesson: activeLesson ?? this.activeLesson,
      completedCount: completedCount ?? this.completedCount,
      streakDays: streakDays ?? this.streakDays,
      totalPoints: totalPoints ?? this.totalPoints,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      dayCompletionTimes: dayCompletionTimes ?? this.dayCompletionTimes,
    );
  }
}
