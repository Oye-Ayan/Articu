import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/therapist_cubit.dart';
import '../cubit/therapist_state.dart';
import 'booking_sheet.dart';
import 'marham_web_screen.dart';

class TherapistScreen extends StatelessWidget {
  const TherapistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TherapistCubit, TherapistState>(
      listener: (context, state) {
        if (state.bookingSuccessMessage != null) {
          CustomSnackBar.showSuccess(context, state.bookingSuccessMessage!);
        }
        if (state.errorMessage != null) {
          CustomSnackBar.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        final authState = context.read<AuthCubit>().state;
        final currentUser = authState is Authenticated ? authState.user : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('1-on-1 Speech Therapy'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Directory',
                onPressed: () =>
                    context.read<TherapistCubit>().fetchTherapists(),
              ),
              IconButton(
                icon: const Icon(Icons.support_agent_rounded),
                onPressed: () => _showSupportDialog(context),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  context.read<TherapistCubit>().fetchTherapists(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Header Card
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        gradient: AppColors.softCardGradient,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: AppColors.primaryMuted),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    'CERTIFIED SPECIALISTS',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  'Personalized Sessions With Licensed Clinicians',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  'Work directly with expert therapists specialized in stuttering, articulation, and rate control.',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            width: 58.w,
                            height: 58.w,
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              AppAssets.splashLogo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // MARHAM TELEHEALTH INTEGRATION CARD
                    Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F4CD9), Color(0xFF1E60F2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E60F2).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  'MARHAM WEB PORTAL',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'Book Speech Therapists Online',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Access licensed Pakistani speech-language pathologists directly through the integrated Marham portal.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => MarhamWebScreen.open(context),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                                color: Color(0xFF0F4CD9),
                              ),
                              label: Text(
                                'Open Marham Consultation Portal',
                                style: AppTextStyles.button.copyWith(
                                  color: const Color(0xFF0F4CD9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Benefits checklist
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
                          _benefitRow('100% online video consultations at your convenience'),
                          _benefitRow('Available evening & weekend slots'),
                          _benefitRow('ASHA & Certified speech-language pathologists'),
                          _benefitRow('Customized clinical exercise plans in ArticuliCare'),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Therapist Directory Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Pathologists',
                          style: AppTextStyles.titleLarge,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${state.therapists.length} Online',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),

                    // Therapist Cards List
                    if (state.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.therapists.length,
                        separatorBuilder: (_, __) => SizedBox(height: 14.h),
                        itemBuilder: (context, index) {
                          final therapist = state.therapists[index];

                          return Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 28.r,
                                      backgroundColor: AppColors.primarySoft,
                                      child: Text(
                                        therapist.name
                                            .replaceAll('Dr. ', '')
                                            .trim()[0],
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 14.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            therapist.name,
                                            style: AppTextStyles.titleSmall.copyWith(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15.sp,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            therapist.title,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            therapist.specialty,
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 16.sp,
                                            color: const Color(0xFFD97706),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            therapist.rating.toString(),
                                            style: AppTextStyles.caption.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFB45309),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 14.h),
                                const Divider(color: AppColors.border, height: 1),
                                SizedBox(height: 12.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      therapist.hourlyRate,
                                      style: AppTextStyles.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    AppButton(
                                      text: 'Book Consult',
                                      width: 130.w,
                                      height: 38.h,
                                      onTap: () {
                                        context
                                            .read<TherapistCubit>()
                                            .selectTherapist(therapist);
                                        BookingSheet.show(context, therapist);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    SizedBox(height: 24.h),

                    // Registration Callout
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showRegisterTherapistDialog(
                          context,
                          currentUser?.email ?? '',
                          currentUser?.id ?? '',
                        ),
                        icon: const Icon(Icons.badge_rounded, color: AppColors.primary),
                        label: const Text(
                          'Are you a certified therapist? Register here',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRegisterTherapistDialog(
    BuildContext context,
    String defaultEmail,
    String userId,
  ) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController(text: defaultEmail);
    final qualCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Register as a Clinician'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameCtrl,
                labelText: 'Full Name',
                hintText: 'e.g. Dr. John Doe',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: emailCtrl,
                labelText: 'Professional Email',
                hintText: 'name@clinic.com',
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: qualCtrl,
                labelText: 'Qualifications & Credentials',
                hintText: 'e.g. MS Speech-Language Pathology',
                prefixIcon: const Icon(Icons.school_outlined),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || qualCtrl.text.trim().isEmpty) {
                CustomSnackBar.showError(ctx, 'Please fill in all fields');
                return;
              }
              Navigator.pop(ctx);
              await context.read<TherapistCubit>().registerTherapist(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    qualifications: qualCtrl.text.trim(),
                    userId: userId,
                  );
            },
            child: const Text('Submit Application'),
          ),
        ],
      ),
    );
  }

  Widget _benefitRow(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Therapy Support Helpline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our clinical coordinator team is available to assist you with session scheduling or platform queries.',
            ),
            SizedBox(height: 14.h),
            const Text('Email: support@articulicare.org', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4.h),
            const Text('Helpline: +1 (800) 555-CARE', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4.h),
            const Text('Hours: Mon - Fri (9:00 AM - 6:00 PM)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
