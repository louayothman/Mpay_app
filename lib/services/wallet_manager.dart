import 'package:flutter/material.dart';
import 'package:mpay_app/utils/logger.dart';
import 'package:mpay_app/utils/wallet_validator.dart';

/// مدير المحفظة
///
/// يوفر واجهة موحدة للتعامل مع عمليات المحفظة الإلكترونية
/// مثل التحقق من صحة العناوين وإنشاء المعاملات وإدارة الرموز المميزة
class WalletManager {
  // نمط Singleton
  static final WalletManager _instance = WalletManager._internal();
  
  factory WalletManager() {
    return _instance;
  }
  
  WalletManager._internal();
  
  // مدقق المحفظة
  final WalletValidator _validator = WalletValidator();
  
  // قائمة العملات المدعومة
  final List<String> _supportedCurrencies = [
    'BTC', 'ETH', 'BNB', 'USDT', 'USDC', 'XRP', 'ADA', 'SOL', 'DOGE', 'DOT'
  ];
  
  // الحصول على قائمة العملات المدعومة
  List<String> getSupportedCurrencies() {
    return List.unmodifiable(_supportedCurrencies);
  }
  
  // التحقق من صحة عنوان المحفظة
  Future<bool> validateWalletAddress(String address, String currency) async {
    try {
      // التحقق من أن العملة مدعومة
      if (!_supportedCurrencies.contains(currency.toUpperCase())) {
        Logger.warning('عملة غير مدعومة: $currency');
        return false;
      }
      
      // استخدام مدقق المحفظة للتحقق من صحة العنوان
      final isValid = await _validator.validateAddress(address, currency);
      
      if (!isValid) {
        Logger.warning('عنوان محفظة غير صالح: $address لعملة $currency');
      }
      
      return isValid;
    } catch (e) {
      Logger.error('خطأ أثناء التحقق من صحة عنوان المحفظة', error: e);
      return false;
    }
  }
  
  // إنشاء عنوان محفظة جديد
  Future<String?> generateWalletAddress(String currency) async {
    try {
      // التحقق من أن العملة مدعومة
      if (!_supportedCurrencies.contains(currency.toUpperCase())) {
        Logger.warning('عملة غير مدعومة: $currency');
        return null;
      }
      
      // استخدام مدقق المحفظة لإنشاء عنوان جديد
      final address = await _validator.generateAddress(currency);
      
      if (address == null) {
        Logger.warning('فشل في إنشاء عنوان محفظة لعملة $currency');
      }
      
      return address;
    } catch (e) {
      Logger.error('خطأ أثناء إنشاء عنوان محفظة', error: e);
      return null;
    }
  }
  
  // التحقق من رصيد المحفظة
  Future<double> checkWalletBalance(String address, String currency) async {
    try {
      // التحقق من أن العملة مدعومة
      if (!_supportedCurrencies.contains(currency.toUpperCase())) {
        Logger.warning('عملة غير مدعومة: $currency');
        return 0.0;
      }
      
      // التحقق من صحة العنوان
      final isValid = await validateWalletAddress(address, currency);
      if (!isValid) {
        Logger.warning('عنوان محفظة غير صالح: $address');
        return 0.0;
      }
      
      // استخدام مدقق المحفظة للتحقق من الرصيد
      final balance = await _validator.checkBalance(address, currency);
      
      return balance;
    } catch (e) {
      Logger.error('خطأ أثناء التحقق من رصيد المحفظة', error: e);
      return 0.0;
    }
  }
  
  // إنشاء معاملة جديدة
  Future<String?> createTransaction(
    String fromAddress,
    String toAddress,
    double amount,
    String currency,
    {double? fee}
  ) async {
    try {
      // التحقق من أن العملة مدعومة
      if (!_supportedCurrencies.contains(currency.toUpperCase())) {
        Logger.warning('عملة غير مدعومة: $currency');
        return null;
      }
      
      // التحقق من صحة العناوين
      final isFromValid = await validateWalletAddress(fromAddress, currency);
      if (!isFromValid) {
        Logger.warning('عنوان المحفظة المرسل غير صالح: $fromAddress');
        return null;
      }
      
      final isToValid = await validateWalletAddress(toAddress, currency);
      if (!isToValid) {
        Logger.warning('عنوان المحفظة المستلم غير صالح: $toAddress');
        return null;
      }
      
      // التحقق من المبلغ
      if (amount <= 0) {
        Logger.warning('المبلغ يجب أن يكون أكبر من صفر: $amount');
        return null;
      }
      
      // التحقق من الرصيد
      final balance = await checkWalletBalance(fromAddress, currency);
      final totalAmount = amount + (fee ?? 0);
      
      if (balance < totalAmount) {
        Logger.warning('رصيد غير كافٍ: $balance < $totalAmount');
        return null;
      }
      
      // إنشاء المعاملة
      final transactionId = await _validator.createTransaction(
        fromAddress,
        toAddress,
        amount,
        currency,
        fee: fee,
      );
      
      if (transactionId == null) {
        Logger.warning('فشل في إنشاء المعاملة');
      } else {
        Logger.info('تم إنشاء المعاملة بنجاح: $transactionId');
      }
      
      return transactionId;
    } catch (e) {
      Logger.error('خطأ أثناء إنشاء المعاملة', error: e);
      return null;
    }
  }
  
  // التحقق من حالة المعاملة
  Future<TransactionStatus> checkTransactionStatus(String transactionId, String currency) async {
    try {
      // التحقق من أن العملة مدعومة
      if (!_supportedCurrencies.contains(currency.toUpperCase())) {
        Logger.warning('عملة غير مدعومة: $currency');
        return TransactionStatus.failed;
      }
      
      // التحقق من صحة معرف المعاملة
      if (transactionId.isEmpty) {
        Logger.warning('معرف المعاملة فارغ');
        return TransactionStatus.failed;
      }
      
      // استخدام مدقق المحفظة للتحقق من حالة المعاملة
      final status = await _validator.checkTransactionStatus(transactionId, currency);
      
      return status;
    } catch (e) {
      Logger.error('خطأ أثناء التحقق من حالة المعاملة', error: e);
      return TransactionStatus.failed;
    }
  }
  
  // تقدير رسوم المعاملة
  Future<double> estimateTransactionFee(String fromAddress, String toAddress, double amount, String currency) async {
    try {
      // التحقق من أن العملة مدعومة
      if (!_supportedCurrencies.contains(currency.toUpperCase())) {
        Logger.warning('عملة غير مدعومة: $currency');
        return 0.0;
      }
      
      // التحقق من صحة العناوين
      final isFromValid = await validateWalletAddress(fromAddress, currency);
      if (!isFromValid) {
        Logger.warning('عنوان المحفظة المرسل غير صالح: $fromAddress');
        return 0.0;
      }
      
      final isToValid = await validateWalletAddress(toAddress, currency);
      if (!isToValid) {
        Logger.warning('عنوان المحفظة المستلم غير صالح: $toAddress');
        return 0.0;
      }
      
      // التحقق من المبلغ
      if (amount <= 0) {
        Logger.warning('المبلغ يجب أن يكون أكبر من صفر: $amount');
        return 0.0;
      }
      
      // استخدام مدقق المحفظة لتقدير رسوم المعاملة
      final fee = await _validator.estimateTransactionFee(
        fromAddress,
        toAddress,
        amount,
        currency,
      );
      
      return fee;
    } catch (e) {
      Logger.error('خطأ أثناء تقدير رسوم المعاملة', error: e);
      return 0.0;
    }
  }
  
  // الحصول على سعر الصرف
  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      // التحقق من أن العملات مدعومة
      if (!_supportedCurrencies.contains(fromCurrency.toUpperCase())) {
        Logger.warning('عملة غير مدعومة: $fromCurrency');
        return 0.0;
      }
      
      if (!_supportedCurrencies.contains(toCurrency.toUpperCase())) {
        Logger.warning('عملة غير مدعومة: $toCurrency');
        return 0.0;
      }
      
      // استخدام مدقق المحفظة للحصول على سعر الصرف
      final rate = await _validator.getExchangeRate(fromCurrency, toCurrency);
      
      return rate;
    } catch (e) {
      Logger.error('خطأ أثناء الحصول على سعر الصرف', error: e);
      return 0.0;
    }
  }
  
  // تحويل العملة
  Future<double> convertCurrency(double amount, String fromCurrency, String toCurrency) async {
    try {
      // التحقق من أن العملات مدعومة
      if (!_supportedCurrencies.contains(fromCurrency.toUpperCase())) {
        Logger.warning('عملة غير مدعومة: $fromCurrency');
        return 0.0;
      }
      
      if (!_supportedCurrencies.contains(toCurrency.toUpperCase())) {
        Logger.warning('عملة غير مدعومة: $toCurrency');
        return 0.0;
      }
      
      // التحقق من المبلغ
      if (amount <= 0) {
        Logger.warning('المبلغ يجب أن يكون أكبر من صفر: $amount');
        return 0.0;
      }
      
      // الحصول على سعر الصرف
      final rate = await getExchangeRate(fromCurrency, toCurrency);
      
      // حساب المبلغ المحول
      final convertedAmount = amount * rate;
      
      return convertedAmount;
    } catch (e) {
      Logger.error('خطأ أثناء تحويل العملة', error: e);
      return 0.0;
    }
  }
}

/// حالة المعاملة
enum TransactionStatus {
  pending,    // قيد الانتظار
  confirmed,  // مؤكدة
  failed,     // فشلت
  rejected,   // مرفوضة
  expired,    // منتهية الصلاحية
}
