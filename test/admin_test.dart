import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mpay_app/screens/admin/admin_dashboard_screen.dart';
import 'package:mpay_app/screens/admin/admin_wallet_screen.dart';
import 'package:mpay_app/screens/admin/admin_user_management_screen.dart';
import 'package:mpay_app/screens/admin/admin_transactions_screen.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}

void main() {
  // Setup mocks
  final MockFirebaseFirestore mockFirestore = MockFirebaseFirestore();
  final MockCollectionReference mockUsersCollection = MockCollectionReference();
  final MockCollectionReference mockWalletsCollection = MockCollectionReference();
  final MockCollectionReference mockTransactionsCollection = MockCollectionReference();
  final MockCollectionReference mockAdminWalletCollection = MockCollectionReference();
  final MockDocumentReference mockAdminWalletDoc = MockDocumentReference();
  final MockDocumentSnapshot mockAdminWalletSnapshot = MockDocumentSnapshot();
  final MockQuerySnapshot mockUsersSnapshot = MockQuerySnapshot();
  final MockQuerySnapshot mockTransactionsSnapshot = MockQuerySnapshot();

  setUp(() async {
    // Initialize Firebase for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Setup mock responses
    when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(mockFirestore.collection('wallets')).thenReturn(mockWalletsCollection);
    when(mockFirestore.collection('transactions')).thenReturn(mockTransactionsCollection);
    when(mockFirestore.collection('admin_wallet')).thenReturn(mockAdminWalletCollection);
    
    when(mockAdminWalletCollection.doc('main')).thenReturn(mockAdminWalletDoc);
    when(mockAdminWalletDoc.get()).thenAnswer((_) async => mockAdminWalletSnapshot);
    
    // Mock admin wallet data with large balances
    final adminWalletData = {
      'balances': {
        'USD': 1000000.0,
        'EUR': 850000.0,
        'SYP': 500000000.0,
        'SAR': 3750000.0,
        'AED': 3675000.0,
        'TRY': 30000000.0,
      },
      'depositAddresses': [
        {
          'currency': 'USD',
          'address': 'usd_deposit_address_123',
          'network': 'SWIFT',
        },
        {
          'currency': 'EUR',
          'address': 'eur_deposit_address_456',
          'network': 'SEPA',
        },
        {
          'currency': 'SYP',
          'address': 'syp_deposit_address_789',
          'network': 'Local',
        },
      ],
      'updatedAt': Timestamp.now(),
    };
    
    when(mockAdminWalletSnapshot.data()).thenReturn(adminWalletData);
    when(mockAdminWalletSnapshot.exists).thenReturn(true);
    
    // Mock users data
    when(mockUsersCollection.get()).thenAnswer((_) async => mockUsersSnapshot);
    when(mockUsersCollection.where('status', isEqualTo: any)).thenReturn(mockUsersCollection);
    
    final List<MockDocumentSnapshot> userDocs = [];
    // Add mock user documents here
    
    when(mockUsersSnapshot.docs).thenReturn(userDocs);
    
    // Mock transactions data
    when(mockTransactionsCollection.get()).thenAnswer((_) async => mockTransactionsSnapshot);
    when(mockTransactionsCollection.where('type', isEqualTo: any)).thenReturn(mockTransactionsCollection);
    when(mockTransactionsCollection.where('status', isEqualTo: any)).thenReturn(mockTransactionsCollection);
    when(mockTransactionsCollection.orderBy('timestamp', descending: true)).thenReturn(mockTransactionsCollection);
    when(mockTransactionsCollection.limit(any)).thenReturn(mockTransactionsCollection);
    
    final List<MockDocumentSnapshot> transactionDocs = [];
    // Add mock transaction documents here
    
    when(mockTransactionsSnapshot.docs).thenReturn(transactionDocs);
  });

  group('Admin Dashboard Tests', () {
    testWidgets('Admin dashboard screen renders correctly', (WidgetTester tester) async {
      // Build the admin dashboard screen widget
      await tester.pumpWidget(const MaterialApp(home: AdminDashboardScreen()));
      
      // Verify that the admin dashboard elements are present
      expect(find.text('لوحة تحكم المشرف'), findsOneWidget);
      // Check for statistics cards, wallet balances, and recent transactions
    });
    
    testWidgets('Admin wallet screen renders correctly', (WidgetTester tester) async {
      // Build the admin wallet screen widget
      await tester.pumpWidget(const MaterialApp(home: AdminWalletScreen()));
      
      // Verify that the admin wallet screen elements are present
      expect(find.text('محفظة المشرف'), findsOneWidget);
      // Check for balance cards and deposit addresses
    });
    
    testWidgets('Admin user management screen renders correctly', (WidgetTester tester) async {
      // Build the admin user management screen widget
      await tester.pumpWidget(const MaterialApp(home: AdminUserManagementScreen()));
      
      // Verify that the admin user management screen elements are present
      expect(find.text('إدارة المستخدمين'), findsOneWidget);
      // Check for user list and filter options
    });
    
    testWidgets('Admin transactions screen renders correctly', (WidgetTester tester) async {
      // Build the admin transactions screen widget
      await tester.pumpWidget(const MaterialApp(home: AdminTransactionsScreen()));
      
      // Verify that the admin transactions screen elements are present
      expect(find.text('إدارة المعاملات'), findsOneWidget);
      // Check for transaction list and filter options
    });
    
    test('Admin wallet has large balances', () async {
      // Get admin wallet data
      final adminWalletData = await mockAdminWalletDoc.get();
      final balances = (adminWalletData.data() as Map<String, dynamic>)['balances'] as Map<String, dynamic>;
      
      // Verify large balances
      expect(balances['USD'], equals(1000000.0));
      expect(balances['EUR'], equals(850000.0));
      expect(balances['SYP'], equals(500000000.0));
    });
    
    test('Admin wallet has deposit addresses', () async {
      // Get admin wallet data
      final adminWalletData = await mockAdminWalletDoc.get();
      final depositAddresses = (adminWalletData.data() as Map<String, dynamic>)['depositAddresses'] as List<dynamic>;
      
      // Verify deposit addresses
      expect(depositAddresses.length, equals(3));
      expect(depositAddresses[0]['currency'], equals('USD'));
      expect(depositAddresses[0]['address'], equals('usd_deposit_address_123'));
      expect(depositAddresses[1]['currency'], equals('EUR'));
      expect(depositAddresses[2]['currency'], equals('SYP'));
    });
    
    test('Admin can update user status', () async {
      // Setup mock for user update
      final mockUserDoc = MockDocumentReference();
      when(mockUsersCollection.doc(any)).thenReturn(mockUserDoc);
      when(mockUserDoc.update(any)).thenAnswer((_) async => null);
      
      // Update user status
      final updatedData = {
        'status': 'active',
        'updatedAt': Timestamp.now(),
      };
      
      await mockUserDoc.update(updatedData);
      
      // Verify user was updated
      verify(mockUserDoc.update(updatedData)).called(1);
    });
    
    test('Admin can approve/reject transactions', () async {
      // Setup mock for transaction update
      final mockTransactionDoc = MockDocumentReference();
      when(mockTransactionsCollection.doc(any)).thenReturn(mockTransactionDoc);
      when(mockTransactionDoc.update(any)).thenAnswer((_) async => null);
      
      // Update transaction status
      final updatedData = {
        'status': 'completed',
        'updatedAt': Timestamp.now(),
      };
      
      await mockTransactionDoc.update(updatedData);
      
      // Verify transaction was updated
      verify(mockTransactionDoc.update(updatedData)).called(1);
    });
  });
}
