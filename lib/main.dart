import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/network/supabase_service.dart';
import 'core/services/notification_service.dart';
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

  // Initialize Notification Service
  await NotificationService.instance.initialize();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Ping Supabase to register database activity and prevent auto-pause
  SupabaseService.instance.pingDatabaseHealthCheck();

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
