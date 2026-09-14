import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../domain/training_lesson.dart';

class VideoPlayerModal extends StatefulWidget {
  final TrainingLesson lesson;
  final VoidCallback onCompleted;

  const VideoPlayerModal({
    super.key,
    required this.lesson,
    required this.onCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required TrainingLesson lesson,
    required VoidCallback onCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => VideoPlayerModal(
        lesson: lesson,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _controlsVisible = true;
  String? _errorMessage;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.lesson.videoUrl;
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'No video URL provided for this exercise.';
      });
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;

      await controller.initialize();
      controller.addListener(_onPlayerUpdate);
      controller.setLooping(false);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
        controller.play();
        _startHideTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  void _onPlayerUpdate() {
    if (mounted) {
      setState(() {});
      if (_controller != null &&
          _controller!.value.position >= _controller!.value.duration &&
          _controller!.value.duration > Duration.zero) {
        _controlsVisible = true;
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _controlsVisible = true;
        _hideTimer?.cancel();
      } else {
        _controller!.play();
        _startHideTimer();
      }
    });
  }

  void _seekRelative(Duration delta) {
    if (_controller == null || !_isInitialized) return;
    final newPos = _controller!.value.position + delta;
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : newPos > _controller!.value.duration
            ? _controller!.value.duration
            : newPos;
    _controller!.seekTo(clamped);
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return SafeArea(
      child: Container(
        height: isLandscape ? mediaQuery.size.height : mediaQuery.size.height * 0.88,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lesson.title,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.lesson.durationMinutes} • Tap screen for controls',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white60,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Video Canvas Viewport
            Expanded(
              child: Center(
                child: _errorMessage != null
                    ? Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 48,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              _errorMessage!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            AppButton(
                              text: 'Retry Loading Video',
                              onTap: () {
                                setState(() {
                                  _errorMessage = null;
                                  _isInitialized = false;
                                });
                                _initPlayer();
                              },
                            ),

                          ],
                        ),
                      )
                    : !_isInitialized
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              setState(() {
                                _controlsVisible = !_controlsVisible;
                              });
                              if (_controlsVisible) {
                                _startHideTimer();
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio:
                                      _controller!.value.aspectRatio > 0
                                          ? _controller!.value.aspectRatio
                                          : 16 / 9,
                                  child: VideoPlayer(_controller!),
                                ),

                                // Control Overlay
                                AnimatedOpacity(
                                  opacity: _controlsVisible ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 250),
                                  child: Container(
                                    color: Colors.black45,
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Rewind 10s
                                          IconButton(
                                            iconSize: 36.sp,
                                            icon: const Icon(
                                              Icons.replay_10_rounded,
                                              color: Colors.white,
                                            ),
                                            onPressed: () => _seekRelative(
                                              const Duration(seconds: -10),
                                            ),
                                          ),
                                          SizedBox(width: 24.w),

                                          // Play / Pause Toggle
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 16,
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              iconSize: 42.sp,
                                              icon: Icon(
                                                _controller!.value.isPlaying
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                                color: Colors.white,
                                              ),
                                              onPressed: _togglePlayPause,
                                            ),
                                          ),
                                          SizedBox(width: 24.w),

                                          // Fast forward 10s
                                          IconButton(
                                            iconSize: 36.sp,
                                            icon: const Icon(
                                              Icons.forward_10_rounded,
                                              color: Colors.white,
                                            ),
                                            onPressed: () => _seekRelative(
                                              const Duration(seconds: 10),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),

            // Scrubber Bar & Exercise Description Footer
            if (_isInitialized && _controller != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primary,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_controller!.value.position),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                        Text(
                          _formatDuration(_controller!.value.duration),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Technique Instruction Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      color: AppColors.sky,
                      size: 20,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        widget.lesson.techniquePrompt,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 12.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Complete Drill Action Button
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: AppButton(
                text: 'Mark Drill as Completed (+${widget.lesson.points} pts)',
                icon: Icons.check_circle_rounded,
                onTap: () {
                  widget.onCompleted();
                  Navigator.pop(context);
                  CustomSnackBar.showSuccess(
                    context,
                    'Drill "${widget.lesson.title}" completed! +${widget.lesson.points} points awarded.',
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
