import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppButtonType { primary, secondary, outline, danger }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  final AppButtonType type;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.type = AppButtonType.primary,
    this.width,
    this.height,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onTap != null && !widget.isLoading;

    Color bg;
    Color textColor;
    Border? border;
    Gradient? gradient;

    switch (widget.type) {
      case AppButtonType.primary:
        gradient = isEnabled ? AppColors.primaryGradient : null;
        bg = isEnabled ? AppColors.primary : AppColors.primaryLight;
        textColor = Colors.white;
        break;
      case AppButtonType.secondary:
        bg = AppColors.primarySoft;
        textColor = AppColors.primaryDark;
        break;
      case AppButtonType.outline:
        bg = Colors.transparent;
        border = Border.all(color: AppColors.primary, width: 1.5);
        textColor = AppColors.primary;
        break;
      case AppButtonType.danger:
        bg = AppColors.error;
        textColor = Colors.white;
        break;
    }

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 52.h,
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(16.r),
          border: border,
          boxShadow: isEnabled && widget.type == AppButtonType.primary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onHighlightChanged: (val) {
              setState(() => _isPressed = val);
            },
            onTap: isEnabled ? widget.onTap : null,
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: textColor, size: 18.sp),
                          SizedBox(width: 8.w),
                        ],
                        Text(
                          widget.text,
                          style: AppTextStyles.button.copyWith(
                            color: textColor,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
