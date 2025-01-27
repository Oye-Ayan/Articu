// ignore_for_file: library_prefixes

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final fbAuth.FirebaseAuth _auth = fbAuth.FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  String? userName;
  String? userEmail;
  String? profileImgUrl;
  String? profileImagePath;

  final TextEditingController _usernameController = TextEditingController();
  bool isEditingUsername = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _getUserDataFromFirebase();
  }

  Future<void> _getUserDataFromFirebase() async {
    final fbAuth.User? firebaseUser = _auth.currentUser;

    if (firebaseUser != null) {
      setState(() {
        userName = firebaseUser.displayName ?? "Guest";
        userEmail = firebaseUser.email;
        profileImagePath = null; 
        profileImgUrl = null; 
      });

      final response = await _supabase
          .from('users_data')
          .select()
          .eq('id', firebaseUser.uid)
          .maybeSingle();

      if (response != null && response['profile_img_url'] != null) {
        setState(() {
          profileImgUrl = response['profile_img_url'];
        });
      } else {
        if (mounted) {
          setState(() {
            profileImgUrl = null;
          });
        }
      }
      await _storeUserDataInSupabase(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        username: firebaseUser.displayName ?? "Guest",
        profileImgUrl: profileImgUrl,
      );
    }
  }

  Future<void> _storeUserDataInSupabase({
    required String id,
    required String email,
    required String username,
    String? profileImgUrl,
  }) async {
    try {
      final existingUser = await _supabase
          .from('users_data')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (existingUser == null) {
        final response = await _supabase.from('users_data').insert({
          'id': id,
          'email': email,
          'username': username,
          'profile_img_url': profileImgUrl ?? "",
        });
        if (response.error != null) {
          print('Error inserting data: ${response.error!.message}');
        }
      } else {
        // Update existing user data
        final response = await _supabase.from('users_data').update({
          'email': email,
          'username': username,
          'profile_img_url': profileImgUrl ?? "", 
        }).eq('id', id);

        if (response.error != null) {
          print('Error updating data: ${response.error!.message}');
        }
      }
    } catch (error) {
      print('Failed to store user data in Supabase: $error');
    }
  }

  Future<void> _loadProfileImage() async {
    if (profileImgUrl != null) {
      // Supabase URL exists, no need to load local image
      return;
    }

    // Load local image if no Supabase URL is set
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/profile_picture.png';

    if (File(filePath).existsSync()) {
      setState(() {
        profileImagePath = filePath;
      });
    } else {
      setState(() {
        profileImagePath = null;
      });
    }
  }

  Future<void> uploadProfilePicture() async {
    final cameraPermission = await Permission.camera.request();
    final storagePermission = await Permission.storage.request();

    if (cameraPermission.isGranted && storagePermission.isGranted) {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Show a loading indicator while uploading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.black54,
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(width: 20),
                Text('Uploading image...'),
              ],
            ),
          ),
        );

        try {
          // Save image locally
          final directory = await getApplicationDocumentsDirectory();
          final savedImagePath = '${directory.path}/profile_picture.png';
          final newImage = await File(image.path).copy(savedImagePath);

          // Evict any cached version of the image
          await FileImage(newImage).evict();

          // Generate unique storage path
          final storagePath =
              'profile_pictures/$userName/${DateTime.now().millisecondsSinceEpoch}_profile_picture.png';

          // Read file as bytes for upload
          final fileBytes = await File(image.path).readAsBytes();

          // Upload image to Supabase storage
          final uploadResponse = await _supabase.storage
              .from('profile_images')
              .uploadBinary(storagePath, fileBytes);

          if (uploadResponse.isEmpty) {
            throw Exception('Failed to upload image to Supabase storage.');
          }

          // Fetch the public URL of the uploaded image
          final publicUrl = _supabase.storage.from('profile_images').getPublicUrl(storagePath);

          // Ensure the URL is accessible
          if (publicUrl.isEmpty) {
            throw Exception('Could not retrieve public URL of the uploaded image.');
          }

          // Update user data in Supabase
          await _storeUserDataInSupabase(
            id: _auth.currentUser!.uid,
            email: userEmail!,
            username: userName!,
            profileImgUrl: publicUrl,
          );

          // Update local state
          if (mounted) {
            setState(() {
              profileImgUrl = publicUrl; // Update profile image URL
              profileImagePath = savedImagePath; // Save local path for the image
            });
          }

          // Notify user of success
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.blue,
            ),
          );
        } catch (error) {
          // Handle upload failure
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload image: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Handle no image selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image selected.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Handle permissions denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions denied. Please allow access to camera and storage.'),
          backgroundColor: Colors.red,
        ),
      );

      if (cameraPermission.isPermanentlyDenied || storagePermission.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
  }

  void _showBetaVersionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Beta Version'),
          content: const Text('Complete Module is not available at the moment.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveUserName() async {
    final newUserName = _usernameController.text.trim();
    if (newUserName.isNotEmpty) {
      setState(() {
        userName = newUserName;
        isEditingUsername = false;
      });

      // Update username in Supabase
      await _storeUserDataInSupabase(
        id: _auth.currentUser!.uid,
        email: userEmail!,
        username: newUserName,
        profileImgUrl: profileImgUrl,
      );

      await _auth.currentUser!.updateDisplayName(newUserName);

      // Notify user of success
    ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
        content: Text('Username updated and saved to Supabase!'),
        backgroundColor: Colors.blue,
      ),
    );
    }
  }

  void signUserOut() {
    _auth.signOut();
    setState(() {
      userName = null;
      userEmail = null;
      profileImgUrl = null;
      profileImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImgUrl != null
                        ? NetworkImage(profileImgUrl!)
                        : (profileImagePath != null
                            ? FileImage(File(profileImagePath!)) 
                            : const AssetImage('assets/images/profile1.png')) 
                        as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: uploadProfilePicture,
                      child: Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            isEditingUsername
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200.w,
                        child: TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter new username',
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black, width: 1.0),
                            ),
                            border: OutlineInputBorder(), // Default border if none of the above are active
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: _saveUserName,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            isEditingUsername = false;
                          });
                        },
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName ?? '@your_username',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          setState(() {
                            isEditingUsername = true;
                            _usernameController.text = userName ?? '';
                          });
                        },
                      ),
                    ],
                  ),
            const Divider(height: 40, thickness: 1),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Profile'),
              trailing: TextButton(
                onPressed: () {
                  _showBetaVersionDialog();
                },
                child: Text('Edit', style: TextStyle(color: Colors.blue.shade400)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.blue),
              title: const Text('Statistics'),
              trailing: TextButton(
                onPressed: () {
                  _showBetaVersionDialog();
                },
                child: Text('View stats', style: TextStyle(color: Colors.blue.shade400)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.blue),
              title: const Text('Practice Reminder'),
              trailing: TextButton(
                onPressed: () {
                  _showBetaVersionDialog();
                },
                child: Text('Not set', style: TextStyle(color: Colors.blue.shade400)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blue),
              title: const Text('Notification'),
              trailing: TextButton(
                onPressed: () {
                  _showBetaVersionDialog();
                },
                child: Text('On', style: TextStyle(color: Colors.blue.shade400)),
              ),
            ),
            Divider(height: 40.h, thickness: 1.sp),
            // Other Actions
            ListTile(
              leading: const Icon(Icons.featured_play_list, color: Colors.blue),
              title: const Text('Request a feature'),
              onTap: _showBetaVersionDialog,
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share this app'),
              onTap: _showBetaVersionDialog,
            ),
            ListTile(
              leading: const Icon(Icons.contact_support, color: Colors.blue),
              title: const Text('Contact us'),
              onTap: _showBetaVersionDialog,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.blue),
              title: const Text('Log Out'),
              onTap: signUserOut,
            ),
            ListTile(
              leading: const Icon(Icons.pin_end_outlined, color: Colors.blue),
              title: const Text("Privacy Policy"),
              onTap: _showBetaVersionDialog,
            ),
          ],
        ),
      ),
    );
  }
}