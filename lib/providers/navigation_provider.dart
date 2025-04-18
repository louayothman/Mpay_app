import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpay_app/router/app_router.dart';
import 'package:mpay_app/providers/state_management.dart';
import 'package:mpay_app/providers/navigation_provider.dart';

/// مزود التنقل
///
/// يوفر وصولاً مركزياً لوظائف التنقل في جميع أنحاء التطبيق
class NavigationProvider extends ChangeNotifier {
  late final AppRouter _appRouter;
  late final GoRouter _router;
  
  NavigationProvider({required AuthStateProvider authStateProvider}) {
    _appRouter = AppRouter(authStateProvider: authStateProvider);
    _router = _appRouter.router;
  }
  
  /// الحصول على جهاز التوجيه
  GoRouter get router => _router;
  
  /// التنقل إلى المسار المحدد
  void navigateTo(String routeName, {Map<String, String>? params, Map<String, dynamic>? queryParams}) {
    _router.goNamed(
      routeName,
      pathParameters: params ?? {},
      queryParameters: queryParams ?? {},
    );
  }
  
  /// التنقل إلى المسار المحدد مع استبدال المسار الحالي
  void replaceTo(String routeName, {Map<String, String>? params, Map<String, dynamic>? queryParams}) {
    _router.replaceNamed(
      routeName,
      pathParameters: params ?? {},
      queryParameters: queryParams ?? {},
    );
  }
  
  /// العودة إلى المسار السابق
  void goBack() {
    if (_router.canPop()) {
      _router.pop();
    } else {
      _router.go('/home');
    }
  }
  
  /// التنقل إلى شاشة تسجيل الدخول
  void navigateToLogin() {
    _router.go('/login');
  }
  
  /// التنقل إلى الشاشة الرئيسية
  void navigateToHome() {
    _router.go('/home');
  }
  
  /// التنقل إلى شاشة المحفظة
  void navigateToWallet() {
    _router.go('/wallet');
  }
  
  /// التنقل إلى شاشة الإيداع
  void navigateToDeposit() {
    _router.go('/wallet/deposit');
  }
  
  /// التنقل إلى شاشة السحب
  void navigateToWithdraw() {
    _router.go('/wallet/withdraw');
  }
  
  /// التنقل إلى شاشة المعاملات
  void navigateToTransactions() {
    _router.go('/wallet/transactions');
  }
  
  /// التنقل إلى شاشة الملف الشخصي
  void navigateToProfile() {
    _router.go('/profile');
  }
  
  /// التنقل إلى شاشة الإعدادات
  void navigateToSettings() {
    _router.go('/home/settings');
  }
  
  /// التنقل إلى شاشة الإشعارات
  void navigateToNotifications() {
    _router.go('/home/notifications');
  }
}
