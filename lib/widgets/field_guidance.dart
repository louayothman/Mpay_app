import 'package:flutter/material.dart';
import 'package:mpay_app/theme/enhanced_theme.dart';

/// A collection of widgets for providing field tooltips and help text
/// These widgets enhance the user experience by providing clear guidance
/// for form fields and input elements
class FieldGuidance {
  /// Shows a tooltip for a form field
  /// 
  /// Parameters:
  /// - [field]: The form field widget
  /// - [tooltip]: The tooltip text
  /// - [icon]: Optional custom icon
  /// - [position]: Position of the tooltip
  /// - [showOnFocus]: Whether to show the tooltip when the field is focused
  static Widget fieldWithTooltip({
    required Widget field,
    required String tooltip,
    IconData icon = Icons.info_outline,
    TooltipPosition position = TooltipPosition.end,
    bool showOnFocus = false,
  }) {
    return Builder(
      builder: (context) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          textDirection: position == TooltipPosition.end ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Expanded(child: field),
            const SizedBox(width: EnhancedTheme.smallSpacing),
            Tooltip(
              message: tooltip,
              preferBelow: position == TooltipPosition.below,
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
              child: Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// Shows a help text below a form field
  /// 
  /// Parameters:
  /// - [field]: The form field widget
  /// - [helpText]: The help text
  /// - [icon]: Optional custom icon
  /// - [showIcon]: Whether to show an icon
  static Widget fieldWithHelpText({
    required Widget field,
    required String helpText,
    IconData icon = Icons.help_outline,
    bool showIcon = true,
  }) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            field,
            const SizedBox(height: EnhancedTheme.smallSpacing / 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showIcon) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: EnhancedTheme.smallSpacing / 2),
                ],
                Expanded(
                  child: Text(
                    helpText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  /// Shows an error text below a form field
  /// 
  /// Parameters:
  /// - [field]: The form field widget
  /// - [errorText]: The error text
  /// - [icon]: Optional custom icon
  /// - [showIcon]: Whether to show an icon
  static Widget fieldWithErrorText({
    required Widget field,
    required String errorText,
    IconData icon = Icons.error_outline,
    bool showIcon = true,
  }) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            field,
            const SizedBox(height: EnhancedTheme.smallSpacing / 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showIcon) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: EnhancedTheme.smallSpacing / 2),
                ],
                Expanded(
                  child: Text(
                    errorText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  /// Shows a field with a label
  /// 
  /// Parameters:
  /// - [field]: The form field widget
  /// - [label]: The label text
  /// - [required]: Whether the field is required
  /// - [tooltip]: Optional tooltip text
  static Widget fieldWithLabel({
    required Widget field,
    required String label,
    bool required = false,
    String? tooltip,
  }) {
    return Builder(
      builder: (context) {
        Widget labelWidget = Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (required) ...[
              const SizedBox(width: EnhancedTheme.smallSpacing / 2),
              Text(
                '*',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        );
        
        if (tooltip != null) {
          labelWidget = Row(
            children: [
              Expanded(child: labelWidget),
              Tooltip(
                message: tooltip,
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
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelWidget,
            const SizedBox(height: EnhancedTheme.smallSpacing),
            field,
          ],
        );
      },
    );
  }
  
  /// Shows a field with a character counter
  /// 
  /// Parameters:
  /// - [field]: The form field widget
  /// - [currentLength]: Current text length
  /// - [maxLength]: Maximum text length
  /// - [showCounter]: Whether to show the counter
  static Widget fieldWithCounter({
    required Widget field,
    required int currentLength,
    required int maxLength,
    bool showCounter = true,
  }) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            field,
            if (showCounter) ...[
              const SizedBox(height: EnhancedTheme.smallSpacing / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$currentLength / $maxLength',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: currentLength > maxLength
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
  
  /// Shows a guided form field with comprehensive help
  /// 
  /// Parameters:
  /// - [field]: The form field widget
  /// - [label]: The label text
  /// - [helpText]: Optional help text
  /// - [errorText]: Optional error text
  /// - [required]: Whether the field is required
  /// - [tooltip]: Optional tooltip text
  /// - [currentLength]: Optional current text length
  /// - [maxLength]: Optional maximum text length
  static Widget guidedFormField({
    required Widget field,
    required String label,
    String? helpText,
    String? errorText,
    bool required = false,
    String? tooltip,
    int? currentLength,
    int? maxLength,
  }) {
    return Builder(
      builder: (context) {
        Widget result = fieldWithLabel(
          field: field,
          label: label,
          required: required,
          tooltip: tooltip,
        );
        
        if (errorText != null && errorText.isNotEmpty) {
          result = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              result,
              const SizedBox(height: EnhancedTheme.smallSpacing / 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: EnhancedTheme.smallSpacing / 2),
                  Expanded(
                    child: Text(
                      errorText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else if (helpText != null && helpText.isNotEmpty) {
          result = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              result,
              const SizedBox(height: EnhancedTheme.smallSpacing / 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: EnhancedTheme.smallSpacing / 2),
                  Expanded(
                    child: Text(
                      helpText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        
        if (currentLength != null && maxLength != null) {
          result = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              result,
              const SizedBox(height: EnhancedTheme.smallSpacing / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$currentLength / $maxLength',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: currentLength > maxLength
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        
        return result;
      },
    );
  }
}

/// Position of the tooltip
enum TooltipPosition {
  start,
  end,
  above,
  below,
}
