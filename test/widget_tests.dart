import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpay_app/screens/auth/login_screen.dart';
import 'package:mpay_app/screens/auth/register_screen.dart';
import 'package:mpay_app/screens/auth/pin_screen.dart';
import 'package:mpay_app/screens/auth/two_factor_auth_screen.dart';
import 'package:mpay_app/screens/wallet/wallet_screen.dart';
import 'package:mpay_app/screens/wallet/deposit_screen.dart';
import 'package:mpay_app/screens/wallet/withdraw_screen.dart';
import 'package:mpay_app/screens/wallet/transactions_screen.dart';
import 'package:mpay_app/providers/auth_provider.dart';
import 'package:mpay_app/providers/wallet_provider.dart';
import 'package:mpay_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}
class MockAuthProvider extends Mock implements AuthProvider {}
class MockWalletProvider extends Mock implements WalletProvider {}
class MockThemeProvider extends Mock implements ThemeProvider {}

void main() {
  // Setup for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Mock instances
  final mockAuth = MockFirebaseAuth();
  final mockFirestore = MockFirebaseFirestore();
  final mockUser = MockUser();
  final mockAuthProvider = MockAuthProvider();
  final mockWalletProvider = MockWalletProvider();
  final mockThemeProvider = MockThemeProvider();
  
  // Setup default behaviors
  when(mockAuthProvider.isLoading).thenReturn(false);
  when(mockAuthProvider.error).thenReturn(null);
  when(mockAuthProvider.isAuthenticated).thenReturn(false);
  when(mockAuthProvider.isAdmin).thenReturn(false);
  when(mockAuthProvider.isLocked).thenReturn(false);
  
  when(mockWalletProvider.isLoading).thenReturn(false);
  when(mockWalletProvider.error).thenReturn(null);
  when(mockWalletProvider.transactions).thenReturn([]);
  when(mockWalletProvider.walletData).thenReturn({
    'balances': {
      'USDT': 100.0,
      'BTC': 0.001,
      'ETH': 0.01,
      'ShamCash': 500.0,
    }
  });
  
  when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
  when(mockThemeProvider.isDarkMode).thenReturn(false);
  
  // Group tests by screen
  group('Login Screen Tests', () {
    testWidgets('Login Screen UI Elements', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      
      // Verify UI elements
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
      expect(find.byType(ElevatedButton), findsOneWidget); // Login button
      expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    });
    
    testWidgets('Login Form Validation', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      
      // Tap login button without filling form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      // Verify validation errors
      expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);
      expect(find.text('كلمة المرور مطلوبة'), findsOneWidget);
      
      // Fill form with invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, 'password');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      // Verify email validation error
      expect(find.text('البريد الإلكتروني غير صالح'), findsOneWidget);
    });
  });
  
  group('Register Screen Tests', () {
    testWidgets('Register Screen UI Elements', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      
      // Verify UI elements
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(5)); // First name, last name, email, password, confirm password
      expect(find.byType(ElevatedButton), findsOneWidget); // Register button
      expect(find.text('لديك حساب بالفعل؟ تسجيل الدخول'), findsOneWidget);
    });
    
    testWidgets('Password Strength Indicator', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      
      // Enter weak password
      await tester.enterText(find.byKey(const Key('passwordField')), '12345');
      await tester.pump();
      
      // Verify weak password indicator
      expect(find.text('ضعيفة'), findsOneWidget);
      
      // Enter strong password
      await tester.enterText(find.byKey(const Key('passwordField')), 'StrongP@ss123');
      await tester.pump();
      
      // Verify strong password indicator
      expect(find.text('قوية'), findsOneWidget);
    });
  });
  
  group('PIN Screen Tests', () {
    testWidgets('PIN Screen UI Elements', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: PinScreen(isCreating: true),
          ),
        ),
      );
      
      // Verify UI elements
      expect(find.text('إنشاء رمز PIN'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget); // PIN field
      expect(find.byType(ElevatedButton), findsOneWidget); // Confirm button
    });
    
    testWidgets('PIN Validation', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: PinScreen(isCreating: true),
          ),
        ),
      );
      
      // Enter invalid PIN (too short)
      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      // Verify validation error
      expect(find.text('يجب أن يتكون رمز PIN من 4 أرقام'), findsOneWidget);
      
      // Enter invalid PIN (non-numeric)
      await tester.enterText(find.byType(TextFormField), 'abcd');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      // Verify validation error
      expect(find.text('يجب أن يتكون رمز PIN من أرقام فقط'), findsOneWidget);
    });
  });
  
  group('Wallet Screen Tests', () {
    testWidgets('Wallet Screen UI Elements', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<WalletProvider>.value(value: mockWalletProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: WalletScreen(),
          ),
        ),
      );
      
      // Verify UI elements
      expect(find.text('المحفظة'), findsOneWidget);
      expect(find.text('USDT'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('ShamCash'), findsOneWidget);
      expect(find.text('إيداع'), findsOneWidget);
      expect(find.text('سحب'), findsOneWidget);
      expect(find.text('المعاملات الأخيرة'), findsOneWidget);
    });
  });
  
  group('Deposit Screen Tests', () {
    testWidgets('Deposit Screen UI Elements', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<WalletProvider>.value(value: mockWalletProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: DepositScreen(),
          ),
        ),
      );
      
      // Verify UI elements
      expect(find.text('إيداع'), findsOneWidget);
      expect(find.text('اختر طريقة الإيداع'), findsOneWidget);
      expect(find.text('USDT (TRC20)'), findsOneWidget);
      expect(find.text('USDT (ERC20)'), findsOneWidget);
      expect(find.text('Bitcoin (BTC)'), findsOneWidget);
      expect(find.text('Ethereum (ETH)'), findsOneWidget);
      expect(find.text('Sham cash'), findsOneWidget);
    });
    
    testWidgets('Deposit Method Selection', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<WalletProvider>.value(value: mockWalletProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: DepositScreen(),
          ),
        ),
      );
      
      // Select USDT (TRC20)
      await tester.tap(find.text('USDT (TRC20)'));
      await tester.pump();
      
      // Verify wallet address is shown
      expect(find.text('TNeMH7gG6KQW2dBirivmx21UmPmirpCXM7'), findsOneWidget);
      
      // Select Bitcoin (BTC)
      await tester.tap(find.text('Bitcoin (BTC)'));
      await tester.pump();
      
      // Verify wallet address is shown
      expect(find.text('bc1qn5zte2eme8e7ypja7zug3au074cwtlywkpqwaw'), findsOneWidget);
    });
  });
  
  group('Withdraw Screen Tests', () {
    testWidgets('Withdraw Screen UI Elements', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<WalletProvider>.value(value: mockWalletProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: WithdrawScreen(),
          ),
        ),
      );
      
      // Verify UI elements
      expect(find.text('سحب'), findsOneWidget);
      expect(find.text('اختر طريقة السحب'), findsOneWidget);
      expect(find.text('USDT (TRC20)'), findsOneWidget);
      expect(find.text('USDT (ERC20)'), findsOneWidget);
      expect(find.text('Bitcoin (BTC)'), findsOneWidget);
      expect(find.text('Ethereum (ETH)'), findsOneWidget);
      expect(find.text('Sham cash'), findsOneWidget);
      expect(find.text('عنوان المحفظة'), findsOneWidget);
      expect(find.text('المبلغ'), findsOneWidget);
    });
    
    testWidgets('Withdraw Validation', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<WalletProvider>.value(value: mockWalletProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: WithdrawScreen(),
          ),
        ),
      );
      
      // Select USDT (TRC20)
      await tester.tap(find.text('USDT (TRC20)'));
      await tester.pump();
      
      // Tap submit button without filling form
      await tester.tap(find.text('إتمام السحب'));
      await tester.pump();
      
      // Verify validation errors
      expect(find.text('عنوان المحفظة مطلوب'), findsOneWidget);
      expect(find.text('المبلغ مطلوب'), findsOneWidget);
      
      // Enter invalid amount (exceeds balance)
      await tester.enterText(find.byKey(const Key('walletAddressField')), 'TAddress123');
      await tester.enterText(find.byKey(const Key('amountField')), '1000000');
      await tester.tap(find.text('إتمام السحب'));
      await tester.pump();
      
      // Verify validation error
      expect(find.text('المبلغ يتجاوز الرصيد المتاح'), findsOneWidget);
    });
  });
  
  group('Transactions Screen Tests', () {
    // Setup mock transactions
    final mockTransactions = [
      {
        'id': 'tx1',
        'type': 'deposit',
        'method': 'USDT (TRC20)',
        'amount': 100.0,
        'status': 'completed',
        'timestamp': Timestamp.now(),
      },
      {
        'id': 'tx2',
        'type': 'withdrawal',
        'method': 'Bitcoin (BTC)',
        'amount': 0.001,
        'status': 'pending',
        'timestamp': Timestamp.now(),
      },
    ];
    
    setUp(() {
      when(mockWalletProvider.transactions).thenReturn(mockTransactions);
    });
    
    testWidgets('Transactions Screen UI Elements', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<WalletProvider>.value(value: mockWalletProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: TransactionsScreen(),
          ),
        ),
      );
      
      // Verify UI elements
      expect(find.text('المعاملات'), findsOneWidget);
      expect(find.text('تصفية'), findsOneWidget);
      expect(find.text('إيداع'), findsOneWidget);
      expect(find.text('سحب'), findsOneWidget);
      expect(find.text('USDT (TRC20)'), findsOneWidget);
      expect(find.text('Bitcoin (BTC)'), findsOneWidget);
      expect(find.text('مكتمل'), findsOneWidget);
      expect(find.text('قيد الانتظار'), findsOneWidget);
    });
    
    testWidgets('Transaction Filtering', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<WalletProvider>.value(value: mockWalletProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: MaterialApp(
            home: TransactionsScreen(),
          ),
        ),
      );
      
      // Open filter dialog
      await tester.tap(find.text('تصفية'));
      await tester.pumpAndSettle();
      
      // Verify filter options
      expect(find.text('نوع المعاملة'), findsOneWidget);
      expect(find.text('الحالة'), findsOneWidget);
      
      // Select deposit filter
      await tester.tap(find.text('إيداع').first);
      await tester.pumpAndSettle();
      
      // Apply filter
      await tester.tap(find.text('تطبيق'));
      await tester.pumpAndSettle();
      
      // Verify filtered results
      expect(find.text('USDT (TRC20)'), findsOneWidget);
      expect(find.text('Bitcoin (BTC)'), findsNothing);
    });
  });
}
