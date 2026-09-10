import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/recording_model.dart';
import 'speech_state.dart';

class SpeechCubit extends Cubit<SpeechState> {
  final SupabaseService _supabaseService;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  Timer? _durationTimer;

  SpeechCubit({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService(),
        super(const SpeechState()) {
    _loadInitialMockRecordings();
  }

  void _loadInitialMockRecordings() {
    emit(state.copyWith(
      recentRecordings: [
        SpeechSampleModel(
          id: 'rec-1',
          audioUrl: '',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          username: 'You',
          duration: const Duration(seconds: 14),
        ),
        SpeechSampleModel(
          id: 'rec-2',
          audioUrl: '',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          username: 'You',
          duration: const Duration(seconds: 22),
        ),
      ],
    ));
  }

  Future<bool> _ensureRecorderInitialized() async {
    if (_isRecorderInitialized) return true;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      emit(state.copyWith(
        errorMessage: 'Microphone permission is required to record speech.',
      ));
      return false;
    }

    try {
      await _recorder.openRecorder();
      _isRecorderInitialized = true;
      return true;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to initialize audio recorder: $e',
      ));
      return false;
    }
  }

  Future<void> startRecording() async {
    final ready = await _ensureRecorderInitialized();
    if (!ready) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(toFile: path);

      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        emit(state.copyWith(
          recordingDuration: Duration(seconds: timer.tick),
        ));
      });

      emit(state.copyWith(
        isRecording: true,
        recordedFilePath: path,
        recordingDuration: Duration.zero,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isRecording: false,
        errorMessage: 'Could not start recording: $e',
      ));
    }
  }

  Future<void> stopRecording({required String username}) async {
    if (!_recorder.isRecording) return;

    try {
      _durationTimer?.cancel();
      await _recorder.stopRecorder();

      final currentDuration = state.recordingDuration;
      final filePath = state.recordedFilePath;

      emit(state.copyWith(
        isRecording: false,
      ));

      if (filePath != null && File(filePath).existsSync()) {
        await uploadRecording(
          filePath: filePath,
          username: username,
          duration: currentDuration,
        );
      }
    } catch (e) {
      emit(state.copyWith(
        isRecording: false,
        errorMessage: 'Error stopping recorder: $e',
      ));
    }
  }

  Future<void> uploadRecording({
    required String filePath,
    required String username,
    required Duration duration,
  }) async {
    emit(state.copyWith(isUploading: true, errorMessage: null));

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final safeUsername = username.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final storagePath =
          'recordings/$safeUsername/$dateStr/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      final publicUrl = await _supabaseService.uploadBinaryFile(
        bucket: AppConstants.speechRecordingsBucket,
        path: storagePath,
        bytes: bytes,
      );

      await _supabaseService.saveSpeechSample(
        audioUrl: publicUrl,
        username: username,
      );

      final newSample = SpeechSampleModel(
        id: 'sample_${DateTime.now().millisecondsSinceEpoch}',
        audioUrl: publicUrl,
        timestamp: DateTime.now(),
        username: username,
        duration: duration,
      );

      emit(state.copyWith(
        isUploading: false,
        lastUploadedUrl: publicUrl,
        successMessage: 'Speech sample uploaded and analyzed successfully!',
        recentRecordings: [newSample, ...state.recentRecordings],
      ));
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        errorMessage: 'Upload failed: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _durationTimer?.cancel();
    if (_recorder.isRecording) {
      _recorder.stopRecorder();
    }
    _recorder.closeRecorder();
    return super.close();
  }
}
