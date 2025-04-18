import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// مدير إمكانية الوصول
/// 
/// يوفر هذا الصف آليات لتحسين إمكانية الوصول في التطبيق
/// ويتضمن وظائف لدعم قارئات الشاشة وتباين الألوان والتكبير وغيرها
class AccessibilityManager {
  // نمط Singleton
  static final AccessibilityManager _instance = AccessibilityManager._internal();
  
  factory AccessibilityManager() {
    return _instance;
  }
  
  AccessibilityManager._internal();
  
  // معلومات إمكانية الوصول
  late bool _isScreenReaderEnabled;
  late bool _isHighContrastEnabled;
  late bool _isBoldTextEnabled;
  late bool _isReduceMotionEnabled;
  late double _textScaleFactor;
  
  // تهيئة مدير إمكانية الوصول
  Future<void> initialize(BuildContext context) async {
    final mediaQuery = MediaQuery.of(context);
    
    _textScaleFactor = mediaQuery.textScaler.scale(1.0);
    
    // الحصول على حالة قارئ الشاشة
    _isScreenReaderEnabled = mediaQuery.accessibleNavigation;
    
    // الحصول على حالة التباين العالي
    _isHighContrastEnabled = mediaQuery.highContrast;
    
    // الحصول على حالة النص العريض
    _isBoldTextEnabled = mediaQuery.boldText;
    
    // الحصول على حالة تقليل الحركة
    _isReduceMotionEnabled = mediaQuery.disableAnimations;
    
    // الاستماع إلى تغييرات إمكانية الوصول
    _listenToAccessibilityChanges();
  }
  
  // الاستماع إلى تغييرات إمكانية الوصول
  void _listenToAccessibilityChanges() {
    // في التنفيذ الحقيقي، يمكن استخدام قنوات أصلية للاستماع إلى تغييرات إمكانية الوصول
  }
  
  // التحقق مما إذا كان قارئ الشاشة ممكّنًا
  bool get isScreenReaderEnabled => _isScreenReaderEnabled;
  
  // التحقق مما إذا كان التباين العالي ممكّنًا
  bool get isHighContrastEnabled => _isHighContrastEnabled;
  
  // التحقق مما إذا كان النص العريض ممكّنًا
  bool get isBoldTextEnabled => _isBoldTextEnabled;
  
  // التحقق مما إذا كان تقليل الحركة ممكّنًا
  bool get isReduceMotionEnabled => _isReduceMotionEnabled;
  
  // الحصول على عامل مقياس النص
  double get textScaleFactor => _textScaleFactor;
  
  // الحصول على حجم خط قابل للوصول
  double getAccessibleFontSize(double baseSize) {
    double finalSize = baseSize * _textScaleFactor;
    
    // إذا كان النص العريض ممكّنًا، زيادة حجم الخط قليلاً
    if (_isBoldTextEnabled) {
      finalSize *= 1.1;
    }
    
    return finalSize;
  }
  
  // الحصول على نمط خط قابل للوصول
  TextStyle getAccessibleTextStyle(TextStyle baseStyle) {
    TextStyle finalStyle = baseStyle;
    
    // تطبيق عامل مقياس النص
    finalStyle = finalStyle.copyWith(
      fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! * _textScaleFactor : null,
    );
    
    // إذا كان النص العريض ممكّنًا، جعل النص عريضًا
    if (_isBoldTextEnabled) {
      finalStyle = finalStyle.copyWith(
        fontWeight: FontWeight.bold,
      );
    }
    
    // إذا كان التباين العالي ممكّنًا، زيادة التباين
    if (_isHighContrastEnabled) {
      finalStyle = finalStyle.copyWith(
        color: _increaseContrast(finalStyle.color ?? Colors.black),
      );
    }
    
    return finalStyle;
  }
  
  // زيادة تباين اللون
  Color _increaseContrast(Color color) {
    // حساب درجة السطوع
    final brightness = color.computeLuminance();
    
    // إذا كان اللون فاتحًا، جعله أكثر سطوعًا
    // إذا كان اللون داكنًا، جعله أكثر قتامة
    if (brightness > 0.5) {
      return Color.fromARGB(
        color.alpha,
        (color.red * 1.2).clamp(0, 255).toInt(),
        (color.green * 1.2).clamp(0, 255).toInt(),
        (color.blue * 1.2).clamp(0, 255).toInt(),
      );
    } else {
      return Color.fromARGB(
        color.alpha,
        (color.red * 0.8).clamp(0, 255).toInt(),
        (color.green * 0.8).clamp(0, 255).toInt(),
        (color.blue * 0.8).clamp(0, 255).toInt(),
      );
    }
  }
  
  // الحصول على لون قابل للوصول
  Color getAccessibleColor(Color baseColor) {
    // إذا كان التباين العالي ممكّنًا، زيادة التباين
    if (_isHighContrastEnabled) {
      return _increaseContrast(baseColor);
    }
    
    return baseColor;
  }
  
  // الحصول على حجم أيقونة قابل للوصول
  double getAccessibleIconSize(double baseSize) {
    double finalSize = baseSize;
    
    // زيادة حجم الأيقونة إذا كان عامل مقياس النص كبيرًا
    if (_textScaleFactor > 1.2) {
      finalSize *= _textScaleFactor;
    }
    
    return finalSize;
  }
  
  // الحصول على حجم زر قابل للوصول
  Size getAccessibleButtonSize(Size baseSize) {
    double finalWidth = baseSize.width;
    double finalHeight = baseSize.height;
    
    // زيادة حجم الزر إذا كان عامل مقياس النص كبيرًا
    if (_textScaleFactor > 1.2) {
      finalWidth *= _textScaleFactor;
      finalHeight *= _textScaleFactor;
    }
    
    return Size(finalWidth, finalHeight);
  }
  
  // الحصول على حشوة قابلة للوصول
  EdgeInsets getAccessiblePadding(EdgeInsets basePadding) {
    // زيادة الحشوة إذا كان عامل مقياس النص كبيرًا
    if (_textScaleFactor > 1.2) {
      return EdgeInsets.fromLTRB(
        basePadding.left * _textScaleFactor,
        basePadding.top * _textScaleFactor,
        basePadding.right * _textScaleFactor,
        basePadding.bottom * _textScaleFactor,
      );
    }
    
    return basePadding;
  }
  
  // الحصول على هامش قابل للوصول
  EdgeInsets getAccessibleMargin(EdgeInsets baseMargin) {
    // زيادة الهامش إذا كان عامل مقياس النص كبيرًا
    if (_textScaleFactor > 1.2) {
      return EdgeInsets.fromLTRB(
        baseMargin.left * _textScaleFactor,
        baseMargin.top * _textScaleFactor,
        baseMargin.right * _textScaleFactor,
        baseMargin.bottom * _textScaleFactor,
      );
    }
    
    return baseMargin;
  }
  
  // الحصول على رسوم متحركة قابلة للوصول
  Duration getAccessibleAnimationDuration(Duration baseDuration) {
    // إذا كان تقليل الحركة ممكّنًا، تقليل مدة الرسوم المتحركة أو إلغاؤها
    if (_isReduceMotionEnabled) {
      return Duration.zero;
    }
    
    return baseDuration;
  }
  
  // إضافة وصف دلالي لعنصر واجهة المستخدم
  Widget addSemanticLabel(Widget child, String label) {
    return Semantics(
      label: label,
      child: child,
    );
  }
  
  // إضافة وصف دلالي للزر
  Widget addButtonSemantics(Widget button, String label, {String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      child: button,
    );
  }
  
  // إضافة وصف دلالي للصورة
  Widget addImageSemantics(Widget image, String label) {
    return Semantics(
      label: label,
      image: true,
      child: image,
    );
  }
  
  // إضافة وصف دلالي للنص
  Widget addTextSemantics(Widget text, String label) {
    return Semantics(
      label: label,
      textField: true,
      child: text,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addCheckboxSemantics(Widget checkbox, String label, bool checked) {
    return Semantics(
      label: label,
      checked: checked,
      child: checkbox,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتمرير
  Widget addScrollableSemantics(Widget scrollable, String label) {
    return Semantics(
      label: label,
      scrollable: true,
      child: scrollable,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتركيز
  Widget addFocusableSemantics(Widget focusable, String label) {
    return Semantics(
      label: label,
      focusable: true,
      child: focusable,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للنقر
  Widget addTappableSemantics(Widget tappable, String label) {
    return Semantics(
      label: label,
      button: true,
      child: tappable,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحرير
  Widget addEditableSemantics(Widget editable, String label) {
    return Semantics(
      label: label,
      textField: true,
      child: editable,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addSelectableSemantics(Widget selectable, String label, bool selected) {
    return Semantics(
      label: label,
      selected: selected,
      child: selectable,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتوسيع
  Widget addExpandableSemantics(Widget expandable, String label, bool expanded) {
    return Semantics(
      label: label,
      expanded: expanded,
      child: expandable,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتمكين
  Widget addEnableableSemantics(Widget enableable, String label, bool enabled) {
    return Semantics(
      label: label,
      enabled: enabled,
      child: enableable,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للقراءة فقط
  Widget addReadOnlySemantics(Widget readOnly, String label) {
    return Semantics(
      label: label,
      readOnly: true,
      child: readOnly,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديث
  Widget addLiveRegionSemantics(Widget liveRegion, String label) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: liveRegion,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتجاهل
  Widget addIgnoreSemantics(Widget ignore) {
    return ExcludeSemantics(
      child: ignore,
    );
  }
  
  // إضافة وصف دلالي لمجموعة عناصر
  Widget addGroupSemantics(Widget group, String label) {
    return Semantics(
      label: label,
      container: true,
      child: group,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addRadioSemantics(Widget radio, String label, bool selected) {
    return Semantics(
      label: label,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      child: radio,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addSwitchSemantics(Widget switchWidget, String label, bool toggled) {
    return Semantics(
      label: label,
      toggled: toggled,
      child: switchWidget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addSliderSemantics(Widget slider, String label, double value, double min, double max) {
    return Semantics(
      label: label,
      value: '$value',
      increasedValue: '${(value + (max - min) / 10).clamp(min, max)}',
      decreasedValue: '${(value - (max - min) / 10).clamp(min, max)}',
      child: slider,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addProgressSemantics(Widget progress, String label, double value, double max) {
    return Semantics(
      label: label,
      value: '${(value / max * 100).toStringAsFixed(0)}%',
      child: progress,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addHeaderSemantics(Widget header, String label) {
    return Semantics(
      label: label,
      header: true,
      child: header,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addLinkSemantics(Widget link, String label) {
    return Semantics(
      label: label,
      link: true,
      child: link,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addCustomAction(Widget widget, String label, VoidCallback onAction) {
    return Semantics(
      label: label,
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'تنفيذ'): onAction,
      },
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addHintSemantics(Widget widget, String hint) {
    return Semantics(
      hint: hint,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addValueSemantics(Widget widget, String value) {
    return Semantics(
      value: value,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addIncreasedValueSemantics(Widget widget, String increasedValue) {
    return Semantics(
      increasedValue: increasedValue,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addDecreasedValueSemantics(Widget widget, String decreasedValue) {
    return Semantics(
      decreasedValue: decreasedValue,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnTapSemantics(Widget widget, String label, VoidCallback onTap) {
    return Semantics(
      label: label,
      onTap: onTap,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnLongPressSemantics(Widget widget, String label, VoidCallback onLongPress) {
    return Semantics(
      label: label,
      onLongPress: onLongPress,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnScrollLeftSemantics(Widget widget, String label, VoidCallback onScrollLeft) {
    return Semantics(
      label: label,
      onScrollLeft: onScrollLeft,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnScrollRightSemantics(Widget widget, String label, VoidCallback onScrollRight) {
    return Semantics(
      label: label,
      onScrollRight: onScrollRight,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnScrollUpSemantics(Widget widget, String label, VoidCallback onScrollUp) {
    return Semantics(
      label: label,
      onScrollUp: onScrollUp,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnScrollDownSemantics(Widget widget, String label, VoidCallback onScrollDown) {
    return Semantics(
      label: label,
      onScrollDown: onScrollDown,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnIncreasedSemantics(Widget widget, String label, VoidCallback onIncreased) {
    return Semantics(
      label: label,
      onIncreased: onIncreased,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnDecreasedSemantics(Widget widget, String label, VoidCallback onDecreased) {
    return Semantics(
      label: label,
      onDecreased: onDecreased,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnCopySemantics(Widget widget, String label, VoidCallback onCopy) {
    return Semantics(
      label: label,
      onCopy: onCopy,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnCutSemantics(Widget widget, String label, VoidCallback onCut) {
    return Semantics(
      label: label,
      onCut: onCut,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnPasteSemantics(Widget widget, String label, VoidCallback onPaste) {
    return Semantics(
      label: label,
      onPaste: onPaste,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnDismissSemantics(Widget widget, String label, VoidCallback onDismiss) {
    return Semantics(
      label: label,
      onDismiss: onDismiss,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnMoveCursorForwardByCharacterSemantics(Widget widget, String label, MoveCursorHandler onMoveCursorForwardByCharacter) {
    return Semantics(
      label: label,
      onMoveCursorForwardByCharacter: onMoveCursorForwardByCharacter,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnMoveCursorBackwardByCharacterSemantics(Widget widget, String label, MoveCursorHandler onMoveCursorBackwardByCharacter) {
    return Semantics(
      label: label,
      onMoveCursorBackwardByCharacter: onMoveCursorBackwardByCharacter,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnMoveCursorForwardByWordSemantics(Widget widget, String label, MoveCursorHandler onMoveCursorForwardByWord) {
    return Semantics(
      label: label,
      onMoveCursorForwardByWord: onMoveCursorForwardByWord,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnMoveCursorBackwardByWordSemantics(Widget widget, String label, MoveCursorHandler onMoveCursorBackwardByWord) {
    return Semantics(
      label: label,
      onMoveCursorBackwardByWord: onMoveCursorBackwardByWord,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnSetSelectionSemantics(Widget widget, String label, SetSelectionHandler onSetSelection) {
    return Semantics(
      label: label,
      onSetSelection: onSetSelection,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnDidGainAccessibilityFocusSemantics(Widget widget, String label, VoidCallback onDidGainAccessibilityFocus) {
    return Semantics(
      label: label,
      onDidGainAccessibilityFocus: onDidGainAccessibilityFocus,
      child: widget,
    );
  }
  
  // إضافة وصف دلالي لعنصر قابل للتحديد
  Widget addOnDidLoseAccessibilityFocusSemantics(Widget widget, String label, VoidCallback onDidLoseAccessibilityFocus) {
    return Semantics(
      label: label,
      onDidLoseAccessibilityFocus: onDidLoseAccessibilityFocus,
      child: widget,
    );
  }
}

/// عنصر واجهة مستخدم قابل للوصول
/// 
/// يوفر هذا العنصر واجهة مستخدم قابلة للوصول تدعم قارئات الشاشة وتباين الألوان والتكبير وغيرها
class AccessibleWidget extends StatelessWidget {
  final Widget Function(BuildContext context, AccessibilityManager accessibility) builder;
  
  const AccessibleWidget({
    required this.builder,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final accessibility = AccessibilityManager();
    accessibility.initialize(context);
    
    return builder(context, accessibility);
  }
}

/// امتداد للسياق لتسهيل الوصول إلى مدير إمكانية الوصول
extension AccessibilityExtension on BuildContext {
  AccessibilityManager get accessibility {
    final accessibility = AccessibilityManager();
    accessibility.initialize(this);
    return accessibility;
  }
}
