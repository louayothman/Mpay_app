import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpay_app/screens/splash/splash_screen.dart';
import 'package:mpay_app/screens/home/home_screen.dart';
import 'package:mpay_app/screens/wallet/wallet_screen.dart';
import 'package:mpay_app/screens/profile/profile_screen.dart';
import 'package:mpay_app/screens/auth/login_screen.dart';
import 'package:mpay_app/screens/auth/register_screen.dart';
import 'package:mpay_app/screens/auth/forgot_password_screen.dart';
import 'package:mpay_app/screens/wallet/deposit_screen.dart';
import 'package:mpay_app/screens/wallet/withdraw_screen.dart';
import 'package:mpay_app/screens/wallet/transactions_screen.dart';
import 'package:mpay_app/screens/settings/settings_screen.dart';
import 'package:mpay_app/screens/notifications/notifications_screen.dart';
import 'package:mpay_app/providers/auth_provider.dart';
import 'package:mpay_app/providers/state_management.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

/// مدير التنقل المركزي للتطبيق
///
/// يستخدم مكتبة go_router لإدارة المسارات وتوفير تنقل أكثر كفاءة وقابلية للاختبار
class AppRouter {
  final AuthStateProvider authStateProvider;
  
  AppRouter({required this.authStateProvider});
  
  /// إنشاء جهاز التوجيه
  GoRouter get router => GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: '/splash',
    refreshListenable: authStateProvider,
    redirect: _handleRedirect,
    routes: [
      // شاشة البداية
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => SplashScreen(
          nextScreen: const HomeScreen(),
        ),
      ),
      
      // مسارات المصادقة
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            name: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
        ],
      ),
      
      // المسارات الرئيسية (تتطلب المصادقة)
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          // الشاشة الرئيسية
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: 'settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          
          // شاشة المحفظة
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) => const WalletScreen(),
            routes: [
              GoRoute(
                path: 'deposit',
                name: 'deposit',
                builder: (context, state) => const DepositScreen(),
              ),
              GoRoute(
                path: 'withdraw',
                name: 'withdraw',
                builder: (context, state) => const WithdrawScreen(),
              ),
              GoRoute(
                path: 'transactions',
                name: 'transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          
          // شاشة الملف الشخصي
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
  
  /// التعامل مع إعادة التوجيه بناءً على حالة المصادقة
  String? _handleRedirect(BuildContext context, GoRouterState state) {
    // السماح بالوصول إلى شاشة البداية دائمًا
    if (state.matchedLocation == '/splash') {
      return null;
    }
    
    // التحقق من حالة المصادقة
    final isAuthenticated = authStateProvider.isAuthenticated;
    final isLoggingIn = state.matchedLocation.startsWith('/login');
    
    // إذا لم يكن المستخدم مصادقًا وليس في شاشة تسجيل الدخول، إعادة التوجيه إلى شاشة تسجيل الدخول
    if (!isAuthenticated && !isLoggingIn) {
      return '/login';
    }
    
    // إذا كان المستخدم مصادقًا وفي شاشة تسجيل الدخول، إعادة التوجيه إلى الشاشة الرئيسية
    if (isAuthenticated && isLoggingIn) {
      return '/home';
    }
    
    // لا حاجة لإعادة التوجيه
    return null;
  }
}

/// شاشة الخطأ
class ErrorScreen extends StatelessWidget {
  final Exception? error;
  
  const ErrorScreen({Key? key, this.error}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خطأ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ غير متوقع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('العودة إلى الشاشة الرئيسية'),
            ),
          ],
        ),
      ),
    );
  }
}

/// هيكل التنقل السفلي
class ScaffoldWithBottomNavBar extends StatefulWidget {
  final Widget child;
  
  const ScaffoldWithBottomNavBar({Key? key, required this.child}) : super(key: key);
  
  @override
  State<ScaffoldWithBottomNavBar> createState() => _ScaffoldWithBottomNavBarState();
}

class _ScaffoldWithBottomNavBarState extends State<ScaffoldWithBottomNavBar> {
  int _currentIndex = 0;
  
  static const List<_NavigationDestination> _destinations = [
    _NavigationDestination(
      route: '/home',
      icon: Icons.home,
      label: 'الرئيسية',
    ),
    _NavigationDestination(
      route: '/wallet',
      icon: Icons.account_balance_wallet,
      label: 'المحفظة',
    ),
    _NavigationDestination(
      route: '/profile',
      icon: Icons.person,
      label: 'الملف الشخصي',
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    // تحديد الفهرس الحالي بناءً على المسار الحالي
    final location = GoRouterState.of(context).matchedLocation;
    _updateCurrentIndex(location);
    
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: _destinations.map((destination) {
          return BottomNavigationBarItem(
            icon: Icon(destination.icon),
            label: destination.label,
          );
        }).toList(),
      ),
    );
  }
  
  void _updateCurrentIndex(String location) {
    for (int i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].route)) {
        if (_currentIndex != i) {
          setState(() {
            _currentIndex = i;
          });
        }
        break;
      }
    }
  }
  
  void _onItemTapped(int index, BuildContext context) {
    // التنقل إلى المسار المحدد
    context.go(_destinations[index].route);
  }
}

/// وجهة التنقل
class _NavigationDestination {
  final String route;
  final IconData icon;
  final String label;
  
  const _NavigationDestination({
    required this.route,
    required this.icon,
    required this.label,
  });
}
