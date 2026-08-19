import 'package:articulicare/pages/model_inference.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SpeechRecordingPage extends StatefulWidget {
  const SpeechRecordingPage({super.key});

  @override
  _SpeechRecordingPageState createState() => _SpeechRecordingPageState();
}

class _SpeechRecordingPageState extends State<SpeechRecordingPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool isRecording = false;
  String? filePath;
  bool isRecorderInitialized = false;
  late ModelInference modelInference;

  @override
  void initState() {
    super.initState();
    modelInference = ModelInference();
    modelInference.loadModel(); // Load model on startup
  }

  @override
  void dispose() {
    if (_recorder.isRecording) {
      _recorder.closeRecorder();
    }
    modelInference.close(); // Close the model interpreter
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
        print("Recorder initialized successfully.");
      } catch (e) {
        print("Failed to initialize recorder: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to initialize recorder: $e'),
        ));
      }
    } else {
      print("Microphone permission not granted.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.blue,
        content: Text('Microphone permission is required to record audio.'),
      ));
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
      setState(() {
        isRecording = true;
      });
    } else if (micStatus.isDenied) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        Directory tempDir = await getTemporaryDirectory();
        filePath = '${tempDir.path}/audio_recording.aac';
        await _recorder.startRecorder(toFile: filePath);
        setState(() {
          isRecording = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.blue,
          content: Text('Microphone permission is required to record audio.'),
        ));
      }
    } else if (micStatus.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Microphone Permission'),
            content: const Text(
              'This app requires microphone access to record audio. Please enable microphone access in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings(); 
                },
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.blue,
        content: Text('Microphone access is restricted or unavailable.'),
      ));
    }
  }

  Future<void> stopRecording() async {
    if (_recorder.isRecording) {
      try {
        await _recorder.stopRecorder();
        setState(() {
          isRecording = false;
        });

        if (filePath == null || !File(filePath!).existsSync()) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.blue,
            content: Text('Recording failed. File not found.'),
          ));
          return;
        }

        List<List<List<double>>> mfcc = await extractMFCC(filePath!);
        String prediction = await modelInference.predict(mfcc);
        showPrediction(prediction);

        uploadRecording();
      } catch (e) {
        print("Failed to stop recorder: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to stop recording: $e'),
        ));
      }
    } else {
      print("Recorder not open.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Recorder is not open.'),
      ));
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
      print('Public URL of the uploaded file: $publicUrl');

      await supabase.from('speech_samples').insert({
        'audioUrl': publicUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'username': username,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.blue,
        content: Text('Recording uploaded and saved to Supabase! ✔'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Failed to upload recording: $e'),
      ));
    }
  }

  Future<List<List<List<double>>>> extractMFCC(String filePath) async {
    
    return [[[0.1, 0.2, 0.3], [0.2, 0.3, 0.4], [0.3, 0.4, 0.5]]];
  }

  void showPrediction(String prediction) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(prediction)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Voice Recorder',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Recordings',
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.h),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search Recordings",
                    prefixIcon: const Icon(Icons.search),
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.blue.shade200, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Colors.blue, width: 1),
                    ),
                  ),
                  cursorColor: Colors.blueAccent,
                ),
                SizedBox(height: 20.h),
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
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: Colors.blue,
                      content: Text('Cannot upload file. Please record a file first.'),
                    ));
                  },
                  icon: const Icon(Icons.upload_file, color: Colors.blueAccent),
                  label: const Text(
                    'Upload File',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}