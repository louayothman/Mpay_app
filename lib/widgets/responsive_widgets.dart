import 'package:flutter/material.dart';
import 'package:mpay_app/theme/app_theme.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final bool maintainBottomViewPadding;
  final bool resizeToAvoidBottomInset;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.maintainBottomViewPadding = false,
    this.resizeToAvoidBottomInset = true,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;
      
  static DeviceType getDeviceType(BuildContext context) {
    if (isDesktop(context)) {
      return DeviceType.desktop;
    } else if (isTablet(context)) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }
  
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }
  
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }
  
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  static EdgeInsets getScreenPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
  
  static double getBottomNavigationBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  
  static double getAppBarHeight(BuildContext context) {
    return AppBar().preferredSize.height;
  }
  
  static double getSafeAreaHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - 
           mediaQuery.padding.top - 
           mediaQuery.padding.bottom;
  }
  
  static double getContentHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - 
           mediaQuery.padding.top - 
           mediaQuery.padding.bottom - 
           AppBar().preferredSize.height;
  }
  
  static double getResponsiveValue({
    required BuildContext context,
    required double mobileValue,
    double? tabletValue,
    double? desktopValue,
  }) {
    if (isDesktop(context)) {
      return desktopValue ?? tabletValue ?? mobileValue;
    } else if (isTablet(context)) {
      return tabletValue ?? mobileValue;
    } else {
      return mobileValue;
    }
  }
  
  static double getResponsiveFontSize({
    required BuildContext context,
    required double fontSize,
    double? minFontSize,
    double? maxFontSize,
  }) {
    double scaleFactor;
    
    if (isDesktop(context)) {
      scaleFactor = 1.2;
    } else if (isTablet(context)) {
      scaleFactor = 1.1;
    } else {
      scaleFactor = 1.0;
    }
    
    double responsiveFontSize = fontSize * scaleFactor;
    
    if (minFontSize != null && responsiveFontSize < minFontSize) {
      return minFontSize;
    }
    
    if (maxFontSize != null && responsiveFontSize > maxFontSize) {
      return maxFontSize;
    }
    
    return responsiveFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If width is more than 1100 we consider it a desktop screen
        if (constraints.maxWidth >= 1100 && desktop != null) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.2,
              viewPadding: maintainBottomViewPadding 
                  ? MediaQuery.of(context).viewPadding 
                  : null,
              viewInsets: resizeToAvoidBottomInset 
                  ? MediaQuery.of(context).viewInsets 
                  : null,
            ),
            child: desktop!,
          );
        }
        // If width is less than 1100 and more than 650 we consider it a tablet screen
        else if (constraints.maxWidth >= 650 && tablet != null) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.1,
              viewPadding: maintainBottomViewPadding 
                  ? MediaQuery.of(context).viewPadding 
                  : null,
              viewInsets: resizeToAvoidBottomInset 
                  ? MediaQuery.of(context).viewInsets 
                  : null,
            ),
            child: tablet!,
          );
        }
        // Otherwise we consider it a mobile screen
        else {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0,
              viewPadding: maintainBottomViewPadding 
                  ? MediaQuery.of(context).viewPadding 
                  : null,
              viewInsets: resizeToAvoidBottomInset 
                  ? MediaQuery.of(context).viewInsets 
                  : null,
            ),
            child: mobile,
          );
        }
      },
    );
  }
}

class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;
  final EdgeInsetsGeometry? mobileMargin;
  final EdgeInsetsGeometry? tabletMargin;
  final EdgeInsetsGeometry? desktopMargin;
  final Color? backgroundColor;
  final Decoration? decoration;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;
  final Matrix4? transform;
  final Duration? animationDuration;
  final Curve? animationCurve;

  const AdaptiveContainer({
    Key? key,
    required this.child,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileMargin,
    this.tabletMargin,
    this.desktopMargin,
    this.backgroundColor,
    this.decoration,
    this.alignment,
    this.constraints,
    this.borderRadius,
    this.boxShadow,
    this.clipBehavior = Clip.none,
    this.transform,
    this.animationDuration,
    this.animationCurve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double? width;
    double? height;
    EdgeInsetsGeometry? padding;
    EdgeInsetsGeometry? margin;

    if (ResponsiveLayout.isMobile(context)) {
      width = mobileWidth;
      height = mobileHeight;
      padding = mobilePadding;
      margin = mobileMargin;
    } else if (ResponsiveLayout.isTablet(context)) {
      width = tabletWidth ?? mobileWidth;
      height = tabletHeight ?? mobileHeight;
      padding = tabletPadding ?? mobilePadding;
      margin = tabletMargin ?? mobileMargin;
    } else {
      width = desktopWidth ?? tabletWidth ?? mobileWidth;
      height = desktopHeight ?? tabletHeight ?? mobileHeight;
      padding = desktopPadding ?? tabletPadding ?? mobilePadding;
      margin = desktopMargin ?? tabletMargin ?? mobileMargin;
    }

    Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      color: decoration == null ? backgroundColor : null,
      decoration: decoration ?? (borderRadius != null || boxShadow != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              boxShadow: boxShadow,
            )
          : null),
      alignment: alignment,
      constraints: constraints,
      clipBehavior: clipBehavior,
      transform: transform,
      child: child,
    );
    
    if (animationDuration != null) {
      return AnimatedContainer(
        duration: animationDuration!,
        curve: animationCurve ?? Curves.easeInOut,
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        color: decoration == null ? backgroundColor : null,
        decoration: decoration ?? (borderRadius != null || boxShadow != null
            ? BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius,
                boxShadow: boxShadow,
              )
            : null),
        alignment: alignment,
        constraints: constraints,
        clipBehavior: clipBehavior,
        transform: transform,
        child: child,
      );
    }
    
    return container;
  }
}

class AdaptiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int mobileCrossAxisCount;
  final int tabletCrossAxisCount;
  final int desktopCrossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Axis scrollDirection;
  final bool primary;
  final Widget? emptyWidget;
  final SliverGridDelegate? customGridDelegate;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;

  const AdaptiveGridView({
    Key? key,
    required this.children,
    this.mobileCrossAxisCount = 1,
    this.tabletCrossAxisCount = 2,
    this.desktopCrossAxisCount = 4,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 10.0,
    this.mainAxisSpacing = 10.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.primary,
    this.emptyWidget,
    this.customGridDelegate,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty && emptyWidget != null) {
      return emptyWidget!;
    }
    
    int crossAxisCount;

    if (ResponsiveLayout.isMobile(context)) {
      crossAxisCount = mobileCrossAxisCount;
    } else if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = tabletCrossAxisCount;
    } else {
      crossAxisCount = desktopCrossAxisCount;
    }

    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      controller: controller,
      scrollDirection: scrollDirection,
      primary: primary,
      gridDelegate: customGridDelegate ?? SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent,
    );
  }
}

class AdaptiveTextStyle {
  static TextStyle getStyle({
    required BuildContext context,
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? decoration,
    double? height,
    String? fontFamily,
    double? letterSpacing,
    FontStyle? fontStyle,
    List<Shadow>? shadows,
    TextBaseline? textBaseline,
    Paint? foreground,
    Paint? background,
    TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    double? wordSpacing,
  }) {
    double fontSize;

    if (ResponsiveLayout.isMobile(context)) {
      fontSize = mobileSize;
    } else if (ResponsiveLayout.isTablet(context)) {
      fontSize = tabletSize ?? mobileSize * 1.2;
    } else {
      fontSize = desktopSize ?? mobileSize * 1.4;
    }

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
      height: height,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      shadows: shadows,
      textBaseline: textBaseline,
      foreground: foreground,
      background: background,
      leadingDistribution: leadingDistribution,
      locale: locale,
      wordSpacing: wordSpacing,
    );
  }
  
  static TextStyle fromTheme({
    required BuildContext context,
    required TextStyle baseStyle,
    double? scaleFactor,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? decoration,
    double? height,
  }) {
    double effectiveScaleFactor;
    
    if (scaleFactor != null) {
      effectiveScaleFactor = scaleFactor;
    } else if (ResponsiveLayout.isDesktop(context)) {
      effectiveScaleFactor = 1.2;
    } else if (ResponsiveLayout.isTablet(context)) {
      effectiveScaleFactor = 1.1;
    } else {
      effectiveScaleFactor = 1.0;
    }
    
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! * effectiveScaleFactor : null,
      fontWeight: fontWeight ?? baseStyle.fontWeight,
      color: color ?? baseStyle.color,
      decoration: decoration ?? baseStyle.decoration,
      height: height ?? baseStyle.height,
    );
  }
}

class AdaptiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Widget? bottomSheet;
  final bool? primary;
  final String? restorationId;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final DragStartBehavior drawerDragStartBehavior;
  final double? drawerEdgeDragWidth;
  final Color? drawerScrimColor;
  final double? drawerWidth;
  final Widget? mobileNavigationRail;
  final Widget? tabletNavigationRail;
  final Widget? desktopNavigationRail;

  const AdaptiveScaffold({
    Key? key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.bottomSheet,
    this.primary,
    this.restorationId,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.drawerEdgeDragWidth,
    this.drawerScrimColor,
    this.drawerWidth,
    this.mobileNavigationRail,
    this.tabletNavigationRail,
    this.desktopNavigationRail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if we should show the navigation rail based on device type
    Widget? navigationRail;
    if (ResponsiveLayout.isDesktop(context)) {
      navigationRail = desktopNavigationRail;
    } else if (ResponsiveLayout.isTablet(context)) {
      navigationRail = tabletNavigationRail;
    } else {
      navigationRail = mobileNavigationRail;
    }
    
    // If we have a navigation rail, use a row layout
    if (navigationRail != null) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            navigationRail,
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: ResponsiveLayout.isMobile(context) ? bottomNavigationBar : null,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        bottomSheet: bottomSheet,
        primary: primary,
        restorationId: restorationId,
        drawerScrimColor: drawerScrimColor,
      );
    }
    
    // Otherwise use a standard scaffold
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      bottomSheet: bottomSheet,
      primary: primary,
      restorationId: restorationId,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      drawerDragStartBehavior: drawerDragStartBehavior,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerScrimColor: drawerScrimColor,
    );
  }
}

class AdaptiveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;
  final double? elevation;
  final ShapeBorder? shape;
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final bool isOutlined;
  final bool isText;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final MaterialTapTargetSize? tapTargetSize;
  final Duration? animationDuration;
  final bool enableFeedback;
  final AlignmentGeometry? alignment;
  final InteractiveInkFeatureFactory? splashFactory;
  final OutlinedBorder? outlinedBorder;
  final BorderRadius? borderRadius;
  final double? borderWidth;
  final Color? borderColor;
  final bool? enableHapticFeedback;
  final bool isDisabled;

  const AdaptiveButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.color,
    this.textColor,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.elevation,
    this.shape,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.isOutlined = false,
    this.isText = false,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.tapTargetSize,
    this.animationDuration,
    this.enableFeedback = true,
    this.alignment,
    this.splashFactory,
    this.outlinedBorder,
    this.borderRadius,
    this.borderWidth,
    this.borderColor,
    this.enableHapticFeedback,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine responsive values
    double? height;
    double? width;
    EdgeInsetsGeometry? padding;
    
    if (ResponsiveLayout.isMobile(context)) {
      height = mobileHeight;
      width = mobileWidth;
      padding = mobilePadding;
    } else if (ResponsiveLayout.isTablet(context)) {
      height = tabletHeight ?? mobileHeight;
      width = tabletWidth ?? mobileWidth;
      padding = tabletPadding ?? mobilePadding;
    } else {
      height = desktopHeight ?? tabletHeight ?? mobileHeight;
      width = desktopWidth ?? tabletWidth ?? mobileWidth;
      padding = desktopPadding ?? tabletPadding ?? mobilePadding;
    }
    
    // Default padding if none provided
    padding ??= EdgeInsets.symmetric(
      horizontal: ResponsiveLayout.getResponsiveValue(
        context: context,
        mobileValue: 16.0,
        tabletValue: 20.0,
        desktopValue: 24.0,
      ),
      vertical: ResponsiveLayout.getResponsiveValue(
        context: context,
        mobileValue: 8.0,
        tabletValue: 10.0,
        desktopValue: 12.0,
      ),
    );
    
    // Create the button style
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusMedium);
    
    final ButtonStyle buttonStyle = ButtonStyle(
      backgroundColor: isDisabled
          ? MaterialStateProperty.all(Colors.grey.shade300)
          : color != null 
              ? MaterialStateProperty.all(color) 
              : null,
      foregroundColor: isDisabled
          ? MaterialStateProperty.all(Colors.grey.shade700)
          : textColor != null 
              ? MaterialStateProperty.all(textColor) 
              : null,
      padding: padding != null 
          ? MaterialStateProperty.all(padding) 
          : null,
      elevation: elevation != null 
          ? MaterialStateProperty.all(elevation) 
          : null,
      shape: shape != null 
          ? MaterialStateProperty.all(shape) 
          : outlinedBorder != null
              ? MaterialStateProperty.all(outlinedBorder)
              : borderRadius != null
                  ? MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: effectiveBorderRadius,
                        side: isOutlined && borderWidth != null && borderColor != null
                            ? BorderSide(
                                width: borderWidth!,
                                color: borderColor!,
                              )
                            : BorderSide.none,
                      ),
                    )
                  : null,
      minimumSize: (height != null || width != null)
          ? MaterialStateProperty.all(
              Size(width ?? 0, height ?? 0),
            )
          : null,
      tapTargetSize: tapTargetSize != null
          ? MaterialStateProperty.all(tapTargetSize)
          : null,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
    );
    
    // Handle haptic feedback
    VoidCallback? handlePress;
    if (!isDisabled) {
      handlePress = () {
        if (enableHapticFeedback == true) {
          HapticFeedback.lightImpact();
        }
        onPressed();
      };
    }

    // Return the appropriate button type
    if (isText) {
      return TextButton(
        onPressed: isDisabled ? null : handlePress,
        style: buttonStyle,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        child: child,
      );
    } else if (isOutlined) {
      return OutlinedButton(
        onPressed: isDisabled ? null : handlePress,
        style: buttonStyle,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        child: child,
      );
    } else {
      return ElevatedButton(
        onPressed: isDisabled ? null : handlePress,
        style: buttonStyle,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        child: child,
      );
    }
  }
}

class AdaptiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final InputDecoration? decoration;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool readOnly;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;
  final EdgeInsetsGeometry? mobileContentPadding;
  final EdgeInsetsGeometry? tabletContentPadding;
  final EdgeInsetsGeometry? desktopContentPadding;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool? showCursor;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final VoidCallback? onTap;
  final bool expands;
  final List<TextInputFormatter>? inputFormatters;
  final Color? cursorColor;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final double cursorWidth;
  final bool? enableSuggestions;
  final bool enableIMEPersonalizedLearning;
  final String obscuringCharacter;
  final StrutStyle? strutStyle;
  final TextCapitalization textCapitalization;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final String? helperText;
  final String? errorText;
  final bool isDense;
  final bool filled;
  final bool showErrorText;
  final bool showHelperText;
  final bool showCounter;
  final bool showBorder;
  final double borderWidth;
  final double focusedBorderWidth;
  final double errorBorderWidth;
  final Widget? counter;
  final Widget? label;
  final Widget? helper;
  final Widget? error;

  const AdaptiveTextField({
    Key? key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.decoration,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
    this.readOnly = false,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileContentPadding,
    this.tabletContentPadding,
    this.desktopContentPadding,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.showCursor,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onTap,
    this.expands = false,
    this.inputFormatters,
    this.cursorColor,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorWidth = 2.0,
    this.enableSuggestions = true,
    this.enableIMEPersonalizedLearning = true,
    this.obscuringCharacter = '•',
    this.strutStyle,
    this.textCapitalization = TextCapitalization.none,
    this.fillColor,
    this.borderRadius,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.helperText,
    this.errorText,
    this.isDense = false,
    this.filled = true,
    this.showErrorText = true,
    this.showHelperText = true,
    this.showCounter = true,
    this.showBorder = true,
    this.borderWidth = 1.0,
    this.focusedBorderWidth = 2.0,
    this.errorBorderWidth = 1.0,
    this.counter,
    this.label,
    this.helper,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine responsive values
    double? width;
    EdgeInsetsGeometry? padding;
    EdgeInsetsGeometry? contentPadding;
    
    if (ResponsiveLayout.isMobile(context)) {
      width = mobileWidth;
      padding = mobilePadding;
      contentPadding = mobileContentPadding;
    } else if (ResponsiveLayout.isTablet(context)) {
      width = tabletWidth ?? mobileWidth;
      padding = tabletPadding ?? mobilePadding;
      contentPadding = tabletContentPadding ?? mobileContentPadding;
    } else {
      width = desktopWidth ?? tabletWidth ?? mobileWidth;
      padding = desktopPadding ?? tabletPadding ?? mobilePadding;
      contentPadding = desktopContentPadding ?? tabletContentPadding ?? mobileContentPadding;
    }
    
    // Default content padding if none provided
    contentPadding ??= EdgeInsets.symmetric(
      horizontal: ResponsiveLayout.getResponsiveValue(
        context: context,
        mobileValue: 16.0,
        tabletValue: 18.0,
        desktopValue: 20.0,
      ),
      vertical: ResponsiveLayout.getResponsiveValue(
        context: context,
        mobileValue: 12.0,
        tabletValue: 14.0,
        desktopValue: 16.0,
      ),
    );
    
    // Create the text style
    final effectiveTextStyle = textStyle ?? AdaptiveTextStyle.getStyle(
      context: context,
      mobileSize: 16,
      color: theme.colorScheme.onSurface,
    );
    
    // Create the border radius
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusMedium);
    
    // Create the input decoration
    final effectiveDecoration = decoration ?? InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: fillColor ?? theme.inputDecorationTheme.fillColor,
      isDense: isDense,
      contentPadding: contentPadding,
      border: showBorder ? OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(
          color: borderColor ?? theme.colorScheme.outline,
          width: borderWidth,
        ),
      ) : InputBorder.none,
      enabledBorder: showBorder ? OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(
          color: borderColor ?? theme.colorScheme.outline,
          width: borderWidth,
        ),
      ) : InputBorder.none,
      focusedBorder: showBorder ? OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(
          color: focusedBorderColor ?? theme.colorScheme.primary,
          width: focusedBorderWidth,
        ),
      ) : InputBorder.none,
      errorBorder: showBorder ? OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(
          color: errorBorderColor ?? theme.colorScheme.error,
          width: errorBorderWidth,
        ),
      ) : InputBorder.none,
      focusedErrorBorder: showBorder ? OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(
          color: errorBorderColor ?? theme.colorScheme.error,
          width: focusedBorderWidth,
        ),
      ) : InputBorder.none,
      helperText: showHelperText ? helperText : null,
      errorText: showErrorText ? errorText : null,
      counterText: showCounter ? null : '',
      counter: counter,
      label: label,
      helperStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
      errorStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      alignLabelWithHint: true,
      helperMaxLines: 2,
      errorMaxLines: 2,
    );

    // Create the text field
    Widget textField = TextFormField(
      controller: controller,
      decoration: effectiveDecoration,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      focusNode: focusNode,
      textInputAction: textInputAction,
      autofocus: autofocus,
      readOnly: readOnly,
      style: effectiveTextStyle,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      showCursor: showCursor,
      maxLength: maxLength,
      maxLengthEnforcement: maxLengthEnforcement,
      onTap: onTap,
      expands: expands,
      inputFormatters: inputFormatters,
      cursorColor: cursorColor,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorWidth: cursorWidth,
      enableSuggestions: enableSuggestions ?? true,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      obscuringCharacter: obscuringCharacter,
      strutStyle: strutStyle,
      textCapitalization: textCapitalization,
    );
    
    // Apply container with padding if needed
    if (padding != null || width != null) {
      textField = Container(
        width: width,
        padding: padding,
        child: textField,
      );
    }
    
    return textField;
  }
}

class AdaptiveListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Axis scrollDirection;
  final bool primary;
  final Widget? separator;
  final Widget? emptyWidget;
  final String? emptyText;
  final IconData? emptyIcon;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;
  final bool showScrollbar;
  final bool reverse;
  final double? itemExtent;
  final Widget? prototypeItem;
  final bool useSlivers;
  final Widget? header;
  final Widget? footer;
  final IndexedWidgetBuilder? itemBuilder;
  final int? itemCount;
  final bool showDividers;
  final Color? dividerColor;
  final double dividerThickness;
  final double dividerIndent;
  final double dividerEndIndent;
  final double dividerHeight;

  const AdaptiveListView({
    Key? key,
    required this.children,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.primary,
    this.separator,
    this.emptyWidget,
    this.emptyText,
    this.emptyIcon,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.showScrollbar = true,
    this.reverse = false,
    this.itemExtent,
    this.prototypeItem,
    this.useSlivers = false,
    this.header,
    this.footer,
    this.itemBuilder,
    this.itemCount,
    this.showDividers = false,
    this.dividerColor,
    this.dividerThickness = 1.0,
    this.dividerIndent = 0.0,
    this.dividerEndIndent = 0.0,
    this.dividerHeight = 1.0,
  }) : assert(itemBuilder == null || children.isEmpty, 'Cannot provide both children and itemBuilder'),
       assert(itemCount == null || itemBuilder != null, 'Must provide itemBuilder when itemCount is provided'),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check if the list is empty
    final bool isEmpty = (itemCount != null && itemCount == 0) || 
                         (itemCount == null && children.isEmpty);
    
    // Show empty state if needed
    if (isEmpty) {
      if (emptyWidget != null) {
        return emptyWidget!;
      } else if (emptyText != null || emptyIcon != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emptyIcon != null)
                Icon(
                  emptyIcon,
                  size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
              if (emptyText != null) ...[
                const SizedBox(height: 16),
                Text(
                  emptyText!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      }
    }
    
    // Create the list view
    Widget listView;
    
    if (itemBuilder != null) {
      if (separator != null) {
        listView = ListView.separated(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          controller: controller,
          scrollDirection: scrollDirection,
          primary: primary,
          separatorBuilder: (_, __) => separator!,
          itemCount: itemCount!,
          itemBuilder: itemBuilder!,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          reverse: reverse,
        );
      } else if (showDividers) {
        listView = ListView.separated(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          controller: controller,
          scrollDirection: scrollDirection,
          primary: primary,
          separatorBuilder: (_, __) => Divider(
            color: dividerColor ?? theme.dividerColor,
            thickness: dividerThickness,
            height: dividerHeight,
            indent: dividerIndent,
            endIndent: dividerEndIndent,
          ),
          itemCount: itemCount!,
          itemBuilder: itemBuilder!,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          reverse: reverse,
        );
      } else {
        listView = ListView.builder(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          controller: controller,
          scrollDirection: scrollDirection,
          primary: primary,
          itemCount: itemCount,
          itemBuilder: itemBuilder!,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          reverse: reverse,
          itemExtent: itemExtent,
          prototypeItem: prototypeItem,
        );
      }
    } else {
      if (separator != null) {
        final List<Widget> separatedChildren = [];
        for (int i = 0; i < children.length; i++) {
          separatedChildren.add(children[i]);
          if (i < children.length - 1) {
            separatedChildren.add(separator!);
          }
        }
        
        listView = ListView(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          controller: controller,
          scrollDirection: scrollDirection,
          primary: primary,
          children: separatedChildren,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          reverse: reverse,
          itemExtent: itemExtent,
        );
      } else if (showDividers) {
        final List<Widget> dividedChildren = [];
        for (int i = 0; i < children.length; i++) {
          dividedChildren.add(children[i]);
          if (i < children.length - 1) {
            dividedChildren.add(Divider(
              color: dividerColor ?? theme.dividerColor,
              thickness: dividerThickness,
              height: dividerHeight,
              indent: dividerIndent,
              endIndent: dividerEndIndent,
            ));
          }
        }
        
        listView = ListView(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          controller: controller,
          scrollDirection: scrollDirection,
          primary: primary,
          children: dividedChildren,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          reverse: reverse,
          itemExtent: itemExtent,
        );
      } else {
        listView = ListView(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          controller: controller,
          scrollDirection: scrollDirection,
          primary: primary,
          children: children,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          reverse: reverse,
          itemExtent: itemExtent,
        );
      }
    }
    
    // Add header and footer if needed
    if (header != null || footer != null) {
      listView = Column(
        children: [
          if (header != null) header!,
          Expanded(child: listView),
          if (footer != null) footer!,
        ],
      );
    }
    
    // Add scrollbar if needed
    if (showScrollbar) {
      listView = Scrollbar(
        controller: controller,
        thickness: 6.0,
        radius: const Radius.circular(10.0),
        child: listView,
      );
    }
    
    // Use slivers if needed
    if (useSlivers) {
      return CustomScrollView(
        controller: controller,
        physics: physics,
        scrollDirection: scrollDirection,
        reverse: reverse,
        primary: primary,
        shrinkWrap: shrinkWrap,
        cacheExtent: cacheExtent,
        semanticChildCount: semanticChildCount,
        dragStartBehavior: dragStartBehavior,
        keyboardDismissBehavior: keyboardDismissBehavior,
        restorationId: restorationId,
        clipBehavior: clipBehavior,
        slivers: [
          if (header != null)
            SliverToBoxAdapter(child: header),
          SliverPadding(
            padding: padding ?? EdgeInsets.zero,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                itemBuilder ?? ((context, index) => children[index]),
                childCount: itemCount ?? children.length,
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes,
              ),
            ),
          ),
          if (footer != null)
            SliverToBoxAdapter(child: footer),
        ],
      );
    }
    
    return listView;
  }
}

class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final Color? splashColor;
  final Color? highlightColor;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final ShapeBorder? shape;
  final bool isOutlined;
  final bool isElevated;
  final bool enableHapticFeedback;
  final Duration? animationDuration;
  final Curve? animationCurve;

  const AdaptiveCard({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.border,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.splashColor,
    this.highlightColor,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shape,
    this.isOutlined = false,
    this.isElevated = true,
    this.enableHapticFeedback = true,
    this.animationDuration,
    this.animationCurve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusMedium);
    final effectiveElevation = isElevated ? (elevation ?? 2.0) : 0.0;
    
    final effectiveBorder = isOutlined || showBorder
        ? border ?? Border.all(
            color: borderColor ?? theme.colorScheme.outline.withOpacity(0.5),
            width: borderWidth,
          )
        : null;
    
    final effectiveShape = shape ?? RoundedRectangleBorder(
      borderRadius: effectiveBorderRadius,
    );
    
    final effectiveBoxShadow = isElevated && effectiveElevation > 0
        ? boxShadow ?? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: effectiveElevation * 2,
              offset: Offset(0, effectiveElevation),
            ),
          ]
        : null;
    
    Widget cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: child,
    );
    
    if (onTap != null || onLongPress != null || onDoubleTap != null) {
      cardContent = InkWell(
        onTap: onTap != null
            ? () {
                if (enableHapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                onTap!();
              }
            : null,
        onLongPress: onLongPress != null
            ? () {
                if (enableHapticFeedback) {
                  HapticFeedback.mediumImpact();
                }
                onLongPress!();
              }
            : null,
        onDoubleTap: onDoubleTap,
        splashColor: splashColor ?? theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: highlightColor ?? theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: effectiveBorderRadius,
        child: cardContent,
      );
    }
    
    final containerDecoration = BoxDecoration(
      color: backgroundColor ?? theme.cardColor,
      borderRadius: effectiveBorderRadius,
      border: effectiveBorder,
      boxShadow: effectiveBoxShadow,
    );
    
    if (animationDuration != null) {
      return AnimatedContainer(
        duration: animationDuration!,
        curve: animationCurve ?? Curves.easeInOut,
        width: width,
        height: height,
        margin: margin,
        decoration: containerDecoration,
        clipBehavior: clipBehavior,
        child: Material(
          color: Colors.transparent,
          clipBehavior: clipBehavior,
          shape: effectiveShape,
          child: cardContent,
        ),
      );
    }
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: containerDecoration,
      clipBehavior: clipBehavior,
      child: Material(
        color: Colors.transparent,
        clipBehavior: clipBehavior,
        shape: effectiveShape,
        child: cardContent,
      ),
    );
  }
}

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final bool centerTitle;
  final double? titleSpacing;
  final double? leadingWidth;
  final double? toolbarHeight;
  final double? mobileToolbarHeight;
  final double? tabletToolbarHeight;
  final double? desktopToolbarHeight;
  final TextStyle? titleTextStyle;
  final TextStyle? mobileTitleTextStyle;
  final TextStyle? tabletTitleTextStyle;
  final TextStyle? desktopTitleTextStyle;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool primary;
  final PreferredSizeWidget? bottom;
  final double? bottomOpacity;
  final ShapeBorder? shape;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool forceMaterialTransparency;
  final Clip? clipBehavior;
  final double? toolbarOpacity;
  final bool excludeHeaderSemantics;
  final Widget? flexibleSpace;
  final bool showDivider;
  final Color? dividerColor;
  final double dividerThickness;
  final double dividerIndent;
  final double dividerEndIndent;
  final Widget? searchBar;
  final bool showSearchBar;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? backButtonTooltip;
  final Widget? backIcon;

  const AdaptiveAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.centerTitle = true,
    this.titleSpacing,
    this.leadingWidth,
    this.toolbarHeight,
    this.mobileToolbarHeight,
    this.tabletToolbarHeight,
    this.desktopToolbarHeight,
    this.titleTextStyle,
    this.mobileTitleTextStyle,
    this.tabletTitleTextStyle,
    this.desktopTitleTextStyle,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.bottom,
    this.bottomOpacity,
    this.shape,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior,
    this.toolbarOpacity,
    this.excludeHeaderSemantics = false,
    this.flexibleSpace,
    this.showDivider = false,
    this.dividerColor,
    this.dividerThickness = 1.0,
    this.dividerIndent = 0.0,
    this.dividerEndIndent = 0.0,
    this.searchBar,
    this.showSearchBar = false,
    this.showBackButton = false,
    this.onBackPressed,
    this.backButtonTooltip,
    this.backIcon,
  }) : assert(title == null || titleWidget == null, 'Cannot provide both title and titleWidget'),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine responsive values
    double? effectiveToolbarHeight;
    TextStyle? effectiveTitleTextStyle;
    
    if (ResponsiveLayout.isMobile(context)) {
      effectiveToolbarHeight = mobileToolbarHeight ?? toolbarHeight;
      effectiveTitleTextStyle = mobileTitleTextStyle ?? titleTextStyle;
    } else if (ResponsiveLayout.isTablet(context)) {
      effectiveToolbarHeight = tabletToolbarHeight ?? toolbarHeight;
      effectiveTitleTextStyle = tabletTitleTextStyle ?? titleTextStyle;
    } else {
      effectiveToolbarHeight = desktopToolbarHeight ?? toolbarHeight;
      effectiveTitleTextStyle = desktopTitleTextStyle ?? titleTextStyle;
    }
    
    // Create the title widget
    Widget? effectiveTitleWidget;
    if (titleWidget != null) {
      effectiveTitleWidget = titleWidget;
    } else if (title != null) {
      effectiveTitleWidget = Text(
        title!,
        style: effectiveTitleTextStyle,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    // Create the leading widget
    Widget? effectiveLeading;
    if (leading != null) {
      effectiveLeading = leading;
    } else if (showBackButton) {
      effectiveLeading = IconButton(
        icon: backIcon ?? const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
        tooltip: backButtonTooltip ?? 'Back',
      );
    }
    
    // Create the app bar
    Widget appBar = AppBar(
      title: effectiveTitleWidget,
      actions: actions,
      leading: effectiveLeading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      leadingWidth: leadingWidth,
      toolbarHeight: effectiveToolbarHeight,
      iconTheme: iconTheme,
      actionsIconTheme: actionsIconTheme,
      primary: primary,
      bottom: bottom,
      bottomOpacity: bottomOpacity,
      shape: shape,
      systemOverlayStyle: systemOverlayStyle,
      forceMaterialTransparency: forceMaterialTransparency,
      clipBehavior: clipBehavior,
      toolbarOpacity: toolbarOpacity,
      excludeHeaderSemantics: excludeHeaderSemantics,
      flexibleSpace: flexibleSpace,
    );
    
    // Add divider if needed
    if (showDivider) {
      appBar = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: appBar),
          Divider(
            color: dividerColor ?? theme.dividerColor,
            thickness: dividerThickness,
            height: dividerThickness,
            indent: dividerIndent,
            endIndent: dividerEndIndent,
          ),
        ],
      );
    }
    
    // Add search bar if needed
    if (showSearchBar && searchBar != null) {
      appBar = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: appBar),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: searchBar!,
          ),
        ],
      );
    }
    
    return appBar;
  }

  @override
  Size get preferredSize {
    double height = toolbarHeight ?? kToolbarHeight;
    
    if (ResponsiveLayout.isMobile(context)) {
      height = mobileToolbarHeight ?? height;
    } else if (ResponsiveLayout.isTablet(context)) {
      height = tabletToolbarHeight ?? height;
    } else {
      height = desktopToolbarHeight ?? height;
    }
    
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }
    
    if (showDivider) {
      height += dividerThickness;
    }
    
    if (showSearchBar && searchBar != null) {
      height += 56.0; // Approximate height for search bar
    }
    
    return Size.fromHeight(height);
  }

  BuildContext? get context => null;
}

class AdaptiveBottomNavigationBar extends StatelessWidget {
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;
  final IconThemeData? selectedIconTheme;
  final IconThemeData? unselectedIconTheme;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;
  final BottomNavigationBarType? type;
  final bool enableFeedback;
  final double? selectedFontSize;
  final double? unselectedFontSize;
  final double iconSize;
  final bool useMaterial3;
  final bool hideOnKeyboard;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final bool enableHapticFeedback;
  final bool showIndicator;
  final Color? indicatorColor;
  final double indicatorHeight;
  final double? indicatorWidth;
  final BorderRadius? indicatorBorderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? itemPadding;
  final double? height;
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;
  final bool showOnDesktop;
  final bool showOnTablet;
  final bool showOnMobile;
  final bool showLabels;
  final bool showIcons;
  final bool showShadow;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;
  final bool showFloatingActionButton;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final NotchedShape? notchedShape;

  const AdaptiveBottomNavigationBar({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
    this.selectedIconTheme,
    this.unselectedIconTheme,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true,
    this.type,
    this.enableFeedback = true,
    this.selectedFontSize = 14.0,
    this.unselectedFontSize = 12.0,
    this.iconSize = 24.0,
    this.useMaterial3 = true,
    this.hideOnKeyboard = true,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.0,
    this.enableHapticFeedback = true,
    this.showIndicator = false,
    this.indicatorColor,
    this.indicatorHeight = 3.0,
    this.indicatorWidth,
    this.indicatorBorderRadius,
    this.padding,
    this.itemPadding,
    this.height,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
    this.showOnDesktop = false,
    this.showOnTablet = true,
    this.showOnMobile = true,
    this.showLabels = true,
    this.showIcons = true,
    this.showShadow = true,
    this.boxShadow,
    this.borderRadius,
    this.clipBehavior = Clip.none,
    this.showFloatingActionButton = false,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.notchedShape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Check if we should show the navigation bar based on device type
    if (ResponsiveLayout.isDesktop(context) && !showOnDesktop) {
      return const SizedBox.shrink();
    }
    
    if (ResponsiveLayout.isTablet(context) && !showOnTablet) {
      return const SizedBox.shrink();
    }
    
    if (ResponsiveLayout.isMobile(context) && !showOnMobile) {
      return const SizedBox.shrink();
    }
    
    // Check if we should hide the navigation bar when keyboard is visible
    if (hideOnKeyboard && mediaQuery.viewInsets.bottom > 0) {
      return const SizedBox.shrink();
    }
    
    // Determine responsive values
    double effectiveHeight;
    
    if (ResponsiveLayout.isMobile(context)) {
      effectiveHeight = mobileHeight ?? height ?? kBottomNavigationBarHeight;
    } else if (ResponsiveLayout.isTablet(context)) {
      effectiveHeight = tabletHeight ?? height ?? kBottomNavigationBarHeight;
    } else {
      effectiveHeight = desktopHeight ?? height ?? kBottomNavigationBarHeight;
    }
    
    // Create the bottom navigation bar
    Widget navigationBar;
    
    if (showIndicator) {
      // Custom navigation bar with indicator
      navigationBar = Container(
        height: effectiveHeight,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.bottomNavigationBarTheme.backgroundColor,
          border: showBorder ? Border(
            top: BorderSide(
              color: borderColor ?? theme.dividerColor,
              width: borderWidth,
            ),
          ) : null,
          boxShadow: showShadow ? (boxShadow ?? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ]) : null,
          borderRadius: borderRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = index == currentIndex;
            
            return Expanded(
              child: InkWell(
                onTap: () {
                  if (enableHapticFeedback) {
                    HapticFeedback.selectionClick();
                  }
                  onTap(index);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showIndicator && isSelected)
                      Container(
                        width: indicatorWidth ?? 24,
                        height: indicatorHeight,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: indicatorColor ?? theme.colorScheme.primary,
                          borderRadius: indicatorBorderRadius ?? BorderRadius.circular(indicatorHeight / 2),
                        ),
                      ),
                    if (showIcons)
                      IconTheme(
                        data: isSelected
                            ? (selectedIconTheme ?? IconThemeData(
                                color: selectedItemColor ?? theme.colorScheme.primary,
                                size: iconSize,
                              ))
                            : (unselectedIconTheme ?? IconThemeData(
                                color: unselectedItemColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
                                size: iconSize,
                              )),
                        child: items[index].icon,
                      ),
                    if (showLabels && (isSelected ? showSelectedLabels : showUnselectedLabels))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          items[index].label ?? '',
                          style: isSelected
                              ? (selectedLabelStyle ?? TextStyle(
                                  color: selectedItemColor ?? theme.colorScheme.primary,
                                  fontSize: selectedFontSize,
                                  fontWeight: FontWeight.bold,
                                ))
                              : (unselectedLabelStyle ?? TextStyle(
                                  color: unselectedItemColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: unselectedFontSize,
                                )),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
    } else {
      // Standard bottom navigation bar
      navigationBar = BottomNavigationBar(
        items: items,
        currentIndex: currentIndex,
        onTap: (index) {
          if (enableHapticFeedback) {
            HapticFeedback.selectionClick();
          }
          onTap(index);
        },
        backgroundColor: backgroundColor,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        elevation: elevation,
        selectedIconTheme: selectedIconTheme,
        unselectedIconTheme: unselectedIconTheme,
        selectedLabelStyle: selectedLabelStyle,
        unselectedLabelStyle: unselectedLabelStyle,
        showSelectedLabels: showLabels && showSelectedLabels,
        showUnselectedLabels: showLabels && showUnselectedLabels,
        type: type ?? BottomNavigationBarType.fixed,
        enableFeedback: enableFeedback,
        selectedFontSize: selectedFontSize!,
        unselectedFontSize: unselectedFontSize!,
        iconSize: iconSize,
        useMaterial3: useMaterial3,
      );
      
      if (showBorder || showShadow || borderRadius != null) {
        navigationBar = Container(
          height: effectiveHeight,
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.bottomNavigationBarTheme.backgroundColor,
            border: showBorder ? Border(
              top: BorderSide(
                color: borderColor ?? theme.dividerColor,
                width: borderWidth,
              ),
            ) : null,
            boxShadow: showShadow ? (boxShadow ?? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ]) : null,
            borderRadius: borderRadius,
          ),
          clipBehavior: clipBehavior,
          child: navigationBar,
        );
      }
    }
    
    // Add floating action button if needed
    if (showFloatingActionButton && floatingActionButton != null) {
      return Stack(
        alignment: Alignment.topCenter,
        children: [
          navigationBar,
          Positioned(
            top: -28,
            child: floatingActionButton!,
          ),
        ],
      );
    }
    
    return navigationBar;
  }
}

class AdaptiveDrawer extends StatelessWidget {
  final Widget? header;
  final List<Widget> children;
  final Color? backgroundColor;
  final double? width;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final EdgeInsetsGeometry? padding;
  final bool showScrim;
  final Color? scrimColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip clipBehavior;
  final bool showHeader;
  final bool showFooter;
  final Widget? footer;
  final bool showDividers;
  final Color? dividerColor;
  final double dividerThickness;
  final double dividerIndent;
  final double dividerEndIndent;
  final bool showScrollbar;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool primary;
  final Widget? closeButton;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final bool enableGestures;
  final bool isEndDrawer;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final bool showShadow;
  final bool useSlivers;
  final bool showBackdrop;
  final Color? backdropColor;
  final VoidCallback? onBackdropTap;
  final double backdropOpacity;
  final Duration? animationDuration;
  final Curve? animationCurve;

  const AdaptiveDrawer({
    Key? key,
    this.header,
    required this.children,
    this.backgroundColor,
    this.width,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.padding,
    this.showScrim = true,
    this.scrimColor,
    this.elevation,
    this.shape,
    this.clipBehavior = Clip.hardEdge,
    this.showHeader = true,
    this.showFooter = false,
    this.footer,
    this.showDividers = true,
    this.dividerColor,
    this.dividerThickness = 1.0,
    this.dividerIndent = 0.0,
    this.dividerEndIndent = 0.0,
    this.showScrollbar = true,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.primary = true,
    this.closeButton,
    this.onClose,
    this.showCloseButton = true,
    this.enableGestures = true,
    this.isEndDrawer = false,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.boxShadow,
    this.showShadow = true,
    this.useSlivers = false,
    this.showBackdrop = false,
    this.backdropColor,
    this.onBackdropTap,
    this.backdropOpacity = 0.5,
    this.animationDuration,
    this.animationCurve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine responsive values
    double effectiveWidth;
    
    if (ResponsiveLayout.isMobile(context)) {
      effectiveWidth = mobileWidth ?? width ?? MediaQuery.of(context).size.width * 0.85;
    } else if (ResponsiveLayout.isTablet(context)) {
      effectiveWidth = tabletWidth ?? width ?? 320;
    } else {
      effectiveWidth = desktopWidth ?? width ?? 360;
    }
    
    // Create the drawer content
    Widget drawerContent;
    
    // Create the list of items
    Widget itemsList;
    
    if (showDividers) {
      final List<Widget> dividedChildren = [];
      
      for (int i = 0; i < children.length; i++) {
        dividedChildren.add(children[i]);
        
        if (i < children.length - 1) {
          dividedChildren.add(Divider(
            color: dividerColor ?? theme.dividerColor,
            thickness: dividerThickness,
            indent: dividerIndent,
            endIndent: dividerEndIndent,
          ));
        }
      }
      
      itemsList = ListView(
        controller: controller,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding ?? EdgeInsets.zero,
        primary: primary,
        children: dividedChildren,
      );
    } else {
      itemsList = ListView(
        controller: controller,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding ?? EdgeInsets.zero,
        primary: primary,
        children: children,
      );
    }
    
    if (showScrollbar) {
      itemsList = Scrollbar(
        controller: controller,
        thickness: 6.0,
        radius: const Radius.circular(10.0),
        child: itemsList,
      );
    }
    
    // Add header and footer if needed
    if (showHeader && header != null || showFooter && footer != null) {
      drawerContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader && header != null) header!,
          Expanded(child: itemsList),
          if (showFooter && footer != null) footer!,
        ],
      );
    } else {
      drawerContent = itemsList;
    }
    
    // Add close button if needed
    if (showCloseButton) {
      drawerContent = Stack(
        children: [
          drawerContent,
          Positioned(
            top: 8,
            right: isEndDrawer ? null : 8,
            left: isEndDrawer ? 8 : null,
            child: closeButton ?? IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ),
        ],
      );
    }
    
    // Create the drawer container
    Widget drawer;
    
    if (animationDuration != null) {
      drawer = AnimatedContainer(
        duration: animationDuration!,
        curve: animationCurve ?? Curves.easeInOut,
        width: effectiveWidth,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.drawerTheme.backgroundColor,
          borderRadius: borderRadius,
          border: showBorder ? Border(
            right: isEndDrawer ? BorderSide.none : BorderSide(
              color: borderColor ?? theme.dividerColor,
              width: borderWidth,
            ),
            left: isEndDrawer ? BorderSide(
              color: borderColor ?? theme.dividerColor,
              width: borderWidth,
            ) : BorderSide.none,
          ) : null,
          boxShadow: showShadow ? (boxShadow ?? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(isEndDrawer ? -2 : 2, 0),
            ),
          ]) : null,
        ),
        clipBehavior: clipBehavior,
        child: drawerContent,
      );
    } else {
      drawer = Container(
        width: effectiveWidth,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.drawerTheme.backgroundColor,
          borderRadius: borderRadius,
          border: showBorder ? Border(
            right: isEndDrawer ? BorderSide.none : BorderSide(
              color: borderColor ?? theme.dividerColor,
              width: borderWidth,
            ),
            left: isEndDrawer ? BorderSide(
              color: borderColor ?? theme.dividerColor,
              width: borderWidth,
            ) : BorderSide.none,
          ) : null,
          boxShadow: showShadow ? (boxShadow ?? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(isEndDrawer ? -2 : 2, 0),
            ),
          ]) : null,
        ),
        clipBehavior: clipBehavior,
        child: drawerContent,
      );
    }
    
    // Add backdrop if needed
    if (showBackdrop) {
      return Stack(
        children: [
          GestureDetector(
            onTap: onBackdropTap ?? () => Navigator.of(context).pop(),
            child: Container(
              color: backdropColor ?? Colors.black.withOpacity(backdropOpacity),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: isEndDrawer ? null : 0,
            right: isEndDrawer ? 0 : null,
            child: drawer,
          ),
        ],
      );
    }
    
    // Return the standard drawer
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: effectiveWidth,
      child: drawer,
    );
  }
}

class AdaptiveNavigationRail extends StatelessWidget {
  final List<NavigationRailDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color? backgroundColor;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final Color? selectedLabelColor;
  final Color? unselectedLabelColor;
  final double? elevation;
  final TextStyle? selectedLabelTextStyle;
  final TextStyle? unselectedLabelTextStyle;
  final double groupAlignment;
  final NavigationRailLabelType labelType;
  final bool useIndicator;
  final Color? indicatorColor;
  final ShapeBorder? indicatorShape;
  final double? width;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final Widget? leading;
  final Widget? trailing;
  final bool extended;
  final bool showOnMobile;
  final bool showOnTablet;
  final bool showOnDesktop;
  final double minWidth;
  final double minExtendedWidth;
  final bool showDivider;
  final Color? dividerColor;
  final double dividerThickness;
  final double dividerIndent;
  final double dividerEndIndent;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final bool showShadow;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;
  final bool enableHapticFeedback;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? itemPadding;
  final double? iconSize;
  final double? selectedIconSize;
  final double? unselectedIconSize;
  final bool showLabels;
  final bool showIcons;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;
  final Duration? animationDuration;
  final Curve? animationCurve;

  const AdaptiveNavigationRail({
    Key? key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.backgroundColor,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.selectedLabelColor,
    this.unselectedLabelColor,
    this.elevation,
    this.selectedLabelTextStyle,
    this.unselectedLabelTextStyle,
    this.groupAlignment = -1.0,
    this.labelType = NavigationRailLabelType.selected,
    this.useIndicator = false,
    this.indicatorColor,
    this.indicatorShape,
    this.width,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.leading,
    this.trailing,
    this.extended = false,
    this.showOnMobile = false,
    this.showOnTablet = true,
    this.showOnDesktop = true,
    this.minWidth = 72.0,
    this.minExtendedWidth = 256.0,
    this.showDivider = false,
    this.dividerColor,
    this.dividerThickness = 1.0,
    this.dividerIndent = 0.0,
    this.dividerEndIndent = 0.0,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.0,
    this.showShadow = false,
    this.boxShadow,
    this.borderRadius,
    this.clipBehavior = Clip.none,
    this.enableHapticFeedback = true,
    this.padding,
    this.itemPadding,
    this.iconSize,
    this.selectedIconSize,
    this.unselectedIconSize,
    this.showLabels = true,
    this.showIcons = true,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = false,
    this.animationDuration,
    this.animationCurve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check if we should show the navigation rail based on device type
    if (ResponsiveLayout.isDesktop(context) && !showOnDesktop) {
      return const SizedBox.shrink();
    }
    
    if (ResponsiveLayout.isTablet(context) && !showOnTablet) {
      return const SizedBox.shrink();
    }
    
    if (ResponsiveLayout.isMobile(context) && !showOnMobile) {
      return const SizedBox.shrink();
    }
    
    // Determine responsive values
    double effectiveWidth;
    
    if (ResponsiveLayout.isMobile(context)) {
      effectiveWidth = mobileWidth ?? width ?? (extended ? minExtendedWidth : minWidth);
    } else if (ResponsiveLayout.isTablet(context)) {
      effectiveWidth = tabletWidth ?? width ?? (extended ? minExtendedWidth : minWidth);
    } else {
      effectiveWidth = desktopWidth ?? width ?? (extended ? minExtendedWidth : minWidth);
    }
    
    // Create the navigation rail
    Widget navigationRail = NavigationRail(
      destinations: destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (enableHapticFeedback) {
          HapticFeedback.selectionClick();
        }
        onDestinationSelected(index);
      },
      backgroundColor: backgroundColor,
      elevation: elevation,
      selectedIconTheme: IconThemeData(
        color: selectedIconColor ?? theme.colorScheme.primary,
        size: selectedIconSize ?? iconSize ?? 24.0,
      ),
      unselectedIconTheme: IconThemeData(
        color: unselectedIconColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
        size: unselectedIconSize ?? iconSize ?? 24.0,
      ),
      selectedLabelTextStyle: selectedLabelTextStyle ?? TextStyle(
        color: selectedLabelColor ?? theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: unselectedLabelTextStyle ?? TextStyle(
        color: unselectedLabelColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      groupAlignment: groupAlignment,
      labelType: showLabels ? labelType : NavigationRailLabelType.none,
      useIndicator: useIndicator,
      indicatorColor: indicatorColor,
      indicatorShape: indicatorShape,
      minWidth: minWidth,
      minExtendedWidth: minExtendedWidth,
      extended: extended,
      leading: leading,
      trailing: trailing,
      padding: padding,
    );
    
    // Add container with decoration if needed
    if (showBorder || showShadow || borderRadius != null || showDivider) {
      Widget container;
      
      if (animationDuration != null) {
        container = AnimatedContainer(
          duration: animationDuration!,
          curve: animationCurve ?? Curves.easeInOut,
          width: effectiveWidth,
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.navigationRailTheme.backgroundColor,
            borderRadius: borderRadius,
            border: showBorder ? Border(
              right: BorderSide(
                color: borderColor ?? theme.dividerColor,
                width: borderWidth,
              ),
            ) : null,
            boxShadow: showShadow ? (boxShadow ?? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(2, 0),
              ),
            ]) : null,
          ),
          clipBehavior: clipBehavior != Clip.none ? clipBehavior : Clip.hardEdge,
          child: navigationRail,
        );
      } else {
        container = Container(
          width: effectiveWidth,
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.navigationRailTheme.backgroundColor,
            borderRadius: borderRadius,
            border: showBorder ? Border(
              right: BorderSide(
                color: borderColor ?? theme.dividerColor,
                width: borderWidth,
              ),
            ) : null,
            boxShadow: showShadow ? (boxShadow ?? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(2, 0),
              ),
            ]) : null,
          ),
          clipBehavior: clipBehavior != Clip.none ? clipBehavior : Clip.hardEdge,
          child: navigationRail,
        );
      }
      
      if (showDivider) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            container,
            VerticalDivider(
              color: dividerColor ?? theme.dividerColor,
              thickness: dividerThickness,
              width: dividerThickness,
              indent: dividerIndent,
              endIndent: dividerEndIndent,
            ),
          ],
        );
      }
      
      return container;
    }
    
    return SizedBox(
      width: effectiveWidth,
      child: navigationRail,
    );
  }
}
