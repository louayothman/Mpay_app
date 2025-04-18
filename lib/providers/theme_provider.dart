import 'package:flutter/material.dart';
import 'package:mpay_app/theme/enhanced_theme.dart';
import 'package:mpay_app/theme/theme_manager.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeData get currentTheme => _isDarkMode 
      ? ThemeManager.getDarkTheme() 
      : ThemeManager.getLightTheme();
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}
