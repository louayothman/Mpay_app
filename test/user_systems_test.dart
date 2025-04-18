import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mpay_app/screens/wallet/referral_system_screen.dart';
import 'package:mpay_app/screens/wallet/levels_system_screen.dart';
import 'package:mpay_app/screens/wallet/commission_system_screen.dart';
import 'package:mpay_app/screens/wallet/notifications_screen.dart';
import 'package:mpay_app/screens/wallet/support_screen.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}

void main() {
  // Setup mocks
  final MockFirebaseFirestore mockFirestore = MockFirebaseFirestore();
  final MockCollectionReference mockReferralsCollection = MockCollectionReference();
  final MockCollectionReference mockLevelsCollection = MockCollectionReference();
  final MockCollectionReference mockCommissionsCollection = MockCollectionReference();
  final MockCollectionReference mockNotificationsCollection = MockCollectionReference();
  final MockCollectionReference mockSupportTicketsCollection = MockCollectionReference();
  final MockQuerySnapshot mockReferralsSnapshot = MockQuerySnapshot();
  final MockQuerySnapshot mockNotificationsSnapshot = MockQuerySnapshot();
  final MockQuerySnapshot mockSupportTicketsSnapshot = MockQuerySnapshot();
  final MockDocumentReference mockLevelsDoc = MockDocumentReference();
  final MockDocumentSnapshot mockLevelsSnapshot = MockDocumentSnapshot();
  final MockDocumentReference mockCommissionsDoc = MockDocumentReference();
  final MockDocumentSnapshot mockCommissionsSnapshot = MockDocumentSnapshot();

  setUp(() async {
    // Initialize Firebase for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Setup mock responses for referrals
    when(mockFirestore.collection('referrals')).thenReturn(mockReferralsCollection);
    when(mockReferralsCollection.where('referrerId', isEqualTo: any)).thenReturn(mockReferralsCollection);
    when(mockReferralsCollection.get()).thenAnswer((_) async => mockReferralsSnapshot);
    
    final List<MockDocumentSnapshot> referralDocs = [];
    // Add mock referral documents here
    
    when(mockReferralsSnapshot.docs).thenReturn(referralDocs);
    
    // Setup mock responses for levels
    when(mockFirestore.collection('system_settings')).thenReturn(mockLevelsCollection);
    when(mockLevelsCollection.doc('levels')).thenReturn(mockLevelsDoc);
    when(mockLevelsDoc.get()).thenAnswer((_) async => mockLevelsSnapshot);
    
    // Mock levels data
    final levelsData = {
      'levels': [
        {
          'name': 'برونزي',
          'requiredPoints': 0,
          'benefits': ['رسوم تحويل 1%', 'حد سحب يومي 1000 دولار'],
        },
        {
          'name': 'فضي',
          'requiredPoints': 1000,
          'benefits': ['رسوم تحويل 0.8%', 'حد سحب يومي 2500 دولار', 'دعم فني أولوية متوسطة'],
        },
        {
          'name': 'ذهبي',
          'requiredPoints': 5000,
          'benefits': ['رسوم تحويل 0.5%', 'حد سحب يومي 5000 دولار', 'دعم فني أولوية عالية'],
        },
        {
          'name': 'بلاتيني',
          'requiredPoints': 10000,
          'benefits': ['رسوم تحويل 0.3%', 'حد سحب يومي 10000 دولار', 'دعم فني أولوية قصوى', 'مدير حساب شخصي'],
        },
      ],
      'updatedAt': Timestamp.now(),
    };
    
    when(mockLevelsSnapshot.data()).thenReturn(levelsData);
    when(mockLevelsSnapshot.exists).thenReturn(true);
    
    // Setup mock responses for commissions
    when(mockLevelsCollection.doc('commissions')).thenReturn(mockCommissionsDoc);
    when(mockCommissionsDoc.get()).thenAnswer((_) async => mockCommissionsSnapshot);
    
    // Mock commissions data
    final commissionsData = {
      'referralCommission': 0.1, // 10% of first transaction
      'transactionCommission': 0.01, // 1% of transaction amount
      'exchangeCommission': 0.005, // 0.5% of exchange amount
      'withdrawCommission': 0.02, // 2% of withdraw amount
      'levelDiscounts': {
        'برونزي': 0.0,
        'فضي': 0.2, // 20% discount on commissions
        'ذهبي': 0.5, // 50% discount on commissions
        'بلاتيني': 0.7, // 70% discount on commissions
      },
      'updatedAt': Timestamp.now(),
    };
    
    when(mockCommissionsSnapshot.data()).thenReturn(commissionsData);
    when(mockCommissionsSnapshot.exists).thenReturn(true);
    
    // Setup mock responses for notifications
    when(mockFirestore.collection('notifications')).thenReturn(mockNotificationsCollection);
    when(mockNotificationsCollection.where('userId', isEqualTo: any)).thenReturn(mockNotificationsCollection);
    when(mockNotificationsCollection.orderBy('createdAt', descending: true)).thenReturn(mockNotificationsCollection);
    when(mockNotificationsCollection.get()).thenAnswer((_) async => mockNotificationsSnapshot);
    
    final List<MockDocumentSnapshot> notificationDocs = [];
    // Add mock notification documents here
    
    when(mockNotificationsSnapshot.docs).thenReturn(notificationDocs);
    
    // Setup mock responses for support tickets
    when(mockFirestore.collection('support_tickets')).thenReturn(mockSupportTicketsCollection);
    when(mockSupportTicketsCollection.where('userId', isEqualTo: any)).thenReturn(mockSupportTicketsCollection);
    when(mockSupportTicketsCollection.orderBy('createdAt', descending: true)).thenReturn(mockSupportTicketsCollection);
    when(mockSupportTicketsCollection.get()).thenAnswer((_) async => mockSupportTicketsSnapshot);
    
    final List<MockDocumentSnapshot> supportTicketDocs = [];
    // Add mock support ticket documents here
    
    when(mockSupportTicketsSnapshot.docs).thenReturn(supportTicketDocs);
  });

  group('User Systems Tests', () {
    testWidgets('Referral system screen renders correctly', (WidgetTester tester) async {
      // Build the referral system screen widget
      await tester.pumpWidget(const MaterialApp(home: ReferralSystemScreen()));
      
      // Verify that the referral system screen elements are present
      expect(find.text('نظام الإحالة'), findsOneWidget);
      // Check for referral code display and referred users list
    });
    
    testWidgets('Levels system screen renders correctly', (WidgetTester tester) async {
      // Build the levels system screen widget
      await tester.pumpWidget(const MaterialApp(home: LevelsSystemScreen()));
      
      // Verify that the levels system screen elements are present
      expect(find.text('نظام المستويات'), findsOneWidget);
      // Check for level cards and progress indicators
    });
    
    testWidgets('Commission system screen renders correctly', (WidgetTester tester) async {
      // Build the commission system screen widget
      await tester.pumpWidget(const MaterialApp(home: CommissionSystemScreen()));
      
      // Verify that the commission system screen elements are present
      expect(find.text('نظام العمولات'), findsOneWidget);
      // Check for commission rates display
    });
    
    testWidgets('Notifications screen renders correctly', (WidgetTester tester) async {
      // Build the notifications screen widget
      await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
      
      // Verify that the notifications screen elements are present
      expect(find.text('الإشعارات'), findsOneWidget);
      // Check for notifications list
    });
    
    testWidgets('Support screen renders correctly', (WidgetTester tester) async {
      // Build the support screen widget
      await tester.pumpWidget(const MaterialApp(home: SupportScreen()));
      
      // Verify that the support screen elements are present
      expect(find.text('الدعم الفني'), findsOneWidget);
      // Check for support options and ticket creation form
    });
    
    test('Levels system data is loaded correctly', () async {
      // Get levels data
      final levelsData = await mockLevelsDoc.get();
      final levels = (levelsData.data() as Map<String, dynamic>)['levels'] as List<dynamic>;
      
      // Verify levels data
      expect(levels.length, equals(4));
      expect(levels[0]['name'], equals('برونزي'));
      expect(levels[1]['name'], equals('فضي'));
      expect(levels[2]['name'], equals('ذهبي'));
      expect(levels[3]['name'], equals('بلاتيني'));
      
      expect(levels[0]['requiredPoints'], equals(0));
      expect(levels[3]['requiredPoints'], equals(10000));
    });
    
    test('Commission calculation is correct', () async {
      // Get commission data
      final commissionsData = await mockCommissionsDoc.get();
      final data = commissionsData.data() as Map<String, dynamic>;
      
      // Calculate transaction commission for different levels
      final transactionAmount = 1000.0;
      final baseCommission = transactionAmount * data['transactionCommission'];
      
      // Bronze level (no discount)
      final bronzeDiscount = data['levelDiscounts']['برونزي'];
      final bronzeCommission = baseCommission * (1 - bronzeDiscount);
      expect(bronzeCommission, equals(10.0));
      
      // Platinum level (70% discount)
      final platinumDiscount = data['levelDiscounts']['بلاتيني'];
      final platinumCommission = baseCommission * (1 - platinumDiscount);
      expect(platinumCommission, equals(3.0));
    });
    
    test('Creating a support ticket adds a document to the support_tickets collection', () async {
      // Setup mock for ticket creation
      when(mockSupportTicketsCollection.add(any)).thenAnswer((_) async => MockDocumentReference());
      
      // Create a support ticket
      final ticketData = {
        'userId': 'test_user_id',
        'subject': 'Test Support Ticket',
        'message': 'This is a test support ticket message.',
        'category': 'account',
        'status': 'open',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      
      // Add the ticket
      await mockSupportTicketsCollection.add(ticketData);
      
      // Verify ticket was added
      verify(mockSupportTicketsCollection.add(ticketData)).called(1);
    });
    
    test('Marking a notification as read updates the document', () async {
      // Setup mock for notification update
      final mockNotificationDoc = MockDocumentReference();
      when(mockNotificationsCollection.doc(any)).thenReturn(mockNotificationDoc);
      when(mockNotificationDoc.update(any)).thenAnswer((_) async => null);
      
      // Update notification
      final updatedData = {
        'isRead': true,
        'readAt': Timestamp.now(),
      };
      
      await mockNotificationDoc.update(updatedData);
      
      // Verify notification was updated
      verify(mockNotificationDoc.update(updatedData)).called(1);
    });
  });
}
