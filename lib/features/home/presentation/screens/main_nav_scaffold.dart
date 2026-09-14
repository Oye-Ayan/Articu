import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../speech_recording/presentation/screens/speech_recording_screen.dart';
import '../../../therapist/presentation/screens/therapist_screen.dart';
import '../../../training/presentation/screens/training_screen.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'home_screen.dart';

class MainNavScaffold extends StatelessWidget {
  const MainNavScaffold({super.key});

  final List<Widget> _pages = const [
    HomeScreen(),
    TherapistScreen(),
    SpeechRecordingScreen(),
    TrainingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final currentIndex = state.selectedIndex.clamp(0, _pages.length - 1);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(
            index: currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
              border: const Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(
                      context: context,
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.home_rounded,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                    ),
                    _navItem(
                      context: context,
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.medical_services_outlined,
                      activeIcon: Icons.medical_services_rounded,
                      label: 'Therapist',
                    ),
                    _centerMicItem(
                      context: context,
                      index: 2,
                      currentIndex: currentIndex,
                    ),
                    _navItem(
                      context: context,
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.fitness_center_rounded,
                      activeIcon: Icons.fitness_center_rounded,
                      label: 'Drills',
                    ),
                    _navItem(
                      context: context,
                      index: 4,
                      currentIndex: currentIndex,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navItem({
    required BuildContext context,
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = index == currentIndex;

    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: () => context.read<HomeCubit>().setTabIndex(index),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerMicItem({
    required BuildContext context,
    required int index,
    required int currentIndex,
  }) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => context.read<HomeCubit>().setTabIndex(index),
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isSelected ? 0.4 : 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.mic_rounded,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }
}
