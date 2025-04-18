import 'package:mpay_app/domain/entities/transaction/transaction.dart';
import 'package:mpay_app/domain/repositories/wallet_repository.dart';

/// حالة استخدام الحصول على معاملات المستخدم
///
/// تنفذ منطق الحصول على معاملات المستخدم
class GetTransactionsUseCase {
  final WalletRepository walletRepository;

  GetTransactionsUseCase(this.walletRepository);

  /// تنفيذ عملية الحصول على المعاملات
  ///
  /// يقوم باستدعاء المستودع للحصول على معاملات المستخدم
  /// يمكن تحديد عدد المعاملات المطلوبة من خلال المعامل limit
  Future<List<Transaction>> execute(String userId, {int limit = 10}) async {
    if (userId.isEmpty) {
      throw Exception('معرف المستخدم غير صالح');
    }
    
    if (limit <= 0) {
      throw Exception('عدد المعاملات المطلوبة يجب أن يكون أكبر من صفر');
    }
    
    return await walletRepository.getTransactions(userId, limit: limit);
  }
}
