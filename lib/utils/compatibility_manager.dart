import 'package:flutter/material.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:mpay_app/utils/logger.dart';

/// مدير التوافق
///
/// يوفر أدوات للتحقق من توافق الأجهزة وتكييف واجهة المستخدم لمختلف أحجام الشاشات
class CompatibilityManager {
  // نمط Singleton
  static final CompatibilityManager _instance = CompatibilityManager._internal();
  
  factory CompatibilityManager() {
    return _instance;
  }
  
  CompatibilityManager._internal();
  
  // معلومات الجهاز
  AndroidDeviceInfo? _androidInfo;
  IosDeviceInfo? _iosInfo;
  
  // معلومات الشاشة
  Size? _screenSize;
  double? _pixelRatio;
  
  // متطلبات النظام الدنيا
  static const int _minAndroidSdk = 21; // Android 5.0 Lollipop
  static const String _minIosVersion = "12.0";
  static const double _minRamGb = 2.0;
  
  // تهيئة مدير التوافق
  Future<void> initialize(BuildContext context) async {
    try {
      // الحصول على معلومات الجهاز
      await _getDeviceInfo();
      
      // الحصول على معلومات الشاشة
      _getScreenInfo(context);
      
      // تسجيل معلومات الجهاز
      _logDeviceInfo();
      
      Logger.info('تم تهيئة مدير التوافق بنجاح');
    } catch (e) {
      Logger.error('فشل في تهيئة مدير التوافق', error: e);
    }
  }
  
  // الحصول على معلومات الجهاز
  Future<void> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        _androidInfo = await deviceInfo.androidInfo;
      } else if (Platform.isIOS) {
        _iosInfo = await deviceInfo.iosInfo;
      }
    } catch (e) {
      Logger.error('فشل في الحصول على معلومات الجهاز', error: e);
    }
  }
  
  // الحصول على معلومات الشاشة
  void _getScreenInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenSize = mediaQuery.size;
    _pixelRatio = mediaQuery.devicePixelRatio;
  }
  
  // تسجيل معلومات الجهاز
  void _logDeviceInfo() {
    if (_androidInfo != null) {
      Logger.info('معلومات جهاز Android:');
      Logger.info('  الطراز: ${_androidInfo!.model}');
      Logger.info('  المصنع: ${_androidInfo!.manufacturer}');
      Logger.info('  إصدار Android: ${_androidInfo!.version.release} (SDK ${_androidInfo!.version.sdkInt})');
      Logger.info('  عدد النوى: ${_androidInfo!.supportedAbis.length}');
    } else if (_iosInfo != null) {
      Logger.info('معلومات جهاز iOS:');
      Logger.info('  الطراز: ${_iosInfo!.model}');
      Logger.info('  إصدار iOS: ${_iosInfo!.systemVersion}');
      Logger.info('  المعرف: ${_iosInfo!.identifierForVendor}');
    }
    
    if (_screenSize != null && _pixelRatio != null) {
      Logger.info('معلومات الشاشة:');
      Logger.info('  الأبعاد: ${_screenSize!.width.toStringAsFixed(1)} × ${_screenSize!.height.toStringAsFixed(1)}');
      Logger.info('  نسبة البكسل: ${_pixelRatio!.toStringAsFixed(2)}');
      Logger.info('  الأبعاد الفعلية: ${(_screenSize!.width * _pixelRatio!).toStringAsFixed(1)} × ${(_screenSize!.height * _pixelRatio!).toStringAsFixed(1)}');
    }
  }
  
  // التحقق من توافق الجهاز
  Future<DeviceCompatibilityResult> checkDeviceCompatibility() async {
    if (_androidInfo == null && _iosInfo == null) {
      await _getDeviceInfo();
    }
    
    final result = DeviceCompatibilityResult();
    
    // التحقق من إصدار نظام التشغيل
    if (_androidInfo != null) {
      result.isOsVersionCompatible = _androidInfo!.version.sdkInt >= _minAndroidSdk;
      result.osVersion = '${_androidInfo!.version.release} (SDK ${_androidInfo!.version.sdkInt})';
      
      // تقدير ذاكرة الوصول العشوائي (RAM) - قد لا يكون دقيقًا على جميع الأجهزة
      try {
        final activityManager = await const MethodChannel('com.mpay/device_info')
            .invokeMethod('getMemoryInfo');
        
        if (activityManager != null && activityManager.containsKey('totalMem')) {
          final totalRamBytes = activityManager['totalMem'] as int;
          final totalRamGb = totalRamBytes / (1024 * 1024 * 1024);
          result.ramGb = totalRamGb;
          result.isRamSufficient = totalRamGb >= _minRamGb;
        }
      } catch (e) {
        Logger.warning('فشل في الحصول على معلومات الذاكرة', error: e);
        // افتراض أن الذاكرة كافية إذا فشل الاستعلام
        result.isRamSufficient = true;
      }
    } else if (_iosInfo != null) {
      // تحليل إصدار iOS
      try {
        final currentVersion = _iosInfo!.systemVersion;
        final minVersionParts = _minIosVersion.split('.').map(int.parse).toList();
        final currentVersionParts = currentVersion.split('.').map(int.parse).toList();
        
        bool isCompatible = true;
        for (int i = 0; i < minVersionParts.length; i++) {
          if (i >= currentVersionParts.length) {
            break;
          }
          
          if (currentVersionParts[i] < minVersionParts[i]) {
            isCompatible = false;
            break;
          } else if (currentVersionParts[i] > minVersionParts[i]) {
            break;
          }
        }
        
        result.isOsVersionCompatible = isCompatible;
        result.osVersion = currentVersion;
        
        // افتراض أن أجهزة iOS الحديثة لديها ذاكرة كافية
        result.isRamSufficient = true;
      } catch (e) {
        Logger.warning('فشل في تحليل إصدار iOS', error: e);
        // افتراض أن الإصدار متوافق إذا فشل التحليل
        result.isOsVersionCompatible = true;
        result.isRamSufficient = true;
      }
    } else {
      // إذا لم نتمكن من تحديد نوع الجهاز، نفترض أنه متوافق
      result.isOsVersionCompatible = true;
      result.isRamSufficient = true;
    }
    
    // التحقق من توفر خدمات Google Play (لأجهزة Android فقط)
    if (_androidInfo != null) {
      try {
        final isGooglePlayAvailable = await const MethodChannel('com.mpay/device_info')
            .invokeMethod('isGooglePlayServicesAvailable');
        
        result.isGooglePlayAvailable = isGooglePlayAvailable ?? false;
      } catch (e) {
        Logger.warning('فشل في التحقق من توفر خدمات Google Play', error: e);
        // افتراض أن خدمات Google Play متوفرة إذا فشل الاستعلام
        result.isGooglePlayAvailable = true;
      }
    } else {
      // أجهزة iOS لا تحتاج إلى خدمات Google Play
      result.isGooglePlayAvailable = true;
    }
    
    // التحقق من توفر الكاميرا
    try {
      final cameras = await availableCameras();
      result.isCameraAvailable = cameras.isNotEmpty;
    } catch (e) {
      Logger.warning('فشل في التحقق من توفر الكاميرا', error: e);
      // افتراض أن الكاميرا متوفرة إذا فشل الاستعلام
      result.isCameraAvailable = true;
    }
    
    // التحقق من توفر اتصال الإنترنت
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      result.isInternetAvailable = connectivityResult != ConnectivityResult.none;
    } catch (e) {
      Logger.warning('فشل في التحقق من توفر اتصال الإنترنت', error: e);
      // افتراض أن اتصال الإنترنت متوفر إذا فشل الاستعلام
      result.isInternetAvailable = true;
    }
    
    // تحديد النتيجة الإجمالية
    result.isCompatible = result.isOsVersionCompatible && 
                          result.isRamSufficient && 
                          result.isGooglePlayAvailable && 
                          result.isCameraAvailable;
    
    return result;
  }
  
  // الحصول على نوع الجهاز
  DeviceType getDeviceType() {
    if (_screenSize == null) {
      return DeviceType.unknown;
    }
    
    final shortestSide = _screenSize!.shortestSide;
    
    // تصنيف الجهاز بناءً على أبعاد الشاشة
    if (shortestSide < 600) {
      return DeviceType.phone;
    } else if (shortestSide < 900) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  // الحصول على حجم الشاشة
  ScreenSize getScreenSize() {
    if (_screenSize == null) {
      return ScreenSize.medium;
    }
    
    final width = _screenSize!.width;
    
    // تصنيف حجم الشاشة بناءً على العرض
    if (width < 360) {
      return ScreenSize.small;
    } else if (width < 600) {
      return ScreenSize.medium;
    } else if (width < 900) {
      return ScreenSize.large;
    } else {
      return ScreenSize.extraLarge;
    }
  }
  
  // الحصول على كثافة الشاشة
  ScreenDensity getScreenDensity() {
    if (_pixelRatio == null) {
      return ScreenDensity.medium;
    }
    
    // تصنيف كثافة الشاشة بناءً على نسبة البكسل
    if (_pixelRatio! < 1.5) {
      return ScreenDensity.low;
    } else if (_pixelRatio! < 2.5) {
      return ScreenDensity.medium;
    } else if (_pixelRatio! < 3.5) {
      return ScreenDensity.high;
    } else {
      return ScreenDensity.extraHigh;
    }
  }
  
  // الحصول على اتجاه الشاشة
  ScreenOrientation getScreenOrientation(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.portrait
        ? ScreenOrientation.portrait
        : ScreenOrientation.landscape;
  }
  
  // الحصول على حجم الخط المناسب بناءً على حجم الشاشة
  double getAdaptiveFontSize(double baseFontSize) {
    final screenSize = getScreenSize();
    
    switch (screenSize) {
      case ScreenSize.small:
        return baseFontSize * 0.8;
      case ScreenSize.medium:
        return baseFontSize;
      case ScreenSize.large:
        return baseFontSize * 1.2;
      case ScreenSize.extraLarge:
        return baseFontSize * 1.4;
    }
  }
  
  // الحصول على حجم الأيقونة المناسب بناءً على حجم الشاشة
  double getAdaptiveIconSize(double baseIconSize) {
    final screenSize = getScreenSize();
    
    switch (screenSize) {
      case ScreenSize.small:
        return baseIconSize * 0.8;
      case ScreenSize.medium:
        return baseIconSize;
      case ScreenSize.large:
        return baseIconSize * 1.2;
      case ScreenSize.extraLarge:
        return baseIconSize * 1.4;
    }
  }
  
  // الحصول على التباعد المناسب بناءً على حجم الشاشة
  double getAdaptiveSpacing(double baseSpacing) {
    final screenSize = getScreenSize();
    
    switch (screenSize) {
      case ScreenSize.small:
        return baseSpacing * 0.8;
      case ScreenSize.medium:
        return baseSpacing;
      case ScreenSize.large:
        return baseSpacing * 1.2;
      case ScreenSize.extraLarge:
        return baseSpacing * 1.5;
    }
  }
  
  // الحصول على عدد الأعمدة المناسب للشبكة بناءً على حجم الشاشة
  int getAdaptiveGridColumns() {
    final deviceType = getDeviceType();
    final orientation = _screenSize != null
        ? (_screenSize!.width > _screenSize!.height
            ? ScreenOrientation.landscape
            : ScreenOrientation.portrait)
        : ScreenOrientation.portrait;
    
    switch (deviceType) {
      case DeviceType.phone:
        return orientation == ScreenOrientation.portrait ? 2 : 3;
      case DeviceType.tablet:
        return orientation == ScreenOrientation.portrait ? 3 : 4;
      case DeviceType.desktop:
        return orientation == ScreenOrientation.portrait ? 4 : 6;
      case DeviceType.unknown:
        return 2;
    }
  }
  
  // التحقق من دعم الميزات المتقدمة
  Future<FeatureSupportResult> checkFeatureSupport() async {
    final result = FeatureSupportResult();
    
    // التحقق من دعم المصادقة البيومترية
    try {
      final localAuth = LocalAuthentication();
      result.isBiometricSupported = await localAuth.canCheckBiometrics;
      
      if (result.isBiometricSupported) {
        final availableBiometrics = await localAuth.getAvailableBiometrics();
        result.supportsFaceId = availableBiometrics.contains(BiometricType.face);
        result.supportsFingerprintAuth = availableBiometrics.contains(BiometricType.fingerprint);
      }
    } catch (e) {
      Logger.warning('فشل في التحقق من دعم المصادقة البيومترية', error: e);
    }
    
    // التحقق من دعم NFC
    try {
      final isNfcAvailable = await const MethodChannel('com.mpay/device_info')
          .invokeMethod('isNfcAvailable');
      
      result.isNfcSupported = isNfcAvailable ?? false;
    } catch (e) {
      Logger.warning('فشل في التحقق من دعم NFC', error: e);
    }
    
    // التحقق من دعم الإشعارات
    try {
      final notificationSettings = await FirebaseMessaging.instance.getNotificationSettings();
      result.areNotificationsEnabled = notificationSettings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      Logger.warning('فشل في التحقق من دعم الإشعارات', error: e);
    }
    
    return result;
  }
  
  // عرض رسالة عدم التوافق
  Future<void> showCompatibilityWarning(
    BuildContext context,
    DeviceCompatibilityResult compatibilityResult,
  ) async {
    final messages = <String>[];
    
    if (!compatibilityResult.isOsVersionCompatible) {
      messages.add('إصدار نظام التشغيل غير متوافق. الإصدار الحالي: ${compatibilityResult.osVersion}');
    }
    
    if (!compatibilityResult.isRamSufficient) {
      messages.add('ذاكرة الجهاز غير كافية. الذاكرة المتوفرة: ${compatibilityResult.ramGb?.toStringAsFixed(1)} GB');
    }
    
    if (!compatibilityResult.isGooglePlayAvailable && Platform.isAndroid) {
      messages.add('خدمات Google Play غير متوفرة على هذا الجهاز.');
    }
    
    if (!compatibilityResult.isCameraAvailable) {
      messages.add('الكاميرا غير متوفرة أو لا يمكن الوصول إليها.');
    }
    
    if (!compatibilityResult.isInternetAvailable) {
      messages.add('اتصال الإنترنت غير متوفر.');
    }
    
    if (messages.isNotEmpty) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('تحذير التوافق'),
          content: SingleChildScrollView(
            child: ListBody(
              children: messages.map((message) => Text(message)).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('فهمت'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }
  
  // تطبيق تكييف واجهة المستخدم
  Widget adaptiveBuilder({
    required BuildContext context,
    required Widget Function(BuildContext, DeviceType, ScreenSize, ScreenOrientation) builder,
  }) {
    final deviceType = getDeviceType();
    final screenSize = getScreenSize();
    final orientation = getScreenOrientation(context);
    
    return OrientationBuilder(
      builder: (context, _) {
        return builder(context, deviceType, screenSize, orientation);
      },
    );
  }
  
  // الحصول على الكاميرات المتوفرة
  Future<List<CameraDescription>> availableCameras() async {
    try {
      return await camera.availableCameras();
    } catch (e) {
      Logger.error('فشل في الحصول على الكاميرات المتوفرة', error: e);
      return [];
    }
  }
}

/// نتيجة التحقق من توافق الجهاز
class DeviceCompatibilityResult {
  bool isCompatible = false;
  bool isOsVersionCompatible = false;
  bool isRamSufficient = false;
  bool isGooglePlayAvailable = false;
  bool isCameraAvailable = false;
  bool isInternetAvailable = false;
  String? osVersion;
  double? ramGb;
  
  @override
  String toString() {
    return 'DeviceCompatibilityResult{'
        'isCompatible: $isCompatible, '
        'isOsVersionCompatible: $isOsVersionCompatible, '
        'isRamSufficient: $isRamSufficient, '
        'isGooglePlayAvailable: $isGooglePlayAvailable, '
        'isCameraAvailable: $isCameraAvailable, '
        'isInternetAvailable: $isInternetAvailable, '
        'osVersion: $osVersion, '
        'ramGb: $ramGb'
        '}';
  }
}

/// نتيجة التحقق من دعم الميزات
class FeatureSupportResult {
  bool isBiometricSupported = false;
  bool supportsFaceId = false;
  bool supportsFingerprintAuth = false;
  bool isNfcSupported = false;
  bool areNotificationsEnabled = false;
  
  @override
  String toString() {
    return 'FeatureSupportResult{'
        'isBiometricSupported: $isBiometricSupported, '
        'supportsFaceId: $supportsFaceId, '
        'supportsFingerprintAuth: $supportsFingerprintAuth, '
        'isNfcSupported: $isNfcSupported, '
        'areNotificationsEnabled: $areNotificationsEnabled'
        '}';
  }
}

/// نوع الجهاز
enum DeviceType {
  phone,
  tablet,
  desktop,
  unknown,
}

/// حجم الشاشة
enum ScreenSize {
  small,
  medium,
  large,
  extraLarge,
}

/// كثافة الشاشة
enum ScreenDensity {
  low,
  medium,
  high,
  extraHigh,
}

/// اتجاه الشاشة
enum ScreenOrientation {
  portrait,
  landscape,
}

// استيراد المكتبات المطلوبة
import 'package:camera/camera.dart' as camera;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
