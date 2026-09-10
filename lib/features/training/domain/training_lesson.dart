class TrainingLesson {
  final String id;
  final String title;
  final String description;
  final String durationMinutes;
  final bool isCompleted;
  final bool isLocked;
  final String techniquePrompt;

  const TrainingLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    this.isCompleted = false,
    this.isLocked = false,
    required this.techniquePrompt,
  });

  TrainingLesson copyWith({
    String? id,
    String? title,
    String? description,
    String? durationMinutes,
    bool? isCompleted,
    bool? isLocked,
    String? techniquePrompt,
  }) {
    return TrainingLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
      techniquePrompt: techniquePrompt ?? this.techniquePrompt,
    );
  }
}
