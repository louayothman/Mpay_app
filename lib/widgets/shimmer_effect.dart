import 'package:flutter/material.dart';

/// تعداد يحدد أنواع التأثيرات الحركية
enum AnimationType {
  fade,
  scale,
  slide,
  rotation
}

/// مكون ShimmerEffect يوفر تأثير الوميض للعناصر أثناء التحميل
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;
  final AnimationType animationType;

  const ShimmerEffect({
    Key? key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
    this.animationType = AnimationType.fade,
  }) : super(key: key);

  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildShimmerEffect();
      },
    );
  }

  Widget _buildShimmerEffect() {
    switch (widget.animationType) {
      case AnimationType.fade:
        return _buildFadeShimmer();
      case AnimationType.scale:
        return _buildScaleShimmer();
      case AnimationType.slide:
        return _buildSlideShimmer();
      case AnimationType.rotation:
        return _buildRotationShimmer();
      default:
        return _buildFadeShimmer();
    }
  }

  Widget _buildFadeShimmer() {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            widget.baseColor,
            widget.highlightColor,
            widget.baseColor,
          ],
          stops: [
            0.0,
            _animation.value,
            1.0,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: widget.child,
    );
  }

  Widget _buildScaleShimmer() {
    final scaleValue = 0.95 + (_animation.value * 0.05);
    return Transform.scale(
      scale: scaleValue,
      child: _buildFadeShimmer(),
    );
  }

  Widget _buildSlideShimmer() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.2, 0),
        end: const Offset(0.2, 0),
      ).animate(_animation),
      child: _buildFadeShimmer(),
    );
  }

  Widget _buildRotationShimmer() {
    return RotationTransition(
      turns: Tween<double>(
        begin: -0.01,
        end: 0.01,
      ).animate(_animation),
      child: _buildFadeShimmer(),
    );
  }
}
