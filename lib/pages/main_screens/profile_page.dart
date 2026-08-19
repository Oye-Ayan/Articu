import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final fbAuth.FirebaseAuth _auth = fbAuth.FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  String? selectedRole;
  final List<String> _allRoles = ['Normal User', 'Caregiver', 'Therapist', 'Admin'];
  List<String> get roles => _auth.currentUser?.email == 'ayann9211@gmail.com'
      ? _allRoles
      : _allRoles.where((role) => role != 'Admin').toList();

  String? userName;
  String? userEmail;
  String? profileImgUrl;
  String? profileImagePath;
  String? fullName;
  String? phoneNumber;
  bool _isSaving = false; // Track saving state for edit profile
  bool _isNotificationOn = true; // Notification toggle state
  TimeOfDay? _reminderTime; // Store the selected reminder time

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserDataFromFirebase();
  }

  // Helper function to sanitize username for storage paths
  String _sanitizeUsername(String username) {
    return username
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') // Replace non-alphanumeric with underscore
        .toLowerCase();
  }

  Future<void> _getUserDataFromFirebase() async {
    final fbAuth.User? firebaseUser = _auth.currentUser;

    if (firebaseUser != null) {
      // Reset all states to avoid stale data
      if (mounted) {
        setState(() {
          userName = firebaseUser.displayName ?? "Guest";
          userEmail = firebaseUser.email;
          profileImgUrl = null;
          profileImagePath = null;
          selectedRole = null;
          fullName = null;
          phoneNumber = null;
          _isNotificationOn = true; // Default until fetched
          _reminderTime = null;
          _isSaving = false;
        });
      }

      try {
        // Fetch user data from Supabase
        final response = await _supabase
            .from('user_profiles')
            .select()
            .eq('id', firebaseUser.uid)
            .maybeSingle();

        if (response != null) {
          final reminderTimeString = response['reminder_time'] as String?;
          if (mounted) {
            setState(() {
              userEmail = response['email'] as String? ?? firebaseUser.email;
              profileImgUrl = response['profile_img_url'] as String?;
              selectedRole = response['role'] as String? ?? 'Normal User';
              fullName = response['full_name'] as String? ?? '';
              phoneNumber = response['phone_number'] as String?;
              _isNotificationOn = response['notification_enabled'] as bool? ?? true;
              _reminderTime = reminderTimeString != null
                  ? TimeOfDay.fromDateTime(DateTime.parse(reminderTimeString))
                  : null;
            });
          }

          // Cache data in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', selectedRole!);
          if (fullName != null) await prefs.setString('full_name', fullName!);
          if (phoneNumber != null) await prefs.setString('phone_number', phoneNumber!);
          await prefs.setBool('notification_enabled', _isNotificationOn);
          if (reminderTimeString != null) await prefs.setString('reminder_time', reminderTimeString);

          // Debug: Verify profile image URL
          if (profileImgUrl != null && profileImgUrl!.isNotEmpty) {
            debugPrint('Fetched profile_img_url: $profileImgUrl');
          } else {
            debugPrint('No profile_img_url found in Supabase for user ${firebaseUser.uid}');
          }
        } else {
          // If no Supabase data, use local cache or defaults
          final prefs = await SharedPreferences.getInstance();
          String? localRole = prefs.getString('user_role');
          String? localFullName = prefs.getString('full_name');
          String? localPhone = prefs.getString('phone_number');
          bool? localNotification = prefs.getBool('notification_enabled');
          String? localReminderTime = prefs.getString('reminder_time');

          if (localRole != null) {
            if (mounted) {
              setState(() {
                selectedRole = localRole;
                fullName = localFullName;
                phoneNumber = localPhone;
                _isNotificationOn = localNotification ?? true;
                _reminderTime = localReminderTime != null
                    ? TimeOfDay.fromDateTime(DateTime.parse(localReminderTime))
                    : null;
              });
            }
          }
        }

        // Load local image only if no Supabase image is available
        await _loadProfileImage();
      } catch (error) {
        debugPrint('Failed to fetch user data from Supabase: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile data: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _storeUserDataInSupabase({
    required String id,
    required String email,
    required String username,
    String? profileImgUrl,
    String? role,
    String? fullName,
    String? phoneNumber,
    bool? notificationEnabled,
    String? reminderTime,
  }) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final existingUser = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      final data = {
        'id': id,
        'email': email,
        'username': username,
        'profile_img_url': profileImgUrl ?? "",
        'role': role ?? 'Normal User',
        'full_name': fullName ?? '',
        'phone_number': phoneNumber,
      };

      // Only include notification_enabled if the column exists
      if (notificationEnabled != null) {
        try {
          await _supabase.from('user_profiles').select('notification_enabled').limit(1);
          data['notification_enabled'] = notificationEnabled as String?;
        } catch (e) {
          debugPrint('notification_enabled column not found, skipping: $e');
        }
      }

      // Only include reminder_time if the column exists
      if (reminderTime != null || _reminderTime != null) {
        try {
          await _supabase.from('user_profiles').select('reminder_time').limit(1);
          data['reminder_time'] = reminderTime ??
              (_reminderTime != null
                  ? DateTime(2023, 1, 1, _reminderTime!.hour, _reminderTime!.minute).toIso8601String()
                  : null);
        } catch (e) {
          debugPrint('reminder_time column not found, skipping: $e');
        }
      }

      if (existingUser == null) {
        await _supabase.from('user_profiles').insert(data);
        debugPrint('Inserted new user data: $data');
      } else {
        await _supabase.from('user_profiles').update(data).eq('id', id);
        debugPrint('Updated user data: $data');
      }

      // Cache data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role ?? 'Normal User');
      if (fullName != null) await prefs.setString('full_name', fullName);
      if (phoneNumber != null) await prefs.setString('phone_number', phoneNumber);
      await prefs.setBool('notification_enabled', notificationEnabled ?? _isNotificationOn);
      if (reminderTime != null) await prefs.setString('reminder_time', reminderTime);

      if (mounted) {
        setState(() {
          userEmail = email;
          _isSaving = false;
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (error) {
      debugPrint('Failed to store user data in Supabase: $error');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUserDataFromSupabase(String id) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _supabase.from('user_profiles').delete().eq('id', id);
      debugPrint('Deleted user data for ID: $id');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      await prefs.remove('full_name');
      await prefs.remove('phone_number');
      await prefs.remove('notification_enabled');
      await prefs.remove('reminder_time');

      // Clear local profile image
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/profile_picture.png';
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }

      if (mounted) {
        setState(() {
          userName = null;
          userEmail = null;
          profileImgUrl = null;
          profileImagePath = null;
          fullName = null;
          phoneNumber = null;
          selectedRole = null;
          _isNotificationOn = true;
          _reminderTime = null;
          _isSaving = false;
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('User data deleted successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (error) {
      debugPrint('Failed to delete user data in Supabase: $error');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete user data: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProfileImage() async {
    if (!mounted) return;
    // Only load local image if no Supabase URL is available or if URL fails
    if (profileImgUrl == null || profileImgUrl!.isEmpty) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/profile_picture.png';

      if (File(filePath).existsSync()) {
        if (mounted) {
          setState(() {
            profileImagePath = filePath;
            profileImgUrl = null; // Ensure profileImgUrl is cleared
          });
        }
      } else {
        if (mounted) {
          setState(() {
            profileImagePath = null;
            profileImgUrl = null;
          });
        }
      }
    } else {
      // Test if profileImgUrl is accessible
      try {
        final imagePath = profileImgUrl!.split('/public/profile_images/').last.split('?').first;
        final response = await _supabase.storage.from('profile_images').download(imagePath);
        if (response.isEmpty) {
          throw Exception('Failed to download image');
        }
        if (mounted) {
          setState(() {
            profileImagePath = null; // Use network image
          });
        }
      } catch (e) {
        debugPrint('Profile image URL inaccessible, clearing URL: $e');
        // Clear the invalid URL from Supabase
        await _supabase
            .from('user_profiles')
            .update({'profile_img_url': null})
            .eq('id', _auth.currentUser!.uid);
        if (mounted) {
          setState(() {
            profileImgUrl = null; // Clear invalid URL
            profileImagePath = null;
          });
        }
        // Try loading local image as fallback
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/profile_picture.png';
        if (File(filePath).existsSync()) {
          if (mounted) {
            setState(() {
              profileImagePath = filePath;
            });
          }
        }
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (!mounted) return;
    final cameraPermission = await Permission.camera.request();
    final storagePermission = await Permission.storage.request();

    if (cameraPermission.isGranted && storagePermission.isGranted) {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        if (mounted) {
          setState(() {
            _isSaving = true;
          });
          scaffoldMessenger.showSnackBar(
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
        }

        try {
          final directory = await getApplicationDocumentsDirectory();
          final savedImagePath = '${directory.path}/profile_picture.png';
          final newImage = await File(image.path).copy(savedImagePath);

          await FileImage(newImage).evict();
          imageCache.clear();
          imageCache.clearLiveImages(); // Ensure live images are cleared

          final sanitizedUsername = _sanitizeUsername(userName ?? 'user');
          final storagePath =
              'profile_pictures/$sanitizedUsername/${DateTime.now().millisecondsSinceEpoch}_profile_picture.png';

          final fileBytes = await File(image.path).readAsBytes();

          debugPrint('Uploading image to Supabase at path: $storagePath');
          final uploadResponse = await _supabase.storage
              .from('profile_images')
              .uploadBinary(storagePath, fileBytes);

          if (uploadResponse.isEmpty) {
            throw Exception('Failed to upload image to Supabase storage. Response empty.');
          }

          debugPrint('Upload response: $uploadResponse');
          final publicUrl = _supabase.storage.from('profile_images').getPublicUrl(storagePath);
          if (publicUrl.isEmpty) {
            throw Exception('Could not retrieve public URL of the uploaded image.');
          }
          debugPrint('Public URL: $publicUrl');

          await _storeUserDataInSupabase(
            id: _auth.currentUser!.uid,
            email: userEmail!,
            username: userName!,
            profileImgUrl: publicUrl,
            role: selectedRole,
            fullName: fullName,
            phoneNumber: phoneNumber,
            notificationEnabled: _isNotificationOn,
          );

          if (mounted) {
            setState(() {
              profileImgUrl = publicUrl;
              profileImagePath = savedImagePath;
              _isSaving = false;
            });
            scaffoldMessenger.hideCurrentSnackBar();
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        } catch (error) {
          debugPrint('Image upload error: $error');
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }
          if (mounted) {
            scaffoldMessenger.hideCurrentSnackBar();
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions denied. Please allow access to camera and storage.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (cameraPermission.isPermanentlyDenied || storagePermission.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
  }

  void _showNotificationDialog(bool isOn) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text(
            'Notification Settings',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          content: Text(
            'Notifications are now ${isOn ? 'turned on' : 'turned off'}.',
            style: TextStyle(fontSize: 16.sp),
          ),
          actions: [
            TextButton(
              onPressed: (){Navigator.of(context).pop();},// Handled in then
              child: Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _showContactUsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text(
            'Contact Us',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We’re here to support your healthcare journey!',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
              ),
              SizedBox(height: 12.h),
              Text(
                'Email: ArticuliCare@gmail.com',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8.h),
              Text(
                'Support Hours: Mon-Fri, 9 AM - 6 PM',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 8.h),
              Text(
                'For urgent care, please call our helpline: +1-800-555-CARE',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: (){Navigator.of(context).pop();}, // Handled in then
              child: Text('Close', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms);
      },
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text(
            'Privacy Policy',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'At ArticuliCare, your privacy is our priority.',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
                ),
                SizedBox(height: 12.h),
                Text(
                  '• We collect only necessary data to provide healthcare services.\n'
                  '• Your data is encrypted and stored securely.\n'
                  '• We comply with HIPAA and GDPR regulations.\n'
                  '• You can request data deletion at any time.',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 8.h),
                Text(
                  'For more details, Email us at ArticuliCare@gmail.com.',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions:  [
            TextButton(
              onPressed: (){Navigator.of(context).pop();}, // Handled in then
              child: Text('Close', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms);
      },
    );
  }



  void _showEditProfileDialog() {
    if (!mounted) return;
    _usernameController.text = userName ?? '';
    _fullNameController.text = fullName ?? '';
    _phoneController.text = phoneNumber ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(IconlyLight.profile, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(fontSize: 16.sp),
                ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                SizedBox(height: 12.h),
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(IconlyLight.user3, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(fontSize: 16.sp),
                ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                SizedBox(height: 12.h),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: const Icon(IconlyLight.call, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: 16.sp),
                ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final newUserName = _usernameController.text.trim();
                      final newFullName = _fullNameController.text.trim();
                      final newPhone = _phoneController.text.trim();

                      if (newUserName.isNotEmpty && newFullName.isNotEmpty) {
                        if (mounted) {
                          setState(() {
                            _isSaving = true;
                          });
                        }

                        final sanitizedNewUserName = _sanitizeUsername(newUserName);
                        if (mounted) {
                          setState(() {
                            userName = sanitizedNewUserName;
                            fullName = newFullName;
                            phoneNumber = newPhone.isNotEmpty ? newPhone : null;
                          });
                        }

                        await _storeUserDataInSupabase(
                          id: _auth.currentUser!.uid,
                          email: userEmail!,
                          username: sanitizedNewUserName,
                          profileImgUrl: profileImgUrl,
                          role: selectedRole,
                          fullName: newFullName,
                          phoneNumber: newPhone.isNotEmpty ? newPhone : null,
                          notificationEnabled: _isNotificationOn,
                        );

                        await _auth.currentUser!.updateDisplayName(sanitizedNewUserName);

                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                          Navigator.of(context).pop();
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Username and Full Name are required.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms);
      },
    );
  }

  void _showRoleSelectionDialog() {
    if (!mounted) return;
    String? tempRole = selectedRole;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text(
            'Select Role',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: roles
                    .map((role) => RadioListTile<String>(
                          title: Text(role, style: TextStyle(fontSize: 16.sp)),
                          value: role,
                          groupValue: tempRole,
                          onChanged: (value) {
                            setDialogState(() => tempRole = value);
                          },
                          activeColor: Colors.blue,
                        ))
                    .toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tempRole != null && mounted) {
                  setState(() {
                    selectedRole = tempRole;
                    _isSaving = true;
                  });
                  await _storeUserDataInSupabase(
                    id: _auth.currentUser!.uid,
                    email: userEmail!,
                    username: userName!,
                    profileImgUrl: profileImgUrl,
                    role: selectedRole,
                    fullName: fullName,
                    phoneNumber: phoneNumber,
                    notificationEnabled: _isNotificationOn,
                  );
                  if (mounted) {
                    setState(() {
                      _isSaving = false;
                    });
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms);
      },
    );
  }

  void signUserOut() async {
    // Clear local profile image
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/profile_picture.png';
    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('full_name');
    await prefs.remove('phone_number');
    await prefs.remove('notification_enabled');
    await prefs.remove('reminder_time');

    // Sign out from Firebase
    await _auth.signOut();

    // Clear image cache
    imageCache.clear();
    imageCache.clearLiveImages();

    if (mounted) {
      setState(() {
        userName = null;
        userEmail = null;
        profileImgUrl = null;
        profileImagePath = null;
        fullName = null;
        phoneNumber = null;
        selectedRole = null;
        _isNotificationOn = true;
        _reminderTime = null;
        _isSaving = false;
      });
    }
  }

  void _showProfileOptionsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text(
            'Profile Options',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(IconlyLight.image, color: Colors.blue),
                title: const Text('View Image'),
                onTap: () {
                  if (mounted) {
                    Navigator.of(context).pop();
                    _showImageViewer();
                  }
                },
              ),
              ListTile(
                leading: const Icon(IconlyLight.camera, color: Colors.blue),
                title: const Text('Upload Image'),
                onTap: () {
                  if (mounted) {
                    Navigator.of(context).pop();
                    _uploadProfilePicture();
                  }
                },
              ),
              ListTile(
                leading: const Icon(IconlyLight.delete, color: Colors.red),
                title: const Text('Delete Profile'),
                onTap: () {
                  if (mounted) {
                    Navigator.of(context).pop();
                    _showDeleteConfirmationDialog();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to get the correct image provider
  ImageProvider _getProfileImageProvider() {
    if (profileImgUrl != null && profileImgUrl!.isNotEmpty) {
      final url = '$profileImgUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Attempting to load image from: $url');
      return NetworkImage(url);
    } else if (profileImagePath != null && profileImagePath!.isNotEmpty) {
      debugPrint('Loading local image from: $profileImagePath');
      return FileImage(File(profileImagePath!));
    } else {
      debugPrint('Falling back to default image');
      return const AssetImage('assets/images/profile1.png');
    }
  }

  void _showImageViewer() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image(
                    image: _getProfileImageProvider(),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Failed to load image for viewer: $error');
                      return Image.asset(
                        'assets/images/profile1.png',
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: () {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Close', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: const Text(
            'Confirm Delete',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          content: const Text('Are you sure you want to delete your profile data? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (mounted) {
                  await _deleteUserDataFromSupabase(_auth.currentUser!.uid);
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _showProfileOptionsDialog,
              child: _buildProfileHeader(),
            ),
            SizedBox(height: 20.h),
            _buildProfileCard(),
            SizedBox(height: 16.h),
            _buildSettingsCard(),
            SizedBox(height: 16.h),
            _buildSupportCard(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue[200]!, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50.r,
                    backgroundColor: Colors.blue[100],
                    child: ClipOval(
                      child: RepaintBoundary(
                        child: Image(
                          image: _getProfileImageProvider(),
                          fit: BoxFit.cover,
                          width: 100.r,
                          height: 100.r,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Failed to load profile image: $error');
                            return Image.asset(
                              'assets/images/profile1.png',
                              fit: BoxFit.cover,
                              width: 100.r,
                              height: 100.r,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _uploadProfilePicture,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      IconlyLight.camera,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ).animate().scale(duration: 300.ms),
              ],
            ).animate().scale(duration: 400.ms),
            SizedBox(height: 12.h),
            Text(
              userName ?? '@your_username',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildListTile(
              icon: IconlyLight.shieldDone,
              title: 'Role',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedRole ?? 'Normal User',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 8.w),
                  _buildActionButton(IconlyLight.edit, Colors.blue, _showRoleSelectionDialog),
                ],
              ),
            ),
            const Divider(),
            _buildListTile(
              icon: IconlyLight.profile,
              title: 'Profile',
              trailing: TextButton(
                onPressed: _showEditProfileDialog,
                child: const Text('Edit', style: TextStyle(color: Colors.blue, fontSize: 14)),
              ),
            ),
            _buildListTile(
              icon: IconlyLight.chart,
              title: 'Statistics',
              trailing: TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.pushNamed(context, 'ProgressTrackingPage');
                  }
                },
                child: const Text('View stats', style: TextStyle(color: Colors.blue, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildListTile(
              icon: IconlyLight.notification,
              title: 'Notification',
              trailing: TextButton(
                onPressed: () async {
                  if (mounted) {
                    setState(() {
                      _isNotificationOn = !_isNotificationOn;
                    });
                    await _storeUserDataInSupabase(
                      id: _auth.currentUser!.uid,
                      email: userEmail!,
                      username: userName!,
                      profileImgUrl: profileImgUrl,
                      role: selectedRole,
                      fullName: fullName,
                      phoneNumber: phoneNumber,
                      notificationEnabled: _isNotificationOn,
                    );
                    _showNotificationDialog(_isNotificationOn);
                  }
                },
                child: Text(
                  _isNotificationOn ? 'On' : 'Off',
                  style: const TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildListTile(
              icon: IconlyLight.message,
              title: 'Contact Us',
              onTap: _showContactUsDialog,
            ),
            _buildListTile(
              icon: IconlyLight.logout,
              title: 'Log Out',
              onTap: signUserOut,
            ),
            _buildListTile(
              icon: IconlyLight.lock,
              title: 'Privacy Policy',
              onTap: _showPrivacyPolicyDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: Colors.blue, size: 20.r),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(icon, color: color, size: 20.r),
      ),
    ).animate().scale(duration: 200.ms);
  }
}