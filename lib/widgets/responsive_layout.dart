import 'package:flutter/material.dart';

/// صف التخطيط المتجاوب
///
/// يوفر تخطيطًا متجاوبًا يتكيف مع أحجام الشاشات المختلفة
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;
  
  // حدود أحجام الشاشات
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  
  const ResponsiveLayout({
    Key? key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // تخطيط سطح المكتب
        if (width >= tabletBreakpoint && desktopLayout != null) {
          return desktopLayout!;
        }
        
        // تخطيط الجهاز اللوحي
        if (width >= mobileBreakpoint && tabletLayout != null) {
          return tabletLayout!;
        }
        
        // تخطيط الهاتف المحمول (الافتراضي)
        return mobileLayout;
      },
    );
  }
  
  /// التحقق مما إذا كان الجهاز هاتفًا محمولًا
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  /// التحقق مما إذا كان الجهاز جهازًا لوحيًا
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
  
  /// التحقق مما إذا كان الجهاز سطح مكتب
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  /// الحصول على عدد الأعمدة المناسب بناءً على حجم الشاشة
  static int getColumnCount(BuildContext context) {
    if (isDesktop(context)) {
      return 3;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 1;
    }
  }
  
  /// الحصول على حجم الخط المناسب بناءً على حجم الشاشة
  static double getFontSize(BuildContext context, double baseFontSize) {
    if (isDesktop(context)) {
      return baseFontSize * 1.2;
    } else if (isTablet(context)) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize;
    }
  }
  
  /// الحصول على التباعد المناسب بناءً على حجم الشاشة
  static double getSpacing(BuildContext context, double baseSpacing) {
    if (isDesktop(context)) {
      return baseSpacing * 1.5;
    } else if (isTablet(context)) {
      return baseSpacing * 1.25;
    } else {
      return baseSpacing;
    }
  }
  
  /// إنشاء شبكة متجاوبة
  static Widget responsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    double spacing = 16,
    EdgeInsetsGeometry? padding,
  }) {
    final columnCount = getColumnCount(context);
    
    return Padding(
      padding: padding ?? EdgeInsets.all(getSpacing(context, 16)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          crossAxisSpacing: getSpacing(context, spacing),
          mainAxisSpacing: getSpacing(context, spacing),
          childAspectRatio: 1.5,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) {
          return children[index];
        },
      ),
    );
  }
}
