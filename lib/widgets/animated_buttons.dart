import 'package:flutter/material.dart';

class EnhancedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String? text;
  final Widget? child;
  final Color backgroundColor;
  final Color? splashColor;
  final double height;
  final double width;
  final double borderRadius;
  final AnimationType animationType;
  final Duration animationDuration;

  const EnhancedButton({
    Key? key,
    required this.onPressed,
    this.text,
    this.child,
    this.backgroundColor = Colors.blue,
    this.splashColor,
    this.height = 50,
    this.width = double.infinity,
    this.borderRadius = 8.0,
    this.animationType = AnimationType.ripple,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : assert(text != null || child != null, 'Either text or child must be provided'),
       super(key: key);

  @override
  _EnhancedButtonState createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final buttonContent = widget.child ?? Text(
      widget.text!,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    final splashColor = widget.splashColor ?? widget.backgroundColor.withOpacity(0.7);

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: _buildButtonByType(widget.backgroundColor, splashColor, buttonContent),
    );
  }

  Widget _buildButtonByType(Color backgroundColor, Color splashColor, Widget buttonContent) {
    switch (widget.animationType) {
      case AnimationType.scale:
        return _buildScaleButton(backgroundColor, splashColor, buttonContent);
      case AnimationType.pulse:
        return _buildPulseButton(backgroundColor, splashColor, buttonContent);
      case AnimationType.ripple:
        return _buildRippleButton(backgroundColor, splashColor, buttonContent);
      case AnimationType.elevation:
        return _buildElevationButton(backgroundColor, splashColor, buttonContent);
      default:
        return _buildRippleButton(backgroundColor, splashColor, buttonContent);
    }
  }

  Widget _buildScaleButton(Color backgroundColor, Color splashColor, Widget buttonContent) {
    return AnimatedContainer(
      duration: widget.animationDuration,
      height: widget.height,
      width: widget.width,
      transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: buttonContent,
      ),
    );
  }

  Widget _buildPulseButton(Color backgroundColor, Color splashColor, Widget buttonContent) {
    return AnimatedContainer(
      duration: widget.animationDuration,
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(_isPressed ? 0.3 : 0.0),
            spreadRadius: _isPressed ? 8 : 0,
            blurRadius: _isPressed ? 16 : 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: buttonContent,
      ),
    );
  }

  Widget _buildRippleButton(Color backgroundColor, Color splashColor, Widget buttonContent) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: buttonContent,
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: splashColor,
              highlightColor: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElevationButton(Color backgroundColor, Color splashColor, Widget buttonContent) {
    return AnimatedContainer(
      duration: widget.animationDuration,
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: _isPressed ? 4 : 8,
            offset: Offset(0, _isPressed ? 1 : 3),
          ),
        ],
      ),
      transform: Matrix4.identity()
        ..translate(0.0, _isPressed ? 2.0 : 0.0)
        ..scale(_isPressed ? 0.98 : 1.0),
      child: Center(
        child: buttonContent,
      ),
    );
  }
}

class BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final double height;
  final double width;
  final double borderRadius;

  const BounceButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.height = 50,
    this.width = double.infinity,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  _BounceButtonState createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {});
      });
    
    // Removed unused springSimulation
    
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;

    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      onTap: widget.onPressed,
      child: Transform.scale(
        scale: _scale.value,
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

enum AnimationType {
  scale,
  pulse,
  ripple,
  elevation,
}
