import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:articulicare/pages/signIn/signUp/auth_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _loadingComplete = false;

  @override
  void initState() {
    super.initState();
    
    // Create a pulse animation for the logo
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _controller.repeat(reverse: true);
    
    // Simulate loading and navigate after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _loadingComplete = true;
      });
    });

    // Navigate to auth page after animation completes
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutQuint;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Custom wave pattern drawn with CustomPaint
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 160.h,
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, 160.h),
                    painter: WavePainter(
                      waveColor: Colors.blue.shade200.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40.h),
                    
                    // Animated logo with pulse effect
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        height: 220.h,
                        width: 220.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade300, Colors.blue.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade300.withOpacity(0.5),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                        child: Image.asset(
                          'assets/images/splash_logo.png',
                          color: Colors.white,
                          fit: BoxFit.contain,
                        ),
                      
                        ),
                      ),
                    ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                    ).fadeIn(duration: 800.ms),
                    
                    SizedBox(height: 40.h),
                    
                    // App name with text shadow
                    Text(
                      'ArticuliCare',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.blue.shade800,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.blue.shade200,
                            offset: const Offset(1, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
                    
                    SizedBox(height: 16.h),
                    
                    // Tagline with staggered animation
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Text(
                        'Speak with Confidence,\nImprove with Care',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms, duration: 800.ms),
                    
                    SizedBox(height: 60.h),
                    
                    // Loading indicator
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 400),
                      crossFadeState: _loadingComplete 
                          ? CrossFadeState.showSecond 
                          : CrossFadeState.showFirst,
                      firstChild: SizedBox(
                        width: 180.w,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.blue.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade500),
                            minHeight: 6.h,
                          ),
                        ),
                      ),
                      secondChild: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.blue.shade700,
                            size: 24.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Loading Complete',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ).animate().scale(
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
              
              // Footer attribution
              Positioned(
                bottom: 20.h,
                left: 0,
                right: 0,
                child: Text(
                  'Your Speech Therapy Companion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.blue.shade600.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter to draw wave pattern instead of using an image asset
class WavePainter extends CustomPainter {
  final Color waveColor;
  
  WavePainter({required this.waveColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;
      
    final path = Path();
    
    // Start at the bottom-left corner
    path.moveTo(0, size.height);
    
    // Draw the first wave
    path.quadraticBezierTo(
      size.width * 0.25, 
      size.height * 0.7,
      size.width * 0.5, 
      size.height * 0.8,
    );
    
    // Draw the second wave
    path.quadraticBezierTo(
      size.width * 0.75, 
      size.height * 0.9,
      size.width, 
      size.height * 0.6,
    );
    
    // Complete the path by connecting to bottom-right corner
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    
    // Draw the path on the canvas
    canvas.drawPath(path, paint);
    
    // Draw a second wave with slight offset for a layered effect
    final path2 = Path();
    final paint2 = Paint()
      ..color = waveColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    path2.moveTo(0, size.height);
    path2.quadraticBezierTo(
      size.width * 0.15, 
      size.height * 0.8,
      size.width * 0.35, 
      size.height * 0.65,
    );
    path2.quadraticBezierTo(
      size.width * 0.6, 
      size.height * 0.5,
      size.width, 
      size.height * 0.7,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}