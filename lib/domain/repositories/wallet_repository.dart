import 'package:mpay_app/domain/entities/wallet/wallet.dart';
import 'package:mpay_app/domain/entities/transaction/transaction.dart';

/// واجهة مستودع المحفظة
/// 
/// تحدد هذه الواجهة العمليات التي يمكن إجراؤها على المحفظة
/// بدون تحديد كيفية تنفيذ هذه العمليات
abstract class WalletRepository {
  /// الحصول على محفظة المستخدم
  Future<Wallet?> getWallet(String userId);
  
  /// تحديث محفظة المستخدم
  Future<bool> updateWallet(Wallet wallet);
  
  /// الحصول على معاملات المستخدم
  Future<List<Transaction>> getTransactions(String userId, {int limit = 10});
  
  /// إضافة معاملة جديدة
  Future<bool> addTransaction(Transaction transaction);
  
  /// تحديث حالة معاملة
  Future<bool> updateTransactionStatus(String transactionId, TransactionStatus status);
  
  /// إيداع رصيد في محفظة المستخدم
  Future<Transaction> deposit(String userId, String currency, double amount, String method);
  
  /// سحب رصيد من محفظة المستخدم
  Future<Transaction?> withdraw(String userId, String currency, double amount, String method);
  
  /// تحويل رصيد بين عملتين
  Future<Transaction?> exchange(String userId, String fromCurrency, String toCurrency, double amount);
}
