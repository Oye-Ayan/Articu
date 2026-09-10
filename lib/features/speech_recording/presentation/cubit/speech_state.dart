import '../../domain/recording_model.dart';

class SpeechState {
  final bool isRecording;
  final bool isUploading;
  final Duration recordingDuration;
  final String? recordedFilePath;
  final String? lastUploadedUrl;
  final String? errorMessage;
  final String? successMessage;
  final List<SpeechSampleModel> recentRecordings;

  const SpeechState({
    this.isRecording = false,
    this.isUploading = false,
    this.recordingDuration = Duration.zero,
    this.recordedFilePath,
    this.lastUploadedUrl,
    this.errorMessage,
    this.successMessage,
    this.recentRecordings = const [],
  });

  SpeechState copyWith({
    bool? isRecording,
    bool? isUploading,
    Duration? recordingDuration,
    String? recordedFilePath,
    String? lastUploadedUrl,
    String? errorMessage,
    String? successMessage,
    List<SpeechSampleModel>? recentRecordings,
  }) {
    return SpeechState(
      isRecording: isRecording ?? this.isRecording,
      isUploading: isUploading ?? this.isUploading,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      recordedFilePath: recordedFilePath ?? this.recordedFilePath,
      lastUploadedUrl: lastUploadedUrl ?? this.lastUploadedUrl,
      errorMessage: errorMessage,
      successMessage: successMessage,
      recentRecordings: recentRecordings ?? this.recentRecordings,
    );
  }
}
