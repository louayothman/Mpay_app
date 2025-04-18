import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced theme class that provides consistent theming across the application
/// with support for accessibility features and responsive design.
class EnhancedTheme {
  // Primary color palette
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryLightColor = Color(0xFF64B5F6);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF03A9F4);
  
  // Semantic colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Light theme colors
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightTextColor = Color(0xFF212121);
  static const Color lightSecondaryTextColor = Color(0xFF757575);
  static const Color lightDividerColor = Color(0xFFE0E0E0);
  
  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Color(0xFFEEEEEE);
  static const Color darkSecondaryTextColor = Color(0xFFAAAAAA);
  static const Color darkDividerColor = Color(0xFF424242);
  
  // High contrast theme colors
  static const Color highContrastBackgroundColor = Colors.black;
  static const Color highContrastSurfaceColor = Color(0xFF121212);
  static const Color highContrastTextColor = Colors.white;
  static const Color highContrastPrimaryColor = Color(0xFF4FC3F7);
  static const Color highContrastErrorColor = Color(0xFFFF8A80);
  
  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  
  // Padding
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double pagePadding = 20.0;
  
  // Border radius
  static const double smallBorderRadius = 4.0;
  static const double mediumBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double extraLargeBorderRadius = 24.0;
  
  // Elevation
  static const double lowElevation = 2.0;
  static const double mediumElevation = 4.0;
  static const double highElevation = 8.0;
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Font family
  static const String fontFamily = 'Cairo';
  
  // Text styles
  static TextStyle get displayStyle => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.4,
    fontFamily: fontFamily,
    height: 1.3,
  );
  
  static TextStyle get headlineStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
    fontFamily: fontFamily,
    height: 1.3,
  );
  
  static TextStyle get titleStyle => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    fontFamily: fontFamily,
    height: 1.3,
  );
  
  static TextStyle get subtitleStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    fontFamily: fontFamily,
    height: 1.3,
  );
  
  static TextStyle get bodyStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    fontFamily: fontFamily,
    height: 1.5,
  );
  
  static TextStyle get buttonStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
    fontFamily: fontFamily,
  );
  
  static TextStyle get captionStyle => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    fontFamily: fontFamily,
    height: 1.5,
  );
  
  /// Get responsive text scale based on screen size
  static double getResponsiveTextScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 0.8;
    if (width < 600) return 1.0;
    if (width < 900) return 1.1;
    return 1.2;
  }
  
  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.all(smallPadding);
    if (width < 600) return const EdgeInsets.all(mediumPadding);
    return const EdgeInsets.all(largePadding);
  }
  
  /// Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLightColor,
        secondary: accentColor,
        surface: lightSurfaceColor,
        background: lightBackgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextColor,
        onBackground: lightTextColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardTheme(
        color: lightSurfaceColor,
        elevation: lowElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: mediumElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          minimumSize: const Size(88, 36),
          textStyle: buttonStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          textStyle: buttonStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          textStyle: buttonStyle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(mediumPadding),
        hintStyle: bodyStyle.copyWith(color: lightSecondaryTextColor),
        errorStyle: captionStyle.copyWith(color: errorColor),
        helperStyle: captionStyle.copyWith(color: lightSecondaryTextColor),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightSecondaryTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: highElevation,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: displayStyle.copyWith(color: lightTextColor),
        headlineMedium: headlineStyle.copyWith(color: lightTextColor),
        titleLarge: titleStyle.copyWith(color: lightTextColor),
        titleMedium: subtitleStyle.copyWith(color: lightTextColor),
        bodyLarge: bodyStyle.copyWith(color: lightTextColor),
        bodyMedium: bodyStyle.copyWith(color: lightSecondaryTextColor),
        labelLarge: buttonStyle.copyWith(color: Colors.white),
        bodySmall: captionStyle.copyWith(color: lightSecondaryTextColor),
      ),
      dividerTheme: const DividerThemeData(
        color: lightDividerColor,
        thickness: 1,
        space: mediumSpacing,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightSurfaceColor,
        contentTextStyle: bodyStyle.copyWith(color: lightTextColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: mediumElevation,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: lightSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(largeBorderRadius),
        ),
        elevation: highElevation,
        titleTextStyle: titleStyle.copyWith(color: lightTextColor),
        contentTextStyle: bodyStyle.copyWith(color: lightTextColor),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: lightTextColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(smallBorderRadius),
        ),
        textStyle: captionStyle.copyWith(color: lightSurfaceColor),
        padding: const EdgeInsets.symmetric(
          horizontal: smallPadding,
          vertical: smallPadding / 2,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return lightSecondaryTextColor.withOpacity(0.5);
          }
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return lightSecondaryTextColor;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallBorderRadius / 2),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return lightSecondaryTextColor.withOpacity(0.5);
          }
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return lightSecondaryTextColor;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return lightSecondaryTextColor.withOpacity(0.5);
          }
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return lightSurfaceColor;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return lightSecondaryTextColor.withOpacity(0.2);
          }
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return lightSecondaryTextColor.withOpacity(0.3);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        circularTrackColor: lightDividerColor,
        linearTrackColor: lightDividerColor,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceColor,
        disabledColor: lightDividerColor,
        selectedColor: primaryLightColor,
        secondarySelectedColor: primaryLightColor,
        padding: const EdgeInsets.symmetric(horizontal: smallPadding, vertical: smallPadding / 2),
        labelStyle: bodyStyle.copyWith(color: lightTextColor),
        secondaryLabelStyle: bodyStyle.copyWith(color: lightTextColor),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          side: const BorderSide(color: lightDividerColor),
        ),
      ),
    );
  }
  
  /// Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        primaryContainer: primaryDarkColor,
        secondary: accentColor,
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextColor,
        onBackground: darkTextColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextColor),
        titleTextStyle: TextStyle(
          color: darkTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurfaceColor,
        elevation: lowElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: mediumElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          minimumSize: const Size(88, 36),
          textStyle: buttonStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          textStyle: buttonStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          textStyle: buttonStyle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(mediumPadding),
        hintStyle: bodyStyle.copyWith(color: darkSecondaryTextColor),
        errorStyle: captionStyle.copyWith(color: errorColor),
        helperStyle: captionStyle.copyWith(color: darkSecondaryTextColor),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkSecondaryTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: highElevation,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: displayStyle.copyWith(color: darkTextColor),
        headlineMedium: headlineStyle.copyWith(color: darkTextColor),
        titleLarge: titleStyle.copyWith(color: darkTextColor),
        titleMedium: subtitleStyle.copyWith(color: darkTextColor),
        bodyLarge: bodyStyle.copyWith(color: darkTextColor),
        bodyMedium: bodyStyle.copyWith(color: darkSecondaryTextColor),
        labelLarge: buttonStyle.copyWith(color: Colors.white),
        bodySmall: captionStyle.copyWith(color: darkSecondaryTextColor),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDividerColor,
        thickness: 1,
        space: mediumSpacing,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceColor,
        contentTextStyle: bodyStyle.copyWith(color: darkTextColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: mediumElevation,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(largeBorderRadius),
        ),
        elevation: highElevation,
        titleTextStyle: titleStyle.copyWith(color: darkTextColor),
        contentTextStyle: bodyStyle.copyWith(color: darkTextColor),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkTextColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(smallBorderRadius),
        ),
        textStyle: captionStyle.copyWith(color: darkSurfaceColor),
        padding: const EdgeInsets.symmetric(
          horizontal: smallPadding,
          vertical: smallPadding / 2,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return darkSecondaryTextColor.withOpacity(0.5);
          }
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return darkSecondaryTextColor;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallBorderRadius / 2),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return darkSecondaryTextColor.withOpacity(0.5);
          }
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return darkSecondaryTextColor;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return darkSecondaryTextColor.withOpacity(0.5);
          }
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return darkSurfaceColor;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return darkSecondaryTextColor.withOpacity(0.2);
          }
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return darkSecondaryTextColor.withOpacity(0.3);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        circularTrackColor: darkDividerColor,
        linearTrackColor: darkDividerColor,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceColor,
        disabledColor: darkDividerColor,
        selectedColor: primaryDarkColor,
        secondarySelectedColor: primaryDarkColor,
        padding: const EdgeInsets.symmetric(horizontal: smallPadding, vertical: smallPadding / 2),
        labelStyle: bodyStyle.copyWith(color: darkTextColor),
        secondaryLabelStyle: bodyStyle.copyWith(color: darkTextColor),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          side: const BorderSide(color: darkDividerColor),
        ),
      ),
    );
  }
  
  /// High contrast theme for accessibility
  static ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: highContrastPrimaryColor,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: highContrastPrimaryColor,
        primaryContainer: highContrastPrimaryColor,
        secondary: highContrastPrimaryColor,
        surface: highContrastSurfaceColor,
        background: highContrastBackgroundColor,
        error: highContrastErrorColor,
        onPrimary: highContrastTextColor,
        onSecondary: highContrastTextColor,
        onSurface: highContrastTextColor,
        onBackground: highContrastTextColor,
        onError: highContrastTextColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: highContrastBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: highContrastSurfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: highContrastTextColor),
        titleTextStyle: TextStyle(
          color: highContrastTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardTheme(
        color: highContrastSurfaceColor,
        elevation: highElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          side: const BorderSide(color: highContrastPrimaryColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: highContrastPrimaryColor,
          foregroundColor: highContrastTextColor,
          elevation: mediumElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumBorderRadius),
            side: const BorderSide(color: highContrastTextColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          minimumSize: const Size(88, 36),
          textStyle: buttonStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: highContrastPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumBorderRadius),
            side: const BorderSide(color: highContrastPrimaryColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          textStyle: buttonStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: highContrastPrimaryColor,
          side: const BorderSide(color: highContrastPrimaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mediumBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding,
            vertical: smallPadding,
          ),
          textStyle: buttonStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: highContrastSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: const BorderSide(color: highContrastTextColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: const BorderSide(color: highContrastTextColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: const BorderSide(color: highContrastPrimaryColor, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumBorderRadius),
          borderSide: const BorderSide(color: highContrastErrorColor, width: 3),
        ),
        contentPadding: const EdgeInsets.all(mediumPadding),
        hintStyle: bodyStyle.copyWith(color: highContrastTextColor.withOpacity(0.7)),
        errorStyle: captionStyle.copyWith(
          color: highContrastErrorColor,
          fontWeight: FontWeight.bold,
        ),
        helperStyle: captionStyle.copyWith(color: highContrastTextColor.withOpacity(0.7)),
        labelStyle: subtitleStyle.copyWith(color: highContrastTextColor),
        floatingLabelStyle: subtitleStyle.copyWith(color: highContrastPrimaryColor),
      ),
      textTheme: TextTheme(
        displayLarge: displayStyle.copyWith(
          color: highContrastTextColor,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: headlineStyle.copyWith(
          color: highContrastTextColor,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: titleStyle.copyWith(
          color: highContrastTextColor,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: subtitleStyle.copyWith(
          color: highContrastTextColor,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: bodyStyle.copyWith(
          color: highContrastTextColor,
          fontSize: 16, // Larger for better readability
        ),
        bodyMedium: bodyStyle.copyWith(
          color: highContrastTextColor,
          fontSize: 16, // Larger for better readability
        ),
        labelLarge: buttonStyle.copyWith(
          color: highContrastTextColor,
          fontWeight: FontWeight.bold,
        ),
        bodySmall: captionStyle.copyWith(
          color: highContrastTextColor,
          fontSize: 14, // Larger for better readability
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: highContrastPrimaryColor,
        thickness: 2,
        space: mediumSpacing,
      ),
      iconTheme: const IconThemeData(
        color: highContrastPrimaryColor,
        size: 24,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return highContrastTextColor.withOpacity(0.5);
          }
          if (states.contains(MaterialState.selected)) {
            return highContrastPrimaryColor;
          }
          return highContrastTextColor;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return highContrastTextColor.withOpacity(0.3);
          }
          if (states.contains(MaterialState.selected)) {
            return highContrastPrimaryColor.withOpacity(0.6);
          }
          return highContrastTextColor.withOpacity(0.5);
        }),
        trackOutlineColor: MaterialStateProperty.all(highContrastTextColor),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return highContrastTextColor.withOpacity(0.5);
          }
          if (states.contains(MaterialState.selected)) {
            return highContrastPrimaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(highContrastTextColor),
        side: const BorderSide(color: highContrastTextColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallBorderRadius / 2),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return highContrastTextColor.withOpacity(0.5);
          }
          if (states.contains(MaterialState.selected)) {
            return highContrastPrimaryColor;
          }
          return highContrastTextColor;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: highContrastPrimaryColor,
        circularTrackColor: highContrastSurfaceColor,
        linearTrackColor: highContrastSurfaceColor,
        refreshBackgroundColor: highContrastSurfaceColor,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: highContrastPrimaryColor,
          borderRadius: BorderRadius.circular(smallBorderRadius),
          border: Border.all(color: highContrastTextColor, width: 1),
        ),
        textStyle: captionStyle.copyWith(
          color: highContrastTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: mediumPadding,
          vertical: smallPadding,
        ),
      ),
    );
  }
  
  /// Get theme based on accessibility preferences
  static ThemeData getThemeByAccessibility(BuildContext context, ThemeMode themeMode) {
    final isHighContrast = MediaQuery.of(context).highContrast;
    
    if (isHighContrast) {
      return highContrastTheme;
    }
    
    switch (themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        return brightness == Brightness.dark ? darkTheme : lightTheme;
    }
  }
}
