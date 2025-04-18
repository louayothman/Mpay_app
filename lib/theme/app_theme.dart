import 'package:flutter/material.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Light theme colors
  static const Color primaryColor = Color(0xFF6A1B9A); // Deep Purple 800
  static const Color secondaryColor = Color(0xFF9C27B0); // Purple 500
  static const Color accentColor = Color(0xFFE1BEE7); // Purple 100
  static const Color backgroundColor = Color(0xFFF5F5F5); // Grey 100
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F); // Red 700
  static const Color successColor = Color(0xFF388E3C); // Green 700
  static const Color warningColor = Color(0xFFFFA000); // Amber 700
  static const Color infoColor = Color(0xFF1976D2); // Blue 700
  static const Color textPrimaryColor = Color(0xFF212121); // Grey 900
  static const Color textSecondaryColor = Color(0xFF757575); // Grey 600
  static const Color dividerColor = Color(0xFFBDBDBD); // Grey 400
  static const Color surfaceColor = Colors.white;
  static const Color shadowColor = Color(0x1A000000); // Black 10%

  // Dark theme colors
  static const Color darkPrimaryColor = Color(0xFF9C27B0); // Purple 500
  static const Color darkSecondaryColor = Color(0xFFBA68C8); // Purple 300
  static const Color darkAccentColor = Color(0xFF4A148C); // Purple 900
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkErrorColor = Color(0xFFEF5350); // Red 400
  static const Color darkSuccessColor = Color(0xFF66BB6A); // Green 400
  static const Color darkWarningColor = Color(0xFFFFD54F); // Amber 300
  static const Color darkInfoColor = Color(0xFF42A5F5); // Blue 400
  static const Color darkTextPrimaryColor = Color(0xFFEEEEEE); // Grey 200
  static const Color darkTextSecondaryColor = Color(0xFFBDBDBD); // Grey 400
  static const Color darkDividerColor = Color(0xFF616161); // Grey 700
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkShadowColor = Color(0x52000000); // Black 32%

  // Brand colors
  static const Color mpayBrandPrimary = Color(0xFF6A1B9A); // Deep Purple 800
  static const Color mpayBrandSecondary = Color(0xFF9C27B0); // Purple 500
  static const Color mpayBrandAccent = Color(0xFFE1BEE7); // Purple 100
  static const Color mpayBrandLight = Color(0xFFF3E5F5); // Purple 50
  static const Color mpayBrandDark = Color(0xFF4A148C); // Purple 900

  // Currency colors
  static const Color usdtColor = Color(0xFF26A17B); // USDT Green
  static const Color bitcoinColor = Color(0xFFF7931A); // Bitcoin Orange
  static const Color ethereumColor = Color(0xFF627EEA); // Ethereum Blue
  static const Color shamCashColor = Color(0xFF1E88E5); // Blue 600

  // Font sizes
  static const double fontSizeXXSmall = 10.0;
  static const double fontSizeXSmall = 12.0;
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeXXXLarge = 30.0;
  static const double fontSizeHuge = 36.0;

  // Font weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // Spacing
  static const double spacingXXSmall = 2.0;
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  static const double spacingHuge = 64.0;

  // Border radius
  static const double borderRadiusXSmall = 2.0;
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double borderRadiusXXLarge = 24.0;
  static const double borderRadiusCircular = 100.0;

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationXSmall = 0.5;
  static const double elevationSmall = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationLarge = 4.0;
  static const double elevationXLarge = 8.0;
  static const double elevationXXLarge = 16.0;

  // Animation durations
  static const Duration animationDurationXFast = Duration(milliseconds: 100);
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  static const Duration animationDurationXSlow = Duration(milliseconds: 800);

  // Animation curves
  static const Curve animationCurveStandard = Curves.easeInOut;
  static const Curve animationCurveDecelerate = Curves.easeOutCubic;
  static const Curve animationCurveAccelerate = Curves.easeInCubic;
  static const Curve animationCurveSharp = Curves.easeInOutCubic;
  static const Curve animationCurveBounce = Curves.elasticOut;

  // Icon sizes
  static const double iconSizeXSmall = 16.0;
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  static const double iconSizeXXLarge = 64.0;

  // Button sizes
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;
  static const double buttonHeightXLarge = 56.0;

  // Light theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: textPrimaryColor,
        onSurface: textPrimaryColor,
        onBackground: textPrimaryColor,
        onError: Colors.white,
        brightness: Brightness.light,
        shadow: shadowColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: const CardTheme(
        color: cardColor,
        elevation: elevationMedium,
        margin: EdgeInsets.all(spacingSmall),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusMedium)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: elevationMedium,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightBold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusMedium)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
        minWidth: 88.0,
        height: buttonHeightMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: elevationMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightMedium,
          ),
          minimumSize: const Size(88.0, buttonHeightMedium),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightMedium,
          ),
          minimumSize: const Size(88.0, buttonHeightMedium),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightMedium,
          ),
          minimumSize: const Size(88.0, buttonHeightMedium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: textSecondaryColor),
        hintStyle: const TextStyle(color: textSecondaryColor),
        errorStyle: const TextStyle(
          color: errorColor,
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightMedium,
        ),
        prefixIconColor: textSecondaryColor,
        suffixIconColor: textSecondaryColor,
        helperStyle: const TextStyle(
          color: textSecondaryColor,
          fontSize: fontSizeXSmall,
        ),
        isDense: false,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeHuge,
          fontWeight: fontWeightBold,
          color: textPrimaryColor,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXXXLarge,
          fontWeight: fontWeightBold,
          color: textPrimaryColor,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: fontWeightBold,
          color: textPrimaryColor,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: fontWeightBold,
          color: textPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: fontWeightBold,
          color: textPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightBold,
          color: textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightBold,
          color: textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightMedium,
          color: textPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightMedium,
          color: textPrimaryColor,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightRegular,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightRegular,
          color: textPrimaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightRegular,
          color: textSecondaryColor,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightMedium,
          color: textPrimaryColor,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightMedium,
          color: textPrimaryColor,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: fontSizeXXSmall,
          fontWeight: fontWeightMedium,
          color: textSecondaryColor,
          letterSpacing: 0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1.0,
        space: spacingMedium,
        indent: 0,
        endIndent: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accentColor.withOpacity(0.2),
        disabledColor: dividerColor,
        selectedColor: primaryColor.withOpacity(0.2),
        secondarySelectedColor: secondaryColor.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSmall,
          vertical: spacingXSmall,
        ),
        labelStyle: const TextStyle(color: textPrimaryColor),
        secondaryLabelStyle: const TextStyle(color: textPrimaryColor),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusCircular),
        ),
        side: BorderSide.none,
        elevation: elevationNone,
        pressElevation: elevationSmall,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevationMedium,
        actionTextColor: accentColor,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardColor,
        elevation: elevationLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
        titleTextStyle: const TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightBold,
          color: textPrimaryColor,
        ),
        contentTextStyle: const TextStyle(
          fontSize: fontSizeMedium,
          color: textPrimaryColor,
        ),
        alignment: Alignment.center,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        elevation: elevationLarge,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadiusLarge),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        modalElevation: elevationXLarge,
        modalBackgroundColor: cardColor,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightMedium,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightRegular,
        ),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white, width: 2.0),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.symmetric(
          horizontal: spacingSmall,
          vertical: spacingXSmall,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return dividerColor;
          }
          return primaryColor;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        side: const BorderSide(color: dividerColor, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return dividerColor;
          }
          return primaryColor;
        }),
        overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return primaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return dividerColor;
          } else if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return dividerColor.withOpacity(0.5);
          } else if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return primaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        circularTrackColor: accentColor,
        linearTrackColor: accentColor,
        refreshBackgroundColor: backgroundColor,
        linearMinHeight: 4.0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        elevation: elevationMedium,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: fontSizeXXSmall,
          fontWeight: fontWeightMedium,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSizeXXSmall,
          fontWeight: fontWeightRegular,
        ),
        selectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: primaryColor,
        ),
        unselectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: textSecondaryColor,
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: cardColor,
        selectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: primaryColor,
        ),
        unselectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: textSecondaryColor,
        ),
        selectedLabelTextStyle: TextStyle(
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightMedium,
          color: primaryColor,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightRegular,
          color: textSecondaryColor,
        ),
        elevation: elevationMedium,
        labelType: NavigationRailLabelType.selected,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimaryColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        textStyle: const TextStyle(
          fontSize: fontSizeXSmall,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSmall,
          vertical: spacingXSmall,
        ),
        preferBelow: true,
        verticalOffset: 16.0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: elevationMedium,
        highlightElevation: elevationLarge,
        shape: CircleBorder(),
        sizeConstraints: BoxConstraints.tightFor(
          width: 56.0,
          height: 56.0,
        ),
        smallSizeConstraints: BoxConstraints.tightFor(
          width: 40.0,
          height: 40.0,
        ),
        largeSizeConstraints: BoxConstraints.tightFor(
          width: 96.0,
          height: 96.0,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textPrimaryColor,
        size: iconSizeMedium,
        opacity: 1.0,
      ),
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: iconSizeMedium,
        opacity: 1.0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.3),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: fontSizeXSmall,
        ),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 10.0,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: 20.0,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: cardColor,
        hourMinuteTextColor: textPrimaryColor,
        hourMinuteColor: accentColor.withOpacity(0.2),
        dayPeriodTextColor: textPrimaryColor,
        dayPeriodColor: accentColor.withOpacity(0.2),
        dialHandColor: primaryColor,
        dialBackgroundColor: accentColor.withOpacity(0.2),
        dialTextColor: textPrimaryColor,
        entryModeIconColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: cardColor,
        headerBackgroundColor: primaryColor,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightBold,
          color: Colors.white,
        ),
        headerHelpStyle: const TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightRegular,
          color: Colors.white70,
        ),
        dayStyle: const TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightRegular,
        ),
        yearStyle: const TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightRegular,
        ),
        weekdayStyle: const TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightMedium,
          color: textSecondaryColor,
        ),
        dayBackgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        dayForegroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return textPrimaryColor;
        }),
        yearBackgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        yearForegroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return textPrimaryColor;
        }),
        todayBackgroundColor: MaterialStateProperty.all(Colors.transparent),
        todayForegroundColor: MaterialStateProperty.all(primaryColor),
        todayBorder: BorderSide(color: primaryColor, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
      ),
      bannerTheme: const MaterialBannerThemeData(
        backgroundColor: cardColor,
        contentTextStyle: TextStyle(
          fontSize: fontSizeMedium,
          color: textPrimaryColor,
        ),
        padding: EdgeInsets.all(spacingMedium),
        leadingPadding: EdgeInsets.only(right: spacingMedium),
      ),
      dividerColor: dividerColor,
      disabledColor: dividerColor,
      highlightColor: primaryColor.withOpacity(0.1),
      splashColor: primaryColor.withOpacity(0.1),
      hoverColor: primaryColor.withOpacity(0.05),
      focusColor: primaryColor.withOpacity(0.1),
      shadowColor: shadowColor,
      hintColor: textSecondaryColor,
      unselectedWidgetColor: textSecondaryColor,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Dark theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: darkPrimaryColor,
        secondary: darkSecondaryColor,
        tertiary: darkAccentColor,
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
        error: darkErrorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: darkTextPrimaryColor,
        onSurface: darkTextPrimaryColor,
        onBackground: darkTextPrimaryColor,
        onError: Colors.white,
        brightness: Brightness.dark,
        shadow: darkShadowColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      cardTheme: const CardTheme(
        color: darkCardColor,
        elevation: elevationMedium,
        margin: EdgeInsets.all(spacingSmall),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusMedium)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        elevation: elevationMedium,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightBold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: darkPrimaryColor,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusMedium)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
        minWidth: 88.0,
        height: buttonHeightMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: Colors.white,
          elevation: elevationMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightMedium,
          ),
          minimumSize: const Size(88.0, buttonHeightMedium),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimaryColor,
          side: const BorderSide(color: darkPrimaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightMedium,
          ),
          minimumSize: const Size(88.0, buttonHeightMedium),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkSecondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: fontWeightMedium,
          ),
          minimumSize: const Size(88.0, buttonHeightMedium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: darkDividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: darkDividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: darkPrimaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: darkErrorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: darkErrorColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: darkTextSecondaryColor),
        hintStyle: const TextStyle(color: darkTextSecondaryColor),
        errorStyle: const TextStyle(
          color: darkErrorColor,
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightMedium,
        ),
        prefixIconColor: darkTextSecondaryColor,
        suffixIconColor: darkTextSecondaryColor,
        helperStyle: const TextStyle(
          color: darkTextSecondaryColor,
          fontSize: fontSizeXSmall,
        ),
        isDense: false,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeHuge,
          fontWeight: fontWeightBold,
          color: darkTextPrimaryColor,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXXXLarge,
          fontWeight: fontWeightBold,
          color: darkTextPrimaryColor,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: fontWeightBold,
          color: darkTextPrimaryColor,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: fontWeightBold,
          color: darkTextPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: fontWeightBold,
          color: darkTextPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightBold,
          color: darkTextPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightBold,
          color: darkTextPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightMedium,
          color: darkTextPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightMedium,
          color: darkTextPrimaryColor,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightRegular,
          color: darkTextPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightRegular,
          color: darkTextPrimaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightRegular,
          color: darkTextSecondaryColor,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightMedium,
          color: darkTextPrimaryColor,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightMedium,
          color: darkTextPrimaryColor,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: fontSizeXXSmall,
          fontWeight: fontWeightMedium,
          color: darkTextSecondaryColor,
          letterSpacing: 0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDividerColor,
        thickness: 1.0,
        space: spacingMedium,
        indent: 0,
        endIndent: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkAccentColor.withOpacity(0.2),
        disabledColor: darkDividerColor,
        selectedColor: darkPrimaryColor.withOpacity(0.2),
        secondarySelectedColor: darkSecondaryColor.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSmall,
          vertical: spacingXSmall,
        ),
        labelStyle: const TextStyle(color: darkTextPrimaryColor),
        secondaryLabelStyle: const TextStyle(color: darkTextPrimaryColor),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusCircular),
        ),
        side: BorderSide.none,
        elevation: elevationNone,
        pressElevation: elevationSmall,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkTextPrimaryColor,
        contentTextStyle: const TextStyle(color: darkBackgroundColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevationMedium,
        actionTextColor: darkAccentColor,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkCardColor,
        elevation: elevationLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
        titleTextStyle: const TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightBold,
          color: darkTextPrimaryColor,
        ),
        contentTextStyle: const TextStyle(
          fontSize: fontSizeMedium,
          color: darkTextPrimaryColor,
        ),
        alignment: Alignment.center,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkCardColor,
        elevation: elevationLarge,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadiusLarge),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        modalElevation: elevationXLarge,
        modalBackgroundColor: darkCardColor,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightMedium,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightRegular,
        ),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white, width: 2.0),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.symmetric(
          horizontal: spacingSmall,
          vertical: spacingXSmall,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return darkDividerColor;
          }
          return darkPrimaryColor;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        side: const BorderSide(color: darkDividerColor, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return darkDividerColor;
          }
          return darkPrimaryColor;
        }),
        overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return darkPrimaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return darkDividerColor;
          } else if (states.contains(MaterialState.selected)) {
            return darkPrimaryColor;
          }
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return darkDividerColor.withOpacity(0.5);
          } else if (states.contains(MaterialState.selected)) {
            return darkPrimaryColor.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return darkPrimaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPrimaryColor,
        circularTrackColor: darkAccentColor,
        linearTrackColor: darkAccentColor,
        refreshBackgroundColor: darkBackgroundColor,
        linearMinHeight: 4.0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCardColor,
        selectedItemColor: darkPrimaryColor,
        unselectedItemColor: darkTextSecondaryColor,
        elevation: elevationMedium,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: fontSizeXXSmall,
          fontWeight: fontWeightMedium,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSizeXXSmall,
          fontWeight: fontWeightRegular,
        ),
        selectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: darkPrimaryColor,
        ),
        unselectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: darkTextSecondaryColor,
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: darkCardColor,
        selectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: darkPrimaryColor,
        ),
        unselectedIconTheme: IconThemeData(
          size: iconSizeMedium,
          color: darkTextSecondaryColor,
        ),
        selectedLabelTextStyle: TextStyle(
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightMedium,
          color: darkPrimaryColor,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: fontSizeXSmall,
          fontWeight: fontWeightRegular,
          color: darkTextSecondaryColor,
        ),
        elevation: elevationMedium,
        labelType: NavigationRailLabelType.selected,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkTextPrimaryColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        textStyle: const TextStyle(
          fontSize: fontSizeXSmall,
          color: darkBackgroundColor,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSmall,
          vertical: spacingXSmall,
        ),
        preferBelow: true,
        verticalOffset: 16.0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        elevation: elevationMedium,
        highlightElevation: elevationLarge,
        shape: CircleBorder(),
        sizeConstraints: BoxConstraints.tightFor(
          width: 56.0,
          height: 56.0,
        ),
        smallSizeConstraints: BoxConstraints.tightFor(
          width: 40.0,
          height: 40.0,
        ),
        largeSizeConstraints: BoxConstraints.tightFor(
          width: 96.0,
          height: 96.0,
        ),
      ),
      iconTheme: const IconThemeData(
        color: darkTextPrimaryColor,
        size: iconSizeMedium,
        opacity: 1.0,
      ),
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: iconSizeMedium,
        opacity: 1.0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: darkPrimaryColor,
        inactiveTrackColor: darkPrimaryColor.withOpacity(0.3),
        thumbColor: darkPrimaryColor,
        overlayColor: darkPrimaryColor.withOpacity(0.2),
        valueIndicatorColor: darkPrimaryColor,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: fontSizeXSmall,
        ),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 10.0,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: 20.0,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: darkCardColor,
        hourMinuteTextColor: darkTextPrimaryColor,
        hourMinuteColor: darkAccentColor.withOpacity(0.2),
        dayPeriodTextColor: darkTextPrimaryColor,
        dayPeriodColor: darkAccentColor.withOpacity(0.2),
        dialHandColor: darkPrimaryColor,
        dialBackgroundColor: darkAccentColor.withOpacity(0.2),
        dialTextColor: darkTextPrimaryColor,
        entryModeIconColor: darkPrimaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: darkCardColor,
        headerBackgroundColor: darkPrimaryColor,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightBold,
          color: Colors.white,
        ),
        headerHelpStyle: const TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightRegular,
          color: Colors.white70,
        ),
        dayStyle: const TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightRegular,
        ),
        yearStyle: const TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightRegular,
        ),
        weekdayStyle: const TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightMedium,
          color: darkTextSecondaryColor,
        ),
        dayBackgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return darkPrimaryColor;
          }
          return Colors.transparent;
        }),
        dayForegroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return darkTextPrimaryColor;
        }),
        yearBackgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return darkPrimaryColor;
          }
          return Colors.transparent;
        }),
        yearForegroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return darkTextPrimaryColor;
        }),
        todayBackgroundColor: MaterialStateProperty.all(Colors.transparent),
        todayForegroundColor: MaterialStateProperty.all(darkPrimaryColor),
        todayBorder: BorderSide(color: darkPrimaryColor, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
      ),
      bannerTheme: const MaterialBannerThemeData(
        backgroundColor: darkCardColor,
        contentTextStyle: TextStyle(
          fontSize: fontSizeMedium,
          color: darkTextPrimaryColor,
        ),
        padding: EdgeInsets.all(spacingMedium),
        leadingPadding: EdgeInsets.only(right: spacingMedium),
      ),
      dividerColor: darkDividerColor,
      disabledColor: darkDividerColor,
      highlightColor: darkPrimaryColor.withOpacity(0.1),
      splashColor: darkPrimaryColor.withOpacity(0.1),
      hoverColor: darkPrimaryColor.withOpacity(0.05),
      focusColor: darkPrimaryColor.withOpacity(0.1),
      shadowColor: darkShadowColor,
      hintColor: darkTextSecondaryColor,
      unselectedWidgetColor: darkTextSecondaryColor,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Get adaptive text style based on device size
  static TextStyle getAdaptiveTextStyle(
    BuildContext context, {
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
  }) {
    final deviceType = ResponsiveLayout.isMobile(context)
        ? DeviceType.mobile
        : ResponsiveLayout.isTablet(context)
            ? DeviceType.tablet
            : DeviceType.desktop;

    double adaptiveFontSize = fontSize;
    
    // Adjust font size based on device type
    switch (deviceType) {
      case DeviceType.mobile:
        adaptiveFontSize = fontSize;
        break;
      case DeviceType.tablet:
        adaptiveFontSize = fontSize * 1.1;
        break;
      case DeviceType.desktop:
        adaptiveFontSize = fontSize * 1.2;
        break;
    }

    return TextStyle(
      fontSize: adaptiveFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
    );
  }

  // Get color for specific currency
  static Color getCurrencyColor(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USDT':
        return usdtColor;
      case 'BTC':
        return bitcoinColor;
      case 'ETH':
        return ethereumColor;
      case 'SHAM':
        return shamCashColor;
      default:
        return primaryColor;
    }
  }

  // Get status color
  static Color getStatusColor(String status, {bool isDarkMode = false}) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'approved':
        return isDarkMode ? darkSuccessColor : successColor;
      case 'pending':
      case 'processing':
      case 'waiting':
        return isDarkMode ? darkWarningColor : warningColor;
      case 'failed':
      case 'rejected':
      case 'cancelled':
        return isDarkMode ? darkErrorColor : errorColor;
      case 'info':
      case 'notice':
        return isDarkMode ? darkInfoColor : infoColor;
      default:
        return isDarkMode ? darkTextSecondaryColor : textSecondaryColor;
    }
  }

  // Get adaptive padding based on screen size
  static EdgeInsets getAdaptivePadding(
    BuildContext context, {
    double? horizontal,
    double? vertical,
  }) {
    final deviceType = ResponsiveLayout.isMobile(context)
        ? DeviceType.mobile
        : ResponsiveLayout.isTablet(context)
            ? DeviceType.tablet
            : DeviceType.desktop;
    
    double horizontalPadding = horizontal ?? spacingMedium;
    double verticalPadding = vertical ?? spacingMedium;
    
    switch (deviceType) {
      case DeviceType.mobile:
        // Use provided values
        break;
      case DeviceType.tablet:
        horizontalPadding = horizontal != null ? horizontal * 1.5 : spacingLarge;
        verticalPadding = vertical != null ? vertical * 1.2 : spacingMedium;
        break;
      case DeviceType.desktop:
        horizontalPadding = horizontal != null ? horizontal * 2 : spacingXLarge;
        verticalPadding = vertical != null ? vertical * 1.5 : spacingLarge;
        break;
    }
    
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
  }

  // Get adaptive border radius based on screen size
  static BorderRadius getAdaptiveBorderRadius(
    BuildContext context, {
    double radius = borderRadiusMedium,
  }) {
    final deviceType = ResponsiveLayout.isMobile(context)
        ? DeviceType.mobile
        : ResponsiveLayout.isTablet(context)
            ? DeviceType.tablet
            : DeviceType.desktop;
    
    double adaptiveRadius = radius;
    
    switch (deviceType) {
      case DeviceType.mobile:
        adaptiveRadius = radius;
        break;
      case DeviceType.tablet:
        adaptiveRadius = radius * 1.25;
        break;
      case DeviceType.desktop:
        adaptiveRadius = radius * 1.5;
        break;
    }
    
    return BorderRadius.circular(adaptiveRadius);
  }
}

// Device type enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
}
