import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/recording_model.dart';
import 'speech_state.dart';

class SpeechCubit extends Cubit<SpeechState> {
  final SupabaseService _supabaseService;
  final FirebaseAuth _firebaseAuth;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecorderInitialized = false;
  Timer? _durationTimer;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _completeSubscription;
  StreamSubscription<User?>? _authSubscription;

  SpeechCubit({
    SupabaseService? supabaseService,
    FirebaseAuth? firebaseAuth,
  })  : _supabaseService = supabaseService ?? SupabaseService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(const SpeechState()) {
    _initAudioPlayerListeners();
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        fetchLiveRecordings();
      } else {
        clear();
      }
    });
  }

  /// Clears speech recordings and resets state completely on sign-out
  void clear() {
    _audioPlayer.stop();
    emit(const SpeechState());
  }

  void _initAudioPlayerListeners() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((pState) {
      final isPlaying = pState == PlayerState.playing;
      emit(state.copyWith(isPlayingAudio: isPlaying));
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      emit(state.copyWith(playbackPosition: pos));
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((dur) {
      emit(state.copyWith(playbackDuration: dur));
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      emit(state.copyWith(
        isPlayingAudio: false,
        currentlyPlayingId: null,
        playbackPosition: Duration.zero,
      ));
    });
  }

  Future<void> fetchLiveRecordings() async {
    final user = _firebaseAuth.currentUser;
    final userId = user?.uid ?? '';
    final username = user?.displayName;

    emit(state.copyWith(isLoadingRecordings: true));
    try {
      final rows = await _supabaseService.fetchSpeechSamples(
        userId: userId,
        username: username,
      );
      final samples = rows.map((m) => SpeechSampleModel.fromMap(m)).toList();

      emit(state.copyWith(
        recentRecordings: samples,
        isLoadingRecordings: false,
      ));
    } catch (e) {
      debugPrint('Error fetching speech samples: $e');
      emit(state.copyWith(
        isLoadingRecordings: false,
        errorMessage: 'Could not load speech samples from cloud.',
      ));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
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
    // Stop any active audio playback before recording
    if (state.isPlayingAudio) {
      await stopAudio();
    }

    final ready = await _ensureRecorderInitialized();
    if (!ready) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

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

      emit(state.copyWith(isRecording: false));

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
      final user = _firebaseAuth.currentUser;
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final safeUsername = username.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final storagePath =
          'recordings/$safeUsername/$dateStr/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      final publicUrl = await _supabaseService.uploadBinaryFile(
        bucket: AppConstants.speechRecordingsBucket,
        path: storagePath,
        bytes: bytes,
      );

      await _supabaseService.saveSpeechSample(
        audioUrl: publicUrl,
        username: username,
        userId: user?.uid,
        durationSeconds: duration.inSeconds.toString(),
        filePath: storagePath,
      );

      final newSample = SpeechSampleModel(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        audioUrl: publicUrl,
        timestamp: DateTime.now(),
        username: username,
        duration: duration,
        filePath: storagePath,
        userId: user?.uid,
      );

      emit(state.copyWith(
        isUploading: false,
        lastUploadedUrl: publicUrl,
        successMessage: 'Speech sample uploaded and saved to Supabase! ✔',
        recentRecordings: [newSample, ...state.recentRecordings],
      ));
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        errorMessage: 'Upload failed: $e',
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Audio Playback Controls
  // ---------------------------------------------------------------------------

  Future<void> togglePlayAudio(SpeechSampleModel sample) async {
    try {
      if (state.currentlyPlayingId == sample.id) {
        if (state.isPlayingAudio) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.resume();
        }
      } else {
        await _audioPlayer.stop();

        emit(state.copyWith(
          currentlyPlayingId: sample.id,
          playbackPosition: Duration.zero,
          playbackDuration: sample.duration,
        ));

        if (sample.audioUrl.isNotEmpty && sample.audioUrl.startsWith('http')) {
          await _audioPlayer.play(UrlSource(sample.audioUrl));
        } else if (sample.filePath != null && File(sample.filePath!).existsSync()) {
          await _audioPlayer.play(DeviceFileSource(sample.filePath!));
        } else {
          emit(state.copyWith(
            errorMessage: 'Audio source unavailable for playback.',
            currentlyPlayingId: null,
          ));
        }
      }
    } catch (e) {
      debugPrint('Playback error: $e');
      emit(state.copyWith(
        errorMessage: 'Could not play audio: $e',
        currentlyPlayingId: null,
        isPlayingAudio: false,
      ));
    }
  }

  Future<void> seekAudio(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Seek error: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      emit(state.copyWith(
        isPlayingAudio: false,
        currentlyPlayingId: null,
        playbackPosition: Duration.zero,
      ));
    } catch (e) {
      debugPrint('Stop audio error: $e');
    }
  }

  @override
  Future<void> close() {
    _durationTimer?.cancel();
    _authSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();
    if (_recorder.isRecording) {
      _recorder.stopRecorder();
    }
    _recorder.closeRecorder();
    return super.close();
  }
}
