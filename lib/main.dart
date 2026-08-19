import 'package:articulicare/pages/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'pages/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://ptgzwiosneqdksjclxzz.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0Z3p3aW9zbmVxZGtzamNseHp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4MDcyNjcsImV4cCI6MjA1MzM4MzI2N30.72atrlPnd6H9xa1Sntkk8K-ZFt1JuBJty2EP7893oXw',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
clk
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: MediaQuery.of(context).size,
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue),
          home: const SplashScreen(),
          routes:appRoutes,
        );
      },
    );
  }
}

