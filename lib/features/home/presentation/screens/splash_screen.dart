import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _waveController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textOpacity;
  late final Animation<double> _footerOpacity;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.80, curve: Curves.easeIn),
      ),
    );

    _footerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    _entranceController.forward();

    // Navigate to AuthGate once initialization sequence finishes
    _navTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppConstants.authGateRoute);
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _entranceController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // 1. Ambient Background Lighting Orbs
          Positioned(
            top: -80.h,
            right: -60.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primaryLight.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50.h,
            left: -50.w,
            child: Container(
              width: 260.w,
              height: 260.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sky.withValues(alpha: 0.10),
                    AppColors.primarySoft.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Central Branding Content (Responsive & Scroll-Safe)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Clinical Category Tag Pill
                      FadeTransition(
                        opacity: _textOpacity,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 7.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 15.sp,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'CLINICAL SPEECH INTELLIGENCE',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                    fontSize: 10.5.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 28.h),

                      // Animated Soundwave Concentric Ripples + Hero Logo Pedestal
                      AnimatedBuilder(
                        animation: Listenable.merge([_entranceController, _waveController]),
                        builder: (context, child) {
                          final waveVal = _waveController.value;
                          return Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: SizedBox(
                                width: 220.w,
                                height: 220.w,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Ripple 1
                                    _buildAcousticRipple(waveVal, 0.0, 140.w, 184.w),
                                    // Ripple 2
                                    _buildAcousticRipple(waveVal, 0.45, 140.w, 218.w),

                                    // Elevated Frosted Pedestal Container
                                    Container(
                                      width: 140.w,
                                      height: 140.w,
                                      padding: EdgeInsets.all(10.w),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        gradient: const RadialGradient(
                                          colors: [
                                            Colors.white,
                                            Color(0xFFF4F8FE),
                                          ],
                                          center: Alignment(0.0, -0.2),
                                        ),
                                        border: Border.all(
                                          color: AppColors.primaryLight.withValues(alpha: 0.35),
                                          width: 2.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.22),
                                            blurRadius: 32,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 12),
                                          ),
                                          BoxShadow(
                                            color: AppColors.sky.withValues(alpha: 0.15),
                                            blurRadius: 18,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          AppAssets.splashLogo,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 24.h),

                      // App Title & Tagline
                      FadeTransition(
                        opacity: _textOpacity,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    AppColors.primaryDark,
                                    AppColors.primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  AppConstants.appName,
                                  style: AppTextStyles.displayLarge.copyWith(
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Precision Articulation & Speech Therapy',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 36.h),

                      // Interactive Animated Equalizer Waveform Loading Indicator
                      FadeTransition(
                        opacity: _footerOpacity,
                        child: Column(
                          children: [
                            _buildEqualizerWaveform(),
                            SizedBox(height: 10.h),
                            Text(
                              'Calibrating therapeutic audio engine...',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // Bottom Clinical Trust Footnote
                      FadeTransition(
                        opacity: _footerOpacity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 13.sp,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              'HIPAA-Ready Speech Assessment Framework',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11.sp,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an expanding acoustic soundwave ripple with smooth decay
  Widget _buildAcousticRipple(
    double progress,
    double delayFraction,
    double minDiameter,
    double maxDiameter,
  ) {
    final double shifted = (progress + delayFraction) % 1.0;
    final double diameter = minDiameter + (maxDiameter - minDiameter) * shifted;
    final double opacity = (1.0 - shifted) * 0.38;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: opacity),
          width: 1.6,
        ),
      ),
    );
  }

  /// Builds a harmonic 5-bar animated audio equalizer waveform
  Widget _buildEqualizerWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final double t = _waveController.value * 2 * math.pi;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(5, (index) {
            // Staggered sine phase for each audio bar
            final double sineVal = (math.sin(t + index * 0.9) + 1.0) / 2.0;
            final double barHeight = 6.h + (sineVal * 16.h);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2.5.w),
              width: 4.w,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.sky,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
