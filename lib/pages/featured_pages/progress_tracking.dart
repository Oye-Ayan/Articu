import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

final supabase = Supabase.instance.client;
final firebaseAuth = FirebaseAuth.instance;

class ProgressTrackingPage extends StatefulWidget {
  const ProgressTrackingPage({super.key});

  @override
  State<ProgressTrackingPage> createState() => _ProgressTrackingPageState();
}

class _ProgressTrackingPageState extends State<ProgressTrackingPage> {
  bool isLoading = true;
  double overallProgress = 0.0;
  List<Map<String, dynamic>> recentActivities = [];
  List<Map<String, dynamic>> dailyProgressData = [];
  Map<String, double> categoryDistribution = {};
  int streakDays = 0;

  final List<Map<String, dynamic>> exercises = [
    {
      'title': 'Lip Strengthening',
      'difficulty': 'Easy',
      'category': 'Muscle Strengthening',
      'description': 'Strengthen lip muscles to improve articulation.',
      'time': '1 min',
      'completed': false,
      'icon': IconlyBold.heart,
    },
    {
      'title': 'Tongue Elevation',
      'difficulty': 'Medium',
      'category': 'Muscle Strengthening',
      'description': 'Practice raising the tongue to improve "L" sounds.',
      'time': '1 min',
      'completed': false,
      'icon': IconlyBold.activity,
    },
    {
      'title': 'S Sound Practice',
      'difficulty': 'Medium',
      'category': 'Sound Production',
      'description': 'Improve pronunciation of "S" through repetition drills.',
      'time': '1 min',
      'completed': false,
      'icon': IconlyBold.voice,
    },
    {
      'title': 'Sentence Formation',
      'difficulty': 'Hard',
      'category': 'Fluency Training',
      'description': 'Practice complete sentences for better fluency.',
      'time': '1 min',
      'completed': false,
      'icon': IconlyBold.chat,
    },
  ];

  // Color theme
  final Color primaryColor = const Color(0xFF4A80F0);
  final Color secondaryColor = const Color(0xFF61B15A);
  final Color accentColor = const Color(0xFFFFA41B);
  final Color backgroundColor = const Color(0xFFF8F9FE);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF2D3142);
  final Color textSecondaryColor = const Color(0xFF9C9EB9);

  final List<Color> categoryColors = [
    const Color(0xFF4A80F0),
    const Color(0xFF61B15A),
    const Color(0xFFFFA41B),
  ];

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() {
      isLoading = true;
    });

    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('User not authenticated');
      return;
    }

    try {
      // Load exercise progress
      final exerciseData = await supabase
          .from('exercise_progress')
          .select()
          .eq('user_id', userId);

      int completedExercises = 0;
      for (var progress in exerciseData) {
        for (int i = 0; i < exercises.length; i++) {
          if (exercises[i]['title'] == progress['exercise_title']) {
            exercises[i]['completed'] = progress['is_completed'] ?? false;
            if (exercises[i]['completed']) {
              completedExercises++;
            }
            break;
          }
        }
      }

      setState(() {
        overallProgress = exercises.isEmpty ? 0 : completedExercises / exercises.length;
      });

      // Load recent activities
      final recentData = await supabase
          .from('exercise_progress')
          .select()
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('updated_at', ascending: false)
          .limit(5);

      setState(() {
        recentActivities = recentData.map<Map<String, dynamic>>((activity) {
          return {
            'title': activity['exercise_title'],
            'timestamp': DateTime.parse(activity['updated_at']),
          };
        }).toList();
      });

      // Load daily progress for the past 7 days
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 6));
      final dailyData = await supabase
          .from('daily_progress')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', now.toIso8601String());

      setState(() {
        dailyProgressData = List.generate(7, (index) {
          final date = startDate.add(Duration(days: index));
          final formattedDate = DateFormat('yyyy-MM-dd').format(date);
          final matchingEntry = dailyData.firstWhere(
            (entry) => entry['date'].startsWith(formattedDate),
            orElse: () => {'completed_count': 0},
          );
          return {
            'date': date,
            'completed': matchingEntry['completed_count'] ?? 0,
          };
        });

        // Calculate streak
        streakDays = 0;
        for (var i = dailyProgressData.length - 1; i >= 0; i--) {
          if (dailyProgressData[i]['completed'] > 0) {
            streakDays++;
          } else {
            break;
          }
        }
      });

      // Calculate category distribution
      final completedByCategory = <String, int>{};
      for (var exercise in exercises) {
        if (exercise['completed']) {
          final category = exercise['category'] as String;
          completedByCategory[category] = (completedByCategory[category] ?? 0) + 1;
        }
      }
      setState(() {
        categoryDistribution = completedByCategory.map((category, count) => MapEntry(
              category,
              completedExercises == 0 ? 0 : count / completedExercises * 100,
            ));
      });

      // Update daily progress for today if needed
      final today = DateFormat('yyyy-MM-dd').format(now);
      final todayData = dailyData.firstWhere(
        (entry) => entry['date'].startsWith(today),
        orElse: () => <String, dynamic>{},
      );

      if (todayData.isEmpty) {
        await supabase.from('daily_progress').insert({
          'user_id': userId,
          'date': now.toIso8601String(),
          'completed_count': completedExercises,
        });
      } else {
        await supabase
            .from('daily_progress')
            .update({'completed_count': completedExercises})
            .eq('user_id', userId)
            .eq('date', todayData['date']);
      }
    } catch (e) {
      debugPrint('Error loading progress data: $e');
      if (mounted) {
        _showErrorSnackBar('Error loading data: ${e.toString()}');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Progress Tracking',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: textPrimaryColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconlyLight.arrowLeft2, color: primaryColor, size: 24.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(IconlyLight.infoSquare, color: primaryColor, size: 24.sp),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildInfoSheet(),
              );
            },
            tooltip: 'About Progress Tracking',
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3.w,
              ).animate().fadeIn(duration: 300.ms),
            )
          : RefreshIndicator(
              color: primaryColor,
              backgroundColor: cardColor,
              onRefresh: _loadProgressData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummarySection()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    SizedBox(height: 24.h),
                    _buildProgressChart()
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    SizedBox(height: 24.h),
                    _buildCategoryDistribution()
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 400.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    SizedBox(height: 24.h),
                    _buildRecentActivities()
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 600.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/TherapeuticExercises");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Starting new exercise session'),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              margin: EdgeInsets.all(16.w),
            ),
          );
        },
        backgroundColor: primaryColor,
        elevation: 4,
        child: Icon(IconlyBold.play, color: Colors.white, size: 24.sp),
      ).animate().scale(
            delay: 800.ms,
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildInfoSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.all(24.w),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'About Progress Tracking',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimaryColor,
                ),
              ),
              SizedBox(height: 16.h),
              _buildInfoItem(
                icon: IconlyBold.chart,
                title: 'Overall Progress',
                description: 'Shows the percentage of exercises completed in your therapy program.',
              ),
              _buildInfoItem(
                icon: IconlyBold.timeCircle,
                title: 'Progress Over Time',
                description: 'Tracks daily exercise completion over the past week for consistency.',
              ),
              _buildInfoItem(
                icon: IconlyBold.category,
                title: 'Category Distribution',
                description: 'Displays the breakdown of completed exercises by category.',
              ),
              _buildInfoItem(
                icon: IconlyBold.activity,
                title: 'Recent Activities',
                description: 'Lists recently completed exercises for quick reference.',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: primaryColor, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: textPrimaryColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: textSecondaryColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconlyBold.star,
                color: Colors.white.withOpacity(0.9),
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Progress Summary',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(overallProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 80.w,
                height: 80.w,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 80.w,
                      height: 80.w,
                      child: CircularProgressIndicator(
                        value: overallProgress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 8.w,
                      ).animate().scale(duration: 600.ms, curve: Curves.easeOut),
                    ),
                    Center(
                      child: Icon(
                        IconlyBold.tickSquare,
                        color: Colors.white,
                        size: 32.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _buildWeeklySummary(),
          SizedBox(height: 16.h),
          Text(
            '"Small steps every day lead to big results."',
            style: TextStyle(
              fontSize: 14.sp,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary() {
    int completedToday = dailyProgressData.isEmpty ? 0 : dailyProgressData.last['completed'] as int;
    int totalCompletedThisWeek = dailyProgressData.fold(0, (sum, item) => sum + (item['completed'] as int));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryStat(
          value: completedToday.toString(),
          label: 'Today',
          icon: IconlyBold.timeCircle,
        ),
        Container(
          height: 40.h,
          width: 1.w,
          color: Colors.white.withOpacity(0.2),
        ),
        _buildSummaryStat(
          value: totalCompletedThisWeek.toString(),
          label: 'This Week',
          icon: IconlyBold.calendar,
        ),
        Container(
          height: 40.h,
          width: 1.w,
          color: Colors.white.withOpacity(0.2),
        ),
        _buildSummaryStat(
          value: '$streakDays',
          label: 'Streak',
          icon: IconlyBold.star,
        ),
      ],
    );
  }

  Widget _buildSummaryStat({required String value, required String label, required IconData icon}) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 20.sp,
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChart() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    IconlyBold.chart,
                    color: primaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Weekly Progress',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: textPrimaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Last 7 Days',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 220.h,
            child: dailyProgressData.every((entry) => entry['completed'] == 0)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconlyBold.document,
                          color: textSecondaryColor.withOpacity(0.5),
                          size: 48.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No progress data available',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: textSecondaryColor,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Complete exercises to see your progress',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: textSecondaryColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40.w,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0) return const SizedBox.shrink();
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: textSecondaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30.w,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final date = dailyProgressData[value.toInt()]['date'] as DateTime;
                              final isToday = DateFormat('yyyyMMdd').format(date) ==
                                  DateFormat('yyyyMMdd').format(DateTime.now());
                              return Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('EEE').format(date),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                        color: isToday ? primaryColor : textSecondaryColor,
                                      ),
                                    ),
                                    if (isToday) ...[
                                      SizedBox(height: 2.h),
                                      Container(
                                        width: 3.w,
                                        height: 3.w,
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailyProgressData
                              .asMap()
                              .entries
                              .map((entry) => FlSpot(
                                    entry.key.toDouble(),
                                    (entry.value['completed'] as int).toDouble(),
                                  ))
                              .toList(),
                          isCurved: true,
                          color: primaryColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              final isToday = index == dailyProgressData.length - 1;
                              return FlDotCirclePainter(
                                radius: isToday ? 6 : 4,
                                color: isToday ? primaryColor : Colors.white,
                                strokeWidth: 2,
                                strokeColor: primaryColor,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.3),
                                primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: (exercises.length + 1).toDouble(),
                    ),
                  ).animate().fadeIn(duration: 600.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconlyBold.category,
                color: secondaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Category Distribution',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 220.h,
            child: categoryDistribution.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconlyBold.category,
                          color: textSecondaryColor.withOpacity(0.5),
                          size: 48.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No completed exercises yet',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: textSecondaryColor,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Complete exercises to see category breakdown',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: textSecondaryColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            sections: categoryDistribution.entries.map((entry) {
                              final index = categoryDistribution.keys.toList().indexOf(entry.key);
                              return PieChartSectionData(
                                value: entry.value,
                                color: categoryColors[index % categoryColors.length],
                                title: '${entry.value.toStringAsFixed(1)}%',
                                radius: 80.r,
                                titleStyle: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                titlePositionPercentageOffset: 0.55,
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40.r,
                            startDegreeOffset: -90,
                          ),
                        ).animate().scale(duration: 600.ms, curve: Curves.easeOut),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: categoryDistribution.keys.map((category) {
                            final index = categoryDistribution.keys.toList().indexOf(category);
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12.w,
                                    height: 12.h,
                                    decoration: BoxDecoration(
                                      color: categoryColors[index % categoryColors.length],
                                      borderRadius: BorderRadius.circular(3.r),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    IconlyBold.activity,
                    color: accentColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: textPrimaryColor,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Viewing full activity history'),
                      backgroundColor: primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      margin: EdgeInsets.all(16.w),
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          recentActivities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 16.h),
                      Icon(
                        IconlyBold.activity,
                        color: textSecondaryColor.withOpacity(0.5),
                        size: 48.sp,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No recent activities',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Complete exercises to see your activities here',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textSecondaryColor.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentActivities.length,
                  itemBuilder: (context, index) {
                    final activity = recentActivities[index];
                    final exercise = exercises.firstWhere(
                      (e) => e['title'] == activity['title'],
                      orElse: () => {
                        'icon': IconlyBold.activity,
                        'category': 'Exercise',
                      },
                    );

                    return GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing details for ${activity['title']}'),
                            backgroundColor: primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            margin: EdgeInsets.all(16.w),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                exercise['icon'] as IconData? ?? IconlyBold.activity,
                                color: primaryColor,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['title'],
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${exercise['category'] ?? 'Exercise'} • ${_getTimeAgo(activity['timestamp'])}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: secondaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                IconlyBold.tickSquare,
                                color: secondaryColor,
                                size: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(
                          begin: 0.1,
                          end: 0,
                          curve: Curves.easeOutQuad,
                        );
                  },
                ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return difference.inDays == 1 ? 'Yesterday' : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}