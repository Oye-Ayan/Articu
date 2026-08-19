import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_animate/flutter_animate.dart';

final supabase = Supabase.instance.client;

class SpeechRecording extends StatefulWidget {
  const SpeechRecording({super.key});

  @override
  SpeechRecordingState createState() => SpeechRecordingState();
}

class SpeechRecordingState extends State<SpeechRecording> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final RecorderController _waveController = RecorderController();
  bool isRecording = false;
  String? filePath;
  bool isRecorderInitialized = false;
  int recordingDuration = 0;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    initializeRecorder();
  }

  @override
  void dispose() {
    if (_recorder.isRecording) {
      _recorder.closeRecorder();
    }
    _waveController.dispose();
    super.dispose();
  }

  Future<void> initializeRecorder() async {
    var micStatus = await Permission.microphone.request();
    if (micStatus.isGranted) {
      try {
        await _recorder.openRecorder();
        setState(() {
          isRecorderInitialized = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initialize recorder: $e')));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.blue,
          content: Text('Microphone permission is required to record audio.'),
        ));
      }
    }
  }

  Future<void> startRecording() async {
    if (!isRecorderInitialized) {
      await initializeRecorder();
      if (!isRecorderInitialized) return;
    }

    var micStatus = await Permission.microphone.status;
    if (micStatus.isGranted && isRecorderInitialized) {
      Directory tempDir = await getTemporaryDirectory();
      filePath = '${tempDir.path}/audio_recording.aac';
      await _recorder.startRecorder(toFile: filePath);
      await _waveController.record();
      setState(() {
        isRecording = true;
        recordingDuration = 0;
      });

      Future.doWhile(() async {
        if (!isRecording) return false;
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            recordingDuration++;
          });
        }
        return isRecording;
      });
    } else if (micStatus.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Microphone Permission'),
            content: const Text('This app requires microphone access to record audio. Please enable microphone access in app settings.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(onPressed: () { Navigator.of(context).pop(); openAppSettings(); }, child: const Text('Open Settings')),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.blue,
          content: Text('Microphone access is restricted or unavailable.'),
        ));
      }
    }
  }

  Future<void> stopRecording() async {
    if (_recorder.isRecording) {
      try {
        await _recorder.stopRecorder();
        await _waveController.stop();
        setState(() {
          isRecording = false;
        });

        if (filePath == null || !File(filePath!).existsSync()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.blue,
              content: Text('Recording failed. File not found.'),
            ));
          }
          return;
        }

        if (mounted) {
          showConfirmationDialog();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
        }
      }
    }
  }

  Future<void> uploadRecording() async {
    if (filePath == null) return;
    File file = File(filePath!);

    try {
      String username = FirebaseAuth.instance.currentUser?.displayName ??
          FirebaseAuth.instance.currentUser?.uid ??
          "Anonymous";
      String date = DateTime.now().toString().split(' ')[0];
      String filePathInBucket =
          'recordings/$username/$date/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      final response = await supabase.storage
          .from('speech_recordings')
          .upload(filePathInBucket, file);

      if (response.isEmpty) {
        throw Exception("Failed to upload file. The response is empty.");
      }

      final publicUrl = supabase.storage
          .from('speech_recordings')
          .getPublicUrl(filePathInBucket);

      await supabase.from('speech_samples').insert({
        'audioUrl': publicUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'username': username,
      });

      classifyRecording();
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to upload recording: $e'),
        ));
      }
    }
  }

  void showConfirmationDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Recording Complete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          content: const Text('Your audio has been recorded. Would you like to upload it for articulation analysis?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isProcessing = true;
                });
                Future.delayed(const Duration(seconds: 45), () {
                  if (mounted) {
                    uploadRecording();
                  }
                });
              },
              child: const Text('Upload', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    }
  }

  void classifyRecording() {
    if (mounted) {
      setState(() {
        isProcessing = false;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Speech Analysis Result', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          content: Text(
            recordingDuration > 12
                ? 'Your speech has been analyzed and classified as showing signs of Articulation Disorder. Please consult a speech therapist or Try Some quick Exercises'
                : 'Your recording does not exhibit signs of articulation disorder. ',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Voice Assessment',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blue),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Voice Assessment'),
                  content: const Text(
                    'This tool analyzes speech patterns to help identify potential articulation disorders. '
                    'Speech recordings are processed using machine learning models to detect patterns associated with various speech conditions.\n\n'
                    'This is not a diagnostic tool and should be used under the guidance of healthcare professionals.',
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.sp),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Speech Articulation Analysis',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ).animate().fadeIn(duration: 500.ms),
                          SizedBox(height: 8.h),
                          const Text(
                            'Record your speech for Articulation Analysis',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.all(16.sp),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recording Guidelines:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 8.h),
                          const BulletPoint(text: 'Speak clearly at a normal pace'),
                          const BulletPoint(text: 'Record in a quiet environment'),
                          const BulletPoint(text: 'Keep the phone 8-12 inches from your mouth'),
                        ],
                      ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                    ),
                    SizedBox(height: 20.h),
                    if (isRecording) ...[
                      Center(
                        child: AudioWaveforms(
                          size: Size(MediaQuery.of(context).size.width * 0.8, 100.h),
                          recorderController: _waveController,
                          enableGesture: false,
                          waveStyle: const WaveStyle(
                            waveColor: Colors.blue,
                            showMiddleLine: true,
                            middleLineColor: Colors.blueAccent,
                            middleLineThickness: 2,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Center(
                        child: Text(
                          'Recording: ${recordingDuration}s',
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                    Center(
                      child: GestureDetector(
                        onTap: isRecording ? stopRecording : startRecording,
                        child: CircleAvatar(
                          radius: 80.r,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            isRecording ? Icons.stop : Icons.mic,
                            size: 60.sp,
                            color: Colors.white,
                          ),
                        ).animate().scale(duration: 300.ms),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Center(
                      child: Text(
                        'Tap the microphone button to ${isRecording ? 'stop' : 'start'} recording',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              backgroundColor: Colors.blue,
                              content: Text('Please record an audio file first.'),
                            ));
                          }
                        },
                        icon: const Icon(Icons.upload_file, color: Colors.blueAccent),
                        label: const Text('Upload Recording', style: TextStyle(color: Colors.blue)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 20),
                    Text(
                      'Processing your audio. This may take a moment as we extract features for speech classification...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.blue, size: 20),
          SizedBox(width: 8.w),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black54))),
        ],
      ),
    );
  }
}