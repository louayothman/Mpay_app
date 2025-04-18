import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mpay_app/theme/enhanced_theme.dart';
import 'package:mpay_app/providers/theme_provider.dart';
import 'package:mpay_app/providers/auth_provider.dart';
import 'package:mpay_app/providers/wallet_provider.dart';
import 'package:mpay_app/providers/state_management.dart';
import 'package:mpay_app/providers/security_provider.dart';
import 'package:mpay_app/providers/navigation_provider.dart';
import 'package:mpay_app/utils/performance_optimizer.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:async';

void main() async {
  // تهيئة معالج الأخطاء لالتقاط أي أخطاء أثناء بدء التشغيل
  final errorHandler = ErrorHandler();
  errorHandler.initialize();
  
  // تنفيذ التطبيق داخل منطقة محمية لمعالجة الأخطاء
  runZonedGuarded<Future<void>>(() async {
    // الحفاظ على شاشة البداية حتى يتم تحميل التطبيق بالكامل
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    
    // تهيئة وحدة تسجيل الأحداث
    await Logger.initialize();
    await Logger.info('بدء تشغيل التطبيق');
    
    // تعيين الاتجاهات المفضلة - سيتم تحديدها بشكل ديناميكي في _MaterialAppWithRouter
    // لا نقوم بتعيينها هنا لأننا سنتحقق من نوع الجهاز أولاً
    
    // تعيين نمط واجهة النظام - سيتم تحديثه بناءً على السمة المستخدمة
    // سيتم تحديثه في ThemeProvider عند تغيير السمة
    
    // تمكين تحسين الأداء في وضع الإصدار
    if (!kDebugMode) {
      // تحسين رسم الإطارات
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    }
    
    // تهيئة محسن الأداء
    PerformanceOptimizer.initialize();
    
    // تشغيل التطبيق مع هيكل مزود محسن
    runApp(const MyApp());
    
    // إزالة شاشة البداية عند جاهزية التطبيق
    FlutterNativeSplash.remove();
    
    // تنظيف ملفات السجل القديمة
    await Logger.cleanOldLogs();
  }, (error, stack) {
    // معالجة أي أخطاء غير متوقعة أثناء بدء التشغيل
    Logger.error('خطأ غير متوقع أثناء بدء التشغيل', error: error, stackTrace: stack);
    // استخدام الطريقة العامة بدلاً من الطريقة الخاصة
    errorHandler.handleNetworkError(error, stack, endpoint: 'app_startup');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Use more efficient provider implementation
      providers: [
        // Theme provider should be at the top level since it affects the entire app
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          // Lazy loading is false for theme since it's needed immediately
          lazy: false,
        ),
        // Security provider should be initialized early
        ChangeNotifierProvider(
          create: (_) => SecurityServiceProvider(),
          lazy: false,
        ),
        // Auth state provider
        ChangeNotifierProvider(
          create: (_) => AuthStateProvider(),
          lazy: false,
        ),
        // Auth provider can be lazy loaded
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        // Wallet provider can be lazy loaded
        ChangeNotifierProvider(
          create: (_) => WalletProvider(),
        ),
        // Wallet state provider
        ChangeNotifierProvider(
          create: (_) => WalletStateProvider(),
        ),
        // Navigation provider should be created after auth state provider
        ChangeNotifierProxyProvider<AuthStateProvider, NavigationProvider>(
          create: (context) => NavigationProvider(
            authStateProvider: Provider.of<AuthStateProvider>(context, listen: false),
          ),
          update: (context, authStateProvider, previous) => 
            previous ?? NavigationProvider(authStateProvider: authStateProvider),
          lazy: false,
        ),
      ],
      child: const _MaterialAppWithRouter(),
    );
  }
}

// Separate widget to avoid rebuilding the entire app when only the theme changes
class _MaterialAppWithRouter extends StatelessWidget {
  const _MaterialAppWithRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only listen to ThemeProvider changes
    final themeProvider = context.watch<ThemeProvider>();
    final navigationProvider = Provider.of<NavigationProvider>(context);
    
    // تحديد ما إذا كان الجهاز جهاز لوحي
    // سيتم استخدام هذا لتحديد اتجاهات الشاشة المسموح بها
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setDeviceOrientations(context);
      _updateSystemUIStyle(themeProvider.themeMode);
    });
    
    return Directionality(
      textDirection: TextDirection.rtl, // Set text direction for Arabic
      child: MaterialApp.router(
        title: 'Mpay Plus',
        debugShowCheckedModeBanner: false,
        theme: EnhancedTheme.lightTheme,
        darkTheme: EnhancedTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        // Use builder to apply performance optimizations to all routes
        builder: (context, child) {
          // Apply text scaling with improved accessibility
          return MediaQuery(
            // توسيع نطاق التحجيم لتحسين إمكانية الوصول
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale.clamp(0.7, 1.5),
              ),
            ),
            child: child!,
          );
        },
        // Use the router from navigation provider
        routerConfig: navigationProvider.router,
      ),
    );
  }
  
  // تعيين اتجاهات الشاشة بناءً على نوع الجهاز
  void _setDeviceOrientations(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isTablet = mediaQuery.size.shortestSide >= 600;
    
    SystemChrome.setPreferredOrientations(
      isTablet 
        ? DeviceOrientation.values // السماح بجميع الاتجاهات للأجهزة اللوحية
        : [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ], // تقييد الهواتف على الوضع الرأسي فقط
    );
  }
  
  // تحديث نمط واجهة النظام بناءً على السمة المستخدمة
  void _updateSystemUIStyle(ThemeMode themeMode) {
    final isDarkMode = themeMode == ThemeMode.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDarkMode ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
