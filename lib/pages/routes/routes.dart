import 'package:articulicare/home_page.dart';
import 'package:articulicare/pages/featured_pages/progress_tracking.dart';
import 'package:articulicare/pages/featured_pages/therapeutic_exercises.dart';
import 'package:flutter/material.dart';
import 'package:articulicare/pages/featured_pages/speech_recording.dart';
import 'package:articulicare/pages/main_screens/training_page.dart';
import 'package:articulicare/pages/main_screens/profile_page.dart';
import 'package:articulicare/pages/featured_pages/risk_assessment.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/SpeechRecording': (context) =>  SpeechRecording(),
  '/TrainingPage': (context) => const TrainingPage(),
  '/ProfilePage': (context) => const ProfilePage(),
  '/RiskAssessment': (context) => const RiskAssessment(),
  '/TherapeuticExercises': (context) => const TherapeuticExercises(),
  '/HomePage': (context) => const HomePage(),
  'ProgressTrackingPage': (context) => const ProgressTrackingPage(),
};