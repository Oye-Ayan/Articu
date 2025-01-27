import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class SpeechRecording extends StatefulWidget {
  @override
  _SpeechRecordingState createState() => _SpeechRecordingState();
}

class _SpeechRecordingState extends State<SpeechRecording> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool isRecording = false;
  String? filePath;

  bool isRecorderInitialized = false;

  @override
  void dispose() {
    if (_recorder.isRecording) {
      _recorder.closeRecorder();
    }
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
    // If denied, show a dialog to request permission
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
    // If permission is permanently denied, show a dialog asking to open settings
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Microphone Permission'),
          content: Text(
            'This app requires microphone access to record audio. Please enable microphone access in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); 
              },
              child: Text('Open Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
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
    
    uploadRecording();
      } catch (e) {
        print("Failed to stop recorder: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to stop recording: $e'),
        ));
      }
    } else {
      print("Recorder not open.");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Recorder is not open.'),
      ));
    }
  }

  // Future<void> uploadRecording() async {
  //   if (filePath == null) return;

  //   File file = File(filePath!);

  //   try {
  //     List<int> bytes = await file.readAsBytes();
  //     String base64Audio = base64Encode(bytes);

  //     String username =
  //         FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.uid ?? "Anonymous";

  //     await FirebaseFirestore.instance.collection('recordings').add({
  //       'audioData': base64Audio,
  //       'timestamp': FieldValue.serverTimestamp(),
  //       'username': username,
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.blue,
  //       content: Text('Recording uploaded and saved to Firestore!'),
  //     ));
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       backgroundColor: Colors.blue,
  //       content: Text('Failed to upload recording: $e'),
  //     ));
  //   }
  // }

final supabase = Supabase.instance.client;
Future<void> uploadRecording() async {
    if (filePath == null) return;

    File file = File(filePath!);

    try {
      String username = FirebaseAuth.instance.currentUser?.displayName ??
          FirebaseAuth.instance.currentUser?.uid ??
          "Anonymous";
      String date = DateTime.now().toString().split(' ')[0]; // Format: YYYY-MM-DD
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
                  prefixIcon:const Icon(Icons.search),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide:  BorderSide(color: Colors.blue.shade200, width: 1),
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
                  onPressed: (){
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