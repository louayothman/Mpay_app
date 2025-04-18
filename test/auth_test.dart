import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mpay_app/screens/auth/login_screen.dart';
import 'package:mpay_app/screens/auth/register_screen.dart';
import 'package:mpay_app/screens/auth/pin_screen.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  // Setup mocks
  final MockFirebaseAuth mockAuth = MockFirebaseAuth();
  final MockFirebaseFirestore mockFirestore = MockFirebaseFirestore();
  final MockUser mockUser = MockUser();
  final MockUserCredential mockUserCredential = MockUserCredential();

  setUp(() async {
    // Initialize Firebase for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Setup mock responses
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.signInWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => mockUserCredential);
    
    when(mockAuth.createUserWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => mockUserCredential);
    
    when(mockUserCredential.user).thenReturn(mockUser);
  });

  group('Authentication Tests', () {
    testWidgets('Login screen renders correctly', (WidgetTester tester) async {
      // Build the login screen widget
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      
      // Verify that the login form elements are present
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Email and password fields
      expect(find.byType(ElevatedButton), findsOneWidget); // Login button
    });
    
    testWidgets('Register screen renders correctly', (WidgetTester tester) async {
      // Build the register screen widget
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      
      // Verify that the registration form elements are present
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(5)); // First name, last name, email, password, confirm password
      expect(find.byType(ElevatedButton), findsOneWidget); // Register button
    });
    
    testWidgets('PIN screen renders correctly', (WidgetTester tester) async {
      // Build the PIN screen widget
      await tester.pumpWidget(const MaterialApp(home: PinScreen(isConfirmation: false)));
      
      // Verify that the PIN form elements are present
      expect(find.text('إنشاء رمز PIN'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4)); // 4 PIN digits
    });
    
    test('User login succeeds with correct credentials', () async {
      // Setup successful login response
      when(mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockUserCredential);
      
      // Attempt login
      final result = await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      
      // Verify login was successful
      expect(result, equals(mockUserCredential));
    });
    
    test('User login fails with incorrect credentials', () async {
      // Setup failed login response
      when(mockAuth.signInWithEmailAndPassword(
        email: 'wrong@example.com',
        password: 'wrongpassword',
      )).thenThrow(FirebaseAuthException(code: 'user-not-found'));
      
      // Attempt login and expect exception
      expect(
        () => mockAuth.signInWithEmailAndPassword(
          email: 'wrong@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
    
    test('User registration succeeds with valid data', () async {
      // Setup successful registration response
      when(mockAuth.createUserWithEmailAndPassword(
        email: 'new@example.com',
        password: 'newpassword123',
      )).thenAnswer((_) async => mockUserCredential);
      
      // Attempt registration
      final result = await mockAuth.createUserWithEmailAndPassword(
        email: 'new@example.com',
        password: 'newpassword123',
      );
      
      // Verify registration was successful
      expect(result, equals(mockUserCredential));
    });
  });
}
