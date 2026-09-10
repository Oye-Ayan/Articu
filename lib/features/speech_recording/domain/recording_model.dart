class SpeechSampleModel {
  final String id;
  final String audioUrl;
  final DateTime timestamp;
  final String username;
  final Duration duration;

  const SpeechSampleModel({
    required this.id,
    required this.audioUrl,
    required this.timestamp,
    required this.username,
    this.duration = const Duration(seconds: 0),
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'audioUrl': audioUrl,
      'timestamp': timestamp.toIso8601String(),
      'username': username,
      'durationSeconds': duration.inSeconds,
    };
  }

  factory SpeechSampleModel.fromMap(Map<String, dynamic> map) {
    return SpeechSampleModel(
      id: map['id']?.toString() ?? '',
      audioUrl: map['audioUrl'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      username: map['username'] ?? 'Anonymous',
      duration: Duration(seconds: map['durationSeconds'] ?? 0),
    );
  }
}
