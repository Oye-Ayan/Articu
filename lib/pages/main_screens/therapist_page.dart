import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

// Get Supabase client instance
final supabaseClient = Supabase.instance.client;

class MyButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final Color? backgroundColor;

  const MyButton({
    super.key,
    required this.onTap,
    required this.text,
    this.backgroundColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 16.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      child: Text(text),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class TherapistPage extends StatefulWidget {
  const TherapistPage({super.key});

  @override
  State<TherapistPage> createState() => _TherapistPageState();
}

class _TherapistPageState extends State<TherapistPage> {
  bool _showWebView = false;
  bool _isLoading = false;
  bool _isLoadingTherapists = false;
  WebViewController? _webViewController;
  List<Map<String, dynamic>> _therapists = [];
  late final firebase_auth.User _currentUser;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentUser = firebase_auth.FirebaseAuth.instance.currentUser!;
    _fetchTherapists();
    if (Platform.isAndroid) {
      _initializeWebView();
    }
  }

void showContactUsDialog() {
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

  Future<void> _initializeWebView() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted && progress < 100 != _isLoading) {
              setState(() => _isLoading = progress < 100);
            }
          },
          onPageStarted: (String url) {
            if (mounted && !_isLoading) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
              _webViewController!.runJavaScript(
                """
                document.body.style.overflow = 'auto';
                document.documentElement.style.overflow = 'auto';
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=2.0, user-scalable=yes';
                document.getElementsByTagName('head')[0].appendChild(meta);
                """
              );
            }
          },
        ),
      );

    if (Platform.isAndroid) {
      final androidController = _webViewController!.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    await _webViewController!.loadRequest(
      Uri.parse('https://www.marham.pk/doctors/speech-therapist'),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTherapists() async {
    if (_therapists.isNotEmpty) return;
    if (mounted) setState(() => _isLoadingTherapists = true);
    try {
      final response = await supabaseClient
          .from('therapists')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _therapists = List<Map<String, dynamic>>.from(response);
          _isLoadingTherapists = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch therapists error: $e');
      if (mounted) {
        setState(() => _isLoadingTherapists = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading therapists: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void showRegistrationDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController(text: _currentUser.email);
    final qualificationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Register as a Therapist', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: false,
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: qualificationController,
                  decoration: InputDecoration(
                    labelText: 'Qualifications',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.school, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty || qualificationController.text.isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields.'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }

                try {
                  await supabaseClient.from('therapists').insert({
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'qualifications': qualificationController.text.trim(),
                    'user_id': _currentUser.uid,
                    'created_at': DateTime.now().toIso8601String(),
                    'superhero_points': 20,
                  });
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registration submitted successfully!'), backgroundColor: Colors.green),
                  );
                  _therapists = [];
                  await _fetchTherapists();
                } catch (e) {
                  debugPrint('Insert therapist error: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving therapist: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text('Submit', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
            ),
          ],
        ).animate().fadeIn(duration: 200.ms);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade50,
        centerTitle: true,
        title: Text(
          "Speech Therapy Consultation",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.contact_support, color: Colors.black87),
            onPressed: showContactUsDialog,
            tooltip: 'Contact Us',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Online Speech Therapy with Verified Therapists",
                            style: TextStyle(
                              fontSize: 20.sp,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Container(
                      height: 60.h,
                      width: 60.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.shade200, width: 2),
                        color: Colors.white,
                      ),
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.srcATop),
                        child: Image.asset(
                          'assets/images/splash_logo.png',
                          fit: BoxFit.contain,
                          height: 40.h,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Why Choose Us?",
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    const FeatureItem("Online consultations with certified speech therapists"),
                    SizedBox(height: 12.h),
                    const FeatureItem("Flexible scheduling, including nights and weekends"),
                    SizedBox(height: 12.h),
                    const FeatureItem("Verified professionals with extensive experience"),
                    SizedBox(height: 12.h),
                    const FeatureItem("Affordable sessions with transparent pricing"),
                    SizedBox(height: 12.h),
                    const FeatureItem("Secure and confidential video consultations"),
                  ],
                ).animate().fadeIn(duration: 200.ms),
              ),
              SizedBox(height: 16.h),
              Center(
                child: MyButton(
                  onTap: () {
                    if (Platform.isAndroid) {
                      setState(() => _showWebView = !_showWebView);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Consultation booking is only available on Android.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  text: _showWebView ? 'Close Consultation' : 'Book a Consultation',
                  backgroundColor: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 16.h),
              if (_showWebView && _webViewController != null)
                Container(
                  height: 4000.h,
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.blue.shade100, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Stack(
                      children: [
                        WebViewWidget(controller: _webViewController!),
                        if (_isLoading)
                          Container(
                            color: Colors.white.withOpacity(0.8),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms),
              if (!_showWebView)
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(color: Colors.grey.shade300, thickness: 1),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.grey.shade300, thickness: 1),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Column(
                        children: [
                          MyButton(
                            onTap: showRegistrationDialog,
                            text: 'Register as a Therapist',
                            backgroundColor: Colors.blue.shade600,
                          ),
                          SizedBox(height: 12.h),
                          MyButton(
                            onTap: showContactUsDialog,
                            text: 'Contact Support',
                            backgroundColor: Colors.blue.shade600,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Our Registered Therapists",
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _isLoadingTherapists
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          )
                        : _therapists.isEmpty
                            ? Text(
                                "No therapists registered yet.",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _therapists.length,
                                itemBuilder: (context, index) {
                                  final therapist = _therapists[index];
                                  return TherapistCard(
                                    name: therapist['name'] ?? 'No Name',
                                    qualification: therapist['qualifications'] ?? 'Not specified',
                                    superheroPoints: therapist['superhero_points'] ?? 0,
                                  ).animate().fadeIn(duration: 200.ms);
                                },
                              ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showRegistrationDialog,
        backgroundColor: Colors.blue.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String text;

  const FeatureItem(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.blue.shade600,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black87,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TherapistCard extends StatelessWidget {
  final String name;
  final String qualification;
  final int superheroPoints;

  const TherapistCard({
    super.key,
    required this.name,
    required this.qualification,
    required this.superheroPoints,
  });

  @override
  Widget build(context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    qualification,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (superheroPoints > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber.shade700,
                      size: 20.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      superheroPoints.toString(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}