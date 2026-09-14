import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../home/presentation/screens/main_nav_scaffold.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../speech_recording/presentation/cubit/speech_cubit.dart';
import '../../../training/presentation/cubit/training_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showLogin = true;

  void _toggleView() {
    setState(() => _showLogin = !_showLogin);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.read<ProfileCubit>().clear();
          context.read<SpeechCubit>().clear();
          context.read<TrainingCubit>().clear();
          context.read<HomeCubit>().reset();
        } else if (state is Authenticated) {
          context.read<ProfileCubit>().loadUserProfile();
          context.read<SpeechCubit>().fetchLiveRecordings();
          context.read<TrainingCubit>().refreshUserProgress();
        }
      },
      builder: (context, state) {
        if (state is Authenticated) {
          return const MainNavScaffold();
        }

        if (state is AuthInitial) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (_showLogin) {
          return LoginScreen(onToggleRegister: _toggleView);
        } else {
          return RegisterScreen(onToggleLogin: _toggleView);
        }
      },
    );
  }
}
