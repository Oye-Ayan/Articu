import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/my_button.dart';

class TherapistPage extends StatefulWidget {
  const TherapistPage({super.key});

  @override
  State<TherapistPage> createState() => _TherapistPageState();
}

class _TherapistPageState extends State<TherapistPage> {
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
        elevation: 0,
        backgroundColor: Colors.blue.shade50,
        centerTitle: true,
        title: Text(
          "1-1 Speech Therapy",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              Betaversion_showDialog();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                 decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
                  color: Colors.blue.shade50,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h), 
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          Text(
                            "1-1 ArticuliCare Sessions With Certified Speech Therapists",
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                       child: Container(
                        height: 55.h, 
                        width: 55.h,  
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle, 
                          ),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.srcATop),
                            child: Image.asset(
                              'assets/images/splash_logo.png',
                              fit: BoxFit.cover, 
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Features Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    const FeatureItem("One-on-one speech therapy sessions delivered online"),
                    SizedBox(height: 10.h),
                    const FeatureItem("Available at nights or weekends at your convenience"),
                    SizedBox(height: 10.h),
                    const FeatureItem("Certified speech therapists with years of experience"),
                    SizedBox(height: 10.h),
                    const FeatureItem("Free cancellations and pro-rated refunds"),
                    SizedBox(height: 10.h),
                    const FeatureItem("World class speech therapy at a fraction of the cost"),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
              Center(
                child: MyButton(
                  onTap: () {
                    Betaversion_showDialog();
                  },
                  text: 'View All Plans',
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        "OR",
                        style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.grey)),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50, 
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chat, color: Colors.blue, size: 24.sp),
                        SizedBox(width: 8.w),
                        Text(
                          "Chat With Us To Learn More",
                          style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                        ),
                      ],
                    ),
                  SizedBox(height: 12.h),
                  MyButton(
                          onTap: (){
                            Betaversion_showDialog();
                          }, 
                        text: "Contact us")
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Features
class FeatureItem extends StatelessWidget {
  final String text;

  const FeatureItem(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: Colors.blue[700], size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
