import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../cubit/training_cubit.dart';
import '../cubit/training_state.dart';
import 'exercise_session_sheet.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrainingCubit, TrainingState>(
      builder: (context, state) {
        final progressRatio = state.lessons.isEmpty
            ? 0.0
            : (state.completedCount / state.lessons.length);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Daily Speech Practice'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () {
                  _showTrainingGuide(context);
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
                  // 7-Day Streak Scroller
                  Text(
                    'Training Week',
                    style: AppTextStyles.titleLarge,
                  ),
                  SizedBox(height: 12.h),

                  SizedBox(
                    height: 74.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      separatorBuilder: (_, __) => SizedBox(width: 10.w),
                      itemBuilder: (context, index) {
                        final dayNumber = index + 1;
                        final isSelected = state.selectedDay == dayNumber;
                        final isPast = dayNumber <= 3;

                        return GestureDetector(
                          onTap: () {
                            context.read<TrainingCubit>().selectDay(dayNumber);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52.w,
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : isPast
                                      ? AppColors.primarySoft
                                      : AppColors.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'D$dayNumber',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                if (isPast)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 18.sp,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primary,
                                  )
                                else
                                  Text(
                                    '${dayNumber * 3}m',
                                    style: AppTextStyles.caption.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Progress Bar Card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Day ${state.selectedDay} Progress',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${state.completedCount} of ${state.lessons.length} Completed',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            minHeight: 8.h,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Lessons Header
                  Text(
                    'Practice Curriculum',
                    style: AppTextStyles.titleLarge,
                  ),
                  SizedBox(height: 12.h),

                  // Lessons List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.lessons.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final lesson = state.lessons[index];

                      return Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: lesson.isCompleted
                                ? AppColors.primaryLight.withValues(alpha: 0.5)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Indicator Icon
                            Container(
                              width: 44.w,
                              height: 44.w,
                              decoration: BoxDecoration(
                                color: lesson.isCompleted
                                    ? AppColors.primary
                                    : lesson.isLocked
                                        ? AppColors.surfaceVariant
                                        : AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Icon(
                                lesson.isCompleted
                                    ? Icons.check_rounded
                                    : lesson.isLocked
                                        ? Icons.lock_outline_rounded
                                        : Icons.play_arrow_rounded,
                                color: lesson.isCompleted
                                    ? Colors.white
                                    : lesson.isLocked
                                        ? AppColors.textMuted
                                        : AppColors.primary,
                                size: 22.sp,
                              ),
                            ),
                            SizedBox(width: 14.w),

                            // Title & Description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    lesson.description,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 11.sp,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),

                            // Duration & Action
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    lesson.durationMinutes,
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                if (!lesson.isLocked)
                                  InkWell(
                                    onTap: () {
                                      ExerciseSessionSheet.show(context, lesson);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(4.w),
                                      child: Text(
                                        lesson.isCompleted ? 'Review' : 'Start',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24.h),

                  // Start Next Drill Button
                  AppButton(
                    text: 'Continue Today\'s Session',
                    icon: Icons.bolt_rounded,
                    onTap: () {
                      final nextLesson = state.lessons.firstWhere(
                        (l) => !l.isCompleted && !l.isLocked,
                        orElse: () => state.lessons.first,
                      );
                      ExerciseSessionSheet.show(context, nextLesson);
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTrainingGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('ArticuliCare Training Method'),
        content: const Text(
          'Our clinically informed speech exercises utilize Flexible Rate Control, Diaphragmatic Breath Alignment, and Light Consonant Contacts to help you achieve effortless, fluent speech patterns.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
