import 'package:mpay_app/domain/entities/wallet/wallet.dart';
import 'package:mpay_app/domain/entities/transaction/transaction.dart';
import 'package:mpay_app/domain/repositories/wallet_repository.dart';
import 'package:mpay_app/utils/currency_converter.dart';
import 'package:mpay_app/domain/exceptions/transaction_exceptions.dart';

/// حالة استخدام إيداع الرصيد
///
/// تنفذ منطق إيداع الرصيد في محفظة المستخدم
class DepositUseCase {
  final WalletRepository walletRepository;
  final CurrencyConverter _currencyConverter;

  DepositUseCase(this.walletRepository)
      : _currencyConverter = CurrencyConverter(
          apiService: ApiIntegrationService(),
          firebaseService: FirebaseService(),
          errorHandler: ErrorHandler(),
        );

  /// تنفيذ عملية الإيداع
  ///
  /// يقوم بالتحقق من صحة البيانات ثم استدعاء المستودع لإيداع الرصيد
  /// يعيد كائن المعاملة في حالة النجاح، أو يرمي استثناء في حالة الفشل
  Future<Transaction> execute(String userId, String currency, double amount, String method) async {
    try {
      // التحقق من صحة المدخلات
      _validateInputs(userId, currency, amount, method);
      
      // استدعاء المستودع لإيداع الرصيد باستخدام async/await بشكل متسق
      final transaction = await walletRepository.deposit(userId, currency, amount, method);
      
      // التحقق من نجاح العملية
      if (transaction == null) {
        throw TransactionFailedException('فشلت عملية الإيداع لسبب غير معروف');
      }
      
      return transaction;
    } on InvalidInputException catch (e) {
      // إعادة رمي استثناءات المدخلات غير الصالحة
      throw InvalidInputException(e.message);
    } on InsufficientFundsException catch (e) {
      // إعادة رمي استثناءات عدم كفاية الرصيد
      throw InsufficientFundsException(e.message);
    } on TransactionFailedException catch (e) {
      // إعادة رمي استثناءات فشل المعاملة
      throw TransactionFailedException('فشلت عملية الإيداع: ${e.message}');
    } catch (e) {
      // التعامل مع الاستثناءات الأخرى
      throw TransactionFailedException('حدث خطأ غير متوقع أثناء عملية الإيداع: $e');
    }
  }
  
  /// التحقق من صحة المدخلات
  void _validateInputs(String userId, String currency, double amount, String method) {
    // التحقق من صحة معرف المستخدم
    if (userId.isEmpty) {
      throw InvalidInputException('معرف المستخدم مطلوب');
    }
    
    // التحقق من صحة المبلغ
    if (amount <= 0) {
      throw InvalidInputException('المبلغ يجب أن يكون أكبر من صفر');
    }

    // التحقق من الحد الأقصى للإيداع
    final maxDepositAmount = _getMaxDepositAmount(currency);
    if (amount > maxDepositAmount) {
      throw InvalidInputException('المبلغ يتجاوز الحد الأقصى المسموح به للإيداع: $maxDepositAmount $currency');
    }

    // التحقق من صحة العملة
    if (!_isValidCurrency(currency)) {
      throw InvalidInputException('العملة غير مدعومة: $currency');
    }

    // التحقق من صحة طريقة الإيداع
    if (!_isValidDepositMethod(method)) {
      throw InvalidInputException('طريقة الإيداع غير مدعومة: $method');
    }
  }

  /// التحقق من صحة العملة
  bool _isValidCurrency(String currency) {
    return _currencyConverter.isCurrencySupported(currency);
  }

  /// التحقق من صحة طريقة الإيداع
  bool _isValidDepositMethod(String method) {
    return _currencyConverter.isDepositMethodSupported(method);
  }
  
  /// الحصول على الحد الأقصى للإيداع حسب العملة
  double _getMaxDepositAmount(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
      case 'USDT':
        return 10000.0;
      case 'EUR':
        return 8500.0;
      case 'BTC':
        return 0.5;
      case 'ETH':
        return 10.0;
      case 'SYP':
        return 25000000.0;
      case 'TRY':
        return 300000.0;
      case 'SAR':
        return 37500.0;
      case 'AED':
        return 37500.0;
      default:
        return 5000.0; // قيمة افتراضية
    }
  }
}

// إضافة الاستيرادات المطلوبة
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
