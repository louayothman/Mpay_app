import 'package:flutter/material.dart';
import 'dart:ui';

/// مكون GlassmorphicContainer يوفر تأثير زجاجي (glassmorphism) للحاويات
class GlassmorphicContainer extends StatelessWidget {
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
  final Gradient? gradient;

  const GlassmorphicContainer({
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
    this.gradient,
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
            gradient: gradient,
          ),
          child: child,
        ),
      ),
    );
  }
}
