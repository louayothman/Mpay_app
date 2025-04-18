import 'package:flutter/material.dart';
import 'package:mpay_app/theme/enhanced_theme.dart';

class ThemeManager {
  // تحسين الوضع الليلي
  static ThemeData getDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: EnhancedTheme.darkPrimaryColor,
      colorScheme: ColorScheme.dark(
        primary: EnhancedTheme.darkPrimaryColor,
        secondary: EnhancedTheme.darkAccentColor,
        surface: EnhancedTheme.darkBackgroundColor,
        background: EnhancedTheme.darkBackgroundColor,
        error: EnhancedTheme.darkErrorColor,
      ),
      scaffoldBackgroundColor: EnhancedTheme.darkBackgroundColor,
      cardColor: EnhancedTheme.darkCardColor,
      dividerColor: EnhancedTheme.darkDividerColor,
      shadowColor: EnhancedTheme.darkShadowColor,
      textTheme: TextTheme(
        headline1: TextStyle(
          color: EnhancedTheme.darkTextPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headline2: TextStyle(
          color: EnhancedTheme.darkTextPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headline3: TextStyle(
          color: EnhancedTheme.darkTextPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        headline4: TextStyle(
          color: EnhancedTheme.darkTextPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        headline5: TextStyle(
          color: EnhancedTheme.darkTextPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        headline6: TextStyle(
          color: EnhancedTheme.darkTextPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        bodyText1: TextStyle(
          color: EnhancedTheme.darkTextPrimaryColor,
          fontSize: 16,
        ),
        bodyText2: TextStyle(
          color: EnhancedTheme.darkTextSecondaryColor,
          fontSize: 14,
        ),
        caption: TextStyle(
          color: EnhancedTheme.darkTextSecondaryColor,
          fontSize: 12,
        ),
      ),
    );
  }

  // تحسين الوضع النهاري
  static ThemeData getLightTheme() {
    return ThemeData.light().copyWith(
      primaryColor: EnhancedTheme.primaryColor,
      colorScheme: ColorScheme.light(
        primary: EnhancedTheme.primaryColor,
        secondary: EnhancedTheme.accentColor,
        surface: EnhancedTheme.backgroundColor,
        background: EnhancedTheme.backgroundColor,
        error: EnhancedTheme.errorColor,
      ),
      scaffoldBackgroundColor: EnhancedTheme.backgroundColor,
      cardColor: EnhancedTheme.cardColor,
      dividerColor: EnhancedTheme.dividerColor,
      shadowColor: EnhancedTheme.shadowColor,
      textTheme: TextTheme(
        headline1: TextStyle(
          color: EnhancedTheme.textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headline2: TextStyle(
          color: EnhancedTheme.textPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headline3: TextStyle(
          color: EnhancedTheme.textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        headline4: TextStyle(
          color: EnhancedTheme.textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        headline5: TextStyle(
          color: EnhancedTheme.textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        headline6: TextStyle(
          color: EnhancedTheme.textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        bodyText1: TextStyle(
          color: EnhancedTheme.textPrimaryColor,
          fontSize: 16,
        ),
        bodyText2: TextStyle(
          color: EnhancedTheme.textSecondaryColor,
          fontSize: 14,
        ),
        caption: TextStyle(
          color: EnhancedTheme.textSecondaryColor,
          fontSize: 12,
        ),
      ),
    );
  }
}
