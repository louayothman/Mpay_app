import 'package:mpay_app/domain/entities/wallet/wallet.dart';
import 'package:mpay_app/domain/entities/transaction/transaction.dart';
import 'package:mpay_app/domain/repositories/wallet_repository.dart';
import 'package:mpay_app/utils/fee_calculator.dart';
import 'package:mpay_app/utils/currency_converter.dart';
import 'package:mpay_app/domain/exceptions/transaction_exceptions.dart';
import 'package:mpay_app/utils/network_connectivity.dart';

/// حالة استخدام سحب الرصيد
///
/// تنفذ منطق سحب الرصيد من محفظة المستخدم
class WithdrawUseCase {
  final WalletRepository walletRepository;
  final CurrencyConverter _currencyConverter;
  final FeeCalculator _feeCalculator;
  final NetworkConnectivity _networkConnectivity;

  WithdrawUseCase(this.walletRepository)
      : _currencyConverter = CurrencyConverter(
          apiService: ApiIntegrationService(),
          firebaseService: FirebaseService(),
          errorHandler: ErrorHandler(),
        ),
        _feeCalculator = FeeCalculator(),
        _networkConnectivity = NetworkConnectivity();

  /// تنفيذ عملية السحب
  ///
  /// يقوم بالتحقق من صحة البيانات ثم استدعاء المستودع لسحب الرصيد
  Future<Transaction> execute(String userId, String currency, double amount, String method) async {
    try {
      // التحقق من حالة الاتصال بالإنترنت
      final isConnected = await _networkConnectivity.isConnected();
      if (!isConnected) {
        throw ConnectionException('لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.');
      }
      
      // التحقق من صحة المدخلات
      _validateInputs(userId, currency, amount, method);
      
      // حساب الرسوم باستخدام رسوم المعاملات الحالية من محول العملات
      final feePercentage = _currencyConverter.getTransactionFee(currency);
      final fees = _feeCalculator.calculateWithdrawalFees(amount, currency, feePercentage);
      final totalAmount = amount + fees;

      // الحصول على محفظة المستخدم للتحقق من الرصيد
      final wallet = await walletRepository.getWallet(userId);
      if (wallet == null) {
        throw TransactionFailedException('لم يتم العثور على المحفظة');
      }

      // التحقق من كفاية الرصيد (مع أخذ الرسوم في الاعتبار)
      if (wallet.getBalance(currency) < totalAmount) {
        throw InsufficientFundsException(
          'الرصيد غير كافٍ. المبلغ المطلوب مع الرسوم: $totalAmount $currency، الرصيد المتاح: ${wallet.getBalance(currency)} $currency'
        );
      }

      // التحقق من عدم تجاوز الحد اليومي للسحب
      final dailyLimit = _getDailyWithdrawalLimit(currency);
      final todayWithdrawals = await walletRepository.getTodayWithdrawals(userId, currency);
      
      if (todayWithdrawals + amount > dailyLimit) {
        throw LimitExceededException(
          'تم تجاوز الحد اليومي للسحب',
          limit: dailyLimit,
          currency: currency
        );
      }

      // استدعاء المستودع لسحب الرصيد
      final transaction = await walletRepository.withdraw(userId, currency, amount, method, fees);
      
      // التحقق من نجاح العملية
      if (transaction == null) {
        throw TransactionFailedException('فشلت عملية السحب لسبب غير معروف');
      }
      
      return transaction;
    } on InvalidInputException catch (e) {
      // إعادة رمي استثناءات المدخلات غير الصالحة
      throw InvalidInputException(e.message);
    } on InsufficientFundsException catch (e) {
      // إعادة رمي استثناءات عدم كفاية الرصيد
      throw InsufficientFundsException(e.message);
    } on LimitExceededException catch (e) {
      // إعادة رمي استثناءات تجاوز الحد
      throw LimitExceededException(
        e.message,
        limit: e.limit,
        currency: e.currency
      );
    } on ConnectionException catch (e) {
      // إعادة رمي استثناءات الاتصال
      throw ConnectionException(e.message);
    } on TransactionFailedException catch (e) {
      // إعادة رمي استثناءات فشل المعاملة
      throw TransactionFailedException('فشلت عملية السحب: ${e.message}');
    } catch (e) {
      // التعامل مع الاستثناءات الأخرى
      throw TransactionFailedException('حدث خطأ غير متوقع أثناء عملية السحب: $e');
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
    
    // التحقق من الحد الأدنى للسحب
    final minWithdrawalAmount = _getMinWithdrawalAmount(currency);
    if (amount < minWithdrawalAmount) {
      throw InvalidInputException('المبلغ أقل من الحد الأدنى المسموح به للسحب: $minWithdrawalAmount $currency');
    }

    // التحقق من الحد الأقصى للسحب
    final maxWithdrawalAmount = _getMaxWithdrawalAmount(currency);
    if (amount > maxWithdrawalAmount) {
      throw InvalidInputException('المبلغ يتجاوز الحد الأقصى المسموح به للسحب: $maxWithdrawalAmount $currency');
    }

    // التحقق من صحة العملة
    if (!_isValidCurrency(currency)) {
      throw UnsupportedCurrencyException('العملة غير مدعومة', currency: currency);
    }

    // التحقق من صحة طريقة السحب
    if (!_isValidWithdrawalMethod(method, currency)) {
      throw UnsupportedPaymentMethodException('طريقة السحب غير مدعومة للعملة المحددة', method: method);
    }
  }

  /// التحقق من صحة العملة
  bool _isValidCurrency(String currency) {
    return _currencyConverter.isCurrencySupported(currency);
  }
  
  /// التحقق من صحة طريقة السحب
  bool _isValidWithdrawalMethod(String method, String currency) {
    return _currencyConverter.isWithdrawalMethodSupported(method, currency);
  }
  
  /// الحصول على الحد الأدنى للسحب حسب العملة
  double _getMinWithdrawalAmount(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
      case 'USDT':
        return 10.0;
      case 'EUR':
        return 10.0;
      case 'BTC':
        return 0.0001;
      case 'ETH':
        return 0.01;
      case 'SYP':
        return 25000.0;
      case 'TRY':
        return 300.0;
      case 'SAR':
        return 50.0;
      case 'AED':
        return 50.0;
      default:
        return 10.0; // قيمة افتراضية
    }
  }
  
  /// الحصول على الحد الأقصى للسحب حسب العملة
  double _getMaxWithdrawalAmount(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
      case 'USDT':
        return 5000.0;
      case 'EUR':
        return 4500.0;
      case 'BTC':
        return 0.2;
      case 'ETH':
        return 5.0;
      case 'SYP':
        return 10000000.0;
      case 'TRY':
        return 150000.0;
      case 'SAR':
        return 18750.0;
      case 'AED':
        return 18750.0;
      default:
        return 2500.0; // قيمة افتراضية
    }
  }
  
  /// الحصول على الحد اليومي للسحب حسب العملة
  double _getDailyWithdrawalLimit(String currency) {
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
