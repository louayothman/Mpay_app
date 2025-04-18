import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpay_app/theme/enhanced_theme.dart';

/// A collection of widgets for providing user feedback
/// These widgets enhance the user experience by providing clear feedback
/// for various user interactions and system states
class FeedbackWidgets {
  /// Shows a snackbar with customizable appearance and behavior
  /// 
  /// Parameters:
  /// - [context]: The build context
  /// - [message]: The message to display
  /// - [type]: The type of feedback (success, error, warning, info)
  /// - [duration]: How long to show the snackbar
  /// - [action]: Optional action button
  /// - [onDismissed]: Callback when snackbar is dismissed
  /// - [showIcon]: Whether to show an icon
  /// - [position]: Position of the snackbar (top, bottom)
  static void showSnackBar({
    required BuildContext context,
    required String message,
    FeedbackType type = FeedbackType.info,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    VoidCallback? onDismissed,
    bool showIcon = true,
    SnackBarPosition position = SnackBarPosition.bottom,
  }) {
    // Clear any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Get theme colors based on feedback type
    final Color backgroundColor = _getBackgroundColor(context, type);
    final Color textColor = _getTextColor(context, type);
    final Color iconColor = _getIconColor(context, type);
    final IconData icon = _getIcon(type);
    
    // Create snackbar
    final snackBar = SnackBar(
      content: Row(
        children: [
          if (showIcon) ...[
            Icon(
              icon,
              color: iconColor,
              size: 24,
              semanticLabel: _getSemanticLabel(type),
            ),
            const SizedBox(width: EnhancedTheme.smallSpacing),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontFamily: EnhancedTheme.fontFamily,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EnhancedTheme.mediumBorderRadius),
      ),
      margin: EdgeInsets.only(
        left: EnhancedTheme.mediumPadding,
        right: EnhancedTheme.mediumPadding,
        bottom: position == SnackBarPosition.bottom ? EnhancedTheme.mediumPadding : 0,
        top: position == SnackBarPosition.top ? EnhancedTheme.mediumPadding + 50 : 0,
      ),
      dismissDirection: position == SnackBarPosition.bottom
          ? DismissDirection.down
          : DismissDirection.up,
      elevation: EnhancedTheme.mediumElevation,
      onVisible: () {
        // Provide haptic feedback
        HapticFeedback.mediumImpact();
        
        // Announce to screen readers
        final String semanticMessage = '${_getSemanticLabel(type)}: $message';
        SemanticsService.announce(semanticMessage, TextDirection.rtl);
      },
    );
    
    // Show the snackbar
    final SnackBarClosedReason reason = ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
      if (onDismissed != null) {
        onDismissed();
      }
      return reason;
    }) as SnackBarClosedReason;
  }
  
  /// Shows a toast message that automatically disappears
  static void showToast({
    required BuildContext context,
    required String message,
    FeedbackType type = FeedbackType.info,
    Duration duration = const Duration(seconds: 2),
    bool showIcon = true,
    ToastPosition position = ToastPosition.bottom,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) {
        return _ToastWidget(
          message: message,
          type: type,
          showIcon: showIcon,
          position: position,
        );
      },
    );
    
    // Add toast to overlay
    overlay.insert(overlayEntry);
    
    // Provide haptic feedback
    HapticFeedback.selectionClick();
    
    // Remove after duration
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
  
  /// Shows a loading dialog with customizable appearance
  static Future<T?> showLoadingDialog<T>({
    required BuildContext context,
    String message = 'جاري التحميل...',
    bool barrierDismissible = false,
    Color? barrierColor,
    String? semanticLabel,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => barrierDismissible,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: EnhancedTheme.mediumSpacing),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EnhancedTheme.largeBorderRadius),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: EnhancedTheme.highElevation,
            semanticLabel: semanticLabel ?? 'شاشة التحميل: $message',
          ),
        );
      },
    );
  }
  
  /// Shows a confirmation dialog with customizable appearance and actions
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    FeedbackType type = FeedbackType.info,
    bool barrierDismissible = true,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getIcon(type),
                color: _getIconColor(context, type),
                semanticLabel: _getSemanticLabel(type),
              ),
              const SizedBox(width: EnhancedTheme.smallSpacing),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                if (onCancel != null) {
                  onCancel();
                }
              },
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                if (onConfirm != null) {
                  onConfirm();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getBackgroundColor(context, type),
                foregroundColor: _getTextColor(context, type),
              ),
              child: Text(confirmText),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EnhancedTheme.largeBorderRadius),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: EnhancedTheme.highElevation,
        );
      },
    );
    
    return result ?? false;
  }
  
  /// Shows a banner at the top of the screen
  static void showBanner({
    required BuildContext context,
    required String message,
    required String title,
    FeedbackType type = FeedbackType.info,
    List<Widget>? actions,
    bool showIcon = true,
    VoidCallback? onClose,
  }) {
    final MaterialBanner banner = MaterialBanner(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: EnhancedTheme.smallSpacing / 2),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      leading: showIcon ? Icon(
        _getIcon(type),
        color: _getIconColor(context, type),
        size: 28,
        semanticLabel: _getSemanticLabel(type),
      ) : null,
      backgroundColor: _getBackgroundColor(context, type).withOpacity(0.7),
      forceActionsBelow: actions != null && actions.length > 1,
      actions: actions ?? [
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            if (onClose != null) {
              onClose();
            }
          },
          child: const Text('إغلاق'),
        ),
      ],
      elevation: EnhancedTheme.lowElevation,
      padding: const EdgeInsets.all(EnhancedTheme.mediumPadding),
      margin: const EdgeInsets.all(EnhancedTheme.smallPadding),
      onVisible: () {
        // Provide haptic feedback
        HapticFeedback.mediumImpact();
        
        // Announce to screen readers
        final String semanticMessage = '${_getSemanticLabel(type)}: $title - $message';
        SemanticsService.announce(semanticMessage, TextDirection.rtl);
      },
    );
    
    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(banner);
  }
  
  /// Shows an in-app notification that slides in from the top
  static void showInAppNotification({
    required BuildContext context,
    required String title,
    required String message,
    FeedbackType type = FeedbackType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    Widget? trailing,
    bool showIcon = true,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) {
        return _InAppNotificationWidget(
          title: title,
          message: message,
          type: type,
          duration: duration,
          onTap: onTap,
          onDismiss: () {
            overlayEntry.remove();
            if (onDismiss != null) {
              onDismiss();
            }
          },
          trailing: trailing,
          showIcon: showIcon,
        );
      },
    );
    
    // Add notification to overlay
    overlay.insert(overlayEntry);
    
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    // Remove after duration
    if (onTap == null) {
      Future.delayed(duration, () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
          if (onDismiss != null) {
            onDismiss();
          }
        }
      });
    }
  }
  
  /// Shows a progress indicator with customizable appearance
  static Widget progressIndicator({
    required double value,
    FeedbackType type = FeedbackType.info,
    String? label,
    String? valueLabel,
    double height = 8.0,
    bool showPercentage = false,
    bool animate = true,
    String? semanticLabel,
  }) {
    return Builder(
      builder: (context) {
        final Color progressColor = _getIconColor(context, type);
        final Color backgroundColor = _getBackgroundColor(context, type).withOpacity(0.2);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null || valueLabel != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (label != null)
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (valueLabel != null)
                    Text(
                      valueLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (showPercentage)
                    Text(
                      '${(value * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            if (label != null || valueLabel != null)
              const SizedBox(height: EnhancedTheme.smallSpacing / 2),
            Semantics(
              label: semanticLabel ?? 'شريط التقدم: ${(value * 100).toInt()}%',
              value: '${(value * 100).toInt()}%',
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: height,
                borderRadius: BorderRadius.circular(height / 2),
                semanticsLabel: semanticLabel,
                semanticsValue: '${(value * 100).toInt()}%',
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// Shows a button with haptic feedback
  static Widget feedbackButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback onPressed,
    FeedbackType feedbackType = FeedbackType.info,
    HapticFeedbackType hapticType = HapticFeedbackType.medium,
    ButtonStyle? style,
    bool isOutlined = false,
    bool isTextButton = false,
    String? semanticLabel,
    bool enabled = true,
  }) {
    final void Function()? onPressedWithFeedback = enabled ? () {
      _triggerHapticFeedback(hapticType);
      onPressed();
    } : null;
    
    final Widget semanticChild = semanticLabel != null
        ? Semantics(
            label: semanticLabel,
            button: true,
            enabled: enabled,
            child: ExcludeSemantics(child: child),
          )
        : child;
    
    if (isTextButton) {
      return TextButton(
        onPressed: onPressedWithFeedback,
        style: style,
        child: semanticChild,
      );
    } else if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressedWithFeedback,
        style: style,
        child: semanticChild,
      );
    } else {
      return ElevatedButton(
        onPressed: onPressedWithFeedback,
        style: style,
        child: semanticChild,
      );
    }
  }
  
  /// Shows a tooltip with enhanced accessibility
  static Widget enhancedTooltip({
    required BuildContext context,
    required Widget child,
    required String message,
    String? richMessage,
    TooltipTriggerMode triggerMode = TooltipTriggerMode.longPress,
    Duration waitDuration = const Duration(milliseconds: 500),
    Duration showDuration = const Duration(seconds: 2),
    bool preferBelow = true,
    EdgeInsetsGeometry? padding,
    double? height,
    bool enableFeedback = true,
  }) {
    return Tooltip(
      message: message,
      richMessage: richMessage != null ? TextSpan(text: richMessage) : null,
      triggerMode: triggerMode,
      waitDuration: waitDuration,
      showDuration: showDuration,
      preferBelow: preferBelow,
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: EnhancedTheme.mediumPadding,
        vertical: EnhancedTheme.smallPadding,
      ),
      height: height,
      enableFeedback: enableFeedback,
      textStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        fontSize: 14,
        fontFamily: EnhancedTheme.fontFamily,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.9)
            : Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(EnhancedTheme.smallBorderRadius),
      ),
      child: child,
    );
  }
  
  // Helper methods
  static Color _getBackgroundColor(BuildContext context, FeedbackType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (type) {
      case FeedbackType.success:
        return isDark
            ? EnhancedTheme.successColor.withOpacity(0.2)
            : EnhancedTheme.successColor.withOpacity(0.1);
      case FeedbackType.error:
        return isDark
            ? EnhancedTheme.errorColor.withOpacity(0.2)
            : EnhancedTheme.errorColor.withOpacity(0.1);
      case FeedbackType.warning:
        return isDark
            ? EnhancedTheme.warningColor.withOpacity(0.2)
            : EnhancedTheme.warningColor.withOpacity(0.1);
      case FeedbackType.info:
        return isDark
            ? EnhancedTheme.infoColor.withOpacity(0.2)
            : EnhancedTheme.infoColor.withOpacity(0.1);
    }
  }
  
  static Color _getTextColor(BuildContext context, FeedbackType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (type) {
      case FeedbackType.success:
        return isDark ? Colors.white : EnhancedTheme.successColor.shade800;
      case FeedbackType.error:
        return isDark ? Colors.white : EnhancedTheme.errorColor.shade800;
      case FeedbackType.warning:
        return isDark ? Colors.white : EnhancedTheme.warningColor.shade800;
      case FeedbackType.info:
        return isDark ? Colors.white : EnhancedTheme.infoColor.shade800;
    }
  }
  
  static Color _getIconColor(BuildContext context, FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return EnhancedTheme.successColor;
      case FeedbackType.error:
        return EnhancedTheme.errorColor;
      case FeedbackType.warning:
        return EnhancedTheme.warningColor;
      case FeedbackType.info:
        return EnhancedTheme.infoColor;
    }
  }
  
  static IconData _getIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Icons.check_circle_outline;
      case FeedbackType.error:
        return Icons.error_outline;
      case FeedbackType.warning:
        return Icons.warning_amber_outlined;
      case FeedbackType.info:
        return Icons.info_outline;
    }
  }
  
  static String _getSemanticLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return 'نجاح';
      case FeedbackType.error:
        return 'خطأ';
      case FeedbackType.warning:
        return 'تحذير';
      case FeedbackType.info:
        return 'معلومات';
    }
  }
  
  static void _triggerHapticFeedback(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }
}

/// Type of feedback to show
enum FeedbackType {
  success,
  error,
  warning,
  info,
}

/// Position of the snackbar
enum SnackBarPosition {
  top,
  bottom,
}

/// Position of the toast
enum ToastPosition {
  top,
  center,
  bottom,
}

/// Type of haptic feedback
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  vibrate,
}

/// Toast widget implementation
class _ToastWidget extends StatefulWidget {
  final String message;
  final FeedbackType type;
  final bool showIcon;
  final ToastPosition position;
  
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.showIcon,
    required this.position,
  });
  
  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
      ),
    );
    
    // Different animations based on position
    switch (widget.position) {
      case ToastPosition.top:
        _positionAnimation = Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        );
        break;
      case ToastPosition.center:
        _positionAnimation = Tween<Offset>(
          begin: const Offset(0, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        );
        break;
      case ToastPosition.bottom:
        _positionAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        );
        break;
    }
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Semantics(
        label: '${FeedbackWidgets._getSemanticLabel(widget.type)}: ${widget.message}',
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: _getAlignment(),
              child: Padding(
                padding: const EdgeInsets.all(EnhancedTheme.mediumPadding),
                child: SlideTransition(
                  position: _positionAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EnhancedTheme.mediumPadding,
                        vertical: EnhancedTheme.smallPadding,
                      ),
                      decoration: BoxDecoration(
                        color: FeedbackWidgets._getBackgroundColor(context, widget.type),
                        borderRadius: BorderRadius.circular(EnhancedTheme.mediumBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.showIcon) ...[
                            Icon(
                              FeedbackWidgets._getIcon(widget.type),
                              color: FeedbackWidgets._getIconColor(context, widget.type),
                              size: 20,
                            ),
                            const SizedBox(width: EnhancedTheme.smallSpacing),
                          ],
                          Flexible(
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                color: FeedbackWidgets._getTextColor(context, widget.type),
                                fontFamily: EnhancedTheme.fontFamily,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Alignment _getAlignment() {
    switch (widget.position) {
      case ToastPosition.top:
        return Alignment.topCenter;
      case ToastPosition.center:
        return Alignment.center;
      case ToastPosition.bottom:
        return Alignment.bottomCenter;
    }
  }
}

/// In-app notification widget implementation
class _InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final FeedbackType type;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;
  final Widget? trailing;
  final bool showIcon;
  
  const _InAppNotificationWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    this.onTap,
    required this.onDismiss,
    this.trailing,
    required this.showIcon,
  });
  
  @override
  _InAppNotificationWidgetState createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<_InAppNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
      ),
    );
    
    _controller.forward();
    
    // Announce to screen readers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String semanticMessage = '${FeedbackWidgets._getSemanticLabel(widget.type)}: ${widget.title} - ${widget.message}';
      SemanticsService.announce(semanticMessage, TextDirection.rtl);
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Semantics(
        label: '${FeedbackWidgets._getSemanticLabel(widget.type)}: ${widget.title} - ${widget.message}',
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(EnhancedTheme.mediumPadding),
                child: SlideTransition(
                  position: _positionAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: GestureDetector(
                      onTap: widget.onTap,
                      onVerticalDragEnd: (details) {
                        if (details.primaryVelocity! < 0) {
                          // Swipe up to dismiss
                          _controller.reverse().then((_) {
                            widget.onDismiss();
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(EnhancedTheme.mediumPadding),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(EnhancedTheme.mediumBorderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: FeedbackWidgets._getIconColor(context, widget.type).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (widget.showIcon) ...[
                              Container(
                                padding: const EdgeInsets.all(EnhancedTheme.smallPadding),
                                decoration: BoxDecoration(
                                  color: FeedbackWidgets._getIconColor(context, widget.type).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  FeedbackWidgets._getIcon(widget.type),
                                  color: FeedbackWidgets._getIconColor(context, widget.type),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: EnhancedTheme.mediumSpacing),
                            ],
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: EnhancedTheme.smallSpacing / 2),
                                  Text(
                                    widget.message,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (widget.trailing != null) ...[
                              const SizedBox(width: EnhancedTheme.smallSpacing),
                              widget.trailing!,
                            ] else ...[
                              const SizedBox(width: EnhancedTheme.smallSpacing),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _controller.reverse().then((_) {
                                    widget.onDismiss();
                                  });
                                },
                                tooltip: 'إغلاق',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
