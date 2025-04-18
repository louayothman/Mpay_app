import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpay_integrated/theme/enhanced_theme.dart';
import 'package:mpay_integrated/widgets/animated_buttons.dart';
import 'package:mpay_integrated/widgets/interactive_containers.dart';
import 'package:mpay_integrated/widgets/motion_effects.dart';
import 'package:mpay_integrated/widgets/animated_transitions.dart';
import 'package:mpay_integrated/widgets/modern_containers.dart';

class PerformanceOptimizer {
  // تحسين أداء التطبيق من خلال تقليل عمليات إعادة البناء غير الضرورية
  static bool shouldRebuild(Widget oldWidget, Widget newWidget) {
    // تنفيذ منطق مخصص لتحديد ما إذا كان يجب إعادة بناء الواجهة
    return true; // افتراضياً، نعيد البناء دائماً
  }

  // تحسين استخدام الذاكرة
  static void disposeResources(BuildContext context) {
    // تحرير الموارد غير المستخدمة
  }

  // تحسين أداء القوائم
  static Widget buildOptimizedList({
    required BuildContext context,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    Axis scrollDirection = Axis.vertical,
  }) {
    // استخدام ListView.builder للقوائم الطويلة
    if (itemCount > 20) {
      return ListView.builder(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        scrollDirection: scrollDirection,
      );
    }
    
    // استخدام ListView العادي للقوائم القصيرة
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      scrollDirection: scrollDirection,
      children: List.generate(
        itemCount,
        (index) => itemBuilder(context, index),
      ),
    );
  }

  // تحسين أداء الصور باستخدام cached_network_image
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // استخدام cached_network_image لتحسين الأداء وتقليل استهلاك البيانات
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => errorWidget ?? Icon(Icons.error),
      // إعدادات إضافية لتحسين الأداء
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: (width != null && width > 0) ? (width * 2).toInt() : null,
      maxHeightDiskCache: (height != null && height > 0) ? (height * 2).toInt() : null,
    );
  }

  // تحسين أداء الرسوم المتحركة
  static bool shouldAnimateBasedOnDevicePerformance(BuildContext context) {
    // تحديد ما إذا كان يجب تشغيل الرسوم المتحركة بناءً على أداء الجهاز
    // يمكن تنفيذ منطق لاكتشاف قدرات الجهاز
    return true; // افتراضياً، نشغل الرسوم المتحركة
  }

  // تحسين أداء التحميل المتأخر
  static Widget lazyLoadWidget({
    required BuildContext context,
    required WidgetBuilder builder,
    Widget? placeholder,
    bool shouldLoad = true,
  }) {
    if (!shouldLoad) {
      return placeholder ?? Container();
    }
    
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: 100), () => true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder(context);
        }
        return placeholder ?? Container();
      },
    );
  }

  // تحسين استخدام الموارد
  static void optimizeResources() {
    // تنفيذ منطق لتحسين استخدام الموارد
  }

  // تحسين أداء الانتقالات
  static PageRoute optimizedPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute(
      builder: builder,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }
}

class EnhancedApp extends StatelessWidget {
  final Widget child;
  final bool enablePerformanceOptimizations;

  const EnhancedApp({
    Key? key,
    required this.child,
    this.enablePerformanceOptimizations = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (enablePerformanceOptimizations) {
      PerformanceOptimizer.optimizeResources();
    }

    return MaterialApp(
      title: 'Mpay Enhanced',
      theme: EnhancedTheme.createTheme(),
      debugShowCheckedModeBanner: false,
      home: child,
    );
  }
}

class EnhancedScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool enableBackgroundEffects;

  const EnhancedScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.bottomNavigationBar,
    this.enableBackgroundEffects = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    // إضافة تأثيرات الخلفية إذا كانت مفعلة
    if (enableBackgroundEffects) {
      content = Stack(
        children: [
          AnimatedBackground(
            color1: EnhancedTheme.primaryColor.withOpacity(0.05),
            color2: EnhancedTheme.accentColor.withOpacity(0.05),
            color3: EnhancedTheme.primaryColorLight.withOpacity(0.05),
            enableParticles: true,
            particleCount: 10,
            child: Container(),
          ),
          body,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: actions,
        elevation: 0,
      ),
      body: content,
      floatingActionButton: floatingActionButton != null
          ? FloatingEffect(
              floatHeight: 5,
              duration: Duration(seconds: 2),
              child: floatingActionButton!,
            )
          : null,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class EnhancedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double width;
  final double height;
  final bool isLoading;
  final AnimationType animationType;
  final IconData? icon;

  const EnhancedButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width = double.infinity,
    this.height = 50,
    this.isLoading = false,
    this.animationType = AnimationType.scale,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor;
    final txtColor = textColor ?? Colors.white;

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: txtColor),
          SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: txtColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    return AnimatedButton(
      onPressed: onPressed,
      backgroundColor: bgColor,
      height: height,
      width: width,
      isLoading: isLoading,
      animationType: animationType,
      child: buttonContent,
    );
  }
}

class EnhancedCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool interactive;
  final bool enableWaveEffect;
  final bool enableParallaxEffect;
  final EdgeInsetsGeometry padding;

  const EnhancedCard({
    Key? key,
    required this.child,
    this.width = double.infinity,
    this.height = 200,
    this.backgroundColor,
    this.onTap,
    this.interactive = true,
    this.enableWaveEffect = false,
    this.enableParallaxEffect = false,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.cardColor;

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (enableWaveEffect) {
      return WaveContainer(
        color: theme.primaryColor.withOpacity(0.3),
        width: width,
        height: height,
        borderRadius: EnhancedTheme.mediumBorderRadius,
        child: content,
      );
    }

    if (enableParallaxEffect) {
      return ParallaxCard(
        width: width,
        height: height,
        background: Container(
          color: bgColor,
        ),
        foreground: content,
        onTap: onTap,
      );
    }

    if (interactive) {
      return InteractiveCard(
        width: width,
        height: height,
        backgroundColor: bgColor,
        onTap: onTap,
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(EnhancedTheme.mediumBorderRadius),
        boxShadow: EnhancedTheme.smallShadow,
      ),
      child: content,
    );
  }
}

class EnhancedTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool enabled;

  const EnhancedTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon),
                    onPressed: onSuffixIconPressed,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(EnhancedTheme.mediumBorderRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(EnhancedTheme.mediumBorderRadius),
              borderSide: BorderSide(color: EnhancedTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(EnhancedTheme.mediumBorderRadius),
              borderSide: BorderSide(color: EnhancedTheme.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(EnhancedTheme.mediumBorderRadius),
              borderSide: BorderSide(color: EnhancedTheme.errorColor),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
          ),
        ),
      ],
    );
  }
}

class EnhancedProgressIndicator extends StatelessWidget {
  final double value;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final bool showPercentage;
  final bool animate;

  const EnhancedProgressIndicator({
    Key? key,
    required this.value,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 10.0,
    this.showPercentage = false,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor.withOpacity(0.2);
    final fgColor = foregroundColor ?? theme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
        ],
        animate
            ? AnimatedProgressBar(
                value: value,
                height: height,
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                showPercentage: showPercentage,
              )
            : LinearProgressIndicator(
                value: value,
                backgroundColor: bgColor,
                valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                minHeight: height,
              ),
      ],
    );
  }
}
