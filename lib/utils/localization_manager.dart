import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مدير التوطين
/// 
/// يوفر هذا الصف آليات لدعم تعدد اللغات في التطبيق
/// ويتضمن وظائف لتحميل ملفات الترجمة وتغيير اللغة وترجمة النصوص
class LocalizationManager {
  // نمط Singleton
  static final LocalizationManager _instance = LocalizationManager._internal();
  
  factory LocalizationManager() {
    return _instance;
  }
  
  LocalizationManager._internal();
  
  // اللغة الحالية
  Locale _currentLocale = const Locale('ar');
  
  // اللغات المدعومة
  final List<Locale> _supportedLocales = [
    const Locale('ar'), // العربية
    const Locale('en'), // الإنجليزية
  ];
  
  // مفتاح تخزين اللغة في الإعدادات
  static const String _localeKey = 'app_locale';
  
  // ترجمات اللغات
  final Map<String, Map<String, String>> _localizedValues = {};
  
  // مراقب تغيير اللغة
  final StreamController<Locale> _localeController = StreamController<Locale>.broadcast();
  
  // الحصول على دفق تغيير اللغة
  Stream<Locale> get localeStream => _localeController.stream;
  
  // تهيئة مدير التوطين
  Future<void> initialize() async {
    // تحميل اللغة المحفوظة
    await _loadSavedLocale();
    
    // تحميل ملفات الترجمة
    await _loadTranslations();
  }
  
  // تحميل اللغة المحفوظة
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);
      
      if (savedLocale != null) {
        final localeParts = savedLocale.split('_');
        if (localeParts.isNotEmpty) {
          final languageCode = localeParts[0];
          final countryCode = localeParts.length > 1 ? localeParts[1] : null;
          
          _currentLocale = countryCode != null
              ? Locale(languageCode, countryCode)
              : Locale(languageCode);
        }
      }
    } catch (e) {
      debugPrint('خطأ في تحميل اللغة المحفوظة: $e');
    }
  }
  
  // تحميل ملفات الترجمة
  Future<void> _loadTranslations() async {
    try {
      for (final locale in _supportedLocales) {
        final languageCode = locale.languageCode;
        final jsonString = await rootBundle.loadString('assets/i18n/$languageCode.json');
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        
        _localizedValues[languageCode] = jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل ملفات الترجمة: $e');
    }
  }
  
  // الحصول على اللغة الحالية
  Locale get currentLocale => _currentLocale;
  
  // الحصول على اللغات المدعومة
  List<Locale> get supportedLocales => _supportedLocales;
  
  // تغيير اللغة
  Future<void> changeLocale(Locale newLocale) async {
    // التحقق من أن اللغة مدعومة
    if (!_isLocaleSupported(newLocale)) {
      throw Exception('اللغة غير مدعومة: ${newLocale.languageCode}');
    }
    
    // تحديث اللغة الحالية
    _currentLocale = newLocale;
    
    // حفظ اللغة في الإعدادات
    await _saveLocale(newLocale);
    
    // إرسال إشعار بتغيير اللغة
    _localeController.add(newLocale);
  }
  
  // التحقق من أن اللغة مدعومة
  bool _isLocaleSupported(Locale locale) {
    return _supportedLocales.any((supportedLocale) =>
        supportedLocale.languageCode == locale.languageCode);
  }
  
  // حفظ اللغة في الإعدادات
  Future<void> _saveLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      
      await prefs.setString(_localeKey, localeString);
    } catch (e) {
      debugPrint('خطأ في حفظ اللغة: $e');
    }
  }
  
  // ترجمة نص
  String translate(String key, {Map<String, String>? args}) {
    // الحصول على قيمة الترجمة
    final languageCode = _currentLocale.languageCode;
    final translations = _localizedValues[languageCode];
    
    if (translations == null) {
      return key;
    }
    
    String value = translations[key] ?? key;
    
    // استبدال المتغيرات
    if (args != null) {
      args.forEach((argKey, argValue) {
        value = value.replaceAll('{$argKey}', argValue);
      });
    }
    
    return value;
  }
  
  // الحصول على اتجاه النص
  TextDirection getTextDirection() {
    return _currentLocale.languageCode == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
  
  // الحصول على اسم اللغة
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }
  
  // إضافة لغة مدعومة
  void addSupportedLocale(Locale locale) {
    if (!_isLocaleSupported(locale)) {
      _supportedLocales.add(locale);
    }
  }
  
  // التخلص من الموارد
  void dispose() {
    _localeController.close();
  }
}

/// مندوب التوطين
/// 
/// يوفر هذا الصف واجهة لاستخدام مدير التوطين في التطبيق
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  // الحصول على مثيل من السياق
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  // مندوب التوطين
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  // ترجمة نص
  String translate(String key, {Map<String, String>? args}) {
    return LocalizationManager().translate(key, args: args);
  }
  
  // الحصول على اتجاه النص
  TextDirection getTextDirection() {
    return LocalizationManager().getTextDirection();
  }
}

/// مندوب التوطين
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return LocalizationManager().supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// امتداد للسياق لتسهيل الوصول إلى مدير التوطين
extension LocalizationExtension on BuildContext {
  // ترجمة نص
  String tr(String key, {Map<String, String>? args}) {
    return AppLocalizations.of(this).translate(key, args: args);
  }
  
  // الحصول على اتجاه النص
  TextDirection get textDirection {
    return AppLocalizations.of(this).getTextDirection();
  }
  
  // الحصول على اللغة الحالية
  Locale get currentLocale {
    return LocalizationManager().currentLocale;
  }
}

/// عنصر واجهة مستخدم للتوطين
/// 
/// يوفر هذا العنصر واجهة مستخدم للتوطين تدعم تعدد اللغات
class LocalizedWidget extends StatefulWidget {
  final Widget Function(BuildContext context, AppLocalizations localization) builder;
  
  const LocalizedWidget({
    required this.builder,
    Key? key,
  }) : super(key: key);
  
  @override
  _LocalizedWidgetState createState() => _LocalizedWidgetState();
}

class _LocalizedWidgetState extends State<LocalizedWidget> {
  late StreamSubscription<Locale> _localeSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // الاستماع إلى تغييرات اللغة
    _localeSubscription = LocalizationManager().localeStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, AppLocalizations.of(context));
  }
  
  @override
  void dispose() {
    _localeSubscription.cancel();
    super.dispose();
  }
}
