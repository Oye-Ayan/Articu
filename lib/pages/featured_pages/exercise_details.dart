import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

final supabase = Supabase.instance.client;
final firebaseAuth = FirebaseAuth.instance;

class ExerciseDetailPage extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onCompleted;

  const ExerciseDetailPage({super.key, required this.exercise, required this.onCompleted});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late int remainingSeconds;
  Timer? _timer;
  bool isRunning = false;
  bool isCompleted = false;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    remainingSeconds = _getInitialTime();
    loadState().then((_) {
      if (!isCompleted) {
        startTimer();
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  int _getInitialTime() {
    final timeString = widget.exercise['time'] as String;
    final minutes = int.tryParse(timeString.split(' ')[0]) ?? 5;
    return minutes * 60;
  }

  void startTimer() {
    if (isRunning || isCompleted) return;
    
    setState(() {
      isRunning = true;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          isRunning = false;
          isCompleted = true;
        });
        saveState(completed: true);
        widget.onCompleted();
      } else {
        setState(() {
          remainingSeconds--;
        });
        // Save state periodically (e.g., every 10 seconds)
        if (remainingSeconds % 10 == 0) {
          saveState();
        }
      }
    });
  }

  void pauseTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      setState(() => isRunning = false);
      saveState();
    }
  }

  void resumeTimer() {
    if (!isRunning && !isCompleted) {
      startTimer();
    }
  }

  void cancelTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      setState(() => isRunning = false);
    }
    saveState();
    Navigator.pop(context);
  }

  Future<void> saveState({bool completed = false}) async {
    if (isSaving) return; // Prevent multiple simultaneous save operations
    
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated'),
          backgroundColor: Colors.blue,),
      );
      return;
    }

    setState(() {
      isSaving = true;
      if (completed) {
        isCompleted = true;
      }
    });

    try {
      // First check if there's an existing record
      final existingData = await supabase
          .from('exercise_progress')
          .select()
          .eq('user_id', userId.toString())
          .eq('exercise_title', widget.exercise['title'])
          .maybeSingle();
      
      Map<String, dynamic> dataToSave = {
        'remaining_seconds': remainingSeconds,
        'is_paused': !isRunning,
        'is_completed': completed || isCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (existingData != null) {
        // Update existing record
        await supabase
            .from('exercise_progress')
            .update(dataToSave)
            .eq('id', existingData['id']);
      } else {
        // Insert new record
        dataToSave['user_id'] = userId.toString();
        dataToSave['exercise_title'] = widget.exercise['title'];
        
        await supabase
            .from('exercise_progress')
            .insert(dataToSave);
      }
      
      // Show success message for completed exercises
      if (completed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise completed successfully!'),
          backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving exercise state: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save progress: ${e.toString()}'),
          backgroundColor: Colors.blue,),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> loadState() async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('exercise_progress')
          .select()
          .eq('user_id', userId.toString())
          .eq('exercise_title', widget.exercise['title'])
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          // Handle various data types safely
          var remainingValue = response['remaining_seconds'];
          int seconds;
          
          if (remainingValue is int) {
            seconds = remainingValue;
          } else if (remainingValue is BigInt) {
            seconds = remainingValue.toInt();
          } else {
            seconds = int.tryParse(remainingValue.toString()) ?? _getInitialTime();
          }
          
          remainingSeconds = seconds;
          isCompleted = (response['is_completed'] ?? false) as bool;
          
          // If it's already completed, don't start the timer
          if (isCompleted) {
            remainingSeconds = 0;
          } else if (remainingSeconds <= 0) {
            // If somehow the remaining seconds is 0 but not marked completed
            remainingSeconds = _getInitialTime();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading exercise state: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exercise data: ${e.toString()}'),
          backgroundColor: Colors.blue,),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.detached) {
      pauseTimer();
      saveState();
    } else if (state == AppLifecycleState.resumed) {
      // Reload state to ensure consistency
      loadState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        pauseTimer();
        await saveState();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.exercise['title']),
          centerTitle: true,
        ),
        body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200.w,
                      height: 200.w,
                      child: CircularProgressIndicator(
                        value: (remainingSeconds / _getInitialTime()).clamp(0.0, 1.0),
                        strokeWidth: 10.w,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    Text(
                      formatTime(remainingSeconds),
                      style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                if (!isCompleted) Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: isSaving ? null : (isRunning ? pauseTimer : resumeTimer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRunning ? Colors.red.shade400 : Colors.green.shade400,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: isSaving
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isRunning ? 'Pause' : 'Resume', 
                            style: TextStyle(color: Colors.white, fontSize: 16.sp),
                          ),
                    ),
                    SizedBox(width: 20.w),
                    ElevatedButton(
                      onPressed: isSaving ? null : cancelTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: Text(
                        'Cancel', 
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40.h),
                if (!isRunning || isCompleted)
                  ElevatedButton(
                    onPressed: isSaving 
                      ? null 
                      : isCompleted 
                        ? () {
                            Navigator.pop(context);
                          } 
                        : () async {
                            if (_timer != null && _timer!.isActive) {
                              _timer!.cancel();
                            }
                            await saveState(completed: true);
                            // Call onCompleted before popping to ensure data is saved
                            widget.onCompleted();
                            
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 8,
                      shadowColor: Colors.greenAccent,
                    ),
                    child: isSaving
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isCompleted ? 'Return to Exercises' : 'Mark as Completed',
                          style: TextStyle(fontSize: 16.sp, color: Colors.white),
                        ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }