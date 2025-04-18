import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MotionEffects extends StatelessWidget {
  final Widget child;
  final EffectType effectType;
  final Duration duration;
  final double intensity;
  final Curve curve;
  final bool enabled;
  final String? semanticLabel;

  const MotionEffects({
    Key? key,
    required this.child,
    required this.effectType,
    this.duration = const Duration(seconds: 2),
    this.intensity = 1.0,
    this.curve = Curves.easeInOut,
    this.enabled = true,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If animations are disabled or reduced motion is preferred, return child without effects
    if (!enabled || MediaQuery.of(context).disableAnimations) {
      return semanticLabel != null 
          ? Semantics(label: semanticLabel, child: child)
          : child;
    }

    Widget effectWidget;
    
    switch (effectType) {
      case EffectType.pulse:
        effectWidget = PulseEffect(
          child: child,
          duration: duration,
          maxScale: 1.0 + (0.1 * intensity),
          curve: curve,
          enabled: enabled,
        );
        break;
      case EffectType.float:
        effectWidget = FloatingEffect(
          child: child,
          duration: duration,
          floatHeight: 10.0 * intensity,
          curve: curve,
          enabled: enabled,
        );
        break;
      case EffectType.shimmer:
        effectWidget = ShimmerEffect(
          child: child,
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.white,
          duration: duration,
          enabled: enabled,
        );
        break;
      case EffectType.rotate:
        effectWidget = RotatingEffect(
          child: child,
          duration: duration,
          maxRotation: 0.1 * intensity,
          axis: Axis.vertical,
          enabled: enabled,
        );
        break;
      default:
        effectWidget = child;
    }
    
    // Add semantics if provided
    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        child: effectWidget,
      );
    }
    
    return effectWidget;
  }
}

enum EffectType {
  pulse,
  float,
  shimmer,
  rotate,
}

class PulseEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double maxScale;
  final Curve curve;
  final bool enabled;

  const PulseEffect({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.maxScale = 1.1,
    this.curve = Curves.easeInOut,
    this.enabled = true,
  }) : super(key: key);

  @override
  _PulseEffectState createState() => _PulseEffectState();
}

class _PulseEffectState extends State<PulseEffect> with SingleTickerProviderStateMixin {
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
    
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    
    // Only start animation when widget is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkVisibility();
  }
  
  @override
  void didUpdateWidget(PulseEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation parameters if they changed
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    
    if (oldWidget.maxScale != widget.maxScale || oldWidget.curve != widget.curve) {
      _animation = Tween<double>(
        begin: 1.0,
        end: widget.maxScale,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ),
      );
    }
    
    // Update animation state based on enabled flag
    if (oldWidget.enabled != widget.enabled) {
      _updateAnimationState();
    }
  }
  
  void _checkVisibility() {
    // Check if widget is visible in viewport
    final bool isVisible = _isWidgetVisible();
    
    if (_isVisible != isVisible) {
      _isVisible = isVisible;
      _updateAnimationState();
    }
  }
  
  bool _isWidgetVisible() {
    // Simple check - assume widget is visible when mounted
    // For more accurate visibility detection, you would need to use VisibilityDetector package
    return mounted;
  }
  
  void _updateAnimationState() {
    if (widget.enabled && _isVisible) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      if (_controller.isAnimating) {
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
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class FloatingEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double floatHeight;
  final Curve curve;
  final bool enabled;

  const FloatingEffect({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.floatHeight = 10.0,
    this.curve = Curves.easeInOut,
    this.enabled = true,
  }) : super(key: key);

  @override
  _FloatingEffectState createState() => _FloatingEffectState();
}

class _FloatingEffectState extends State<FloatingEffect> with SingleTickerProviderStateMixin {
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
    
    _animation = Tween<double>(
      begin: 0,
      end: widget.floatHeight,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    
    // Only start animation when widget is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkVisibility();
  }
  
  @override
  void didUpdateWidget(FloatingEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation parameters if they changed
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    
    if (oldWidget.floatHeight != widget.floatHeight || oldWidget.curve != widget.curve) {
      _animation = Tween<double>(
        begin: 0,
        end: widget.floatHeight,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ),
      );
    }
    
    // Update animation state based on enabled flag
    if (oldWidget.enabled != widget.enabled) {
      _updateAnimationState();
    }
  }
  
  void _checkVisibility() {
    // Check if widget is visible in viewport
    final bool isVisible = _isWidgetVisible();
    
    if (_isVisible != isVisible) {
      _isVisible = isVisible;
      _updateAnimationState();
    }
  }
  
  bool _isWidgetVisible() {
    // Simple check - assume widget is visible when mounted
    // For more accurate visibility detection, you would need to use VisibilityDetector package
    return mounted;
  }
  
  void _updateAnimationState() {
    if (widget.enabled && _isVisible) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      if (_controller.isAnimating) {
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
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: widget.child,
        );
      },
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;

  const ShimmerEffect({
    Key? key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    this.duration = const Duration(seconds: 1),
    this.enabled = true,
  }) : super(key: key);

  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    // Only start animation when widget is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkVisibility();
  }
  
  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation parameters if they changed
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    
    // Update animation state based on enabled flag
    if (oldWidget.enabled != widget.enabled) {
      _updateAnimationState();
    }
  }
  
  void _checkVisibility() {
    // Check if widget is visible in viewport
    final bool isVisible = _isWidgetVisible();
    
    if (_isVisible != isVisible) {
      _isVisible = isVisible;
      _updateAnimationState();
    }
  }
  
  bool _isWidgetVisible() {
    // Simple check - assume widget is visible when mounted
    // For more accurate visibility detection, you would need to use VisibilityDetector package
    return mounted;
  }
  
  void _updateAnimationState() {
    if (widget.enabled && _isVisible) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
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
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class RotatingEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double maxRotation;
  final Axis axis;
  final bool enabled;

  const RotatingEffect({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 10),
    this.maxRotation = 0.1, // in radians
    this.axis = Axis.vertical,
    this.enabled = true,
  }) : super(key: key);

  @override
  _RotatingEffectState createState() => _RotatingEffectState();
}

class _RotatingEffectState extends State<RotatingEffect> with SingleTickerProviderStateMixin {
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
    
    _animation = Tween<double>(
      begin: -widget.maxRotation,
      end: widget.maxRotation,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // Only start animation when widget is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkVisibility();
  }
  
  @override
  void didUpdateWidget(RotatingEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation parameters if they changed
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    
    if (oldWidget.maxRotation != widget.maxRotation) {
      _animation = Tween<double>(
        begin: -widget.maxRotation,
        end: widget.maxRotation,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );
    }
    
    // Update animation state based on enabled flag
    if (oldWidget.enabled != widget.enabled) {
      _updateAnimationState();
    }
  }
  
  void _checkVisibility() {
    // Check if widget is visible in viewport
    final bool isVisible = _isWidgetVisible();
    
    if (_isVisible != isVisible) {
      _isVisible = isVisible;
      _updateAnimationState();
    }
  }
  
  bool _isWidgetVisible() {
    // Simple check - assume widget is visible when mounted
    // For more accurate visibility detection, you would need to use VisibilityDetector package
    return mounted;
  }
  
  void _updateAnimationState() {
    if (widget.enabled && _isVisible) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      if (_controller.isAnimating) {
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
        return Transform(
          alignment: Alignment.center,
          transform: widget.axis == Axis.vertical
              ? Matrix4.rotationY(_animation.value)
              : Matrix4.rotationX(_animation.value),
          child: widget.child,
        );
      },
    );
  }
}

// Helper class to check if animations should be enabled based on device performance
class AnimationPerformanceManager {
  // Singleton pattern
  static final AnimationPerformanceManager _instance = AnimationPerformanceManager._internal();
  
  factory AnimationPerformanceManager() {
    return _instance;
  }
  
  AnimationPerformanceManager._internal();
  
  // Performance metrics
  int _slowFrameCount = 0;
  int _totalFrameCount = 0;
  bool _isLowPerformanceDevice = false;
  bool _areAnimationsEnabled = true;
  
  // Initialize performance monitoring
  void initialize() {
    // Start monitoring frame rate
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _monitorFrameRate();
    });
    
    // Check device performance
    _checkDevicePerformance();
  }
  
  void _monitorFrameRate() {
    _totalFrameCount++;
    
    // Check if frame took too long to render
    final timingInfo = SchedulerBinding.instance.currentTimings;
    if (timingInfo != null && timingInfo.totalSpan.inMilliseconds > 16) {
      _slowFrameCount++;
    }
    
    // Update animation state based on performance
    if (_totalFrameCount % 120 == 0) { // Check every ~2 seconds at 60fps
      _updateAnimationState();
    }
    
    // Schedule next frame check
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _monitorFrameRate();
    });
  }
  
  void _checkDevicePerformance() {
    // This is a simplified check - in a real app, you would use more sophisticated methods
    // to determine if the device is low-end
    final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final refreshRate = SchedulerBinding.instance.currentSystemFrameTimeStamp != null ? 
        1000 / SchedulerBinding.instance.currentSystemFrameTimeStamp!.inMilliseconds : 60;
    
    _isLowPerformanceDevice = devicePixelRatio < 2.0 || refreshRate < 50;
    _updateAnimationState();
  }
  
  void _updateAnimationState() {
    final slowFramePercentage = _totalFrameCount > 0 ? 
        (_slowFrameCount / _totalFrameCount) * 100 : 0;
    
    // Disable animations if device is struggling
    final bool shouldEnableAnimations = !_isLowPerformanceDevice && slowFramePercentage < 10;
    
    if (_areAnimationsEnabled != shouldEnableAnimations) {
      _areAnimationsEnabled = shouldEnableAnimations;
      // Notify listeners if needed
    }
  }
  
  // Check if animations should be enabled
  bool get areAnimationsEnabled => _areAnimationsEnabled;
  
  // Reset performance metrics
  void resetMetrics() {
    _slowFrameCount = 0;
    _totalFrameCount = 0;
  }
}
