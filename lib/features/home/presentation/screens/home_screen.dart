import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/daily_quote_card.dart';
import '../widgets/feature_grid_card.dart';
import '../widgets/quick_practice_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar / Top Header
                  _buildTopHeader(context),
                  SizedBox(height: 20.h),

                  // Quick Practice Banner
                  QuickPracticeBanner(
                    streakDays: homeState.dailyStreak,
                    onStartPractice: () {
                      Navigator.pushNamed(context, AppConstants.trainingRoute);
                    },
                  ),
                  SizedBox(height: 24.h),

                  // Quick Stats Row
                  _buildQuickStats(context, homeState),
                  SizedBox(height: 24.h),

                  // Featured Collection Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Therapy Modules',
                        style: AppTextStyles.titleLarge,
                      ),
                      Text(
                        'Active Tools',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Feature 2x2 Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14.w,
                    mainAxisSpacing: 14.h,
                    childAspectRatio: 0.95,
                    children: [
                      FeatureGridCard(
                        title: 'Speech Recording',
                        subtitle: 'Capture and evaluate audio samples with AI',
                        imagePath: AppAssets.speakIcon,
                        badgeText: 'RECORDER',
                        badgeColor: AppColors.primary,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppConstants.speechRecordingRoute,
                          );
                        },
                      ),
                      FeatureGridCard(
                        title: 'Risk Assessment',
                        subtitle: 'Interactive screening for articulation & fluency',
                        imagePath: AppAssets.riskIcon,
                        badgeText: 'SCREENER',
                        badgeColor: AppColors.cyan,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppConstants.riskAssessmentRoute,
                          );
                        },
                      ),
                      FeatureGridCard(
                        title: 'Therapeutic Drills',
                        subtitle: 'Guided exercises for rhythm & pronunciation',
                        imagePath: AppAssets.therapeuticExercises,
                        badgeText: 'PRACTICE',
                        badgeColor: const Color(0xFF8B5CF6),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppConstants.trainingRoute,
                          );
                        },
                      ),
                      FeatureGridCard(
                        title: 'Progress Tracking',
                        subtitle: 'Live analytics, milestones & fluency stats',
                        imagePath: AppAssets.progressTracking,
                        badgeText: 'INSIGHTS',
                        badgeColor: AppColors.success,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppConstants.progressRoute,
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Daily Quote
                  DailyQuoteCard(
                    quote: homeState.dailyQuote,
                    author: homeState.dailyAuthor,
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String displayName = 'Friend';
        String? photoUrl;

        if (state is Authenticated) {
          displayName = state.user.displayName.isNotEmpty
              ? state.user.displayName.split(' ').first
              : 'User';
          photoUrl = state.user.photoUrl;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $displayName 👋',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Ready for your speech session?',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                context.read<HomeCubit>().setTabIndex(3); // Switch to Profile tab
              },
              child: Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft,
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            AppAssets.profile1,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          AppAssets.profile1,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context, HomeState state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            icon: Icons.timer_outlined,
            value: '${state.minutesPracticed}m',
            label: 'Today',
            color: AppColors.primary,
          ),
          Container(width: 1, height: 32.h, color: AppColors.border),
          _statItem(
            icon: Icons.bolt_rounded,
            value: '${state.dailyStreak}d',
            label: 'Streak',
            color: AppColors.warning,
          ),
          Container(width: 1, height: 32.h, color: AppColors.border),
          _statItem(
            icon: Icons.verified_outlined,
            value: '7/7',
            label: 'Drills',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22.sp),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15.sp,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(fontSize: 11.sp),
            ),
          ],
        ),
      ],
    );
  }
}
