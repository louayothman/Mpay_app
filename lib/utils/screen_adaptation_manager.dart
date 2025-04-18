import 'package:flutter/material.dart';
import 'package:mpay_app/utils/device_compatibility_manager.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

class ScreenAdaptationManager {
  // Device compatibility manager
  final DeviceCompatibilityManager _deviceCompatibilityManager = DeviceCompatibilityManager();
  
  // Error handler
  final ErrorHandler _errorHandler = ErrorHandler();
  
  // Screen size constants
  static const double _designScreenWidth = 375.0; // Design reference width (iPhone X)
  static const double _designScreenHeight = 812.0; // Design reference height (iPhone X)
  
  // Screen metrics cache
  double? _screenWidth;
  double? _screenHeight;
  double? _screenRatio;
  double? _textScaleFactor;
  
  // Singleton pattern
  static final ScreenAdaptationManager _instance = ScreenAdaptationManager._internal();
  
  factory ScreenAdaptationManager() {
    return _instance;
  }
  
  ScreenAdaptationManager._internal();
  
  // Initialize the manager
  void initialize(BuildContext context) {
    try {
      final mediaQuery = MediaQuery.of(context);
      
      _screenWidth = mediaQuery.size.width;
      _screenHeight = mediaQuery.size.height;
      _screenRatio = _screenWidth! / _designScreenWidth;
      _textScaleFactor = _deviceCompatibilityManager.getTextScaleFactor(context);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to initialize screen adaptation manager',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Adapt width based on design width
  double adaptWidth(double width, BuildContext context) {
    if (_screenWidth == null || _screenRatio == null) {
      initialize(context);
    }
    
    return width * (_screenRatio ?? 1.0);
  }
  
  // Adapt height based on design height
  double adaptHeight(double height, BuildContext context) {
    if (_screenHeight == null) {
      initialize(context);
    }
    
    final heightRatio = (_screenHeight ?? _designScreenHeight) / _designScreenHeight;
    return height * heightRatio;
  }
  
  // Adapt font size
  double adaptFontSize(double fontSize, BuildContext context) {
    if (_screenRatio == null || _textScaleFactor == null) {
      initialize(context);
    }
    
    // Apply both screen ratio and text scale factor
    return fontSize * (_screenRatio ?? 1.0) * (_textScaleFactor ?? 1.0);
  }
  
  // Adapt radius
  double adaptRadius(double radius, BuildContext context) {
    if (_screenRatio == null) {
      initialize(context);
    }
    
    return radius * (_screenRatio ?? 1.0);
  }
  
  // Adapt spacing
  double adaptSpacing(double spacing, BuildContext context) {
    if (_screenRatio == null) {
      initialize(context);
    }
    
    return spacing * (_screenRatio ?? 1.0);
  }
  
  // Get safe area padding
  EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  // Get screen width
  double getScreenWidth(BuildContext context) {
    if (_screenWidth == null) {
      initialize(context);
    }
    
    return _screenWidth ?? MediaQuery.of(context).size.width;
  }
  
  // Get screen height
  double getScreenHeight(BuildContext context) {
    if (_screenHeight == null) {
      initialize(context);
    }
    
    return _screenHeight ?? MediaQuery.of(context).size.height;
  }
  
  // Get screen aspect ratio
  double getScreenAspectRatio(BuildContext context) {
    if (_screenWidth == null || _screenHeight == null) {
      initialize(context);
    }
    
    return (_screenWidth ?? 1.0) / (_screenHeight ?? 1.0);
  }
  
  // Check if device is in landscape orientation
  bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  // Check if device has notch
  bool hasNotch(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.top > 20; // Approximate check for notch
  }
  
  // Get keyboard height
  double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }
  
  // Check if keyboard is visible
  bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }
  
  // Get status bar height
  double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
  
  // Get bottom navigation bar height
  double getBottomNavigationBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  
  // Get available screen height (excluding system UI)
  double getAvailableScreenHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - 
           mediaQuery.padding.top - 
           mediaQuery.padding.bottom - 
           mediaQuery.viewInsets.bottom;
  }
  
  // Get screen size category
  ScreenSizeCategory getScreenSizeCategory(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (width < 360) {
      return ScreenSizeCategory.small;
    } else if (width < 400) {
      return ScreenSizeCategory.medium;
    } else if (width < 600) {
      return ScreenSizeCategory.large;
    } else {
      return ScreenSizeCategory.extraLarge;
    }
  }
  
  // Get responsive value based on screen size
  T getResponsiveValue<T>({
    required BuildContext context,
    required T small,
    T? medium,
    T? large,
    T? extraLarge,
  }) {
    final category = getScreenSizeCategory(context);
    
    switch (category) {
      case ScreenSizeCategory.small:
        return small;
      case ScreenSizeCategory.medium:
        return medium ?? small;
      case ScreenSizeCategory.large:
        return large ?? medium ?? small;
      case ScreenSizeCategory.extraLarge:
        return extraLarge ?? large ?? medium ?? small;
    }
  }
  
  // Adapt padding
  EdgeInsets adaptPadding(EdgeInsets padding, BuildContext context) {
    if (_screenRatio == null) {
      initialize(context);
    }
    
    final ratio = _screenRatio ?? 1.0;
    
    return EdgeInsets.only(
      left: padding.left * ratio,
      top: padding.top * ratio,
      right: padding.right * ratio,
      bottom: padding.bottom * ratio,
    );
  }
  
  // Adapt margin
  EdgeInsets adaptMargin(EdgeInsets margin, BuildContext context) {
    if (_screenRatio == null) {
      initialize(context);
    }
    
    final ratio = _screenRatio ?? 1.0;
    
    return EdgeInsets.only(
      left: margin.left * ratio,
      top: margin.top * ratio,
      right: margin.right * ratio,
      bottom: margin.bottom * ratio,
    );
  }
  
  // Get responsive grid count
  int getResponsiveGridCount(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (width < 360) {
      return 2; // Small screens
    } else if (width < 600) {
      return 3; // Phone screens
    } else if (width < 900) {
      return 4; // Small tablet screens
    } else {
      return 6; // Large tablet screens
    }
  }
  
  // Get responsive list item height
  double getResponsiveListItemHeight(BuildContext context) {
    final category = getScreenSizeCategory(context);
    
    switch (category) {
      case ScreenSizeCategory.small:
        return 60.0;
      case ScreenSizeCategory.medium:
        return 70.0;
      case ScreenSizeCategory.large:
        return 80.0;
      case ScreenSizeCategory.extraLarge:
        return 90.0;
    }
  }
  
  // Get responsive icon size
  double getResponsiveIconSize(BuildContext context) {
    final category = getScreenSizeCategory(context);
    
    switch (category) {
      case ScreenSizeCategory.small:
        return 20.0;
      case ScreenSizeCategory.medium:
        return 24.0;
      case ScreenSizeCategory.large:
        return 28.0;
      case ScreenSizeCategory.extraLarge:
        return 32.0;
    }
  }
  
  // Get responsive button height
  double getResponsiveButtonHeight(BuildContext context) {
    final category = getScreenSizeCategory(context);
    
    switch (category) {
      case ScreenSizeCategory.small:
        return 40.0;
      case ScreenSizeCategory.medium:
        return 48.0;
      case ScreenSizeCategory.large:
        return 52.0;
      case ScreenSizeCategory.extraLarge:
        return 56.0;
    }
  }
  
  // Get responsive text style
  TextStyle getResponsiveTextStyle({
    required BuildContext context,
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    String? fontFamily,
  }) {
    final adaptedFontSize = adaptFontSize(fontSize, context);
    
    return TextStyle(
      fontSize: adaptedFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
      fontFamily: fontFamily ?? _deviceCompatibilityManager.getFontFamily(),
    );
  }
  
  // Apply screen adaptation to widget
  Widget adaptiveWidget({
    required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      width: width != null ? adaptWidth(width, context) : null,
      height: height != null ? adaptHeight(height, context) : null,
      padding: padding != null ? adaptPadding(padding, context) : null,
      margin: margin != null ? adaptMargin(margin, context) : null,
      child: child,
    );
  }
  
  // Get device pixel ratio
  double getDevicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }
  
  // Convert logical pixels to physical pixels
  double logicalToPhysical(double logicalPixels, BuildContext context) {
    return logicalPixels * getDevicePixelRatio(context);
  }
  
  // Convert physical pixels to logical pixels
  double physicalToLogical(double physicalPixels, BuildContext context) {
    return physicalPixels / getDevicePixelRatio(context);
  }
  
  // Get responsive font size multiplier
  double getResponsiveFontSizeMultiplier(BuildContext context) {
    final category = getScreenSizeCategory(context);
    
    switch (category) {
      case ScreenSizeCategory.small:
        return 0.85;
      case ScreenSizeCategory.medium:
        return 1.0;
      case ScreenSizeCategory.large:
        return 1.1;
      case ScreenSizeCategory.extraLarge:
        return 1.2;
    }
  }
  
  // Apply text direction based on locale
  TextDirection getTextDirection(BuildContext context) {
    return _deviceCompatibilityManager.getTextDirection(context);
  }
  
  // Get responsive container width
  double getResponsiveContainerWidth(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (width > 900) {
      return 800; // Limit width on large screens
    } else if (width > 600) {
      return width * 0.9; // 90% of screen width on medium screens
    } else {
      return width * 0.95; // 95% of screen width on small screens
    }
  }
  
  // Get responsive spacing
  double getResponsiveSpacing(BuildContext context) {
    final category = getScreenSizeCategory(context);
    
    switch (category) {
      case ScreenSizeCategory.small:
        return 8.0;
      case ScreenSizeCategory.medium:
        return 12.0;
      case ScreenSizeCategory.large:
        return 16.0;
      case ScreenSizeCategory.extraLarge:
        return 20.0;
    }
  }
  
  // Get responsive border radius
  double getResponsiveBorderRadius(BuildContext context) {
    final category = getScreenSizeCategory(context);
    
    switch (category) {
      case ScreenSizeCategory.small:
        return 8.0;
      case ScreenSizeCategory.medium:
        return 12.0;
      case ScreenSizeCategory.large:
        return 16.0;
      case ScreenSizeCategory.extraLarge:
        return 20.0;
    }
  }
  
  // Get responsive elevation
  double getResponsiveElevation(BuildContext context) {
    final category = getScreenSizeCategory(context);
    
    switch (category) {
      case ScreenSizeCategory.small:
        return 2.0;
      case ScreenSizeCategory.medium:
        return 4.0;
      case ScreenSizeCategory.large:
        return 6.0;
      case ScreenSizeCategory.extraLarge:
        return 8.0;
    }
  }
}

// Screen size category enum
enum ScreenSizeCategory {
  small,    // < 360dp
  medium,   // 360dp - 399dp
  large,    // 400dp - 599dp
  extraLarge, // >= 600dp
}
