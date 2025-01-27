import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class FeatureCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color bgColor;
  final bool isLocked;
  final Function()? onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.bgColor,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 50.h,
              width: 50.w,
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isLocked) ...[
              SizedBox(height: 5.h),
              Icon(Icons.lock, color: Colors.grey.shade700, size: 20.sp),
            ],
          ],
        ),
      ),
    );
  }
}