import 'package:flutter/material.dart';

/// مكون GradientBorderContainer يوفر حاوية بحدود متدرجة اللون
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
