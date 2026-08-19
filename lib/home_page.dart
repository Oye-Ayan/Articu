import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'components/feature_card.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "ArticuliCare",
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        // Uncomment to enable profile navigation
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       Navigator.pushNamed(context, '/ProfilePage');
        //     },
        //     icon: Icon(Icons.person, color: Colors.blue, size: 32.sp),
        //     tooltip: 'Profile',
        //   ),
        // ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Practice Section
              Container(
                // margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Quick Practice",
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "Start a quick reading session to improve your speech",
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/SpeechRecording');
                        },
                        child: Container(
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
                      ).animate().scale(delay: 200.ms),
                    ],
                  ),
                ),
              ).animate().slideY(begin: -0.2, end: 0, duration: 500.ms),
              SizedBox(height: 24.h),
              // Featured Collection Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  "Featured Collection",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.symmetric(vertical: 20.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: Colors.blue.shade50,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 20.w,
                    mainAxisSpacing: 20.h,
                  ),
                  children: [
                    FeatureCard(
                      title: "Speech Recording",
                      imagePath: 'assets/images/speak_icon.png',
                      bgColor: Colors.white,
                      isLocked: false,
                      onTap: () {
                        Navigator.pushNamed(context, '/SpeechRecording');
                      },
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),
                    FeatureCard(
                      title: "Risk Assessment",
                      imagePath: 'assets/images/risk.png',
                      bgColor: Colors.white,
                      isLocked: false,
                      onTap: () {
                        Navigator.pushNamed(context, '/RiskAssessment');
                      },
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
                    FeatureCard(
                      title: "Therapeutic Exercises",
                      imagePath: 'assets/images/splash_logo.png',
                      bgColor: Colors.white,
                      isLocked: false,
                      onTap: () {
                        Navigator.pushNamed(context, '/TherapeuticExercises');
                      },
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
                    FeatureCard(
                      title: "Progress Tracking",
                      imagePath: 'assets/images/progress_tracking.png',
                      bgColor: Colors.white,
                      isLocked: false,
                      onTap: (){
                        Navigator.pushNamed(context, 'ProgressTrackingPage');
                      },
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
              SizedBox(height: 24.h),
              // Quote of the Day Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  "Quote of the Day",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: Colors.blue.shade400,
                      size: 40.sp,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Every person you meet knows something you don't.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}