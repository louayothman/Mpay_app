import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mpay_app/theme/enhanced_theme.dart';

/// A class that manages user preferences and customization options
class UserPreferences {
  static const String _themeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _languageKey = 'language';
  static const String _highContrastKey = 'high_contrast';
  static const String _reducedMotionKey = 'reduced_motion';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _biometricsKey = 'biometrics_enabled';
  static const String _autoLockKey = 'auto_lock_timeout';
  static const String _currencyKey = 'preferred_currency';
  static const String _colorSchemeKey = 'color_scheme';

  /// Get the current theme mode
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.getInt(_themeKey) ?? 0;
    return ThemeMode.values[themeValue];
  }

  /// Set the theme mode
  static Future<bool> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_themeKey, mode.index);
  }

  /// Get the font size scale factor
  static Future<double> getFontSizeScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 1.0;
  }

  /// Set the font size scale factor
  static Future<bool> setFontSizeScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setDouble(_fontSizeKey, scale);
  }

  /// Get the current language code
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'ar';
  }

  /// Set the language code
  static Future<bool> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_languageKey, languageCode);
  }

  /// Check if high contrast mode is enabled
  static Future<bool> isHighContrastEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_highContrastKey) ?? false;
  }

  /// Set high contrast mode
  static Future<bool> setHighContrast(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_highContrastKey, enabled);
  }

  /// Check if reduced motion is enabled
  static Future<bool> isReducedMotionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reducedMotionKey) ?? false;
  }

  /// Set reduced motion
  static Future<bool> setReducedMotion(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_reducedMotionKey, enabled);
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  /// Set notifications enabled
  static Future<bool> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_notificationsKey, enabled);
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricsKey) ?? false;
  }

  /// Set biometric authentication enabled
  static Future<bool> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_biometricsKey, enabled);
  }

  /// Get auto-lock timeout in minutes (0 means disabled)
  static Future<int> getAutoLockTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoLockKey) ?? 5;
  }

  /// Set auto-lock timeout in minutes
  static Future<bool> setAutoLockTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_autoLockKey, minutes);
  }

  /// Get preferred currency
  static Future<String> getPreferredCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? 'SAR';
  }

  /// Set preferred currency
  static Future<bool> setPreferredCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_currencyKey, currencyCode);
  }

  /// Get color scheme index
  static Future<int> getColorScheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_colorSchemeKey) ?? 0;
  }

  /// Set color scheme index
  static Future<bool> setColorScheme(int schemeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_colorSchemeKey, schemeIndex);
  }

  /// Reset all preferences to default values
  static Future<bool> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, ThemeMode.system.index);
    await prefs.setDouble(_fontSizeKey, 1.0);
    await prefs.setString(_languageKey, 'ar');
    await prefs.setBool(_highContrastKey, false);
    await prefs.setBool(_reducedMotionKey, false);
    await prefs.setBool(_notificationsKey, true);
    await prefs.setBool(_biometricsKey, false);
    await prefs.setInt(_autoLockKey, 5);
    await prefs.setString(_currencyKey, 'SAR');
    await prefs.setInt(_colorSchemeKey, 0);
    return true;
  }
}

/// A provider for user preferences that notifies listeners of changes
class UserPreferencesProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSizeScale = 1.0;
  String _language = 'ar';
  bool _highContrast = false;
  bool _reducedMotion = false;
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;
  int _autoLockTimeout = 5;
  String _preferredCurrency = 'SAR';
  int _colorScheme = 0;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  double get fontSizeScale => _fontSizeScale;
  String get language => _language;
  bool get highContrast => _highContrast;
  bool get reducedMotion => _reducedMotion;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get biometricsEnabled => _biometricsEnabled;
  int get autoLockTimeout => _autoLockTimeout;
  String get preferredCurrency => _preferredCurrency;
  int get colorScheme => _colorScheme;
  bool get isLoaded => _isLoaded;

  /// Load all preferences
  Future<void> loadPreferences() async {
    _themeMode = await UserPreferences.getThemeMode();
    _fontSizeScale = await UserPreferences.getFontSizeScale();
    _language = await UserPreferences.getLanguage();
    _highContrast = await UserPreferences.isHighContrastEnabled();
    _reducedMotion = await UserPreferences.isReducedMotionEnabled();
    _notificationsEnabled = await UserPreferences.areNotificationsEnabled();
    _biometricsEnabled = await UserPreferences.isBiometricsEnabled();
    _autoLockTimeout = await UserPreferences.getAutoLockTimeout();
    _preferredCurrency = await UserPreferences.getPreferredCurrency();
    _colorScheme = await UserPreferences.getColorScheme();
    _isLoaded = true;
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await UserPreferences.setThemeMode(mode);
      notifyListeners();
    }
  }

  /// Set font size scale
  Future<void> setFontSizeScale(double scale) async {
    if (_fontSizeScale != scale) {
      _fontSizeScale = scale;
      await UserPreferences.setFontSizeScale(scale);
      notifyListeners();
    }
  }

  /// Set language
  Future<void> setLanguage(String languageCode) async {
    if (_language != languageCode) {
      _language = languageCode;
      await UserPreferences.setLanguage(languageCode);
      notifyListeners();
    }
  }

  /// Set high contrast mode
  Future<void> setHighContrast(bool enabled) async {
    if (_highContrast != enabled) {
      _highContrast = enabled;
      await UserPreferences.setHighContrast(enabled);
      notifyListeners();
    }
  }

  /// Set reduced motion
  Future<void> setReducedMotion(bool enabled) async {
    if (_reducedMotion != enabled) {
      _reducedMotion = enabled;
      await UserPreferences.setReducedMotion(enabled);
      notifyListeners();
    }
  }

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled != enabled) {
      _notificationsEnabled = enabled;
      await UserPreferences.setNotificationsEnabled(enabled);
      notifyListeners();
    }
  }

  /// Set biometric authentication enabled
  Future<void> setBiometricsEnabled(bool enabled) async {
    if (_biometricsEnabled != enabled) {
      _biometricsEnabled = enabled;
      await UserPreferences.setBiometricsEnabled(enabled);
      notifyListeners();
    }
  }

  /// Set auto-lock timeout
  Future<void> setAutoLockTimeout(int minutes) async {
    if (_autoLockTimeout != minutes) {
      _autoLockTimeout = minutes;
      await UserPreferences.setAutoLockTimeout(minutes);
      notifyListeners();
    }
  }

  /// Set preferred currency
  Future<void> setPreferredCurrency(String currencyCode) async {
    if (_preferredCurrency != currencyCode) {
      _preferredCurrency = currencyCode;
      await UserPreferences.setPreferredCurrency(currencyCode);
      notifyListeners();
    }
  }

  /// Set color scheme
  Future<void> setColorScheme(int schemeIndex) async {
    if (_colorScheme != schemeIndex) {
      _colorScheme = schemeIndex;
      await UserPreferences.setColorScheme(schemeIndex);
      notifyListeners();
    }
  }

  /// Reset all preferences to default values
  Future<void> resetToDefaults() async {
    await UserPreferences.resetToDefaults();
    await loadPreferences();
  }
}

/// A widget that provides user preferences to the widget tree
class UserPreferencesProviderWidget extends StatefulWidget {
  final Widget child;

  const UserPreferencesProviderWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _UserPreferencesProviderWidgetState createState() => _UserPreferencesProviderWidgetState();
}

class _UserPreferencesProviderWidgetState extends State<UserPreferencesProviderWidget> {
  final UserPreferencesProvider _preferencesProvider = UserPreferencesProvider();

  @override
  void initState() {
    super.initState();
    _preferencesProvider.loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserPreferencesProvider>.value(
      value: _preferencesProvider,
      child: widget.child,
    );
  }
}

/// A widget that applies user preferences to the app
class UserPreferencesApplier extends StatelessWidget {
  final Widget child;

  const UserPreferencesApplier({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final preferences = Provider.of<UserPreferencesProvider>(context);
    
    if (!preferences.isLoaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: preferences.fontSizeScale,
        highContrast: preferences.highContrast,
        boldText: preferences.fontSizeScale > 1.2,
      ),
      child: AnimatedSwitcher(
        duration: preferences.reducedMotion 
            ? const Duration(milliseconds: 100)
            : const Duration(milliseconds: 300),
        child: Directionality(
          key: ValueKey(preferences.language),
          textDirection: preferences.language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child,
        ),
      ),
    );
  }
}

/// A screen for customizing user preferences
class UserPreferencesScreen extends StatelessWidget {
  const UserPreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final preferences = Provider.of<UserPreferencesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('إعادة ضبط الإعدادات'),
                  content: const Text('هل أنت متأكد من رغبتك في إعادة ضبط جميع الإعدادات إلى القيم الافتراضية؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        preferences.resetToDefaults();
                        Navigator.of(context).pop();
                      },
                      child: const Text('إعادة ضبط'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'إعادة ضبط الإعدادات',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(EnhancedTheme.mediumPadding),
        children: [
          _buildSection(
            context,
            title: 'المظهر',
            children: [
              _buildThemeModeSetting(context, preferences),
              const Divider(),
              _buildColorSchemeSetting(context, preferences),
              const Divider(),
              _buildFontSizeSetting(context, preferences),
            ],
          ),
          const SizedBox(height: EnhancedTheme.mediumSpacing),
          _buildSection(
            context,
            title: 'إمكانية الوصول',
            children: [
              _buildSwitchSetting(
                context,
                title: 'وضع التباين العالي',
                subtitle: 'تحسين التباين للأشخاص الذين يعانون من ضعف البصر',
                value: preferences.highContrast,
                onChanged: (value) => preferences.setHighContrast(value),
                icon: Icons.contrast,
              ),
              const Divider(),
              _buildSwitchSetting(
                context,
                title: 'تقليل الحركة',
                subtitle: 'تقليل الرسوم المتحركة والتأثيرات البصرية',
                value: preferences.reducedMotion,
                onChanged: (value) => preferences.setReducedMotion(value),
                icon: Icons.animation,
              ),
            ],
          ),
          const SizedBox(height: EnhancedTheme.mediumSpacing),
          _buildSection(
            context,
            title: 'اللغة والمنطقة',
            children: [
              _buildLanguageSetting(context, preferences),
              const Divider(),
              _buildCurrencySetting(context, preferences),
            ],
          ),
          const SizedBox(height: EnhancedTheme.mediumSpacing),
          _buildSection(
            context,
            title: 'الأمان والخصوصية',
            children: [
              _buildSwitchSetting(
                context,
                title: 'المصادقة البيومترية',
                subtitle: 'استخدام بصمة الإصبع أو التعرف على الوجه لتسجيل الدخول',
                value: preferences.biometricsEnabled,
                onChanged: (value) => preferences.setBiometricsEnabled(value),
                icon: Icons.fingerprint,
              ),
              const Divider(),
              _buildAutoLockSetting(context, preferences),
            ],
          ),
          const SizedBox(height: EnhancedTheme.mediumSpacing),
          _buildSection(
            context,
            title: 'الإشعارات',
            children: [
              _buildSwitchSetting(
                context,
                title: 'تمكين الإشعارات',
                subtitle: 'تلقي إشعارات حول المعاملات والتحديثات',
                value: preferences.notificationsEnabled,
                onChanged: (value) => preferences.setNotificationsEnabled(value),
                icon: Icons.notifications,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: EnhancedTheme.smallSpacing),
        Card(
          elevation: EnhancedTheme.lowElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EnhancedTheme.mediumBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(EnhancedTheme.smallPadding),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeSetting(BuildContext context, UserPreferencesProvider preferences) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('وضع السمة'),
      subtitle: Text(_getThemeModeText(preferences.themeMode)),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('وضع السمة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('النظام'),
                  value: ThemeMode.system,
                  groupValue: preferences.themeMode,
                  onChanged: (value) {
                    preferences.setThemeMode(value!);
                    Navigator.of(context).pop();
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('فاتح'),
                  value: ThemeMode.light,
                  groupValue: preferences.themeMode,
                  onChanged: (value) {
                    preferences.setThemeMode(value!);
                    Navigator.of(context).pop();
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('داكن'),
                  value: ThemeMode.dark,
                  groupValue: preferences.themeMode,
                  onChanged: (value) {
                    preferences.setThemeMode(value!);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'النظام';
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
    }
  }

  Widget _buildColorSchemeSetting(BuildContext context, UserPreferencesProvider preferences) {
    final colorSchemes = [
      'الأزرق (الافتراضي)',
      'الأخضر',
      'الأرجواني',
      'البرتقالي',
      'الوردي',
    ];

    return ListTile(
      leading: const Icon(Icons.color_lens),
      title: const Text('نظام الألوان'),
      subtitle: Text(colorSchemes[preferences.colorScheme]),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('نظام الألوان'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                colorSchemes.length,
                (index) => RadioListTile<int>(
                  title: Text(colorSchemes[index]),
                  value: index,
                  groupValue: preferences.colorScheme,
                  onChanged: (value) {
                    preferences.setColorScheme(value!);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFontSizeSetting(BuildContext context, UserPreferencesProvider preferences) {
    return ListTile(
      leading: const Icon(Icons.format_size),
      title: const Text('حجم الخط'),
      subtitle: Slider(
        value: preferences.fontSizeScale,
        min: 0.8,
        max: 1.4,
        divisions: 6,
        label: _getFontSizeLabel(preferences.fontSizeScale),
        onChanged: (value) => preferences.setFontSizeScale(value),
      ),
    );
  }

  String _getFontSizeLabel(double scale) {
    if (scale <= 0.8) return 'صغير جداً';
    if (scale <= 0.9) return 'صغير';
    if (scale <= 1.0) return 'عادي';
    if (scale <= 1.1) return 'متوسط';
    if (scale <= 1.2) return 'كبير';
    if (scale <= 1.3) return 'كبير جداً';
    return 'ضخم';
  }

  Widget _buildLanguageSetting(BuildContext context, UserPreferencesProvider preferences) {
    final languages = {
      'ar': 'العربية',
      'en': 'English',
    };

    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('اللغة'),
      subtitle: Text(languages[preferences.language] ?? 'العربية'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('اللغة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: languages.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: preferences.language,
                  onChanged: (value) {
                    preferences.setLanguage(value!);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencySetting(BuildContext context, UserPreferencesProvider preferences) {
    final currencies = {
      'SAR': 'ريال سعودي (SAR)',
      'USD': 'دولار أمريكي (USD)',
      'EUR': 'يورو (EUR)',
      'GBP': 'جنيه إسترليني (GBP)',
      'AED': 'درهم إماراتي (AED)',
    };

    return ListTile(
      leading: const Icon(Icons.attach_money),
      title: const Text('العملة المفضلة'),
      subtitle: Text(currencies[preferences.preferredCurrency] ?? 'ريال سعودي (SAR)'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('العملة المفضلة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: currencies.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: preferences.preferredCurrency,
                  onChanged: (value) {
                    preferences.setPreferredCurrency(value!);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAutoLockSetting(BuildContext context, UserPreferencesProvider preferences) {
    final timeouts = {
      0: 'معطل',
      1: 'دقيقة واحدة',
      5: '5 دقائق',
      10: '10 دقائق',
      15: '15 دقيقة',
      30: '30 دقيقة',
    };

    return ListTile(
      leading: const Icon(Icons.lock_clock),
      title: const Text('القفل التلقائي'),
      subtitle: Text(timeouts[preferences.autoLockTimeout] ?? '5 دقائق'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('القفل التلقائي'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: timeouts.entries.map((entry) {
                return RadioListTile<int>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: preferences.autoLockTimeout,
                  onChanged: (value) {
                    preferences.setAutoLockTimeout(value!);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwitchSetting(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
    );
  }
}
