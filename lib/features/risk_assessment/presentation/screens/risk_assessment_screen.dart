import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class RiskAssessmentScreen extends StatefulWidget {
  const RiskAssessmentScreen({super.key});

  @override
  State<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends State<RiskAssessmentScreen> {
  int _currentStep = 0;
  final List<String> _selectedSymptoms = [];
  final List<String> _selectedTriggers = [];
  double _severityScore = 4.0;
  bool _isFinished = false;

  final List<String> _symptoms = [
    'Repetition of sounds or initial syllables (e.g. "b-b-ball")',
    'Prolongation of speech sounds (e.g. "ssss-un")',
    'Physical tension in throat, lips, or jaw when initiating speech',
    'Frequent speech blocks or moments where no sound comes out',
    'Rapid or rushed rate of speech with blurred words',
  ];

  final List<String> _triggers = [
    'Speaking on telephone or conference calls',
    'Presenting or speaking to groups',
    'Interacting with authority figures or job interviews',
    'Ordering food in restaurants or drive-throughs',
    'Casual conversations with close friends or family',
  ];

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      setState(() => _isFinished = true);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Articulation Risk Screener'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: _isFinished ? _buildResultsView() : _buildStepView(),
        ),
      ),
    );
  }

  Widget _buildStepView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${_currentStep + 1} of 3',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Clinical Self-Assessment',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            minHeight: 6.h,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        SizedBox(height: 24.h),

        if (_currentStep == 0) _buildSymptomsStep(),
        if (_currentStep == 1) _buildTriggersStep(),
        if (_currentStep == 2) _buildSeverityStep(),

        SizedBox(height: 32.h),

        // Navigation Controls
        Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Back'),
                ),
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              flex: 2,
              child: AppButton(
                text: _currentStep == 2 ? 'Complete Evaluation' : 'Next Step',
                onTap: _nextStep,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSymptomsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Speech Symptoms',
          style: AppTextStyles.titleLarge,
        ),
        SizedBox(height: 6.h),
        Text(
          'Select any speech patterns or disfluencies you regularly experience:',
          style: AppTextStyles.bodyMedium,
        ),
        SizedBox(height: 18.h),
        ..._symptoms.map((symptom) {
          final isSelected = _selectedSymptoms.contains(symptom);
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSymptoms.remove(symptom);
                  } else {
                    _selectedSymptoms.add(symptom);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySoft
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        symptom,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTriggersStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Situational Triggers',
          style: AppTextStyles.titleLarge,
        ),
        SizedBox(height: 6.h),
        Text(
          'In which environments do you feel most speech difficulty or hesitation?',
          style: AppTextStyles.bodyMedium,
        ),
        SizedBox(height: 18.h),
        ..._triggers.map((trigger) {
          final isSelected = _selectedTriggers.contains(trigger);
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTriggers.remove(trigger);
                  } else {
                    _selectedTriggers.add(trigger);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySoft
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        trigger,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSeverityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Self-Perceived Severity',
          style: AppTextStyles.titleLarge,
        ),
        SizedBox(height: 6.h),
        Text(
          'On a scale from 1 (Minimal) to 10 (High Impact), how much does speech affect your daily life?',
          style: AppTextStyles.bodyMedium,
        ),
        SizedBox(height: 32.h),

        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.primaryMuted),
            ),
            child: Text(
              '${_severityScore.round()} / 10',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),

        Slider(
          value: _severityScore,
          min: 1.0,
          max: 10.0,
          divisions: 9,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
          onChanged: (val) => setState(() => _severityScore = val),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 - Mild', style: AppTextStyles.caption),
            Text('5 - Moderate', style: AppTextStyles.caption),
            Text('10 - Severe', style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    final riskLevel = _severityScore > 6.5
        ? 'Moderate-to-High Disfluency Risk'
        : (_severityScore > 3.5
            ? 'Mild Disfluency & Articulation Tension'
            : 'Low Articulation Risk');

    final color = _severityScore > 6.5
        ? AppColors.error
        : (_severityScore > 3.5 ? AppColors.warning : AppColors.success);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.analytics_rounded, color: color, size: 30.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                'Clinical Screening Completed',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                riskLevel,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Identified ${_selectedSymptoms.length} active symptoms and ${_selectedTriggers.length} situational triggers.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        Text('Recommended Next Steps', style: AppTextStyles.titleLarge),
        SizedBox(height: 12.h),

        _recTile(
          icon: Icons.fitness_center_rounded,
          title: 'Daily Flexible Rate Drills',
          subtitle:
              'Focus 5 mins daily on vowel prolongation and continuous phonation to ease speech blocks.',
          actionLabel: 'Go to Training',
          onTap: () {
            Navigator.pushReplacementNamed(context, AppConstants.trainingRoute);
          },
        ),
        SizedBox(height: 10.h),

        _recTile(
          icon: Icons.mic_rounded,
          title: 'Record Baseline Audio Sample',
          subtitle:
              'Record a 30-second speech sample to track your articulation clarity and rate over time.',
          actionLabel: 'Record Sample',
          onTap: () {
            Navigator.pushReplacementNamed(
              context,
              AppConstants.speechRecordingRoute,
            );
          },
        ),
        SizedBox(height: 10.h),

        _recTile(
          icon: Icons.person_search_rounded,
          title: 'Consult a Speech-Language Pathologist',
          subtitle:
              'Connect with a certified CCC-SLP clinician for a comprehensive clinical diagnostic evaluation.',
          actionLabel: 'Find Therapist',
          onTap: () {
            Navigator.pushReplacementNamed(
              context,
              AppConstants.therapistRoute,
            );
          },
        ),
        SizedBox(height: 24.h),

        AppButton(
          text: 'Save & Return to Dashboard',
          onTap: () {
            CustomSnackBar.showSuccess(
              context,
              'Assessment evaluation saved to your profile!',
            );
            Navigator.pop(context);
          },
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _recTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(subtitle, style: AppTextStyles.bodySmall),
                SizedBox(height: 8.h),
                InkWell(
                  onTap: onTap,
                  child: Text(
                    actionLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
