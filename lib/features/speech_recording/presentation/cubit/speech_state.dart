import '../../domain/recording_model.dart';

class SpeechState {
  final bool isRecording;
  final bool isUploading;
  final bool isLoadingRecordings;
  final Duration recordingDuration;
  final String? recordedFilePath;
  final String? lastUploadedUrl;
  final String? errorMessage;
  final String? successMessage;
  final List<SpeechSampleModel> recentRecordings;

  // Audio Playback State
  final String? currentlyPlayingId;
  final bool isPlayingAudio;
  final Duration playbackPosition;
  final Duration playbackDuration;

  // Search Filter
  final String searchQuery;

  const SpeechState({
    this.isRecording = false,
    this.isUploading = false,
    this.isLoadingRecordings = false,
    this.recordingDuration = Duration.zero,
    this.recordedFilePath,
    this.lastUploadedUrl,
    this.errorMessage,
    this.successMessage,
    this.recentRecordings = const [],
    this.currentlyPlayingId,
    this.isPlayingAudio = false,
    this.playbackPosition = Duration.zero,
    this.playbackDuration = Duration.zero,
    this.searchQuery = '',
  });

  List<SpeechSampleModel> get filteredRecordings {
    if (searchQuery.trim().isEmpty) return recentRecordings;
    final q = searchQuery.toLowerCase().trim();
    return recentRecordings.where((r) {
      final matchesId = r.id.toLowerCase().contains(q);
      final matchesUser = r.username.toLowerCase().contains(q);
      final matchesTitle = r.title.toLowerCase().contains(q);
      final matchesAnalysis =
          (r.analysisResult ?? '').toLowerCase().contains(q);
      return matchesId || matchesUser || matchesTitle || matchesAnalysis;
    }).toList();
  }

  SpeechState copyWith({
    bool? isRecording,
    bool? isUploading,
    bool? isLoadingRecordings,
    Duration? recordingDuration,
    String? recordedFilePath,
    String? lastUploadedUrl,
    String? errorMessage,
    String? successMessage,
    List<SpeechSampleModel>? recentRecordings,
    String? currentlyPlayingId,
    bool? isPlayingAudio,
    Duration? playbackPosition,
    Duration? playbackDuration,
    String? searchQuery,
  }) {
    return SpeechState(
      isRecording: isRecording ?? this.isRecording,
      isUploading: isUploading ?? this.isUploading,
      isLoadingRecordings: isLoadingRecordings ?? this.isLoadingRecordings,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      recordedFilePath: recordedFilePath ?? this.recordedFilePath,
      lastUploadedUrl: lastUploadedUrl ?? this.lastUploadedUrl,
      errorMessage: errorMessage,
      successMessage: successMessage,
      recentRecordings: recentRecordings ?? this.recentRecordings,
      currentlyPlayingId: currentlyPlayingId ?? this.currentlyPlayingId,
      isPlayingAudio: isPlayingAudio ?? this.isPlayingAudio,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      playbackDuration: playbackDuration ?? this.playbackDuration,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
