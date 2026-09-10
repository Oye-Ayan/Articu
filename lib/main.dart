import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/screens/auth_gate.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/home/presentation/screens/main_nav_scaffold.dart';
import 'features/home/presentation/screens/splash_screen.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/progress/presentation/screens/progress_tracking_screen.dart';
import 'features/risk_assessment/presentation/screens/risk_assessment_screen.dart';
import 'features/speech_recording/presentation/cubit/speech_cubit.dart';
import 'features/speech_recording/presentation/screens/speech_recording_screen.dart';
import 'features/therapist/presentation/cubit/therapist_cubit.dart';
import 'features/therapist/presentation/screens/therapist_screen.dart';
import 'features/training/presentation/cubit/training_cubit.dart';
import 'features/training/presentation/screens/training_screen.dart';
import 'services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred system orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ptgzwiosneqdksjclxzz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0Z3p3aW9zbmVxZGtzamNseHp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4MDcyNjcsImV4cCI6MjA1MzM4MzI2N30.72atrlPnd6H9xa1Sntkk8K-ZFt1JuBJty2EP7893oXw',
  );

  runApp(const ArticuliCareApp());
}

class ArticuliCareApp extends StatelessWidget {
  const ArticuliCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
        BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
        BlocProvider<SpeechCubit>(create: (_) => SpeechCubit()),
        BlocProvider<TrainingCubit>(create: (_) => TrainingCubit()),
        BlocProvider<TherapistCubit>(create: (_) => TherapistCubit()),
        BlocProvider<ProfileCubit>(create: (_) => ProfileCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: AppConstants.splashRoute,
            routes: {
              AppConstants.splashRoute: (context) => const SplashScreen(),
              AppConstants.authGateRoute: (context) => const AuthGate(),
              AppConstants.mainNavRoute: (context) => const MainNavScaffold(),
              AppConstants.speechRecordingRoute: (context) =>
                  const SpeechRecordingScreen(),
              AppConstants.trainingRoute: (context) => const TrainingScreen(),
              AppConstants.therapistRoute: (context) => const TherapistScreen(),
              AppConstants.profileRoute: (context) => const ProfileScreen(),
              AppConstants.riskAssessmentRoute: (context) =>
                  const RiskAssessmentScreen(),
              AppConstants.progressRoute: (context) =>
                  const ProgressTrackingScreen(),
            },
          );
        },
      ),
    );
  }
}
