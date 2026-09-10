import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class ProgressTrackingScreen extends StatelessWidget {
  const ProgressTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              CustomSnackBar.showSuccess(
                context,
                'Weekly speech progress report ready to export!',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Summary Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Overall Fluency Score',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '+14% this month',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF86EFAC),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '88%',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 44.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Pronunciation Accuracy',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: 0.88,
                        minHeight: 8.h,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // KPI Grid (4 Metrics)
              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      icon: Icons.local_fire_department_rounded,
                      value: '5 Days',
                      label: 'Current Streak',
                      color: AppColors.warning,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _kpiCard(
                      icon: Icons.timer_rounded,
                      value: '48 mins',
                      label: 'Weekly Practice',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      icon: Icons.graphic_eq_rounded,
                      value: '18',
                      label: 'Recorded Drills',
                      color: AppColors.cyan,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _kpiCard(
                      icon: Icons.verified_rounded,
                      value: '92%',
                      label: 'Pacing Rate',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Weekly Activity Bar Chart
              Text('Weekly Activity', style: AppTextStyles.titleLarge),
              SizedBox(height: 12.h),

              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _barItem('Mon', 12, maxVal: 20),
                        _barItem('Tue', 18, maxVal: 20),
                        _barItem('Wed', 8, maxVal: 20),
                        _barItem('Thu', 15, maxVal: 20),
                        _barItem('Fri', 20, maxVal: 20, isCurrent: true),
                        _barItem('Sat', 5, maxVal: 20),
                        _barItem('Sun', 0, maxVal: 20),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    const Divider(),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target: 15 mins/day', style: AppTextStyles.caption),
                        Text(
                          'Average: 11 mins',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Target Phonemes & Articulation Competence
              Text(
                'Phoneme Articulation Mastery',
                style: AppTextStyles.titleLarge,
              ),
              SizedBox(height: 12.h),

              _phonemeProgressTile(
                sound: '/s/ Sound',
                category: 'Sibilants & Fricatives',
                accuracy: 0.94,
              ),
              SizedBox(height: 10.h),
              _phonemeProgressTile(
                sound: '/r/ Sound',
                category: 'Liquid Approximants',
                accuracy: 0.78,
              ),
              SizedBox(height: 10.h),
              _phonemeProgressTile(
                sound: '/th/ Sound',
                category: 'Dental Fricatives',
                accuracy: 0.86,
              ),
              SizedBox(height: 10.h),
              _phonemeProgressTile(
                sound: '/p, b/ Sounds',
                category: 'Bilabial Stops (Light Contacts)',
                accuracy: 0.92,
              ),
              SizedBox(height: 24.h),

              AppButton(
                text: 'Download Clinical Progress PDF',
                icon: Icons.picture_as_pdf_rounded,
                type: AppButtonType.secondary,
                onTap: () {
                  CustomSnackBar.showSuccess(
                    context,
                    'Progress Summary PDF generated and downloaded!',
                  );
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _barItem(
    String label,
    int minutes, {
    required int maxVal,
    bool isCurrent = false,
  }) {
    final heightRatio = (minutes / maxVal).clamp(0.08, 1.0);
    final barHeight = 85.h * heightRatio;

    return Column(
      children: [
        Text(
          minutes > 0 ? '${minutes}m' : '-',
          style: AppTextStyles.caption.copyWith(
            fontSize: 10.sp,
            color: isCurrent ? AppColors.primary : AppColors.textMuted,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: 24.w,
          height: barHeight,
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.primary : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(6.r),
            border: isCurrent
                ? null
                : Border.all(color: AppColors.primaryMuted, width: 1),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _phonemeProgressTile({
    required String sound,
    required String category,
    required double accuracy,
  }) {
    final percentage = (accuracy * 100).round();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sound,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$percentage% Mastery',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accuracy > 0.85
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(category, style: AppTextStyles.caption),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: accuracy,
              minHeight: 6.h,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                accuracy > 0.85 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
