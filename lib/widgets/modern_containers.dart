import 'package:flutter/material.dart';
import 'dart:ui';

class ModernCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const ModernCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
    this.borderRadius = 12.0,
    this.boxShadow,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: borderWidth > 0
              ? Border.all(
                  color: borderColor,
                  width: borderWidth,
                )
              : null,
          boxShadow: boxShadow ?? defaultShadow,
        ),
        child: child,
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final Color backgroundColor;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const GlassContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.blur = 10.0,
    this.backgroundColor = Colors.white,
    this.opacity = 0.2,
    this.padding = const EdgeInsets.all(16.0),
    this.boxShadow,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Gradient gradient;
  final double borderWidth;
  final double borderRadius;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow>? boxShadow;

  const GradientBorderContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    required this.gradient,
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(16.0),
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth / 2),
        ),
        child: child,
      ),
    );
  }
}

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final double borderRadius;
  final bool isPressed;
  final EdgeInsetsGeometry padding;
  final double intensity;

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color shadowColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.black.withOpacity(0.1 * intensity)
        : Colors.white.withOpacity(0.1 * intensity);

    final Color highlightColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.white.withOpacity(0.8 * intensity)
        : Colors.black.withOpacity(0.1 * intensity);

    // تنفيذ تأثير الظل الداخلي بطريقة بديلة للحالة المضغوطة
    if (isPressed) {
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

    // تأثير عادي (غير مضغوط)
    final List<BoxShadow> shadows = [
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
