import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../domain/user_entity.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onToggleLogin;

  const RegisterScreen({
    super.key,
    required this.onToggleLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qualificationsController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        CustomSnackBar.showError(context, 'Passwords do not match');
        return;
      }

      if (_selectedRole == UserRole.therapist &&
          _qualificationsController.text.trim().isEmpty) {
        CustomSnackBar.showError(
          context,
          'Please provide your clinical qualifications or license number',
        );
        return;
      }

      context.read<AuthCubit>().registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            username: _usernameController.text.trim(),
            role: _selectedRole,
            fullName: _fullNameController.text.trim().isNotEmpty
                ? _fullNameController.text.trim()
                : _usernameController.text.trim(),
            qualifications: _selectedRole == UserRole.therapist
                ? _qualificationsController.text.trim()
                : null,
            phoneNumber: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          CustomSnackBar.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Logo
                      Container(
                        width: 80.w,
                        height: 80.w,
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          AppAssets.splashLogo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      Text(
                        'Create an Account',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Join ArticuliCare speech therapy ecosystem',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // ROLE SELECTOR
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Your Role',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          _roleCard(
                            role: UserRole.patient,
                            icon: Icons.person_rounded,
                            label: 'Patient',
                            subtitle: 'Learner',
                          ),
                          SizedBox(width: 8.w),
                          _roleCard(
                            role: UserRole.caregiver,
                            icon: Icons.family_restroom_rounded,
                            label: 'Caregiver',
                            subtitle: 'Supporter',
                          ),
                          SizedBox(width: 8.w),
                          _roleCard(
                            role: UserRole.therapist,
                            icon: Icons.medical_services_rounded,
                            label: 'Therapist',
                            subtitle: 'Clinician',
                          ),
                        ],
                      ),
                      SizedBox(height: 18.h),

                      // Input Fields
                      AppTextField(
                        controller: _fullNameController,
                        labelText: 'Full Name',
                        hintText: 'John Doe',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),

                      AppTextField(
                        controller: _usernameController,
                        labelText: 'Username',
                        hintText: 'johndoe12',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),

                      AppTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'you@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),

                      AppTextField(
                        controller: _phoneController,
                        labelText: 'Phone Number (Optional)',
                        hintText: '+1 234 567 8900',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 14.h),

                      // Conditional Therapist Qualifications
                      if (_selectedRole == UserRole.therapist) ...[
                        AppTextField(
                          controller: _qualificationsController,
                          labelText: 'Clinical Qualifications & Specialty',
                          hintText: 'e.g. M.S., CCC-SLP, Adult Stuttering',
                          prefixIcon: const Icon(Icons.school_outlined),
                          validator: (val) {
                            if (_selectedRole == UserRole.therapist &&
                                (val == null || val.trim().isEmpty)) {
                              return 'Qualifications required for therapists';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 14.h),
                      ],

                      AppTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'At least 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),

                      AppTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please confirm your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24.h),

                      // Sign Up Button
                      AppButton(
                        text: 'Create ${_selectedRole.displayName} Account',
                        isLoading: isLoading,
                        onTap: _onRegister,
                      ),

                      SizedBox(height: 20.h),

                      // Switch to Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onToggleLogin,
                            child: Text(
                              'Sign In',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _roleCard({
    required UserRole role,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24.sp,
              ),
              SizedBox(height: 6.h),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
