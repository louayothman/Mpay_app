import 'package:mpay_app/domain/entities/wallet/wallet.dart';
import 'package:mpay_app/domain/repositories/wallet_repository.dart';
import 'package:mpay_app/domain/exceptions/transaction_exceptions.dart';
import 'package:mpay_app/utils/network_connectivity.dart';
import 'package:mpay_app/domain/exceptions/data_exceptions.dart';

/// حالة استخدام الحصول على محفظة المستخدم
///
/// تنفذ منطق الحصول على محفظة المستخدم مع معالجة الاستثناءات المختلفة
class GetWalletUseCase {
  final WalletRepository walletRepository;
  final NetworkConnectivity _networkConnectivity;
  
  // عدد محاولات إعادة المحاولة القصوى
  static const int _maxRetries = 2;
  
  // مدة الانتظار بين المحاولات (بالثواني)
  static const int _retryDelaySeconds = 1;

  GetWalletUseCase(this.walletRepository) : _networkConnectivity = NetworkConnectivity();

  /// تنفيذ عملية الحصول على المحفظة
  ///
  /// يقوم بالتحقق من صحة المدخلات والاتصال بالإنترنت ثم استدعاء المستودع للحصول على محفظة المستخدم
  Future<Wallet> execute(String userId) async {
    try {
      // التحقق من صحة معرف المستخدم
      if (userId.isEmpty) {
        throw InvalidInputException('معرف المستخدم غير صالح');
      }
      
      // التحقق من حالة الاتصال بالإنترنت
      final isConnected = await _networkConnectivity.isConnected();
      if (!isConnected) {
        throw ConnectionException('لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.');
      }
      
      // محاولة الحصول على المحفظة مع إعادة المحاولة في حالة فشل الاتصال
      return await _executeWithRetry(userId);
    } on InvalidInputException catch (e) {
      // إعادة رمي استثناءات المدخلات غير الصالحة
      throw InvalidInputException(e.message);
    } on ConnectionException catch (e) {
      // إعادة رمي استثناءات الاتصال
      throw ConnectionException(e.message);
    } on DataNotFoundException catch (e) {
      // إعادة رمي استثناءات عدم وجود البيانات
      throw DataNotFoundException('لم يتم العثور على المحفظة: ${e.message}');
    } on DataCorruptedException catch (e) {
      // إعادة رمي استثناءات فساد البيانات
      throw DataCorruptedException('البيانات المستلمة تالفة: ${e.message}');
    } catch (e) {
      // التعامل مع الاستثناءات الأخرى
      throw DataAccessException('حدث خطأ غير متوقع أثناء الحصول على المحفظة: $e');
    }
  }
  
  /// تنفيذ الحصول على المحفظة مع إعادة المحاولة في حالة فشل الاتصال
  Future<Wallet> _executeWithRetry(String userId) async {
    int retryCount = 0;
    
    while (true) {
      try {
        // محاولة الحصول على المحفظة
        final wallet = await walletRepository.getWallet(userId);
        
        // التحقق من أن المحفظة ليست فارغة
        if (wallet == null) {
          throw DataNotFoundException('لم يتم العثور على محفظة للمستخدم: $userId');
        }
        
        // التحقق من صحة البيانات المستلمة
        _validateWalletData(wallet);
        
        return wallet;
      } on ConnectionException catch (e) {
        // إعادة المحاولة في حالة فشل الاتصال فقط
        retryCount++;
        
        if (retryCount >= _maxRetries) {
          throw ConnectionException('فشل الاتصال بعد $_maxRetries محاولات: ${e.message}');
        }
        
        // الانتظار قبل إعادة المحاولة
        await Future.delayed(Duration(seconds: _retryDelaySeconds * retryCount));
      }
    }
  }
  
  /// التحقق من صحة بيانات المحفظة المستلمة
  void _validateWalletData(Wallet wallet) {
    // التحقق من وجود معرف المحفظة
    if (wallet.id.isEmpty) {
      throw DataCorruptedException('معرف المحفظة غير صالح');
    }
    
    // التحقق من وجود معرف المستخدم
    if (wallet.userId.isEmpty) {
      throw DataCorruptedException('معرف المستخدم في المحفظة غير صالح');
    }
    
    // التحقق من صحة الأرصدة
    final balances = wallet.balances;
    if (balances == null) {
      throw DataCorruptedException('بيانات الأرصدة غير موجودة');
    }
    
    // التحقق من عدم وجود أرصدة سالبة
    for (final entry in balances.entries) {
      if (entry.value < 0) {
        throw DataCorruptedException('رصيد سالب غير صالح للعملة: ${entry.key}');
      }
    }
  }
}
