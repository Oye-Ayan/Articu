import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/audio/speech_analysis_service.dart';
import '../../../core/utils/ml/tflite_service.dart';
import '../../../viewmodels/speech_recording_viewmodel.dart';

class SpeechRecording extends StatelessWidget {
  const SpeechRecording({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final tfliteService = TfliteService();
        final analysisService = SpeechAnalysisService(tfliteService);
        return SpeechRecordingViewModel(analysisService, Supabase.instance.client);
      },
      child: const SpeechRecordingView(),
    );
  }
}

class SpeechRecordingView extends StatelessWidget {
  const SpeechRecordingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Sleek very light gray/blue bg
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Voice Assessment',
          style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  title: const Text('About Voice Assessment'),
                  content: const Text(
                    'This tool uses advanced Machine Learning (TFLite) to analyze your speech features in real-time. '
                    'It extracts Mel-Frequency Cepstral Coefficients (MFCCs) to identify potential signs of dysarthria.\n\n'
                    'This is not a diagnostic tool. Please consult a healthcare professional for clinical advice.',
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SpeechRecordingViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.state == RecordingState.error && viewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.errorMessage!),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              viewModel.reset();
            });
          }

          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(),
                      SizedBox(height: 24.h),
                      _buildGuidelinesCard(),
                      SizedBox(height: 40.h),
                      _buildRecordingUI(context, viewModel),
                      SizedBox(height: 30.h),
                      if (viewModel.state == RecordingState.complete)
                        _buildResultCard(viewModel).animate().slideY(begin: 0.2).fadeIn(),
                    ],
                  ),
                ),
              ),
              if (viewModel.state == RecordingState.processing)
                _buildProcessingOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.sp),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.blueAccent, size: 28),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: const Text(
                  'AI Speech Analysis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Text(
            'Record 3-5 seconds of speech to detect articulation patterns using our real-time dysarthria model.',
            style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildGuidelinesCard() {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guidelines',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 12.h),
          _buildBullet('Speak clearly at a normal pace'),
          _buildBullet('Record in a quiet environment'),
          _buildBullet('Hold device 8-12 inches away'),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          SizedBox(width: 10.w),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black54))),
        ],
      ),
    );
  }

  Widget _buildRecordingUI(BuildContext context, SpeechRecordingViewModel viewModel) {
    bool isRecording = viewModel.state == RecordingState.recording;
    String timeStr = '${(viewModel.recordingDuration ~/ 60).toString().padLeft(2, '0')}:${(viewModel.recordingDuration % 60).toString().padLeft(2, '0')}';

    return Column(
      children: [
        if (isRecording)
          Text(
            timeStr,
            style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1500.ms)
        else
          Text(
            'Ready to Record',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        SizedBox(height: 30.h),
        GestureDetector(
          onTap: () {
            if (isRecording) {
              viewModel.stopRecording();
            } else {
              viewModel.startRecording();
            }
          },
          child: Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecording ? Colors.redAccent : Colors.blueAccent,
              boxShadow: [
                BoxShadow(
                  color: (isRecording ? Colors.redAccent : Colors.blueAccent).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 50.sp,
            ),
          ).animate(target: isRecording ? 1 : 0)
           .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms)
           .then(delay: 200.ms)
           .shimmer(duration: 1.seconds),
        ),
        SizedBox(height: 20.h),
        Text(
          isRecording ? 'Tap to Stop & Analyze' : 'Tap to Start',
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }

  Widget _buildResultCard(SpeechRecordingViewModel viewModel) {
    final int? result = viewModel.predictionResult;
    if (result == null) return const SizedBox.shrink();

    bool hasDysarthria = result == 1;

    return Container(
      padding: EdgeInsets.all(24.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasDysarthria 
              ? [Colors.orange.shade50, Colors.red.shade50]
              : [Colors.green.shade50, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: hasDysarthria ? Colors.orange.shade200 : Colors.green.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasDysarthria ? Colors.red : Colors.green).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            hasDysarthria ? Icons.warning_amber_rounded : Icons.verified_rounded,
            color: hasDysarthria ? Colors.orange : Colors.green,
            size: 48.sp,
          ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
          SizedBox(height: 16.h),
          Text(
            hasDysarthria ? 'Signs of Dysarthria Detected' : 'No Signs of Dysarthria',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: hasDysarthria ? Colors.deepOrange.shade800 : Colors.green.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            hasDysarthria 
              ? 'Our model detected features often associated with dysarthria. We recommend trying some daily vocal exercises and consulting a speech therapist.'
              : 'Your speech patterns appear typical and do not strongly match the dysarthria features in our dataset.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: viewModel.reset,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasDysarthria ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              minimumSize: Size(double.infinity, 50.h),
            ),
            child: const Text('Record Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.8), // Frosted glass effect fallback
      child: Center(
        child: Container(
          padding: EdgeInsets.all(30.sp),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 10,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 24.h),
              const Text(
                'Extracting MFCC Features...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}