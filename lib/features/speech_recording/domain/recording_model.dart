class SpeechSampleModel {
  final String id;
  final String audioUrl;
  final DateTime timestamp;
  final String username;
  final Duration duration;
  final String? filePath;
  final String? analysisResult;
  final String? userId;

  const SpeechSampleModel({
    required this.id,
    required this.audioUrl,
    required this.timestamp,
    required this.username,
    this.duration = const Duration(seconds: 0),
    this.filePath,
    this.analysisResult,
    this.userId,
  });

  String get title => 'Speech Sample #$id';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'audioUrl': audioUrl,
      'timestamp': timestamp.toIso8601String(),
      'username': username,
      'duration_seconds': duration.inSeconds.toString(),
      'file_path': filePath,
      'analysis_result': analysisResult,
      'user_id': userId,
    };
  }

  factory SpeechSampleModel.fromMap(Map<String, dynamic> map) {
    int parsedDuration = 0;
    final durVal = map['duration_seconds'] ?? map['durationSeconds'];
    if (durVal is int) {
      parsedDuration = durVal;
    } else if (durVal is String) {
      parsedDuration = int.tryParse(durVal) ?? 0;
    }

    return SpeechSampleModel(
      id: map['id']?.toString() ?? '',
      audioUrl: map['audioUrl'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      username: map['username'] ?? 'Anonymous',
      duration: Duration(seconds: parsedDuration),
      filePath: map['file_path'] ?? map['filePath'],
      analysisResult: map['analysis_result'] ?? map['analysisResult'],
      userId: map['user_id']?.toString() ?? map['userId']?.toString(),
    );
  }
}
