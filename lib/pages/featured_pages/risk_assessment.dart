import 'package:articulicare/components/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

final supabase = Supabase.instance.client;
final firebaseAuth = FirebaseAuth.instance;

class RiskAssessment extends StatefulWidget {
  const RiskAssessment({super.key});

  @override
  RiskAssessmentState createState() => RiskAssessmentState();
}

class RiskAssessmentState extends State<RiskAssessment> {
  int currentQuestionIndex = 0;
  Map<int, String> selectedAnswers = {};
  bool isLoading = true;
  String? assessmentId;

  final List<Map<String, dynamic>> questions = [
    {'question': 'Do you have difficulty pronouncing certain sounds?'},
    {'question': 'Do people often ask you to repeat yourself?'},
    {'question': 'Do you avoid speaking in public due to speech concerns?'},
    {'question': 'Do you experience frustration while speaking?'},
    {'question': 'Do you feel that your speech affects your confidence?'},
  ];

  final List<String> options = [
    'Never',
    'Rarely',
    'Sometimes',
    'Often',
    'Always',
  ];

  @override
  void initState() {
    super.initState();
    _loadAssessmentData();
  }

  Future<void> _loadAssessmentData() async {
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
      // Check if there's an existing assessment in progress for this user
      final response = await supabase
          .from('risk_assessments')
          .select()
          .eq('user_id', userId.toString())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        // Found existing assessment
        setState(() {
          assessmentId = response['id'];
          if (response['answers'] != null) {
            // Parse the JSON stored answers
            Map<String, dynamic> storedAnswers = response['answers'];
            // Convert string keys to int keys
            storedAnswers.forEach((key, value) {
              selectedAnswers[int.parse(key)] = value;
            });
          }
          
          // If we have answers, set the current question index to continue
          if (selectedAnswers.isNotEmpty) {
            int lastAnsweredIndex = selectedAnswers.keys.reduce((curr, next) => curr > next ? curr : next);
            // If all questions are answered, stay at the last question
            if (lastAnsweredIndex >= questions.length - 1) {
              currentQuestionIndex = questions.length - 1;
            } else {
              // Otherwise, go to the next unanswered question
              currentQuestionIndex = lastAnsweredIndex + 1;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading assessment data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveAnswer(int questionIndex, String answer) async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      return;
    }

    try {
      // Update local state
      setState(() {
        selectedAnswers[questionIndex] = answer;
      });

      // Convert int keys to string keys for JSON storage
      Map<String, dynamic> answersToStore = {};
      selectedAnswers.forEach((key, value) {
        answersToStore[key.toString()] = value;
      });

      if (assessmentId != null) {
        // Update existing assessment
        await supabase
            .from('risk_assessments')
            .update({
              'answers': answersToStore,
              'updated_at': DateTime.now().toIso8601String(),
              'is_completed': false,
            })
            .eq('id', assessmentId!); // Fixed: Added null check exclamation mark
      } else {
        // Create new assessment
        final response = await supabase
            .from('risk_assessments')
            .insert({
              'user_id': userId.toString(),
              'answers': answersToStore,
              'is_completed': false,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        
        // Store the new assessment ID
        setState(() {
          assessmentId = response['id'];
        });
      }
    } catch (e) {
      debugPrint('Error saving answer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save progress: ${e.toString()}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  Future<void> completeAssessment() async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) return;

    try {
      int score = calculateScore();
      
      // Convert answers to string keys for JSON storage
      Map<String, dynamic> answersToStore = {};
      selectedAnswers.forEach((key, value) {
        answersToStore[key.toString()] = value;
      });

      if (assessmentId != null) {
        // Update existing assessment
        await supabase
            .from('risk_assessments')
            .update({
              'answers': answersToStore,
              'score': score,
              'risk_level': riskLevel(score),
              'is_completed': true,
              'completed_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', assessmentId!); // Fixed: Added null check exclamation mark
      } else {
        // Create completed assessment
        final response = await supabase
            .from('risk_assessments')
            .insert({
              'user_id': userId.toString(),
              'answers': answersToStore,
              'score': score,
              'risk_level': riskLevel(score),
              'is_completed': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'completed_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        
        // Store the new assessment ID
        setState(() {
          assessmentId = response['id'];
        });
      }
    } catch (e) {
      debugPrint('Error completing assessment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save assessment results: ${e.toString()}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  void nextQuestion() async {
    // Save the current answer first
    if (selectedAnswers[currentQuestionIndex] != null) {
      await saveAnswer(currentQuestionIndex, selectedAnswers[currentQuestionIndex]!);
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      // Complete the assessment when submitting the last question
      await completeAssessment();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryScreen(
            selectedAnswers: selectedAnswers,
            assessmentId: assessmentId,
          ),
        ),
      );
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  int calculateScore() {
    int score = 0;
    selectedAnswers.forEach((index, answer) {
      switch (answer) {
        case 'Never':
          score += 0;
          break;
        case 'Rarely':
          score += 1;
          break;
        case 'Sometimes':
          score += 2;
          break;
        case 'Often':
          score += 3;
          break;
        case 'Always':
          score += 4;
          break;
      }
    });
    return score;
  }

  String riskLevel(int score) {
    if (score <= 5) return 'Low Risk';
    if (score <= 10) return 'Moderate Risk';
    return 'High Risk';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Speech Health Assessment',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intro Text
                  Text(
                    "Let's quickly check your speech confidence!",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Answer a few questions to help us understand your needs.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Progress Indicator
                  LinearProgressIndicator(
                    value: (currentQuestionIndex + 1) / questions.length,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    minHeight: 8.h,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  SizedBox(height: 10.h),
                  Center(
                    child: Text(
                      'Question ${currentQuestionIndex + 1} of ${questions.length}',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Question Card
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: Container(
                        key: ValueKey<int>(currentQuestionIndex),
                        padding: EdgeInsets.all(20.sp),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Icon(Icons.health_and_safety_rounded,
                                    size: 70.sp,
                                    color: Colors.blueAccent.withOpacity(0.8),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  questions[currentQuestionIndex]['question'],
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                ...options.map((option) => Padding(
                                      padding: EdgeInsets.symmetric(vertical: 1.h),
                                      child: RadioListTile<String>(
                                        activeColor: Colors.blueAccent,
                                        title: Text(option),
                                        value: option,
                                        groupValue: selectedAnswers[currentQuestionIndex],
                                        onChanged: (value) {
                                          setState(() {
                                            selectedAnswers[currentQuestionIndex] = value!;
                                          });
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Navigation Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: currentQuestionIndex > 0 ? previousQuestion : null,
                        icon: Icon(Icons.arrow_back_ios_new, size: 16.sp),
                        label: Text('Back', style: TextStyle(fontSize: 14.sp)),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.blueAccent),
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: selectedAnswers[currentQuestionIndex] != null ? nextQuestion : null,
                        icon: Icon(Icons.arrow_forward_ios, size: 16.sp),
                        label: Text(currentQuestionIndex == questions.length - 1 ? 'Submit' : 'Next',
                            style: TextStyle(fontSize: 14.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class SummaryScreen extends StatefulWidget {
  final Map<int, String> selectedAnswers;
  final String? assessmentId;

  const SummaryScreen({super.key, required this.selectedAnswers, this.assessmentId});

  @override
  SummaryScreenState createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  bool isLoadingHistory = true;
  List<Map<String, dynamic>> assessmentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadAssessmentHistory();
  }

  Future<void> _loadAssessmentHistory() async {
    setState(() {
      isLoadingHistory = true;
    });

    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        isLoadingHistory = false;
      });
      return;
    }

    try {
      // Get user's assessment history
      final data = await supabase
          .from('risk_assessments')
          .select()
          .eq('user_id', userId.toString())
          .eq('is_completed', true)
          .order('completed_at', ascending: false)
          .limit(5);

      if (data.isNotEmpty) {
        setState(() {
          assessmentHistory = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error loading assessment history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: ${e.toString()}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } finally {
      setState(() {
        isLoadingHistory = false;
      });
    }
  }

  int calculateScore() {
    int score = 0;
    widget.selectedAnswers.forEach((index, answer) {
      switch (answer) {
        case 'Never':
          score += 0;
          break;
        case 'Rarely':
          score += 1;
          break;
        case 'Sometimes':
          score += 2;
          break;
        case 'Often':
          score += 3;
          break;
        case 'Always':
          score += 4;
          break;
      }
    });
    return score;
  }

  String riskLevel(int score) {
    if (score <= 5) return 'Low Risk';
    if (score <= 10) return 'Moderate Risk';
    return 'High Risk';
  }

  Color riskColor(int score) {
    if (score <= 5) return Colors.green;
    if (score <= 10) return Colors.orange;
    return Colors.red;
  }

  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalScore = calculateScore();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Assessment Summary', style: TextStyle(fontSize: 18.sp)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current assessment result
            Text(
              'Your Speech Risk Level',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.sp),
              decoration: BoxDecoration(
                color: riskColor(totalScore).withOpacity(0.1),
                border: Border.all(color: riskColor(totalScore)),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Text(
                    riskLevel(totalScore),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: riskColor(totalScore),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Total Score: $totalScore',
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            
            // Answers list
            Text(
              'Your Answers',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedAnswers.length + 
                  (assessmentHistory.isNotEmpty ? 1 : 0), // Add history header if available
                itemBuilder: (context, index) {
                  // Add history section title
                  if (index == widget.selectedAnswers.length && assessmentHistory.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),
                        Text(
                          'Previous Assessments',
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10.h),
                        isLoadingHistory 
                          ? const Center(child: CircularProgressIndicator()) 
                          : Column(
                              children: assessmentHistory.map((assessment) {
                                final historicalScore = assessment['score'] ?? 0;
                                return Card(
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: riskColor(historicalScore).withOpacity(0.1),
                                      child: Text(
                                        historicalScore.toString(),
                                        style: TextStyle(
                                          color: riskColor(historicalScore),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      assessment['risk_level'] ?? 'Unknown Risk',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Completed on: ${formatDate(assessment['completed_at'])}',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                      ],
                    );
                  }
                  
                  // Regular answer items
                  if (index < widget.selectedAnswers.length) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.h),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          child: const Icon(Icons.question_answer, color: Colors.blueAccent),
                        ),
                        title: Text(
                          'Question ${index + 1}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                        ),
                        subtitle: Text(
                          'Answer: ${widget.selectedAnswers[index]}',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
            
            SizedBox(height: 10.h),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BottomNavBar(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text('Done', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}