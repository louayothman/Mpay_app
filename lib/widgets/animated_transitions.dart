import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui'; // إضافة استيراد dart:ui للحصول على ImageFilter

class AnimatedTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final TransitionType type;
  final Curve curve;
  final bool repeat;
  final bool autoStart;

  const AnimatedTransition({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.type = TransitionType.fade,
    this.curve = Curves.easeInOut,
    this.repeat = false,
    this.autoStart = true,
  }) : super(key: key);

  @override
  _AnimatedTransitionState createState() => _AnimatedTransitionState();
}

enum TransitionType {
  fade,
  scale,
  slide,
  rotation,
  flip,
  blur,
}

class _AnimatedTransitionState extends State<AnimatedTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else if (widget.autoStart) {
      _controller.forward();
    }

    _isVisible = widget.autoStart;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void show() {
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
      _controller.forward();
    }
  }

  void hide() {
    if (_isVisible) {
      _controller.reverse().then((_) {
        setState(() {
          _isVisible = false;
        });
      });
    }
  }

  void toggle() {
    if (_isVisible) {
      hide();
    } else {
      show();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible && !widget.autoStart) {
      return const SizedBox.shrink();
    }

    switch (widget.type) {
      case TransitionType.fade:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      case TransitionType.scale:
        return ScaleTransition(
          scale: _animation,
          child: widget.child,
        );
      case TransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );
      case TransitionType.rotation:
        return RotationTransition(
          turns: _animation,
          child: widget.child,
        );
      case TransitionType.flip:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final value = _animation.value;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(math.pi * value),
              child: widget.child,
            );
          },
        );
      case TransitionType.blur:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 10 * (1 - _animation.value),
                sigmaY: 10 * (1 - _animation.value),
              ),
              child: widget.child,
            );
          },
        );
    }
  }
}

class PageTransitionBuilder extends PageRouteBuilder {
  final Widget page;
  final PageTransitionType transitionType;
  final Curve curve;
  final Duration duration;
  final bool fullscreenDialog;

  PageTransitionBuilder({
    required this.page,
    this.transitionType = PageTransitionType.rightToLeft,
    this.curve = Curves.easeInOut,
    this.duration = const Duration(milliseconds: 300),
    this.fullscreenDialog = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          fullscreenDialog: fullscreenDialog,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            switch (transitionType) {
              case PageTransitionType.fade:
                return FadeTransition(
                  opacity: curvedAnimation,
                  child: child,
                );
              case PageTransitionType.rightToLeft:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              case PageTransitionType.leftToRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              case PageTransitionType.topToBottom:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              case PageTransitionType.bottomToTop:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              case PageTransitionType.scale:
                return ScaleTransition(
                  scale: curvedAnimation,
                  child: child,
                );
              case PageTransitionType.rotate:
                return RotationTransition(
                  turns: curvedAnimation,
                  child: child,
                );
              case PageTransitionType.size:
                return SizeTransition(
                  sizeFactor: curvedAnimation,
                  child: child,
                );
              case PageTransitionType.rightToLeftWithFade:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: FadeTransition(
                    opacity: curvedAnimation,
                    child: child,
                  ),
                );
              case PageTransitionType.leftToRightWithFade:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: FadeTransition(
                    opacity: curvedAnimation,
                    child: child,
                  ),
                );
            }
          },
        );
}

enum PageTransitionType {
  fade,
  rightToLeft,
  leftToRight,
  topToBottom,
  bottomToTop,
  scale,
  rotate,
  size,
  rightToLeftWithFade,
  leftToRightWithFade,
}

class AnimatedProgressBar extends StatefulWidget {
  final double value;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;
  final Duration duration;
  final Curve curve;
  final bool showPercentage;
  final TextStyle? percentageTextStyle;
  final bool animateFromPrevious;

  const AnimatedProgressBar({
    Key? key,
    required this.value,
    this.height = 10.0,
    this.backgroundColor = Colors.grey,
    this.foregroundColor = Colors.blue,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
    this.showPercentage = false,
    this.percentageTextStyle,
    this.animateFromPrevious = true,
  }) : super(key: key);

  @override
  _AnimatedProgressBarState createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    final startValue = widget.animateFromPrevious ? _previousValue : 0.0;
    _animation = Tween<double>(
      begin: startValue,
      end: widget.value,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final percentage = (_animation.value * 100).toInt();
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: widget.height,
                width: _animation.value * MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: widget.foregroundColor,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),
            ),
            if (widget.showPercentage)
              Text(
                '$percentage%',
                style: widget.percentageTextStyle ??
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: widget.height * 0.7,
                    ),
              ),
          ],
        );
      },
    );
  }
}

class AnimatedCounter extends StatefulWidget {
  final int end;
  final int start;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final bool includeCommas;

  const AnimatedCounter({
    Key? key,
    required this.end,
    this.start = 0,
    this.duration = const Duration(seconds: 1),
    this.curve = Curves.easeInOut,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.includeCommas = false,
  }) : super(key: key);

  @override
  _AnimatedCounterState createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> with SingleTickerProviderStateMixin {
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
      curve: widget.curve,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end || oldWidget.start != widget.start) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    if (widget.includeCommas) {
      return number.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = widget.start + ((widget.end - widget.start) * _animation.value).round();
        return Text(
          '${widget.prefix}${_formatNumber(value)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
