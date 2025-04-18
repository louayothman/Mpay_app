import 'package:flutter_test/flutter_test.dart';
import 'package:mpay_app/screens/wallet/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mpay_app/domain/repositories/wallet_repository.dart';
import 'package:mpay_app/domain/entities/wallet/wallet.dart';
import 'package:mpay_app/domain/entities/transaction/transaction.dart';

// إنشاء الموكس للاختبارات
@GenerateMocks([WalletRepository])
void main() {
  group('اختبارات شاشة المحفظة', () {
    late MockWalletRepository mockWalletRepository;
    
    setUp(() {
      mockWalletRepository = MockWalletRepository();
    });
    
    testWidgets('عرض معلومات المحفظة', (WidgetTester tester) async {
      // تجهيز البيانات الوهمية
      final wallet = Wallet(
        id: '1',
        userId: '1',
        balance: 1000.0,
        currency: 'EGP',
        isActive: true,
      );
      
      final transactions = [
        Transaction(
          id: '1',
          walletId: '1',
          amount: 500.0,
          type: TransactionType.deposit,
          status: TransactionStatus.completed,
          timestamp: DateTime(2025, 4, 17),
        ),
        Transaction(
          id: '2',
          walletId: '1',
          amount: 200.0,
          type: TransactionType.withdrawal,
          status: TransactionStatus.completed,
          timestamp: DateTime(2025, 4, 16),
        ),
      ];
      
      // تعيين سلوك الموك
      when(mockWalletRepository.getWallet('1')).thenAnswer((_) async => wallet);
      when(mockWalletRepository.getTransactions('1')).thenAnswer((_) async => transactions);
      
      // بناء الواجهة
      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(
            walletId: '1',
            walletRepository: mockWalletRepository,
          ),
        ),
      );
      
      // انتظار تحميل البيانات
      await tester.pump(const Duration(seconds: 1));
      
      // التحقق من عرض معلومات المحفظة
      expect(find.text('رصيد المحفظة'), findsOneWidget);
      expect(find.text('1000.0 EGP'), findsOneWidget);
      
      // التحقق من عرض المعاملات
      expect(find.text('المعاملات الأخيرة'), findsOneWidget);
      expect(find.text('إيداع'), findsOneWidget);
      expect(find.text('سحب'), findsOneWidget);
      expect(find.text('500.0 EGP'), findsOneWidget);
      expect(find.text('200.0 EGP'), findsOneWidget);
    });
  });
}
