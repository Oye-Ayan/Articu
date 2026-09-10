import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class AudioVisualizerWave extends StatefulWidget {
  final bool isRecording;

  const AudioVisualizerWave({
    super.key,
    required this.isRecording,
  });

  @override
  State<AudioVisualizerWave> createState() => _AudioVisualizerWaveState();
}

class _AudioVisualizerWaveState extends State<AudioVisualizerWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          18,
          (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            width: 3.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            20,
            (index) {
              final factor = (sin((index + _controller.value * 6)) + 1) / 2;
              final height = 6.h + (factor * 32.h) + (_random.nextDouble() * 8.h);

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                width: 3.5.w,
                height: height.clamp(4.h, 44.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.sky],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
