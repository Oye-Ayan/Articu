// ignore_for_file: unused_field
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  VideoPlayerController? _videoPlayerController;
  bool _isPlaying = false;
  bool _controlsVisible = true;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Track user progress
  final Map<int, bool> _completedExercises = {};
  int _totalPoints = 0;

  // For day unlocking logic
  final List<DateTime?> _dayUnlockTimes = List.filled(5, null); // Track completion times for each day
  final int _totalExercisesPerDay = 8; // Number of exercises per day (based on titles list)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Auto-select first item
    _selectedIndex = 0;
    _animationController.forward();
    _loadProgress(); // Load progress when the page initializes
  }

  bool isDayUnlocked(int dayIndex) {
    if (dayIndex == 0) return true; // Day 1 is always unlocked

    final previousDayIndex = dayIndex - 1;
    final previousDayCompletedAt = _dayUnlockTimes[previousDayIndex];

    if (previousDayCompletedAt == null) {
      return false; // Previous day not completed
    }

    final now = DateTime.now();
    final timeSinceCompletion = now.difference(previousDayCompletedAt);
    final isUnlocked = timeSinceCompletion.inHours >= 24;

    print('Day ${dayIndex + 1} unlock check: Previous day completed at $previousDayCompletedAt, Time since: ${timeSinceCompletion.inHours} hours, Unlocked: $isUnlocked');

    return isUnlocked;
  }

  void _showBetaDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 24.sp),
              SizedBox(width: 10.w),
              Text(
                'Beta Version',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This is a beta version. The complete module is not available at the moment.',
                style: TextStyle(fontSize: 14.sp, height: 1.4),
              ),
              SizedBox(height: 10.h),
              Text(
                'We appreciate your patience as we continue to improve.',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[700], height: 1.4),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLockedDayDialog(int dayIndex) {
    final previousDayIndex = dayIndex - 1;
    final previousDayCompletedAt = _dayUnlockTimes[previousDayIndex];
    String message = 'Complete the current day to unlock the next one.';
    String timeRemaining = '';

    if (previousDayCompletedAt != null) {
      final now = DateTime.now();
      final timeSinceCompletion = now.difference(previousDayCompletedAt);
      final hoursRemaining = 24 - timeSinceCompletion.inHours;
      final minutesRemaining = 60 - (timeSinceCompletion.inMinutes % 60);

      if (hoursRemaining > 0) {
        timeRemaining = 'Unlocks in $hoursRemaining hours and $minutesRemaining minutes.';
      } else if (minutesRemaining > 0) {
        timeRemaining = 'Unlocks in $minutesRemaining minutes.';
      } else {
        timeRemaining = 'Should be unlocked soon. Please try again.';
      }
      message = 'Next exercises will be available after 24 hours.';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.blue[700], size: 24.sp),
              SizedBox(width: 10.w),
              Text(
                'Day ${dayIndex + 1} Locked',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 14.sp, height: 1.4),
              ),
              if (timeRemaining.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(
                  timeRemaining,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[700], height: 1.4),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to load existing progress from Supabase
  Future<void> _loadProgress() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      // Load exercise progress for Day 1
      final response = await _supabase
          .from('user_training')
          .select()
          .eq('user_id', user.uid.toString())
          .eq('day_number', 1);

      if (response.isNotEmpty) {
        setState(() {
          for (var record in response) {
            final exerciseIndex = record['exercise_index'] as int;
            final completed = record['completed'] as bool;
            final points = record['points'] as int? ?? 0;
            _completedExercises[exerciseIndex] = completed;
            if (completed) {
              _totalPoints += points;
            }
          }
        });
      }

      // Load day completion timestamps
      final dayProgressResponse = await _supabase
          .from('user_day_progress')
          .select()
          .eq('user_id', user.uid.toString());

      if (dayProgressResponse.isNotEmpty) {
        setState(() {
          for (var record in dayProgressResponse) {
            final dayIndex = (record['day_number'] as int) - 1; // Convert to 0-based index
            if (dayIndex >= 0 && dayIndex < _dayUnlockTimes.length) {
              _dayUnlockTimes[dayIndex] = DateTime.parse(record['completed_at']).toLocal();
            }
          }
        });
      }
    } catch (e) {
      print('Error loading progress: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading progress: $e'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  // Function to save progress to Supabase
  Future<void> _saveProgress(int dayNumber, int exerciseIndex, bool completed, int points) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }

    // Optimistically update UI
    if (mounted) {
      setState(() {
        _completedExercises[exerciseIndex] = completed;
        if (completed && !_completedExercises.containsKey(exerciseIndex)) {
          _totalPoints += points;
        }
      });
    }

    try {
      // Save exercise progress
      final existingData = await _supabase
          .from('user_training')
          .select()
          .eq('user_id', user.uid.toString())
          .eq('day_number', dayNumber)
          .eq('exercise_index', exerciseIndex)
          .maybeSingle();

      final progressData = {
        'user_id': user.uid.toString(),
        'day_number': dayNumber,
        'exercise_index': exerciseIndex,
        'completed': completed,
        'points': points,
        'completed_at': completed ? DateTime.now().toUtc().toIso8601String() : null,
        'created_at': existingData == null ? DateTime.now().toUtc().toIso8601String() : existingData['created_at'],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (existingData != null) {
        await _supabase
            .from('user_training')
            .update(progressData)
            .eq('id', existingData['id']);
      } else {
        await _supabase.from('user_training').insert(progressData);
      }

      // Check if all exercises for the day are completed
      final dayExercises = await _supabase
          .from('user_training')
          .select()
          .eq('user_id', user.uid.toString())
          .eq('day_number', dayNumber);

      final completedCount = dayExercises.where((record) => record['completed'] == true).length;
      if (completedCount == _totalExercisesPerDay) {
        // All exercises for this day are completed, save the completion timestamp
        final existingDayProgress = await _supabase
            .from('user_day_progress')
            .select()
            .eq('user_id', user.uid.toString())
            .eq('day_number', dayNumber)
            .maybeSingle();

        final dayProgressData = {
          'user_id': user.uid.toString(),
          'day_number': dayNumber,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
          'created_at': existingDayProgress == null ? DateTime.now().toUtc().toIso8601String() : existingDayProgress['created_at'],
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        if (existingDayProgress != null) {
          await _supabase
              .from('user_day_progress')
              .update(dayProgressData)
              .eq('id', existingDayProgress['id']);
        } else {
          await _supabase.from('user_day_progress').insert(dayProgressData);
        }

        // Update _dayUnlockTimes
        setState(() {
          _dayUnlockTimes[dayNumber - 1] = DateTime.now();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Day $dayNumber completed! Next day unlocks in 24 hours.'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              margin: EdgeInsets.all(16.w),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Progress saved successfully! +$points points'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    } catch (e) {
      print('Detailed error saving progress: $e');
      if (mounted) {
        setState(() {
          _completedExercises[exerciseIndex] = !completed;
          if (completed && !_completedExercises.containsKey(exerciseIndex)) {
            _totalPoints -= points;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save progress: $e'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    }
  }

  // Function to fetch video URL and play video
  Future<void> _playVideo(String videoFileName, int index) async {
    try {
      final String videoUrl = await _supabase.storage
          .from('training-videos')
          .getPublicUrl(videoFileName);

      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..addListener(() {
          final isPlaying = _videoPlayerController!.value.isPlaying;
          if (isPlaying != _isPlaying && mounted) {
            setState(() {
              _isPlaying = isPlaying;
              if (isPlaying) {
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted && _isPlaying) {
                    setState(() {
                      _controlsVisible = false;
                    });
                  }
                });
              }
            });
          }
        });

      await _videoPlayerController!.initialize();

      setState(() {
        _controlsVisible = true;
        _isPlaying = false;
      });

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildVideoDialog(index),
      );

      // Mark exercise as completed and save progress
      if (mounted) {
        await _saveProgress(1, index, true, 10); // Assuming day_number is 1
      }

      _videoPlayerController?.dispose();
      if (mounted) {
        setState(() {
          _videoPlayerController = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _playVideo(videoFileName, index),
            ),
          ),
        );
      }
    }
  }

  Widget _buildVideoDialog(int exerciseIndex) {
    return WillPopScope(
      onWillPop: () async {
        _videoPlayerController?.pause();
        return true;
      },
      child: Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setDialogState(() {
                      _controlsVisible = !_controlsVisible;
                    });
                  },
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController!),
                  ),
                ),
                if (!_isPlaying)
                  GestureDetector(
                    onTap: () {
                      _videoPlayerController!.play();
                      setDialogState(() {
                        _isPlaying = true;
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setDialogState(() {
                              _controlsVisible = false;
                            });
                          }
                        });
                      });
                    },
                  ),
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  right: 16.w,
                  child: AnimatedOpacity(
                    opacity: _controlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exercise ${exerciseIndex + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_controlsVisible)
                  Positioned(
                    bottom: 50.h,
                    left: 16.w,
                    right: 16.w,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.replay_10, color: Colors.white, size: 28.sp),
                              onPressed: () {
                                final current = _videoPlayerController!.value.position;
                                _videoPlayerController!.seekTo(current - const Duration(seconds: 10));
                              },
                            ),
                            SizedBox(width: 16.w),
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: Colors.white,
                                size: 48.sp,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  if (_isPlaying) {
                                    _videoPlayerController!.pause();
                                    _isPlaying = false;
                                  } else {
                                    _videoPlayerController!.play();
                                    _isPlaying = true;
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (mounted && _isPlaying) {
                                        setDialogState(() {
                                          _controlsVisible = false;
                                        });
                                      }
                                    });
                                  }
                                });
                              },
                            ),
                            SizedBox(width: 16.w),
                            IconButton(
                              icon: Icon(Icons.forward_10, color: Colors.white, size: 28.sp),
                              onPressed: () {
                                final current = _videoPlayerController!.value.position;
                                _videoPlayerController!.seekTo(current + const Duration(seconds: 10));
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            ValueListenableBuilder(
                              valueListenable: _videoPlayerController!,
                              builder: (context, VideoPlayerValue value, child) {
                                return Text(
                                  _formatDuration(value.position),
                                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                                );
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: VideoProgressIndicator(
                                  _videoPlayerController!,
                                  allowScrubbing: true,
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  colors: VideoProgressColors(
                                    playedColor: Colors.blue[400]!,
                                    bufferedColor: Colors.grey[400]!,
                                    backgroundColor: Colors.grey[700]!,
                                  ),
                                ),
                              ),
                            ),
                            ValueListenableBuilder(
                              valueListenable: _videoPlayerController!,
                              builder: (context, VideoPlayerValue value, child) {
                                return Text(
                                  _formatDuration(value.duration),
                                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [
      "Introduction",
      "Balloon Blowing",
      "Let's Say the K Sound",
      "Let's Say the L Sound",
      "Let's Say the S Sound",
      "Lip Trace",
      "Tongue Clicks",
      "Tongue Lip Exercises"
    ];
    final List<String> times = [
      "40 secs",
      "10 secs",
      "30 secs",
      "30 secs",
      "30 secs",
      "10 secs",
      "10 secs",
      "10 secs"
    ];
    final List<String> videoFiles = [
      "Introduction.mp4",
      "Ballon Blowing.mp4",
      "Lets Say the K sound.mp4",
      "Lets say the L sound.mp4",
      "Lets say the S sound.mp4",
      "Lip Trace.mp4",
      "Tongue Clicks.mp4",
      "Tongue Lip myo.mp4"
    ];
    final List<IconData> exerciseIcons = [
      Icons.video_library,
      Icons.air,
      Icons.record_voice_over,
      Icons.record_voice_over,
      Icons.record_voice_over,
      Icons.face,
      Icons.face_unlock_rounded,
      Icons.face_retouching_natural,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade50,
        centerTitle: true,
        title: Text(
          'Daily Practice',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.blue[700]),
            onPressed: _showBetaDialog,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue[700], size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Your Progress',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 80.h,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  final isUnlocked = isDayUnlocked(index);
                  String? timeRemaining;
                  if (!isUnlocked && _dayUnlockTimes[index - 1] != null) {
                    final timeSinceCompletion = DateTime.now().difference(_dayUnlockTimes[index - 1]!);
                    final hoursRemaining = 24 - timeSinceCompletion.inHours;
                    if (hoursRemaining > 0) {
                      timeRemaining = '$hoursRemaining hr';
                    } else {
                      timeRemaining = '<1 hr';
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      if (!isUnlocked) {
                        _showLockedDayDialog(index);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Day ${index + 1} is already unlocked!'),
                            backgroundColor: Colors.blue,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            margin: EdgeInsets.all(16.w),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.only(right: 16.w),
                      child: SizedBox(
                        width: 50.w,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44.w,
                              height: 44.h,
                              decoration: BoxDecoration(
                                color: isUnlocked ? Colors.blue[700] : Colors.grey[300],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isUnlocked
                                    ? Text(
                                        '0${index + 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Icon(
                                        Icons.lock,
                                        color: Colors.grey[600],
                                        size: 18.sp,
                                      ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Flexible(
                              child: Text(
                                timeRemaining != null ? timeRemaining : 'Day ${index + 1}',
                                style: TextStyle(
                                  color: isUnlocked ? Colors.blue[700] : Colors.grey[600],
                                  fontSize: 12.sp,
                                  fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(
                        duration: 600.ms,
                        delay: Duration(milliseconds: 100 * index),
                      ).slideX(
                        begin: 0.1,
                        end: 0,
                        curve: Curves.easeOutQuad,
                      );
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _showBetaDialog();
                },
                icon: Icon(Icons.calendar_month, color: Colors.blue[700], size: 16.sp),
                label: Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, color: Colors.blue[800], size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Today\'s Exercises',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16.sp),
                        SizedBox(width: 4.w),
                        Text(
                          '$_totalPoints pts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(
                        duration: 300.ms,
                        curve: Curves.easeOutBack,
                      ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: titles.length,
                itemBuilder: (context, index) {
                  final bool isCompleted = _completedExercises[index] ?? false;
                  final bool isSelected = _selectedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected ${titles[index]}'),
                          backgroundColor: Colors.blue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          margin: EdgeInsets.all(16.w),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected ? Colors.blue[400]! : Colors.grey[200]!,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                        child: Row(
                          children: [
                            Container(
                              width: 44.w,
                              height: 44.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [Colors.blue[200]!, Colors.blue[100]!]
                                      : [Colors.grey[200]!, Colors.grey[100]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                exerciseIcons[index],
                                color: isSelected ? Colors.blue[700] : Colors.grey[600],
                                size: 22.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        titles[index],
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.blue[800] : Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      if (isCompleted)
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16.sp,
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Colors.grey[500],
                                        size: 14.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        times[index],
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.play_circle_fill,
                                color: isSelected ? Colors.blue[700] : Colors.grey[400],
                                size: 36.sp,
                              ),
                              onPressed: () => _playVideo(videoFiles[index], index),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(
                        duration: 600.ms,
                        delay: Duration(milliseconds: 100 * index),
                      ).slideY(
                        begin: 0.2,
                        end: 0,
                        curve: Curves.easeOutQuad,
                      );
                },
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedIndex != null) {
                    _playVideo(videoFiles[_selectedIndex!], _selectedIndex!);
                  } else {
                    _showBetaDialog();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Continue Practice',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}