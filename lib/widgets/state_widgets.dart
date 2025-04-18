import 'package:flutter/material.dart';
import 'package:mpay_app/theme/enhanced_theme.dart';

/// A collection of widgets for providing loading, error, and empty states
/// These widgets enhance the user experience by providing clear feedback
/// for various application states
class StateWidgets {
  /// Shows a loading state with customizable appearance
  /// 
  /// Parameters:
  /// - [message]: Optional message to display
  /// - [showSpinner]: Whether to show a loading spinner
  /// - [customIndicator]: Optional custom loading indicator
  /// - [semanticLabel]: Semantic label for accessibility
  static Widget loadingState({
    String? message,
    bool showSpinner = true,
    Widget? customIndicator,
    String? semanticLabel,
  }) {
    return Builder(
      builder: (context) {
        return Semantics(
          label: semanticLabel ?? 'جاري التحميل',
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSpinner)
                  customIndicator ?? const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: EnhancedTheme.mediumSpacing),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Shows an error state with customizable appearance
  /// 
  /// Parameters:
  /// - [message]: Error message to display
  /// - [title]: Optional title for the error
  /// - [icon]: Optional custom icon
  /// - [onRetry]: Optional callback for retry action
  /// - [retryText]: Text for retry button
  /// - [semanticLabel]: Semantic label for accessibility
  static Widget errorState({
    required String message,
    String? title,
    IconData icon = Icons.error_outline,
    VoidCallback? onRetry,
    String retryText = 'إعادة المحاولة',
    String? semanticLabel,
  }) {
    return Builder(
      builder: (context) {
        return Semantics(
          label: semanticLabel ?? 'خطأ: $message',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(EnhancedTheme.mediumPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                    semanticLabel: 'رمز الخطأ',
                  ),
                  const SizedBox(height: EnhancedTheme.mediumSpacing),
                  if (title != null) ...[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: EnhancedTheme.smallSpacing),
                  ],
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: EnhancedTheme.largeSpacing),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(retryText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Shows an empty state with customizable appearance
  /// 
  /// Parameters:
  /// - [message]: Message to display
  /// - [title]: Optional title
  /// - [icon]: Optional custom icon
  /// - [action]: Optional action button
  /// - [semanticLabel]: Semantic label for accessibility
  static Widget emptyState({
    required String message,
    String? title,
    IconData icon = Icons.inbox_outlined,
    Widget? action,
    String? semanticLabel,
  }) {
    return Builder(
      builder: (context) {
        return Semantics(
          label: semanticLabel ?? 'لا توجد بيانات: $message',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(EnhancedTheme.mediumPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    semanticLabel: 'رمز الحالة الفارغة',
                  ),
                  const SizedBox(height: EnhancedTheme.mediumSpacing),
                  if (title != null) ...[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: EnhancedTheme.smallSpacing),
                  ],
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (action != null) ...[
                    const SizedBox(height: EnhancedTheme.largeSpacing),
                    action,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Shows a success state with customizable appearance
  /// 
  /// Parameters:
  /// - [message]: Success message to display
  /// - [title]: Optional title
  /// - [icon]: Optional custom icon
  /// - [action]: Optional action button
  /// - [semanticLabel]: Semantic label for accessibility
  static Widget successState({
    required String message,
    String? title,
    IconData icon = Icons.check_circle_outline,
    Widget? action,
    String? semanticLabel,
  }) {
    return Builder(
      builder: (context) {
        return Semantics(
          label: semanticLabel ?? 'نجاح: $message',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(EnhancedTheme.mediumPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: EnhancedTheme.successColor,
                    semanticLabel: 'رمز النجاح',
                  ),
                  const SizedBox(height: EnhancedTheme.mediumSpacing),
                  if (title != null) ...[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: EnhancedTheme.successColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: EnhancedTheme.smallSpacing),
                  ],
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (action != null) ...[
                    const SizedBox(height: EnhancedTheme.largeSpacing),
                    action,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Shows a placeholder state for content that is loading
  /// 
  /// Parameters:
  /// - [width]: Width of the placeholder
  /// - [height]: Height of the placeholder
  /// - [shape]: Shape of the placeholder
  /// - [color]: Color of the placeholder
  /// - [animate]: Whether to animate the placeholder
  /// - [semanticLabel]: Semantic label for accessibility
  static Widget placeholderState({
    double? width,
    double? height,
    BoxShape shape = BoxShape.rectangle,
    Color? color,
    bool animate = true,
    BorderRadius? borderRadius,
    String? semanticLabel,
  }) {
    return Builder(
      builder: (context) {
        final placeholderColor = color ?? 
            Theme.of(context).colorScheme.onBackground.withOpacity(0.1);
        
        Widget placeholder = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: placeholderColor,
            shape: shape,
            borderRadius: shape == BoxShape.rectangle ? 
                (borderRadius ?? BorderRadius.circular(EnhancedTheme.smallBorderRadius)) : 
                null,
          ),
        );
        
        if (animate) {
          placeholder = _AnimatedPlaceholder(
            child: placeholder,
          );
        }
        
        return Semantics(
          label: semanticLabel ?? 'محتوى قيد التحميل',
          child: placeholder,
        );
      },
    );
  }
  
  /// Shows a shimmer loading effect for content that is loading
  /// 
  /// Parameters:
  /// - [child]: Child widget to apply shimmer effect to
  /// - [baseColor]: Base color for shimmer effect
  /// - [highlightColor]: Highlight color for shimmer effect
  /// - [enabled]: Whether the shimmer effect is enabled
  /// - [semanticLabel]: Semantic label for accessibility
  static Widget shimmerLoadingState({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    bool enabled = true,
    String? semanticLabel,
  }) {
    return Builder(
      builder: (context) {
        final baseColorValue = baseColor ?? 
            Theme.of(context).colorScheme.onBackground.withOpacity(0.1);
        final highlightColorValue = highlightColor ?? 
            Theme.of(context).colorScheme.onBackground.withOpacity(0.05);
        
        if (!enabled) {
          return child;
        }
        
        return Semantics(
          label: semanticLabel ?? 'محتوى قيد التحميل',
          child: _ShimmerEffect(
            baseColor: baseColorValue,
            highlightColor: highlightColorValue,
            child: child,
          ),
        );
      },
    );
  }
  
  /// Shows a skeleton loading state for content that is loading
  /// 
  /// Parameters:
  /// - [child]: Child widget to apply skeleton effect to
  /// - [enabled]: Whether the skeleton effect is enabled
  /// - [semanticLabel]: Semantic label for accessibility
  static Widget skeletonLoadingState({
    required Widget child,
    bool enabled = true,
    String? semanticLabel,
  }) {
    if (!enabled) {
      return child;
    }
    
    return shimmerLoadingState(
      child: child,
      semanticLabel: semanticLabel ?? 'محتوى قيد التحميل',
    );
  }
}

/// Animated placeholder widget implementation
class _AnimatedPlaceholder extends StatefulWidget {
  final Widget child;
  
  const _AnimatedPlaceholder({
    required this.child,
  });
  
  @override
  _AnimatedPlaceholderState createState() => _AnimatedPlaceholderState();
}

class _AnimatedPlaceholderState extends State<_AnimatedPlaceholder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer effect widget implementation
class _ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  
  const _ShimmerEffect({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
  });
  
  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
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
                _controller.value,
                1.0,
              ],
              begin: const Alignment(-1.0, -0.5),
              end: const Alignment(1.0, 0.5),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
