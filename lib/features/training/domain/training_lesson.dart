class TrainingLesson {
  final String id;
  final String title;
  final String description;
  final String durationMinutes;
  final bool isCompleted;
  final bool isLocked;
  final String techniquePrompt;
  final String videoFileName;
  final String videoUrl;
  final int points;
  final int dayNumber;
  final int exerciseIndex;

  const TrainingLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    this.isCompleted = false,
    this.isLocked = false,
    required this.techniquePrompt,
    this.videoFileName = '',
    this.videoUrl = '',
    this.points = 10,
    this.dayNumber = 1,
    this.exerciseIndex = 0,
  });

  TrainingLesson copyWith({
    String? id,
    String? title,
    String? description,
    String? durationMinutes,
    bool? isCompleted,
    bool? isLocked,
    String? techniquePrompt,
    String? videoFileName,
    String? videoUrl,
    int? points,
    int? dayNumber,
    int? exerciseIndex,
  }) {
    return TrainingLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
      techniquePrompt: techniquePrompt ?? this.techniquePrompt,
      videoFileName: videoFileName ?? this.videoFileName,
      videoUrl: videoUrl ?? this.videoUrl,
      points: points ?? this.points,
      dayNumber: dayNumber ?? this.dayNumber,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
    );
  }
}
