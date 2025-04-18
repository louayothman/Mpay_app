import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'dart:io';
import 'dart:async';

class DeviceCompatibilityManager {
  // Minimum supported Android SDK version (Android 8.0 Oreo)
  static const int _minimumSupportedAndroidSdk = 26;
  
  // Maximum tested Android SDK version
  static const int _maximumTestedAndroidSdk = 34; // Android 14
  
  // Device info plugin
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  
  // Package info plugin
  PackageInfo? _packageInfo;
  
  // Error handler
  final ErrorHandler _errorHandler = ErrorHandler();
  
  // Device information cache
  AndroidDeviceInfo? _androidInfo;
  String? _deviceInfoString;
  
  // Singleton pattern
  static final DeviceCompatibilityManager _instance = DeviceCompatibilityManager._internal();
  
  factory DeviceCompatibilityManager() {
    return _instance;
  }
  
  DeviceCompatibilityManager._internal();
  
  // Initialize the manager
  Future<void> initialize() async {
    try {
      // Get package info
      _packageInfo = await PackageInfo.fromPlatform();
      
      // Get device info
      if (Platform.isAndroid) {
        _androidInfo = await _deviceInfoPlugin.androidInfo;
      }
      
      // Check compatibility
      checkDeviceCompatibility();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to initialize device compatibility manager',
        ErrorSeverity.high,
      );
    }
  }
  
  // Check device compatibility
  Future<CompatibilityResult> checkDeviceCompatibility() async {
    if (_androidInfo == null) {
      try {
        _androidInfo = await _deviceInfoPlugin.androidInfo;
      } catch (e) {
        _errorHandler.handleError(
          e,
          'Failed to get Android device info',
          ErrorSeverity.medium,
        );
        return CompatibilityResult(
          isCompatible: false,
          warnings: ['Unable to determine device compatibility'],
          sdkVersion: 0,
          deviceModel: 'Unknown',
        );
      }
    }
    
    final List<String> warnings = [];
    bool isCompatible = true;
    
    // Check Android version
    final sdkVersion = _androidInfo!.version.sdkInt;
    
    if (sdkVersion < _minimumSupportedAndroidSdk) {
      isCompatible = false;
      warnings.add('Your Android version (${_androidInfo!.version.release}) is not supported. Minimum required version is Android 8.0 Oreo.');
    } else if (sdkVersion > _maximumTestedAndroidSdk) {
      warnings.add('Your Android version (${_androidInfo!.version.release}) is newer than our maximum tested version. Some features may not work as expected.');
    }
    
    // Check device RAM
    if (_androidInfo!.systemFeatures.contains('android.hardware.ram.low')) {
      warnings.add('Your device has limited RAM. Performance may be affected.');
    }
    
    // Check screen size
    final screenDensity = _androidInfo!.displayMetrics.density;
    if (screenDensity < 1.5) {
      warnings.add('Your device has a low screen density. UI elements may appear too small.');
    }
    
    return CompatibilityResult(
      isCompatible: isCompatible,
      warnings: warnings,
      sdkVersion: sdkVersion,
      deviceModel: '${_androidInfo!.manufacturer} ${_androidInfo!.model}',
    );
  }
  
  // Check API compatibility
  Future<bool> checkApiCompatibility() async {
    try {
      if (_androidInfo == null) {
        _androidInfo = await _deviceInfoPlugin.androidInfo;
      }
      
      // Check TLS version support
      final sdkVersion = _androidInfo!.version.sdkInt;
      
      // Android 5.0+ supports TLS 1.2 by default
      if (sdkVersion < 21) {
        return false;
      }
      
      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to check API compatibility',
        ErrorSeverity.medium,
      );
      return false;
    }
  }
  
  // Apply system UI compatibility settings
  void applySystemUICompatibility() {
    try {
      // Set preferred orientations
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
      
      // Set system UI mode
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to apply system UI compatibility settings',
        ErrorSeverity.low,
      );
    }
  }
  
  // Apply dark mode compatibility
  void applyDarkModeCompatibility(BuildContext context) {
    try {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDarkMode = brightness == Brightness.dark;
      
      if (_androidInfo != null) {
        final sdkVersion = _androidInfo!.version.sdkInt;
        
        // Android 10+ has native dark mode
        if (sdkVersion >= 29) {
          // Use system dark mode
          return;
        }
      }
      
      // For older Android versions, manually set status bar icons
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDarkMode ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ));
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to apply dark mode compatibility',
        ErrorSeverity.low,
      );
    }
  }
  
  // Apply screen size compatibility
  double getScreenScaleFactor(BuildContext context) {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final screenDensity = MediaQuery.of(context).devicePixelRatio;
      
      // Base scale factor on screen width
      if (screenWidth < 320) {
        return 0.8; // Very small screens
      } else if (screenWidth < 360) {
        return 0.9; // Small screens
      } else if (screenWidth > 600) {
        return 1.1; // Tablet screens
      }
      
      return 1.0; // Standard screens
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to calculate screen scale factor',
        ErrorSeverity.low,
      );
      return 1.0;
    }
  }
  
  // Get device info string
  Future<String> getDeviceInfo() async {
    if (_deviceInfoString != null) {
      return _deviceInfoString!;
    }
    
    try {
      if (_androidInfo == null) {
        _androidInfo = await _deviceInfoPlugin.androidInfo;
      }
      
      if (_packageInfo == null) {
        _packageInfo = await PackageInfo.fromPlatform();
      }
      
      final deviceInfo = {
        'manufacturer': _androidInfo!.manufacturer,
        'model': _androidInfo!.model,
        'androidVersion': _androidInfo!.version.release,
        'sdkVersion': _androidInfo!.version.sdkInt,
        'screenWidth': _androidInfo!.displayMetrics.widthPx,
        'screenHeight': _androidInfo!.displayMetrics.heightPx,
        'screenDensity': _androidInfo!.displayMetrics.density,
      };
      
      _deviceInfoString = deviceInfo.toString();
      return _deviceInfoString!;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get device info',
        ErrorSeverity.low,
      );
      return 'Unknown device';
    }
  }
  
  // Get app version
  Future<String> getAppVersion() async {
    if (_packageInfo == null) {
      try {
        _packageInfo = await PackageInfo.fromPlatform();
      } catch (e) {
        _errorHandler.handleError(
          e,
          'Failed to get package info',
          ErrorSeverity.low,
        );
        return 'Unknown version';
      }
    }
    
    return '${_packageInfo!.version}+${_packageInfo!.buildNumber}';
  }
  
  // Check if device supports biometric authentication
  Future<bool> supportsBiometricAuthentication() async {
    try {
      if (_androidInfo == null) {
        _androidInfo = await _deviceInfoPlugin.androidInfo;
      }
      
      final sdkVersion = _androidInfo!.version.sdkInt;
      
      // Fingerprint API was added in Android 6.0 (API 23)
      if (sdkVersion < 23) {
        return false;
      }
      
      // Check if device has fingerprint hardware
      return _androidInfo!.systemFeatures.contains('android.hardware.fingerprint');
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to check biometric support',
        ErrorSeverity.low,
      );
      return false;
    }
  }
  
  // Check if device supports NFC
  Future<bool> supportsNFC() async {
    try {
      if (_androidInfo == null) {
        _androidInfo = await _deviceInfoPlugin.androidInfo;
      }
      
      return _androidInfo!.systemFeatures.contains('android.hardware.nfc');
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to check NFC support',
        ErrorSeverity.low,
      );
      return false;
    }
  }
  
  // Apply text scaling compatibility
  double getTextScaleFactor(BuildContext context) {
    try {
      // Get system text scale factor
      final systemTextScaleFactor = MediaQuery.of(context).textScaleFactor;
      
      // Limit text scaling to reasonable bounds
      if (systemTextScaleFactor > 1.3) {
        return 1.3;
      } else if (systemTextScaleFactor < 0.8) {
        return 0.8;
      }
      
      return systemTextScaleFactor;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to calculate text scale factor',
        ErrorSeverity.low,
      );
      return 1.0;
    }
  }
  
  // Apply RTL compatibility
  TextDirection getTextDirection(BuildContext context) {
    try {
      // Get system text direction
      final textDirection = Directionality.of(context);
      return textDirection;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get text direction',
        ErrorSeverity.low,
      );
      return TextDirection.ltr;
    }
  }
  
  // Get safe area insets
  EdgeInsets getSafeAreaInsets(BuildContext context) {
    try {
      return MediaQuery.of(context).padding;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get safe area insets',
        ErrorSeverity.low,
      );
      return EdgeInsets.zero;
    }
  }
  
  // Check if device is a tablet
  bool isTablet(BuildContext context) {
    try {
      final size = MediaQuery.of(context).size;
      final diagonal = (size.width * size.width + size.height * size.height) * 0.5;
      
      // Diagonal greater than 1100 logical pixels is considered a tablet
      return diagonal > 1100;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to determine if device is a tablet',
        ErrorSeverity.low,
      );
      return false;
    }
  }
  
  // Apply keyboard compatibility
  void applyKeyboardCompatibility(BuildContext context) {
    try {
      // Check if keyboard is visible
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      final isKeyboardVisible = bottomInset > 0;
      
      if (isKeyboardVisible) {
        // Hide status bar when keyboard is visible on older devices
        if (_androidInfo != null && _androidInfo!.version.sdkInt < 30) {
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [SystemUiOverlay.bottom],
          );
        }
      } else {
        // Restore system UI when keyboard is hidden
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to apply keyboard compatibility',
        ErrorSeverity.low,
      );
    }
  }
  
  // Apply font compatibility
  String getFontFamily() {
    try {
      if (_androidInfo == null) {
        return 'Roboto';
      }
      
      final sdkVersion = _androidInfo!.version.sdkInt;
      
      // Use system font for Android 8.0+
      if (sdkVersion >= 26) {
        return '.SF UI Text';
      }
      
      return 'Roboto';
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get font family',
        ErrorSeverity.low,
      );
      return 'Roboto';
    }
  }
  
  // Get Android SDK version
  int getAndroidSdkVersion() {
    if (_androidInfo == null) {
      return 0;
    }
    
    return _androidInfo!.version.sdkInt;
  }
  
  // Get Android version name
  String getAndroidVersionName() {
    if (_androidInfo == null) {
      return 'Unknown';
    }
    
    return _androidInfo!.version.release;
  }
  
  // Get device model
  String getDeviceModel() {
    if (_androidInfo == null) {
      return 'Unknown';
    }
    
    return '${_androidInfo!.manufacturer} ${_androidInfo!.model}';
  }
  
  // Check if running on an emulator
  bool isEmulator() {
    if (_androidInfo == null) {
      return false;
    }
    
    return _androidInfo!.isPhysicalDevice == false;
  }
}

// Compatibility result class
class CompatibilityResult {
  final bool isCompatible;
  final List<String> warnings;
  final int sdkVersion;
  final String deviceModel;
  
  CompatibilityResult({
    required this.isCompatible,
    required this.warnings,
    required this.sdkVersion,
    required this.deviceModel,
  });
}
