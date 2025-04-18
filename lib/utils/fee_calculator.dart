import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/currency_converter.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/firebase/firebase_service.dart';

/// حاسبة الرسوم
///
/// توفر وظائف لحساب الرسوم المختلفة للمعاملات المالية
/// تستخدم معدلات الرسوم المحددة من قبل المشرف
class FeeCalculator {
  final ErrorHandler _errorHandler;
  final CurrencyConverter _currencyConverter;
  
  // الحد الأدنى للرسوم لكل عملة
  static final Map<String, double> _minFees = {
    'SYP': 500.0,
    'USD': 1.0,
    'EUR': 1.0,
    'TRY': 10.0,
    'SAR': 5.0,
    'AED': 5.0,
    'USDT': 1.0,
    'BTC': 0.0001,
    'ETH': 0.001,
  };
  
  // الحد الأقصى للرسوم لكل عملة
  static final Map<String, double> _maxFees = {
    'SYP': 50000.0,
    'USD': 100.0,
    'EUR': 100.0,
    'TRY': 1000.0,
    'SAR': 500.0,
    'AED': 500.0,
    'USDT': 100.0,
    'BTC': 0.01,
    'ETH': 0.1,
  };
  
  // Singleton pattern
  static final FeeCalculator _instance = FeeCalculator._internal();
  
  factory FeeCalculator() {
    return _instance;
  }
  
  FeeCalculator._internal()
      : _errorHandler = ErrorHandler(),
        _currencyConverter = CurrencyConverter(
          apiService: ApiIntegrationService(),
          firebaseService: FirebaseService(),
          errorHandler: ErrorHandler(),
        );
  
  /// حساب رسوم السحب
  /// 
  /// يمكن تمرير نسبة الرسوم مباشرة أو سيتم الحصول عليها من محول العملات
  double calculateWithdrawalFees(double amount, String currency, [double? feePercentage]) {
    try {
      if (amount <= 0) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }
      
      // الحصول على معدل الرسوم للعملة من محول العملات إذا لم يتم تمريره
      final feeRate = feePercentage ?? _currencyConverter.getTransactionFee(currency);
      
      // حساب الرسوم كنسبة مئوية من المبلغ
      double fees = amount * (feeRate / 100);
      
      // التأكد من أن الرسوم ضمن الحدود المسموح بها
      final minFee = _minFees[currency] ?? 0.0;
      final maxFee = _maxFees[currency] ?? double.infinity;
      
      if (fees < minFee) {
        fees = minFee;
      } else if (fees > maxFee) {
        fees = maxFee;
      }
      
      return fees;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'خطأ في حساب رسوم السحب',
        ErrorSeverity.medium,
      );
      
      // إرجاع رسوم افتراضية في حالة حدوث خطأ
      return _getDefaultFee(currency);
    }
  }
  
  /// حساب رسوم الإيداع
  /// 
  /// يمكن تمرير نسبة الرسوم مباشرة أو سيتم الحصول عليها من محول العملات
  double calculateDepositFees(double amount, String currency, [double? feePercentage]) {
    try {
      if (amount <= 0) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }
      
      // الحصول على معدل الرسوم للعملة من محول العملات إذا لم يتم تمريره (نصف رسوم السحب)
      final feeRate = (feePercentage ?? _currencyConverter.getTransactionFee(currency)) / 2;
      
      // حساب الرسوم كنسبة مئوية من المبلغ
      double fees = amount * (feeRate / 100);
      
      // التأكد من أن الرسوم ضمن الحدود المسموح بها
      final minFee = (_minFees[currency] ?? 0.0) / 2;
      final maxFee = (_maxFees[currency] ?? double.infinity) / 2;
      
      if (fees < minFee) {
        fees = minFee;
      } else if (fees > maxFee) {
        fees = maxFee;
      }
      
      return fees;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'خطأ في حساب رسوم الإيداع',
        ErrorSeverity.medium,
      );
      
      // إرجاع رسوم افتراضية في حالة حدوث خطأ
      return _getDefaultFee(currency) / 2;
    }
  }
  
  /// حساب رسوم التحويل
  /// 
  /// يمكن تمرير نسبة الرسوم مباشرة أو سيتم الحصول عليها من محول العملات
  double calculateTransferFees(double amount, String currency, [double? feePercentage]) {
    try {
      if (amount <= 0) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }
      
      // الحصول على معدل الرسوم للعملة من محول العملات إذا لم يتم تمريره (75% من رسوم السحب)
      final feeRate = (feePercentage ?? _currencyConverter.getTransactionFee(currency)) * 0.75;
      
      // حساب الرسوم كنسبة مئوية من المبلغ
      double fees = amount * (feeRate / 100);
      
      // التأكد من أن الرسوم ضمن الحدود المسموح بها
      final minFee = (_minFees[currency] ?? 0.0) * 0.75;
      final maxFee = (_maxFees[currency] ?? double.infinity) * 0.75;
      
      if (fees < minFee) {
        fees = minFee;
      } else if (fees > maxFee) {
        fees = maxFee;
      }
      
      return fees;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'خطأ في حساب رسوم التحويل',
        ErrorSeverity.medium,
      );
      
      // إرجاع رسوم افتراضية في حالة حدوث خطأ
      return _getDefaultFee(currency) * 0.75;
    }
  }
  
  /// حساب رسوم تحويل العملات
  /// 
  /// يمكن تمرير نسبة الرسوم مباشرة أو سيتم الحصول عليها من محول العملات
  double calculateCurrencyExchangeFees(double amount, String fromCurrency, String toCurrency, [double? feePercentage]) {
    try {
      if (amount <= 0) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }
      
      // الحصول على معدل الرسوم للعملة المصدر من محول العملات إذا لم يتم تمريره
      final feeRate = (feePercentage ?? _currencyConverter.getTransactionFee(fromCurrency)) * 1.25;
      
      // حساب الرسوم كنسبة مئوية من المبلغ
      double fees = amount * (feeRate / 100);
      
      // التأكد من أن الرسوم ضمن الحدود المسموح بها
      final minFee = (_minFees[fromCurrency] ?? 0.0) * 1.25;
      final maxFee = (_maxFees[fromCurrency] ?? double.infinity) * 1.25;
      
      if (fees < minFee) {
        fees = minFee;
      } else if (fees > maxFee) {
        fees = maxFee;
      }
      
      return fees;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'خطأ في حساب رسوم تحويل العملات',
        ErrorSeverity.medium,
      );
      
      // إرجاع رسوم افتراضية في حالة حدوث خطأ
      return _getDefaultFee(fromCurrency) * 1.25;
    }
  }
  
  /// الحصول على الرسوم الافتراضية للعملة
  double _getDefaultFee(String currency) {
    switch (currency) {
      case 'SYP':
        return 500.0;
      case 'USD':
      case 'EUR':
      case 'USDT':
        return 1.0;
      case 'TRY':
        return 10.0;
      case 'SAR':
      case 'AED':
        return 5.0;
      case 'BTC':
        return 0.0001;
      case 'ETH':
        return 0.001;
      default:
        return 1.0;
    }
  }
  
  /// الحصول على الحد الأدنى للرسوم للعملة
  double getMinFee(String currency) {
    return _minFees[currency] ?? 0.0;
  }
  
  /// الحصول على الحد الأقصى للرسوم للعملة
  double getMaxFee(String currency) {
    return _maxFees[currency] ?? double.infinity;
  }
  
  /// تحديث الحد الأدنى للرسوم للعملة
  void updateMinFee(String currency, double minFee) {
    if (minFee >= 0) {
      _minFees[currency] = minFee;
    }
  }
  
  /// تحديث الحد الأقصى للرسوم للعملة
  void updateMaxFee(String currency, double maxFee) {
    if (maxFee > 0) {
      _maxFees[currency] = maxFee;
    }
  }
}
