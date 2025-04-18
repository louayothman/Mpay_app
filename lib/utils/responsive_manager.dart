import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

/// مدير التوافق والتكيف
/// 
/// يوفر هذا الصف آليات لتحسين توافق التطبيق مع مختلف الأجهزة والشاشات
/// ويتضمن وظائف للتكيف مع أحجام الشاشات المختلفة وتوجهاتها
class ResponsiveManager {
  // نمط Singleton
  static final ResponsiveManager _instance = ResponsiveManager._internal();
  
  factory ResponsiveManager() {
    return _instance;
  }
  
  ResponsiveManager._internal();
  
  // معلومات الشاشة
  late MediaQueryData _mediaQueryData;
  late double _screenWidth;
  late double _screenHeight;
  late double _blockSizeHorizontal;
  late double _blockSizeVertical;
  late double _safeAreaHorizontal;
  late double _safeAreaVertical;
  late double _safeBlockHorizontal;
  late double _safeBlockVertical;
  late double _pixelRatio;
  late double _textScaleFactor;
  late Orientation _orientation;
  late Size _screenSize;
  late EdgeInsets _padding;
  late EdgeInsets _viewInsets;
  late EdgeInsets _viewPadding;
  
  // تهيئة مدير التوافق
  void initialize(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    _screenWidth = _mediaQueryData.size.width;
    _screenHeight = _mediaQueryData.size.height;
    _orientation = _mediaQueryData.orientation;
    _pixelRatio = _mediaQueryData.devicePixelRatio;
    _textScaleFactor = _mediaQueryData.textScaler.scale(1.0);
    _blockSizeHorizontal = _screenWidth / 100;
    _blockSizeVertical = _screenHeight / 100;
    _screenSize = _mediaQueryData.size;
    _padding = _mediaQueryData.padding;
    _viewInsets = _mediaQueryData.viewInsets;
    _viewPadding = _mediaQueryData.viewPadding;
    
    _safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    _safeBlockHorizontal = (_screenWidth - _safeAreaHorizontal) / 100;
    _safeBlockVertical = (_screenHeight - _safeAreaVertical) / 100;
  }
  
  // الحصول على عرض الشاشة
  double get screenWidth => _screenWidth;
  
  // الحصول على ارتفاع الشاشة
  double get screenHeight => _screenHeight;
  
  // الحصول على حجم الشاشة
  Size get screenSize => _screenSize;
  
  // الحصول على نسبة البكسل
  double get pixelRatio => _pixelRatio;
  
  // الحصول على عامل مقياس النص
  double get textScaleFactor => _textScaleFactor;
  
  // الحصول على توجيه الشاشة
  Orientation get orientation => _orientation;
  
  // الحصول على حجم الكتلة الأفقية
  double get blockSizeHorizontal => _blockSizeHorizontal;
  
  // الحصول على حجم الكتلة الرأسية
  double get blockSizeVertical => _blockSizeVertical;
  
  // الحصول على حجم الكتلة الأفقية الآمنة
  double get safeBlockHorizontal => _safeBlockHorizontal;
  
  // الحصول على حجم الكتلة الرأسية الآمنة
  double get safeBlockVertical => _safeBlockVertical;
  
  // الحصول على حشوة الشاشة
  EdgeInsets get padding => _padding;
  
  // الحصول على حشوة العرض
  EdgeInsets get viewPadding => _viewPadding;
  
  // الحصول على إدخالات العرض
  EdgeInsets get viewInsets => _viewInsets;
  
  // التحقق مما إذا كان الجهاز هاتفًا
  bool get isPhone => _screenWidth < 600;
  
  // التحقق مما إذا كان الجهاز جهاز لوحي
  bool get isTablet => _screenWidth >= 600 && _screenWidth < 900;
  
  // التحقق مما إذا كان الجهاز سطح مكتب
  bool get isDesktop => _screenWidth >= 900;
  
  // التحقق مما إذا كان الجهاز في وضع أفقي
  bool get isLandscape => _orientation == Orientation.landscape;
  
  // التحقق مما إذا كان الجهاز في وضع عمودي
  bool get isPortrait => _orientation == Orientation.portrait;
  
  // الحصول على حجم مستجيب بناءً على عرض الشاشة
  double responsiveWidth(double percentage) {
    return _screenWidth * (percentage / 100);
  }
  
  // الحصول على حجم مستجيب بناءً على ارتفاع الشاشة
  double responsiveHeight(double percentage) {
    return _screenHeight * (percentage / 100);
  }
  
  // الحصول على حجم خط مستجيب
  double responsiveFontSize(double size) {
    double finalSize = size;
    
    if (isTablet) {
      finalSize = size * 1.2;
    } else if (isDesktop) {
      finalSize = size * 1.5;
    }
    
    // التأكد من أن حجم الخط لا يتجاوز الحد الأقصى
    return finalSize.clamp(size * 0.8, size * 1.8);
  }
  
  // الحصول على حجم أيقونة مستجيب
  double responsiveIconSize(double size) {
    double finalSize = size;
    
    if (isTablet) {
      finalSize = size * 1.2;
    } else if (isDesktop) {
      finalSize = size * 1.5;
    }
    
    return finalSize;
  }
  
  // الحصول على حشوة مستجيبة
  EdgeInsets responsivePadding({
    double horizontal = 0,
    double vertical = 0,
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    double horizontalPadding = horizontal;
    double verticalPadding = vertical;
    double leftPadding = left;
    double topPadding = top;
    double rightPadding = right;
    double bottomPadding = bottom;
    
    if (isTablet) {
      horizontalPadding *= 1.2;
      verticalPadding *= 1.2;
      leftPadding *= 1.2;
      topPadding *= 1.2;
      rightPadding *= 1.2;
      bottomPadding *= 1.2;
    } else if (isDesktop) {
      horizontalPadding *= 1.5;
      verticalPadding *= 1.5;
      leftPadding *= 1.5;
      topPadding *= 1.5;
      rightPadding *= 1.5;
      bottomPadding *= 1.5;
    }
    
    return EdgeInsets.fromLTRB(
      horizontal > 0 ? horizontalPadding : leftPadding,
      vertical > 0 ? verticalPadding : topPadding,
      horizontal > 0 ? horizontalPadding : rightPadding,
      vertical > 0 ? verticalPadding : bottomPadding,
    );
  }
  
  // الحصول على هامش مستجيب
  EdgeInsets responsiveMargin({
    double horizontal = 0,
    double vertical = 0,
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return responsivePadding(
      horizontal: horizontal,
      vertical: vertical,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }
  
  // الحصول على حجم زر مستجيب
  Size responsiveButtonSize(double width, double height) {
    double finalWidth = width;
    double finalHeight = height;
    
    if (isTablet) {
      finalWidth *= 1.2;
      finalHeight *= 1.2;
    } else if (isDesktop) {
      finalWidth *= 1.5;
      finalHeight *= 1.5;
    }
    
    return Size(finalWidth, finalHeight);
  }
  
  // الحصول على نصف قطر حدود مستجيب
  double responsiveBorderRadius(double radius) {
    double finalRadius = radius;
    
    if (isTablet) {
      finalRadius *= 1.2;
    } else if (isDesktop) {
      finalRadius *= 1.5;
    }
    
    return finalRadius;
  }
  
  // الحصول على عرض حدود مستجيب
  double responsiveBorderWidth(double width) {
    double finalWidth = width;
    
    if (isTablet) {
      finalWidth *= 1.2;
    } else if (isDesktop) {
      finalWidth *= 1.5;
    }
    
    return finalWidth;
  }
  
  // الحصول على ارتفاع شريط التطبيق المستجيب
  double responsiveAppBarHeight(double height) {
    double finalHeight = height;
    
    if (isTablet) {
      finalHeight *= 1.2;
    } else if (isDesktop) {
      finalHeight *= 1.3;
    }
    
    return finalHeight;
  }
  
  // الحصول على ارتفاع شريط التنقل السفلي المستجيب
  double responsiveBottomNavBarHeight(double height) {
    double finalHeight = height;
    
    if (isTablet) {
      finalHeight *= 1.2;
    } else if (isDesktop) {
      finalHeight *= 1.3;
    }
    
    return finalHeight;
  }
  
  // الحصول على حجم صورة مستجيب
  Size responsiveImageSize(double width, double height) {
    double finalWidth = width;
    double finalHeight = height;
    
    if (isTablet) {
      finalWidth *= 1.2;
      finalHeight *= 1.2;
    } else if (isDesktop) {
      finalWidth *= 1.5;
      finalHeight *= 1.5;
    }
    
    return Size(finalWidth, finalHeight);
  }
  
  // الحصول على تخطيط مستجيب بناءً على توجيه الشاشة
  Widget responsiveLayout({
    required Widget portrait,
    required Widget landscape,
  }) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.portrait ? portrait : landscape;
      },
    );
  }
  
  // الحصول على تخطيط مستجيب بناءً على نوع الجهاز
  Widget responsiveDeviceLayout({
    required Widget phone,
    Widget? tablet,
    Widget? desktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900 && desktop != null) {
          return desktop;
        } else if (constraints.maxWidth >= 600 && tablet != null) {
          return tablet;
        } else {
          return phone;
        }
      },
    );
  }
  
  // تعيين توجيه الشاشة
  Future<void> setOrientation(List<DeviceOrientation> orientations) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }
  
  // تعيين وضع ملء الشاشة
  Future<void> setFullScreen(bool enable) async {
    if (enable) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
  
  // تعيين لون شريط الحالة
  Future<void> setStatusBarColor(Color color, {Brightness? brightness}) async {
    await SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: brightness,
      ),
    );
  }
  
  // تعيين لون شريط التنقل
  Future<void> setNavigationBarColor(Color color, {Brightness? brightness}) async {
    await SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: color,
        systemNavigationBarIconBrightness: brightness,
      ),
    );
  }
  
  // الحصول على حجم الشاشة الفعلي (بما في ذلك منطقة الشق)
  Future<Size> getActualScreenSize() async {
    final window = WidgetsBinding.instance.platformDispatcher.views.first;
    return window.physicalSize / window.devicePixelRatio;
  }
  
  // الحصول على منطقة العرض الآمنة
  EdgeInsets getSafeArea() {
    return _padding;
  }
  
  // التحقق مما إذا كان الجهاز يحتوي على شق
  bool hasNotch() {
    return _padding.top > 20;
  }
  
  // الحصول على ارتفاع الشق
  double getNotchHeight() {
    return _padding.top;
  }
}

/// عنصر واجهة مستخدم مستجيب
/// 
/// يوفر هذا العنصر واجهة مستخدم مستجيبة تتكيف مع مختلف أحجام الشاشات
class ResponsiveWidget extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveManager responsive) builder;
  
  const ResponsiveWidget({
    required this.builder,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveManager();
    responsive.initialize(context);
    
    return builder(context, responsive);
  }
}

/// امتداد للسياق لتسهيل الوصول إلى مدير التوافق
extension ResponsiveExtension on BuildContext {
  ResponsiveManager get responsive {
    final responsive = ResponsiveManager();
    responsive.initialize(this);
    return responsive;
  }
}
