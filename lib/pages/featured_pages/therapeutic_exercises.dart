import 'package:articulicare/pages/featured_pages/exercise_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

final supabase = Supabase.instance.client;
final firebaseAuth = FirebaseAuth.instance;

class TherapeuticExercises extends StatefulWidget {
  const TherapeuticExercises({super.key});

  @override
  State<TherapeuticExercises> createState() => _TherapeuticExercisesState();
}

class _TherapeuticExercisesState extends State<TherapeuticExercises> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int completedExercises = 0;
  bool isLoading = true;

  final List<Map<String, dynamic>> exercises = [
    {
      'title': 'Lip Strengthening',
      'difficulty': 'Easy',
      'category': 'Muscle Strengthening',
      'description': 'Strengthen lip muscles to improve articulation.',
      'time': '1 min',
      'completed': false,
    },
    {
      'title': 'Tongue Elevation',
      'difficulty': 'Medium',
      'category': 'Muscle Strengthening',
      'description': 'Practice raising the tongue to improve "L" sounds.',
      'time': '1 min',
      'completed': false,
    },
    {
      'title': 'S Sound Practice',
      'difficulty': 'Medium',
      'category': 'Sound Production',
      'description': 'Improve pronunciation of "S" through repetition drills.',
      'time': '1 min',
      'completed': false,
    },
    {
      'title': 'Sentence Formation',
      'difficulty': 'Hard',
      'category': 'Fluency Training',
      'description': 'Practice complete sentences for better fluency.',
      'time': '1 min',
      'completed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExerciseData();
  }

  Future<void> _loadExerciseData() async {
    setState(() {
      isLoading = true;
    });

    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Get all exercise progress for this user - use string type for userId
      final data = await supabase
          .from('exercise_progress')
          .select()
          .eq('user_id', userId.toString());

      // Reset completion status
      completedExercises = 0;
      
      // Update the exercises list with completion status
      // ignore: unnecessary_null_comparison
      if (data != null && data.isNotEmpty) {
        for (var progress in data) {
          for (int i = 0; i < exercises.length; i++) {
            if (exercises[i]['title'] == progress['exercise_title']) {
              setState(() {
                exercises[i]['completed'] = progress['is_completed'] ?? false;
                if (exercises[i]['completed']) {
                  completedExercises++;
                }
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading exercise data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}'),
          backgroundColor: Colors.blue,),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> markComplete(int index) async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Don't mark it again if already completed
    if (exercises[index]['completed']) return;

    // Optimistically update UI
    setState(() {
      exercises[index]['completed'] = true;
      completedExercises++;
    });

    // Save to database
    try {
      // First check if there's an existing record
      final existingData = await supabase
          .from('exercise_progress')
          .select()
          .eq('user_id', userId)
          .eq('exercise_title', exercises[index]['title'])
          .maybeSingle();
      
      if (existingData != null) {
        // Update existing record
        await supabase
            .from('exercise_progress')
            .update({
              'is_completed': true,
              'remaining_seconds': 0,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingData['id']);
      } else {
        // Insert new record - use string type for userId
        await supabase.from('exercise_progress').insert({
          'user_id': userId.toString(),
          'exercise_title': exercises[index]['title'],
          'is_completed': true,
          'is_paused': true,
          'remaining_seconds': 0,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress saved successfully'),
          backgroundColor: Colors.blue,),
        );
      }
    } catch (e) {
      debugPrint('Error saving completion status: $e');
      // Revert UI if save fails
      if (mounted) {
        setState(() {
          exercises[index]['completed'] = false;
          completedExercises--;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save progress: ${e.toString()}'),
          backgroundColor: Colors.blue,),
        );
      }
    }
  }

  double get progress => exercises.isEmpty ? 0 : completedExercises / exercises.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Therapeutic Exercises',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
              tabs: const [
                Tab(text: 'Today\'s Exercises'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                children: [
                  // Progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Progress: ${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8.h),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        minHeight: 8.h,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Exercises List
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Today's Exercises
                        buildExerciseList(
                          exercises.where((e) => !e['completed']).toList(),
                          showStartButton: true,
                        ),

                        // Upcoming (hard-coded as the incomplete ones for now)
                        buildExerciseList(
                          exercises.where((e) => !e['completed']).toList(),
                          showStartButton: false,
                        ),

                        // Completed
                        buildExerciseList(
                          exercises.where((e) => e['completed']).toList(),
                          showStartButton: false,
                          completedTab: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildExerciseList(List<Map<String, dynamic>> list, {bool showStartButton = true, bool completedTab = false}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          completedTab ? 'No exercises completed yet.' : 'No exercises available.',
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final exercise = list[index];
        final int originalIndex = exercises.indexOf(exercise);

        return Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Difficulty
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    exercise['title'],
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      exercise['difficulty'],
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),

              // Category
              Text(
                exercise['category'],
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 8.h),

              // Description
              Text(
                exercise['description'],
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
              ),
              SizedBox(height: 8.h),

              // Time and Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⏱ ${exercise['time']}',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                  ),
                  if (showStartButton)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseDetailPage(
                              exercise: exercise,
                              onCompleted: () async {
                                // Wait for the completion to be marked and data reloaded
                                await markComplete(originalIndex);
                                await _loadExerciseData();
                                
                                // After data is reloaded, rebuild the UI with the updated state
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        exercise['completed'] ? 'Completed' : 'Start',
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                    ),

                  if (!showStartButton && completedTab)
                    Icon(Icons.check_circle, color: Colors.blue, size: 24.sp),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}