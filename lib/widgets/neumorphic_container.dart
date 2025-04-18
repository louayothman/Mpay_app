import 'package:flutter/material.dart';

/// تعداد يحدد أنماط النيومورفيزم المختلفة
enum NeumorphicStyle {
  flat,
  convex,
  concave,
  pressed
}

/// مكون NeumorphicContainer يوفر تأثير النيومورفيزم للحاويات
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final double borderRadius;
  final bool isPressed;
  final EdgeInsetsGeometry padding;
  final double intensity;
  final NeumorphicStyle style;

  const NeumorphicContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
    this.borderRadius = 12.0,
    this.isPressed = false,
    this.padding = const EdgeInsets.all(16.0),
    this.intensity = 1.0,
    this.style = NeumorphicStyle.flat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color shadowColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.black.withOpacity(0.1 * intensity)
        : Colors.white.withOpacity(0.1 * intensity);

    final Color highlightColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.white.withOpacity(0.8 * intensity)
        : Colors.black.withOpacity(0.1 * intensity);

    // تنفيذ تأثير الظل الداخلي بدون استخدام معلمة inset
    if (isPressed || style == NeumorphicStyle.pressed) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // الظل الداخلي
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      shadowColor,
                      backgroundColor,
                      highlightColor,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // المحتوى
              Container(
                padding: padding,
                child: child,
              ),
            ],
          ),
        ),
      );
    }

    // تأثير محدب أو مقعر أو مسطح
    List<BoxShadow> shadows = [];
    
    if (style == NeumorphicStyle.convex) {
      // تأثير محدب
      shadows = [
        BoxShadow(
          color: shadowColor,
          offset: Offset(intensity * 2, intensity * 2),
          blurRadius: intensity * 3,
        ),
        BoxShadow(
          color: highlightColor,
          offset: Offset(-intensity, -intensity),
          blurRadius: intensity * 3,
        ),
      ];
    } else if (style == NeumorphicStyle.concave) {
      // تأثير مقعر
      shadows = [
        BoxShadow(
          color: highlightColor,
          offset: Offset(intensity * 2, intensity * 2),
          blurRadius: intensity * 3,
        ),
        BoxShadow(
          color: shadowColor,
          offset: Offset(-intensity, -intensity),
          blurRadius: intensity * 3,
        ),
      ];
    } else {
      // تأثير مسطح
      shadows = [
        BoxShadow(
          color: shadowColor,
          offset: Offset(intensity, intensity),
          blurRadius: intensity * 2,
        ),
        BoxShadow(
          color: highlightColor,
          offset: Offset(-intensity, -intensity),
          blurRadius: intensity * 2,
        ),
      ];
    }

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
