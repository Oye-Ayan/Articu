import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/speech_cubit.dart';
import '../cubit/speech_state.dart';
import '../widgets/audio_visualizer_wave.dart';
import '../widgets/pulsing_mic_button.dart';

class SpeechRecordingScreen extends StatefulWidget {
  const SpeechRecordingScreen({super.key});

  @override
  State<SpeechRecordingScreen> createState() => _SpeechRecordingScreenState();
}

class _SpeechRecordingScreenState extends State<SpeechRecordingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SpeechCubit, SpeechState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          CustomSnackBar.showError(context, state.errorMessage!);
        }
        if (state.successMessage != null) {
          CustomSnackBar.showSuccess(context, state.successMessage!);
        }
      },
      builder: (context, state) {
        final authState = context.read<AuthCubit>().state;
        final username = authState is Authenticated
            ? authState.user.displayName
            : 'User';

        final filteredRecordings = state.recentRecordings.where((r) {
          if (_searchQuery.isEmpty) return true;
          return r.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.username.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Voice Recorder'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () {
                  _showRecordingTips(context);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Recorder Studio Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: state.isRecording
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: state.isRecording
                                      ? AppColors.error
                                      : AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                state.isRecording
                                    ? 'LIVE RECORDING'
                                    : 'READY TO RECORD',
                                style: AppTextStyles.caption.copyWith(
                                  color: state.isRecording
                                      ? AppColors.error
                                      : AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Timer Display
                        Text(
                          _formatDuration(state.recordingDuration),
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 42.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: state.isRecording
                                ? AppColors.error
                                : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Waveform
                        SizedBox(
                          height: 50.h,
                          child: AudioVisualizerWave(
                            isRecording: state.isRecording,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Pulsing Mic Button
                        PulsingMicButton(
                          isRecording: state.isRecording,
                          onTap: () {
                            if (state.isRecording) {
                              context.read<SpeechCubit>().stopRecording(
                                    username: username,
                                  );
                            } else {
                              context.read<SpeechCubit>().startRecording();
                            }
                          },
                        ),
                        SizedBox(height: 16.h),

                        Text(
                          state.isRecording
                              ? 'Tap to stop & save audio sample'
                              : 'Tap microphone to speak prompt',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        if (state.isUploading) ...[
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Uploading to Supabase bucket...',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Recent Recordings Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Recordings',
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
                          '${state.recentRecordings.length} Samples',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search speech recordings...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Recordings List
                  if (filteredRecordings.isEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.h),
                      child: Column(
                        children: [
                          Icon(
                            Icons.mic_none_rounded,
                            size: 48.sp,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'No recordings found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRecordings.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final rec = filteredRecordings[index];
                        final dateStr = DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(rec.timestamp);

                        return Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: const Icon(
                                  Icons.multitrack_audio_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Speech Sample #${filteredRecordings.length - index}',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      dateStr,
                                      style: AppTextStyles.caption,
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
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  '${rec.duration.inSeconds}s',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                icon: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  CustomSnackBar.showInfo(
                                    context,
                                    'Playing speech recording #${filteredRecordings.length - index}',
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRecordingTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8.w),
            const Text('Recording Tips'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tipItem('Hold your device 15-20cm from your mouth.'),
            _tipItem('Speak clearly at your natural comfortable pace.'),
            _tipItem('Ensure you are in a quiet room with minimal background echo.'),
            _tipItem('Audio is automatically uploaded to Supabase secure storage.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}
