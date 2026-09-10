import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/audio/speech_analysis_service.dart';

enum RecordingState { initial, recording, processing, complete, error }

class SpeechRecordingViewModel extends ChangeNotifier {
  final SpeechAnalysisService _analysisService;
  final SupabaseClient _supabase;
  
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  RecordingState _state = RecordingState.initial;
  RecordingState get state => _state;

  int _recordingDuration = 0;
  int get recordingDuration => _recordingDuration;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _predictionResult;
  int? get predictionResult => _predictionResult;

  String? _filePath;
  bool _isRecorderInitialized = false;
  Timer? _timer;

  SpeechRecordingViewModel(this._analysisService, this._supabase);

  Future<void> initialize() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      try {
        await _recorder.openRecorder();
        _isRecorderInitialized = true;
      } catch (e) {
        _setError("Failed to initialize recorder: $e");
      }
    } else {
      _setError("Microphone permission is required.");
    }
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) {
      await initialize();
      if (!_isRecorderInitialized) return;
    }

    try {
      Directory tempDir = await getTemporaryDirectory();
      _filePath = '${tempDir.path}/audio_recording.wav';
      
      // Explicitly record in 16kHz Mono PCM WAV
      await _recorder.startRecorder(
        toFile: _filePath,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      
      _state = RecordingState.recording;
      _recordingDuration = 0;
      _errorMessage = null;
      _predictionResult = null;
      notifyListeners();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;
        notifyListeners();
      });
    } catch (e) {
      _setError("Failed to start recording: $e");
    }
  }

  Future<void> stopRecording() async {
    if (!_recorder.isRecording) return;

    try {
      await _recorder.stopRecorder();
      _timer?.cancel();
      
      if (_filePath == null || !File(_filePath!).existsSync()) {
        _setError("Recording failed to save.");
        return;
      }

      _state = RecordingState.processing;
      notifyListeners();
      
      // We wait for the UI to confirm upload or we upload immediately.
      // We will upload and predict immediately for a seamless UX.
      await _processAndUpload();

    } catch (e) {
      _setError("Failed to stop recording: $e");
    }
  }

  Future<void> _processAndUpload() async {
    if (_filePath == null) return;
    
    try {
      // 1. Run inference locally first
      _predictionResult = await _analysisService.analyzeSpeech(_filePath!);

      // 2. Upload to Supabase asynchronously
      _uploadToSupabase();

      _state = RecordingState.complete;
      notifyListeners();
    } catch (e) {
      _setError("Speech Analysis failed: $e");
    }
  }

  Future<void> _uploadToSupabase() async {
    try {
      File file = File(_filePath!);
      String username = FirebaseAuth.instance.currentUser?.displayName ??
          FirebaseAuth.instance.currentUser?.uid ??
          "Anonymous";
      String date = DateTime.now().toString().split(' ')[0];
      String filePathInBucket =
          'recordings/$username/$date/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      final response = await _supabase.storage
          .from('speech_recordings')
          .upload(filePathInBucket, file);

      if (response.isNotEmpty) {
        final publicUrl = _supabase.storage
            .from('speech_recordings')
            .getPublicUrl(filePathInBucket);

        await _supabase.from('speech_samples').insert({
          'audioUrl': publicUrl,
          'timestamp': DateTime.now().toIso8601String(),
          'username': username,
        });
      }
    } catch (e) {
      print("Background upload failed: $e");
    }
  }

  void reset() {
    _state = RecordingState.initial;
    _recordingDuration = 0;
    _errorMessage = null;
    _predictionResult = null;
    _timer?.cancel();
    notifyListeners();
  }

  void _setError(String msg) {
    _state = RecordingState.error;
    _errorMessage = msg;
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_recorder.isRecording) {
      _recorder.closeRecorder();
    }
    _timer?.cancel();
    super.dispose();
  }
}
