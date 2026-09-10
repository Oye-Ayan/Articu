import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import 'edit_profile_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state.error != null) {
          CustomSnackBar.showError(context, state.error!);
        }
        if (state.message != null) {
          CustomSnackBar.showSuccess(context, state.message!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Account & Settings'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Avatar with Camera Button
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 104.w,
                          height: 104.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primarySoft,
                            border: Border.all(
                              color: AppColors.primaryLight.withValues(alpha: 0.5),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: state.isUploadingAvatar
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : state.profileImgUrl != null &&
                                        state.profileImgUrl!.isNotEmpty
                                    ? Image.network(
                                        state.profileImgUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Image.asset(
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
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              context
                                  .read<ProfileCubit>()
                                  .pickAndUploadAvatar();
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Username with Edit Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.username,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      InkWell(
                        onTap: () {
                          EditProfileSheet.show(context, state.username);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    state.email.isNotEmpty ? state.email : 'user@articulicare.com',
                    style: AppTextStyles.bodySmall,
                  ),
                  SizedBox(height: 20.h),

                  // Quick Stats Row
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _profileStat('5 Days', 'Active Streak'),
                        Container(
                          width: 1,
                          height: 28.h,
                          color: AppColors.border,
                        ),
                        _profileStat('18', 'Audio Drills'),
                        Container(
                          width: 1,
                          height: 28.h,
                          color: AppColors.border,
                        ),
                        _profileStat('88%', 'Pronunciation'),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Preferences & Settings Group
                  _sectionHeader('Therapy Preferences'),
                  SizedBox(height: 8.h),
                  _settingsContainer([
                    _switchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Practice Reminder Notifications',
                      subtitle: 'Daily gentle nudge at 09:00 AM',
                      value: state.notificationsEnabled,
                      onChanged: (val) {
                        context.read<ProfileCubit>().toggleNotifications(val);
                      },
                    ),
                    const Divider(height: 1),
                    _actionTile(
                      icon: Icons.access_time_rounded,
                      title: 'Daily Practice Time',
                      trailingText: state.practiceReminderTime ?? '09:00 AM',
                      onTap: () {
                        _showTimePicker(context);
                      },
                    ),
                  ]),
                  SizedBox(height: 20.h),

                  // Quick Navigation Group
                  _sectionHeader('Clinical Shortcuts'),
                  SizedBox(height: 8.h),
                  _settingsContainer([
                    _actionTile(
                      icon: Icons.analytics_outlined,
                      title: 'Articulation Risk Screener',
                      trailingText: 'Assess',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppConstants.riskAssessmentRoute,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _actionTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Speech Fluency Milestones',
                      trailingText: 'View',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppConstants.progressRoute,
                        );
                      },
                    ),
                  ]),
                  SizedBox(height: 20.h),

                  // Support & Legal Group
                  _sectionHeader('Support & Legal'),
                  SizedBox(height: 8.h),
                  _settingsContainer([
                    _actionTile(
                      icon: Icons.help_center_outlined,
                      title: 'Contact Clinical Support',
                      onTap: () {
                        _showInfoDialog(
                          context,
                          'Contact Support',
                          'Have inquiries or need help? Reach out to support@articulicare.com or message our team 24/7.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _actionTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy & Data Security',
                      onTap: () {
                        _showInfoDialog(
                          context,
                          'Privacy & HIPAA Compliance',
                          'ArticuliCare stores all voice audio and therapy logs with Row Level Security (RLS) encryption. Your voice records are only accessible to your authenticated account.',
                        );
                      },
                    ),
                  ]),
                  SizedBox(height: 24.h),

                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: () {
                      _confirmSignOut(context);
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: Text(
                      'Log Out of Account',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50.h),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
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

  Widget _profileStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _settingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(fontSize: 14.sp),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(fontSize: 14.sp),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 6.w),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null && context.mounted) {
      final formatted = time.format(context);
      context.read<ProfileCubit>().setPracticeReminder(formatted);
    }
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to sign out of ArticuliCare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
