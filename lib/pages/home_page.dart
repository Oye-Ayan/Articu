import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/feature_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
void Betaversion_showDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
    return AlertDialog(
    title: const Text('Beta Version'),
      content: const Text('Beta version. Complete Module is not available at the moment.',),
      actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); 
                  },
                child: const Text('OK', style: TextStyle(color: Colors.blue),),
              ),
            ],
          );         
        },
      );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "ArticuliCare",
          style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       Navigator.pushNamed(context, '/ProfilePage');
        //     },
        //     icon: Icon(Icons.person, color: Colors.blue, size: 30.sp),
        //   ),
        // ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30.r), bottom: Radius.circular(30.r)),
                  color: Colors.blue.shade50,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10.h),
                            Text(
                              "Quick Practice",
                              style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              "A quick reading",
                              style: TextStyle(
                                  fontSize: 14.sp, color: Colors.grey.shade600),
                            ),
                            SizedBox(height: 10.h),
                          ],
                        ),
                      ),
                      SizedBox(width: 5.w),
                      SizedBox(height: 10.h),
                      ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/TrainingPage');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.w, vertical: 10.h),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.r)),
                              ),
                              child: Text("Start Practice",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold)),
                            ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  "Featured Collection",
                  style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ),
              SizedBox(height: 15.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30.r), bottom: Radius.circular(30.r)),
                  color: Colors.blue.shade50,
                ),
                height: 428.h,
                child: Column(
                  children: [
                SizedBox(height: 15.h),
                    Expanded(
                      child: GridView(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        physics:const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 18.w,
                          mainAxisSpacing: 24.h,
                        ),
                        children: [
                          FeatureCard(
                              title: "Speech Recording",
                              imagePath: 'assets/images/speak_icon.png',
                              bgColor: Colors.white,
                              isLocked: false,
                              onTap: (){
                                Navigator.pushNamed(context,'/SpeechRecording');
                              }
                              ),
                          FeatureCard(
                              title: "Risk Assessment",
                              imagePath: 'assets/images/risk.png',
                              bgColor: Colors.white,
                              isLocked: true,
                              onTap: Betaversion_showDialog,
                            ),
                          FeatureCard(
                              title: "Therapeutic Exercises",
                              imagePath: 'assets/images/therapeutic_exercises.png',
                              bgColor: Colors.white,
                              isLocked: true,
                              onTap: Betaversion_showDialog,
                            ),
                          FeatureCard(
                              title: "Progress Tracking",
                              imagePath: 'assets/images/progress_tracking.png',
                              bgColor: Colors.white,
                              isLocked: true,
                              onTap: Betaversion_showDialog,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15.h),
                  ],
                ),
              ),
              SizedBox(height: 15.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text("Quote of The Day",style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              SizedBox(height: 15.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30.r), bottom: Radius.circular(30.r)),
                  color: Colors.blue.shade50,
                ),
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5.h),
                            Center(child: Icon(Icons.format_quote, color: Colors.blue.shade400, size: 35.sp)),
                            Text(
                              "Every Person u met, knows something you don't.",
                              style: TextStyle(
                                  fontSize: 16.sp, color: Colors.black, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 5.h),
                          ],
                        ),
                      ),
                    ]
                  ),
               ),
              ),
              SizedBox(height: 15.h),
            ],
          ),
        ),
      ),
    );
  }
}
