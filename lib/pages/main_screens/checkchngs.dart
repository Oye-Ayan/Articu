// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// class SpeechRecording extends StatefulWidget {
//   @override
//   _SpeechRecordingState createState() => _SpeechRecordingState();
// }

// class _SpeechRecordingState extends State<SpeechRecording> {
//   final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
//   bool isRecording = false;
//   String? filePath;

//   bool isRecorderInitialized = false;

//   @override
//   void dispose() {
//     if (_recorder.isRecording) {
//       _recorder.closeRecorder();
//     }
//     super.dispose();
//   }

//   Future<void> initializeRecorder() async {
//     var micStatus = await Permission.microphone.request();

//     if (micStatus.isGranted) {
//       try {
//         await _recorder.openRecorder();
//         setState(() {
//           isRecorderInitialized = true; 
//         });
//         print("Recorder initialized successfully.");
//       } catch (e) {
//         print("Failed to initialize recorder: $e");
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Failed to initialize recorder: $e'),
//         ));
//       }
//     } else {
//       print("Microphone permission not granted.");
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         backgroundColor: Colors.blue,
//         content: Text('Microphone permission is required to record audio.'),
//       ));
//     }
//   }


  
//   Future<void> startRecording() async {
//   if (!isRecorderInitialized) {
//     await initializeRecorder();
//     if (!isRecorderInitialized) return;
//   }

//   var micStatus = await Permission.microphone.status;

//   if (micStatus.isGranted && isRecorderInitialized) {
    
//     Directory tempDir = await getTemporaryDirectory();
//     filePath = '${tempDir.path}/audio_recording.aac';
//     await _recorder.startRecorder(toFile: filePath);
//     setState(() {
//       isRecording = true;
//     });
//   } else if (micStatus.isDenied) {
//     // If denied, show a dialog to request permission
//     var status = await Permission.microphone.request();
//     if (status.isGranted) {
//       Directory tempDir = await getTemporaryDirectory();
//       filePath = '${tempDir.path}/audio_recording.aac';
//       await _recorder.startRecorder(toFile: filePath);
//       setState(() {
//         isRecording = true;
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         backgroundColor: Colors.blue,
//         content: Text('Microphone permission is required to record audio.'),
//       ));
//     }
//   } else if (micStatus.isPermanentlyDenied) {
//     // If permission is permanently denied, show a dialog asking to open settings
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Microphone Permission'),
//           content: Text(
//             'This app requires microphone access to record audio. Please enable microphone access in app settings.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 openAppSettings(); 
//               },
//               child: Text('Open Settings'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Cancel'),
//             ),
//           ],
//         );
//       },
//     );
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//       backgroundColor: Colors.blue,
//       content: Text('Microphone access is restricted or unavailable.'),
//     ));
//   }
// }



//   Future<void> stopRecording() async {
//     if (_recorder.isRecording) {
//       try {
//         await _recorder.stopRecorder();
//         setState(() {
//           isRecording = false;
//         });

//         if (filePath == null || !File(filePath!).existsSync()) {
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//             backgroundColor: Colors.blue,
//             content: Text('Recording failed. File not found.'),
//           ));
//           return;
//         }
    
//     uploadRecording();
//       } catch (e) {
//         print("Failed to stop recorder: $e");
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Failed to stop recording: $e'),
//         ));
//       }
//     } else {
//       print("Recorder not open.");
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Recorder is not open.'),
//       ));
//     }
//   }

//   // Future<void> uploadRecording() async {
//   //   if (filePath == null) return;

//   //   File file = File(filePath!);

//   //   try {
//   //     List<int> bytes = await file.readAsBytes();
//   //     String base64Audio = base64Encode(bytes);

//   //     String username =
//   //         FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.uid ?? "Anonymous";

//   //     await FirebaseFirestore.instance.collection('recordings').add({
//   //       'audioData': base64Audio,
//   //       'timestamp': FieldValue.serverTimestamp(),
//   //       'username': username,
//   //     });

//   //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.blue,
//   //       content: Text('Recording uploaded and saved to Firestore!'),
//   //     ));
//   //   } catch (e) {
//   //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//   //       backgroundColor: Colors.blue,
//   //       content: Text('Failed to upload recording: $e'),
//   //     ));
//   //   }
//   // }

// final supabase = Supabase.instance.client;
// Future<void> uploadRecording() async {
//     if (filePath == null) return;

//     File file = File(filePath!);

//     try {
//       String username = FirebaseAuth.instance.currentUser?.displayName ??
//           FirebaseAuth.instance.currentUser?.uid ??
//           "Anonymous";
//       String date = DateTime.now().toString().split(' ')[0]; // Format: YYYY-MM-DD
//       String filePathInBucket =
//           'recordings/$username/$date/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

//       final response = await supabase.storage
//           .from('speech_recordings')
//           .upload(filePathInBucket, file);

//       if (response.isEmpty) {
//         throw Exception("Failed to upload file. The response is empty.");
//       }

//       final publicUrl = supabase.storage
//           .from('speech_recordings')
//           .getPublicUrl(filePathInBucket);
//       print('Public URL of the uploaded file: $publicUrl');

//       await supabase.from('speech_samples').insert({
//         'audioUrl': publicUrl,
//         'timestamp': DateTime.now().toIso8601String(),
//         'username': username,
//       });

//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         backgroundColor: Colors.blue,
//         content: Text('Recording uploaded and saved to Supabase! ✔'),
//       ));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         backgroundColor: Colors.red,
//         content: Text('Failed to upload recording: $e'),
//       ));
//     }
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,
//         centerTitle: true,
//         title: Text(
//           'Voice Recorder',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 18.sp,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(16.sp),
//           child: SafeArea(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Text(
//                   'Recordings',
//                   style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 10.h),
//                 TextField(
//                   decoration: InputDecoration(
//                   hintText: "Search Recordings",
//                   prefixIcon:const Icon(Icons.search),
//                   hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.r),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.r),
//                     borderSide:  BorderSide(color: Colors.blue.shade200, width: 1),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.r),
//                     borderSide: const BorderSide(color: Colors.blue, width: 1),
//                   ),
//                 ),
//                 cursorColor: Colors.blueAccent,
//               ),
//                 SizedBox(height: 20.h),
//                 Center(
//                   child: GestureDetector(
//                     onTap: isRecording ? stopRecording : startRecording,
//                     child: CircleAvatar(
//                       radius: 80.r,
//                       backgroundColor: Colors.blue,
//                       child: Icon(
//                         isRecording ? Icons.stop : Icons.mic,
//                         size: 60.sp,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20.h),
//                 ElevatedButton.icon(
//                   onPressed: (){
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                       backgroundColor: Colors.blue,
//                       content: Text('Cannot upload file. Please record a file first.'),
//                     ));
//                   },
//                   icon: const Icon(Icons.upload_file, color: Colors.blueAccent),
//                   label: const Text(
//                     'Upload File',
//                     style: TextStyle(color: Colors.blue),
//                   ),
//                 ),

//              ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


//// WORKING CODE FOR TRAINING PAGE
///import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:video_player/video_player.dart';
// import '../../components/my_button.dart';

// class TrainingPage extends StatefulWidget {
//   final Function(String)? onNavigate; // Callback for navigation
//   const TrainingPage({super.key, this.onNavigate});

//   @override
//   State<TrainingPage> createState() => _TrainingPageState();
// }

// class _TrainingPageState extends State<TrainingPage> {
//   int? _selectedIndex; // Track selected list item
//   VideoPlayerController? _videoPlayerController; // Video player controller
//   bool _isPlaying = false; // Track play/pause state
//   final SupabaseClient _supabase = Supabase.instance.client;

//   // Function to show beta dialog
//   void _showBetaDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Beta Version'),
//           content: const Text('Beta version. Complete Module is not available at the moment.'),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('OK', style: TextStyle(color: Colors.blue)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Function to fetch video URL from Supabase and initialize video player
//   Future<void> _playVideo(String videoFileName) async {
//     try {
//       // Generate a signed URL valid for 1 hour
//       final String videoUrl = await _supabase.storage
//     .from('training-videos')
//     .getPublicUrl(videoFileName);
//       print('Video URL for $videoFileName: $videoUrl'); // Debug log

//       // Initialize video player
//       _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
//         ..addListener(() {
//           setState(() {}); // Update UI for play/pause state
//         });
//       await _videoPlayerController!.initialize();

//       // Show video player in a dialog
//       setState(() {
//         _isPlaying = false; // Start paused
//       });

//       await showDialog(
//         context: context,
//         builder: (context) => Dialog(
//           backgroundColor: Colors.black,
//           insetPadding: EdgeInsets.zero,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               // Video player
//               AspectRatio(
//                 aspectRatio: _videoPlayerController!.value.aspectRatio,
//                 child: _videoPlayerController!.value.isInitialized
//                     ? VideoPlayer(_videoPlayerController!)
//                     : const Center(child: CircularProgressIndicator()),
//               ),
//               // Custom controls overlay
//               Positioned.fill(
//                 child: GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _isPlaying
//                           ? _videoPlayerController!.pause()
//                           : _videoPlayerController!.play();
//                       _isPlaying = !_isPlaying;
//                     });
//                   },
//                   child: Container(
//                     color: Colors.transparent,
//                     child: Center(
//                       child: _isPlaying
//                           ? const SizedBox.shrink()
//                           : Icon(
//                               Icons.play_circle_filled,
//                               color: Colors.white.withOpacity(0.8),
//                               size: 64.sp,
//                             ),
//                     ),
//                   ),
//                 ),
//               ),
//               // Progress bar
//               Positioned(
//                 bottom: 10.h,
//                 left: 10.w,
//                 right: 10.w,
//                 child: VideoProgressIndicator(
//                   _videoPlayerController!,
//                   allowScrubbing: true,
//                   colors: const VideoProgressColors(
//                     playedColor: Colors.blue,
//                     bufferedColor: Colors.grey,
//                     backgroundColor: Colors.grey,
//                   ),
//                 ),
//               ),
//               // Additional controls
//               Positioned(
//                 bottom: 50.h,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.replay_10, color: Colors.white, size: 24.sp),
//                       onPressed: () {
//                         final current = _videoPlayerController!.value.position;
//                         _videoPlayerController!.seekTo(current - const Duration(seconds: 10));
//                       },
//                     ),
//                     IconButton(
//                       icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 24.sp),
//                       onPressed: () {
//                         setState(() {
//                           _isPlaying ? _videoPlayerController!.pause() : _videoPlayerController!.play();
//                           _isPlaying = !_isPlaying;
//                         });
//                       },
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.forward_10, color: Colors.white, size: 24.sp),
//                       onPressed: () {
//                         final current = _videoPlayerController!.value.position;
//                         _videoPlayerController!.seekTo(current + const Duration(seconds: 10));
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );

//       // Dispose controller after dialog is closed
//       _videoPlayerController?.dispose();
//       setState(() {
//         _videoPlayerController = null;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error loading video: $e', ),backgroundColor: Colors.blue,
//           action: SnackBarAction(
//             label: 'Retry',
//             onPressed: () => _playVideo(videoFileName),
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _videoPlayerController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final List<String> titles = [
//       "Introduction", // Moved to first position
//       "Ballon Blowing",
//       "Lets Say the K sound",
//       "Lets say the L sound",
//       "Lets say the S sound",
//       "Lip Trace",
//       "Tongue Clicks",
//       "Tongue Lip myo"
//     ];
//     final List<String> times = [
//       "3 mins", // Adjusted for Introduction
//       "2 mins",
//       "2 mins",
//       "2 mins",
//       "2 mins",
//       "3 mins",
//       "2 mins",
//       "1 min"
//     ];
//     final List<String> videoFiles = [
//       "Introduction.mp4", // Moved to first position
//       "Ballon Blowing.mp4",
//       "Lets Say the K sound.mp4",
//       "Lets say the L sound.mp4",
//       "Lets say the S sound.mp4",
//       "Lip Trace.mp4",
//       "Tongue Clicks.mp4",
//       "Tongue Lip myo.mp4"
//     ];

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: true,
//         title: Text(
//           'Daily Practice',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 18.sp,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info_outline, color: Colors.black),
//             onPressed: _showBetaDialog,
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               height: 50.h,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: 5,
//                 itemBuilder: (context, index) {
//                   if (index == 0) {
//                     return CircleAvatar(
//                       radius: 25.r,
//                       backgroundColor: Colors.blue[700],
//                       child: Text(
//                         '01',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     );
//                   } else {
//                     return Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 10.w),
//                       child: CircleAvatar(
//                         radius: 25.r,
//                         backgroundColor: Colors.grey[300],
//                         child: Icon(
//                           Icons.lock,
//                           color: Colors.grey,
//                           size: 18.sp,
//                         ),
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ),
//             SizedBox(height: 10.h),
//             Align(
//               alignment: Alignment.centerRight,
//               child: Text(
//                 'View All',
//                 style: TextStyle(
//                   color: Colors.blue,
//                   fontSize: 14.sp,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             SizedBox(height: 10.h),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: titles.length,
//                 itemBuilder: (context, index) {
//                   return ListTile(
//                     onTap: () {
//                       setState(() {
//                         _selectedIndex = index; // Highlight selected item
//                       });
//                     },
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.blue.shade100,
//                       child: Icon(Icons.card_giftcard, color: Colors.blue.shade700),
//                     ),
//                     title: Text(
//                       titles[index],
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
//                         color: _selectedIndex == index ? Colors.blue : Colors.grey[700],
//                       ),
//                     ),
//                     subtitle: Text(
//                       times[index],
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         color: Colors.grey[500],
//                       ),
//                     ),
//                     trailing: _selectedIndex == index
//                         ? IconButton(
//                             icon: Icon(Icons.play_circle_filled, color: Colors.blue, size: 24.sp),
//                             onPressed: () => _playVideo(videoFiles[index]),
//                           )
//                         : null,
//                   );
//                 },
//               ),
//             ),
//             SizedBox(height: 10.h),
//             Center(
//               child: MyButton(
//                 onTap: _showBetaDialog,
//                 text: 'Start Practice',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




//  SpeechRecording



/////// 
///
///<manifest xmlns:android="http://schemas.android.com/apk/res/android">

//     <!-- Permissions for notifications -->
//     <uses-permission android:name="android.permission.VIBRATE"/>
//     <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
//     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

//     <!-- Permissions for storage and camera -->
//     <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
//     <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
//     <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
//     <uses-permission android:name="android.permission.CAMERA"/>

//     <!-- Permissions for network -->
//     <uses-permission android:name="android.permission.INTERNET"/>
//     <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    

    
//     <application
//         android:label="articulicare"
//         android:requestLegacyExternalStorage="true"
//         android:name="${applicationName}"
//         android:icon="@mipmap/ic_launcher">
//         <activity
//             android:name=".MainActivity"
//             android:exported="true"
//             android:launchMode="singleTop"
//             android:taskAffinity=""
//             android:theme="@style/LaunchTheme"
//             android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
//             android:hardwareAccelerated="true"
//             android:windowSoftInputMode="adjustResize">
//             <!-- Specifies an Android theme to apply to this Activity as soon as
//                  the Android process has started. This theme is visible to the user
//                  while the Flutter UI initializes. After that, this theme continues
//                  to determine the Window background behind the Flutter UI. -->
//             <meta-data
//               android:name="io.flutter.embedding.android.NormalTheme"
//               android:resource="@style/NormalTheme"
//               />
//             <intent-filter>
//                 <action android:name="android.intent.action.MAIN"/>
//                 <category android:name="android.intent.category.LAUNCHER"/>
//             </intent-filter>
//         </activity>

//         <receiver
//             android:name="me.carda.awesome_notifications.core.receivers.AwesomeNotificationsRebootEventReceiver"
//             android:exported="true">
//             <intent-filter>
//                 <action android:name="android.intent.action.BOOT_COMPLETED"/>
//                 <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
//             </intent-filter>
//         </receiver>
//         <!-- Don't delete the meta-data below.
//              This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
//         <meta-data
//             android:name="flutterEmbedding"
//             android:value="2" />
//     </application>
//     <!-- Required to query activities that can process text, see:
//          https://developer.android.com/training/package-visibility and
//          https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

//          In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
//     <queries>
//         <intent>
//             <action android:name="android.intent.action.PROCESS_TEXT"/>
//             <data android:mimeType="text/plain"/>
//         </intent>
//     </queries>
// </manifest>
// end of file















// <!-- <manifest xmlns:android="http://schemas.android.com/apk/res/android">

//     <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
//     <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
//     <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
//     <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
//     <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
//     <uses-permission android:name="android.permission.CAMERA" />
//     <uses-permission android:name="android.permission.INTERNET" />
//     <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
//     <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
//     <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
//     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    

    
//     <application
//         android:label="ArticuliCare"
//         android:requestLegacyExternalStorage="true"
//         android:name="${applicationName}"
//         android:icon="@mipmap/launcher_icon">
//         <activity
//             android:name=".MainActivity"
//             android:exported="true"
//             android:launchMode="singleTop"
//             android:taskAffinity=""
//             android:theme="@style/LaunchTheme"
//             android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
//             android:hardwareAccelerated="true"
//             android:windowSoftInputMode="adjustResize">
//             <!-- Specifies an Android theme to apply to this Activity as soon as
//                  the Android process has started. This theme is visible to the user
//                  while the Flutter UI initializes. After that, this theme continues
//                  to determine the Window background behind the Flutter UI. -->
//             <meta-data
//               android:name="io.flutter.embedding.android.NormalTheme"
//               android:resource="@style/NormalTheme"
//               />
//             <intent-filter>
//                 <action android:name="android.intent.action.MAIN"/>
//                 <category android:name="android.intent.category.LAUNCHER"/>
//             </intent-filter>
//         </activity>
//         <receiver
//             android:name="com.ryanheise.audioservice.AudioServiceBackgroundReceiver"
//             android:exported="true">
//             <intent-filter>
//                 <action android:name="android.intent.action.BOOT_COMPLETED"/>
//             </intent-filter>
//         </receiver>
//         <!-- Don't delete the meta-data below.
//              This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
//         <meta-data
//             android:name="flutterEmbedding"
//             android:value="2" />
//     </application>
//     <!-- Required to query activities that can process text, see:
//          https://developer.android.com/training/package-visibility and
//          https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

//          In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
//     <queries>
//         <intent>
//             <action android:name="android.intent.action.PROCESS_TEXT"/>
//             <data android:mimeType="text/plain"/>
//         </intent>
//     </queries>
// </manifest> -->