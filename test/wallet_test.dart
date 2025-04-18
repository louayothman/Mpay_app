import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mpay_app/screens/wallet/wallet_screen.dart';
import 'package:mpay_app/screens/wallet/send_screen.dart';
import 'package:mpay_app/screens/wallet/receive_screen.dart';
import 'package:mpay_app/models/data_models.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}

void main() {
  // Setup mocks
  final MockFirebaseFirestore mockFirestore = MockFirebaseFirestore();
  final MockCollectionReference mockWalletsCollection = MockCollectionReference();
  final MockDocumentReference mockWalletDoc = MockDocumentReference();
  final MockDocumentSnapshot mockWalletSnapshot = MockDocumentSnapshot();
  final MockCollectionReference mockTransactionsCollection = MockCollectionReference();
  final MockQuerySnapshot mockTransactionsSnapshot = MockQuerySnapshot();

  setUp(() async {
    // Initialize Firebase for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Setup mock responses
    when(mockFirestore.collection('wallets')).thenReturn(mockWalletsCollection);
    when(mockWalletsCollection.doc(any)).thenReturn(mockWalletDoc);
    when(mockWalletDoc.get()).thenAnswer((_) async => mockWalletSnapshot);
    
    // Mock wallet data
    final walletData = {
      'userId': 'test_user_id',
      'walletId': 'test_wallet_id',
      'balances': {
        'USD': 1000.0,
        'EUR': 850.0,
        'SYP': 500000.0,
        'SAR': 3750.0,
        'AED': 3675.0,
        'TRY': 30000.0,
      },
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
    
    when(mockWalletSnapshot.data()).thenReturn(walletData);
    when(mockWalletSnapshot.exists).thenReturn(true);
    
    // Mock transactions
    when(mockFirestore.collection('transactions')).thenReturn(mockTransactionsCollection);
    when(mockTransactionsCollection.where('userId', isEqualTo: any)).thenReturn(mockTransactionsCollection);
    when(mockTransactionsCollection.orderBy('timestamp', descending: true)).thenReturn(mockTransactionsCollection);
    when(mockTransactionsCollection.limit(any)).thenReturn(mockTransactionsCollection);
    when(mockTransactionsCollection.get()).thenAnswer((_) async => mockTransactionsSnapshot);
    
    final List<MockDocumentSnapshot> transactionDocs = [];
    // Add mock transaction documents here
    
    when(mockTransactionsSnapshot.docs).thenReturn(transactionDocs);
  });

  group('Wallet Tests', () {
    testWidgets('Wallet screen renders correctly', (WidgetTester tester) async {
      // Build the wallet screen widget
      await tester.pumpWidget(const MaterialApp(home: WalletScreen()));
      
      // Verify that the wallet screen elements are present
      expect(find.text('المحفظة'), findsOneWidget);
      // Check for currency cards, QR code, and action buttons
    });
    
    testWidgets('Send screen renders correctly', (WidgetTester tester) async {
      // Build the send screen widget
      await tester.pumpWidget(const MaterialApp(home: SendScreen()));
      
      // Verify that the send screen elements are present
      expect(find.text('إرسال'), findsOneWidget);
      // Check for form fields and buttons
    });
    
    testWidgets('Receive screen renders correctly', (WidgetTester tester) async {
      // Build the receive screen widget
      await tester.pumpWidget(const MaterialApp(home: ReceiveScreen()));
      
      // Verify that the receive screen elements are present
      expect(find.text('استلام'), findsOneWidget);
      // Check for QR code and wallet ID display
    });
    
    test('Wallet balances are loaded correctly', () async {
      // Create a wallet model from mock data
      final walletData = await mockWalletDoc.get();
      final wallet = Wallet.fromMap(walletData.data() as Map<String, dynamic>);
      
      // Verify wallet data
      expect(wallet.walletId, equals('test_wallet_id'));
      expect(wallet.balances['USD'], equals(1000.0));
      expect(wallet.balances['EUR'], equals(850.0));
      expect(wallet.balances['SYP'], equals(500000.0));
    });
    
    test('Send transaction creates a new transaction document', () async {
      // Setup mock for transaction creation
      when(mockTransactionsCollection.add(any)).thenAnswer((_) async => mockWalletDoc);
      
      // Create a transaction
      final transactionData = {
        'userId': 'test_user_id',
        'type': 'transfer',
        'amount': 100.0,
        'currency': 'USD',
        'recipientWalletId': 'recipient_wallet_id',
        'timestamp': Timestamp.now(),
        'status': 'pending',
        'description': 'Test transfer',
      };
      
      // Add the transaction
      await mockTransactionsCollection.add(transactionData);
      
      // Verify transaction was added
      verify(mockTransactionsCollection.add(transactionData)).called(1);
    });
    
    test('Wallet balance updates after transaction', () async {
      // Setup mock for wallet update
      when(mockWalletDoc.update(any)).thenAnswer((_) async => null);
      
      // Update wallet balance
      final updatedBalances = {
        'balances': {
          'USD': 900.0, // Reduced by 100 after send transaction
          'EUR': 850.0,
          'SYP': 500000.0,
          'SAR': 3750.0,
          'AED': 3675.0,
          'TRY': 30000.0,
        },
        'updatedAt': Timestamp.now(),
      };
      
      await mockWalletDoc.update(updatedBalances);
      
      // Verify wallet was updated
      verify(mockWalletDoc.update(updatedBalances)).called(1);
    });
  });
}
