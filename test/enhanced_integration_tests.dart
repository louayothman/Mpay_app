import 'package:flutter_test/flutter_test.dart';
import 'package:mpay_app/screens/home/home_screen.dart';
import 'package:mpay_app/screens/wallet/wallet_screen.dart';
import 'package:mpay_app/screens/profile/profile_screen.dart';
import 'package:mpay_app/screens/auth/login_screen.dart';
import 'package:mpay_app/screens/auth/register_screen.dart';
import 'package:mpay_app/providers/auth_provider.dart';
import 'package:mpay_app/providers/wallet_provider.dart';
import 'package:mpay_app/providers/state_management.dart';
import 'package:mpay_app/providers/security_provider.dart';
import 'package:mpay_app/widgets/enhanced_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:network_image_mock/network_image_mock.dart';

// إنشاء الموكس للاختبارات
@GenerateMocks([
  AuthProvider,
  WalletProvider,
  WalletStateProvider,
  AuthStateProvider,
  SecurityServiceProvider,
])
void main() {
  group('اختبارات تكامل واجهة المستخدم', () {
    testWidgets('اختبار تنقل شاشة الرئيسية', (WidgetTester tester) async {
      // استخدام mockNetworkImagesFor لتجاوز تحميل الصور من الشبكة
      await mockNetworkImagesFor(() async {
        // إنشاء مزودات وهمية
        final mockAuthProvider = MockAuthProvider();
        final mockWalletProvider = MockWalletProvider();
        final mockWalletStateProvider = MockWalletStateProvider();
        final mockAuthStateProvider = MockAuthStateProvider();
        final mockSecurityProvider = MockSecurityServiceProvider();
        
        // تكوين سلوك المزودات الوهمية
        when(mockAuthStateProvider.isAuthenticated).thenReturn(true);
        when(mockWalletStateProvider.isLoading).thenReturn(false);
        when(mockWalletStateProvider.errorMessage).thenReturn('');
        when(mockWalletStateProvider.supportedCurrencies).thenReturn(['SYP', 'USD', 'EUR']);
        when(mockWalletStateProvider.getBalance(any)).thenReturn(1000.0);
        
        // بناء شجرة الواجهة مع المزودات الوهمية
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
                ChangeNotifierProvider<WalletProvider>.value(value: mockWalletProvider),
                ChangeNotifierProvider<WalletStateProvider>.value(value: mockWalletStateProvider),
                ChangeNotifierProvider<AuthStateProvider>.value(value: mockAuthStateProvider),
                ChangeNotifierProvider<SecurityServiceProvider>.value(value: mockSecurityProvider),
              ],
              child: const HomeScreen(),
            ),
          ),
        );
        
        // التحقق من وجود عناصر الشاشة الرئيسية
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
        
        // النقر على أيقونة المحفظة
        await tester.tap(find.byIcon(Icons.account_balance_wallet));
        await tester.pumpAndSettle();
        
        // التحقق من الانتقال إلى شاشة المحفظة
        expect(find.text('المحفظة'), findsOneWidget);
        
        // النقر على أيقونة الملف الشخصي
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();
        
        // التحقق من الانتقال إلى شاشة الملف الشخصي
        expect(find.text('الملف الشخصي'), findsOneWidget);
        
        // العودة إلى الشاشة الرئيسية
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();
        
        // التحقق من العودة إلى الشاشة الرئيسية
        expect(find.text('الرئيسية'), findsOneWidget);
      });
    });
    
    testWidgets('اختبار تدفق المصادقة', (WidgetTester tester) async {
      // استخدام mockNetworkImagesFor لتجاوز تحميل الصور من الشبكة
      await mockNetworkImagesFor(() async {
        // إنشاء مزودات وهمية
        final mockAuthProvider = MockAuthProvider();
        final mockAuthStateProvider = MockAuthStateProvider();
        
        // تكوين سلوك المزودات الوهمية
        when(mockAuthStateProvider.isAuthenticated).thenReturn(false);
        when(mockAuthStateProvider.isLoading).thenReturn(false);
        
        // بناء شجرة الواجهة مع المزودات الوهمية
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
                ChangeNotifierProvider<AuthStateProvider>.value(value: mockAuthStateProvider),
              ],
              child: const LoginScreen(),
            ),
          ),
        );
        
        // التحقق من وجود عناصر شاشة تسجيل الدخول
        expect(find.text('تسجيل الدخول'), findsOneWidget);
        expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);
        
        // إدخال بيانات تسجيل الدخول
        await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        
        // النقر على زر تسجيل الدخول
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        
        // محاكاة نجاح تسجيل الدخول
        when(mockAuthStateProvider.isAuthenticated).thenReturn(true);
        await tester.pump();
        
        // النقر على رابط إنشاء حساب جديد
        await tester.tap(find.text('إنشاء حساب جديد'));
        await tester.pumpAndSettle();
        
        // التحقق من الانتقال إلى شاشة التسجيل
        expect(find.text('إنشاء حساب'), findsOneWidget);
      });
    });
    
    testWidgets('اختبار شاشة المحفظة', (WidgetTester tester) async {
      // استخدام mockNetworkImagesFor لتجاوز تحميل الصور من الشبكة
      await mockNetworkImagesFor(() async {
        // إنشاء مزودات وهمية
        final mockWalletProvider = MockWalletProvider();
        final mockWalletStateProvider = MockWalletStateProvider();
        
        // تكوين سلوك المزودات الوهمية
        when(mockWalletStateProvider.isLoading).thenReturn(false);
        when(mockWalletStateProvider.errorMessage).thenReturn('');
        when(mockWalletStateProvider.supportedCurrencies).thenReturn(['SYP', 'USD', 'EUR']);
        when(mockWalletStateProvider.getBalance(any)).thenReturn(1000.0);
        when(mockWalletStateProvider.calculateTotalBalanceInUSD()).thenAnswer((_) async => 1500.0);
        when(mockWalletStateProvider.getRecentTransactions()).thenAnswer((_) async => [
          {
            'id': '1',
            'title': 'إيداع',
            'amount': 500.0,
            'date': DateTime.now(),
            'type': 'deposit',
          },
          {
            'id': '2',
            'title': 'سحب',
            'amount': -200.0,
            'date': DateTime.now().subtract(const Duration(days: 1)),
            'type': 'withdrawal',
          },
        ]);
        
        // بناء شجرة الواجهة مع المزودات الوهمية
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<WalletProvider>.value(value: mockWalletProvider),
                ChangeNotifierProvider<WalletStateProvider>.value(value: mockWalletStateProvider),
              ],
              child: const WalletScreen(),
            ),
          ),
        );
        
        // انتظار اكتمال التحميل
        await tester.pump();
        
        // التحقق من وجود عناصر شاشة المحفظة
        expect(find.text('المحفظة'), findsOneWidget);
        expect(find.text('إجمالي الرصيد'), findsOneWidget);
        expect(find.text('المعاملات الأخيرة'), findsOneWidget);
        
        // التحقق من وجود أزرار الإجراءات
        expect(find.text('إيداع'), findsAtLeastNWidgets(1));
        expect(find.text('سحب'), findsAtLeastNWidgets(1));
        
        // النقر على زر التحديث
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();
        
        // محاكاة حالة التحميل
        when(mockWalletStateProvider.isLoading).thenReturn(true);
        await tester.pump();
        
        // التحقق من ظهور مؤشر التحميل
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // محاكاة اكتمال التحميل
        when(mockWalletStateProvider.isLoading).thenReturn(false);
        await tester.pump();
        
        // التحقق من اختفاء مؤشر التحميل
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
    
    testWidgets('اختبار المكونات المحسنة', (WidgetTester tester) async {
      // استخدام mockNetworkImagesFor لتجاوز تحميل الصور من الشبكة
      await mockNetworkImagesFor(() async {
        // بناء شجرة الواجهة مع المكونات المحسنة
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  EnhancedNetworkImage(
                    imageUrl: 'https://example.com/image.jpg',
                    width: 100,
                    height: 100,
                  ),
                  EnhancedButton(
                    text: 'زر محسن',
                    onPressed: null,
                  ),
                  EnhancedTextField(
                    hintText: 'حقل نص محسن',
                  ),
                ],
              ),
            ),
          ),
        );
        
        // التحقق من وجود المكونات المحسنة
        expect(find.byType(EnhancedNetworkImage), findsOneWidget);
        expect(find.byType(EnhancedButton), findsOneWidget);
        expect(find.byType(EnhancedTextField), findsOneWidget);
        
        // التحقق من نص المكونات
        expect(find.text('زر محسن'), findsOneWidget);
        expect(find.text('حقل نص محسن'), findsOneWidget);
      });
    });
  });
  
  group('اختبارات تكامل مزودات الحالة', () {
    testWidgets('اختبار تكامل مزود حالة المحفظة', (WidgetTester tester) async {
      // إنشاء مزود حالة المحفظة
      final walletStateProvider = WalletStateProvider();
      
      // بناء شجرة الواجهة مع مزود حالة المحفظة
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: walletStateProvider,
            child: Builder(
              builder: (context) {
                final provider = Provider.of<WalletStateProvider>(context);
                
                return Scaffold(
                  body: Column(
                    children: [
                      Text('isLoading: ${provider.isLoading}'),
                      Text('errorMessage: ${provider.errorMessage}'),
                      Text('supportedCurrencies: ${provider.supportedCurrencies.join(', ')}'),
                      ElevatedButton(
                        onPressed: () => provider.setLoading(true),
                        child: const Text('تعيين التحميل'),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.setError('خطأ في التحميل'),
                        child: const Text('تعيين الخطأ'),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.refreshWalletData(),
                        child: const Text('تحديث البيانات'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      // التحقق من الحالة الأولية
      expect(find.text('isLoading: false'), findsOneWidget);
      expect(find.text('errorMessage: '), findsOneWidget);
      
      // النقر على زر تعيين التحميل
      await tester.tap(find.text('تعيين التحميل'));
      await tester.pump();
      
      // التحقق من تحديث حالة التحميل
      expect(find.text('isLoading: true'), findsOneWidget);
      
      // النقر على زر تعيين الخطأ
      await tester.tap(find.text('تعيين الخطأ'));
      await tester.pump();
      
      // التحقق من تحديث رسالة الخطأ
      expect(find.text('errorMessage: خطأ في التحميل'), findsOneWidget);
      
      // النقر على زر تحديث البيانات
      await tester.tap(find.text('تحديث البيانات'));
      await tester.pump();
      
      // التحقق من تحديث حالة التحميل مرة أخرى
      expect(find.text('isLoading: true'), findsOneWidget);
    });
    
    testWidgets('اختبار تكامل مزود حالة المصادقة', (WidgetTester tester) async {
      // إنشاء مزود حالة المصادقة
      final authStateProvider = AuthStateProvider();
      
      // بناء شجرة الواجهة مع مزود حالة المصادقة
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: authStateProvider,
            child: Builder(
              builder: (context) {
                final provider = Provider.of<AuthStateProvider>(context);
                
                return Scaffold(
                  body: Column(
                    children: [
                      Text('isAuthenticated: ${provider.isAuthenticated}'),
                      Text('isLoading: ${provider.isLoading}'),
                      Text('errorMessage: ${provider.errorMessage}'),
                      ElevatedButton(
                        onPressed: () => provider.setAuthenticated(true),
                        child: const Text('تسجيل الدخول'),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.setAuthenticated(false),
                        child: const Text('تسجيل الخروج'),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.setLoading(true),
                        child: const Text('تعيين التحميل'),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.setError('خطأ في المصادقة'),
                        child: const Text('تعيين الخطأ'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      // التحقق من الحالة الأولية
      expect(find.text('isAuthenticated: false'), findsOneWidget);
      expect(find.text('isLoading: false'), findsOneWidget);
      expect(find.text('errorMessage: '), findsOneWidget);
      
      // النقر على زر تسجيل الدخول
      await tester.tap(find.text('تسجيل الدخول'));
      await tester.pump();
      
      // التحقق من تحديث حالة المصادقة
      expect(find.text('isAuthenticated: true'), findsOneWidget);
      
      // النقر على زر تعيين التحميل
      await tester.tap(find.text('تعيين التحميل'));
      await tester.pump();
      
      // التحقق من تحديث حالة التحميل
      expect(find.text('isLoading: true'), findsOneWidget);
      
      // النقر على زر تعيين الخطأ
      await tester.tap(find.text('تعيين الخطأ'));
      await tester.pump();
      
      // التحقق من تحديث رسالة الخطأ
      expect(find.text('errorMessage: خطأ في المصادقة'), findsOneWidget);
      
      // النقر على زر تسجيل الخروج
      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pump();
      
      // التحقق من تحديث حالة المصادقة
      expect(find.text('isAuthenticated: false'), findsOneWidget);
    });
  });
  
  group('اختبارات تكامل الأمان', () {
    testWidgets('اختبار تكامل مزود خدمة الأمان', (WidgetTester tester) async {
      // إنشاء مزود خدمة الأمان
      final securityProvider = SecurityServiceProvider();
      
      // بناء شجرة الواجهة مع مزود خدمة الأمان
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: securityProvider,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await Provider.of<SecurityServiceProvider>(context, listen: false)
                              .createSecureClient();
                        },
                        child: const Text('إنشاء عميل HTTP آمن'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await Provider.of<SecurityServiceProvider>(context, listen: false)
                              .generateSecurityHeaders();
                        },
                        child: const Text('توليد رؤوس الأمان'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      // التحقق من وجود الأزرار
      expect(find.text('إنشاء عميل HTTP آمن'), findsOneWidget);
      expect(find.text('توليد رؤوس الأمان'), findsOneWidget);
      
      // النقر على زر إنشاء عميل HTTP آمن
      await tester.tap(find.text('إنشاء عميل HTTP آمن'));
      await tester.pump();
      
      // النقر على زر توليد رؤوس الأمان
      await tester.tap(find.text('توليد رؤوس الأمان'));
      await tester.pump();
      
      // لا يمكن التحقق من النتائج مباشرة، لكن يمكن التأكد من عدم حدوث استثناءات
    });
  });
}
