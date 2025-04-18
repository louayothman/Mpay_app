import 'package:flutter/material.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';

/// محول العملات
///
/// يوفر وظائف لتحويل المبالغ بين العملات المختلفة باستخدام أسعار الصرف المحددة من قبل المشرف
class CurrencyConverter {
  final ApiIntegrationService _apiService;
  final FirebaseService _firebaseService;
  final ErrorHandler _errorHandler;
  final FlutterSecureStorage _secureStorage;
  
  // العملات المدعومة
  static const List<String> supportedCurrencies = [
    'SYP', // ليرة سورية
    'USD', // دولار أمريكي
    'EUR', // يورو
    'TRY', // ليرة تركية
    'SAR', // ريال سعودي
    'AED', // درهم إماراتي
    'USDT', // تيثر (عملة رقمية)
    'BTC', // بيتكوين (عملة رقمية)
    'ETH', // إيثريوم (عملة رقمية)
  ];
  
  // طرق الإيداع المدعومة
  static const List<String> supportedDepositMethods = [
    'USDT', // تيثر
    'BTC', // بيتكوين
    'ETH', // إيثريوم
    'ShamCash', // شام كاش
  ];
  
  // أسعار الصرف الافتراضية (بالنسبة للليرة السورية)
  static final Map<String, double> _defaultExchangeRates = {
    'SYP': 1.0,
    'USD': 5000.0,
    'EUR': 5500.0,
    'TRY': 160.0,
    'SAR': 1300.0,
    'AED': 1350.0,
    'USDT': 5000.0,
    'BTC': 150000000.0,
    'ETH': 10000000.0,
  };
  
  // رسوم المعاملات الافتراضية (نسبة مئوية)
  static final Map<String, double> _defaultTransactionFees = {
    'SYP': 1.0, // 1%
    'USD': 1.0,
    'EUR': 1.0,
    'TRY': 1.0,
    'SAR': 1.0,
    'AED': 1.0,
    'USDT': 1.5,
    'BTC': 2.0,
    'ETH': 1.5,
  };
  
  // تاريخ آخر تحديث لأسعار الصرف
  DateTime? _lastRatesUpdateTime;
  
  // أسعار الصرف الحالية
  Map<String, double> _currentExchangeRates = Map.from(_defaultExchangeRates);
  
  // رسوم المعاملات الحالية
  Map<String, double> _currentTransactionFees = Map.from(_defaultTransactionFees);
  
  // عناوين محافظ الإيداع
  Map<String, String> _depositWalletAddresses = {
    'USDT': 'TRX7NHqjeKQxGTCi8q812SiWC8nQc32r8Q',
    'BTC': 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
    'ETH': '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
  };
  
  // Singleton pattern
  static final CurrencyConverter _instance = CurrencyConverter._internal();
  
  factory CurrencyConverter({
    required ApiIntegrationService apiService,
    required FirebaseService firebaseService,
    required ErrorHandler errorHandler,
    FlutterSecureStorage? secureStorage,
  }) {
    _instance._apiService = apiService;
    _instance._firebaseService = firebaseService;
    _instance._errorHandler = errorHandler;
    _instance._secureStorage = secureStorage ?? const FlutterSecureStorage();
    return _instance;
  }
  
  CurrencyConverter._internal()
      : _apiService = ApiIntegrationService(),
        _firebaseService = FirebaseService(),
        _errorHandler = ErrorHandler(),
        _secureStorage = const FlutterSecureStorage();
  
  /// تهيئة محول العملات
  Future<void> initialize() async {
    try {
      await loadExchangeRates();
      await loadTransactionFees();
      await loadDepositWalletAddresses();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تهيئة محول العملات',
        ErrorSeverity.medium,
      );
    }
  }
  
  /// تحميل أسعار الصرف من الخادم أو التخزين المحلي
  Future<void> loadExchangeRates() async {
    try {
      // محاولة تحميل أسعار الصرف من الخادم
      final response = await _apiService.get(
        '/admin/exchange-rates',
        useCache: true,
        cacheDuration: const Duration(hours: 1),
      );
      
      if (response != null && response['rates'] != null) {
        final Map<String, dynamic> rates = response['rates'];
        final Map<String, double> exchangeRates = {};
        
        for (final entry in rates.entries) {
          exchangeRates[entry.key] = double.parse(entry.value.toString());
        }
        
        _currentExchangeRates = exchangeRates;
        _lastRatesUpdateTime = DateTime.now();
        
        // تخزين أسعار الصرف محليًا
        await _storeExchangeRatesLocally(exchangeRates);
      } else {
        // إذا فشل التحميل من الخادم، حاول تحميل أسعار الصرف المخزنة محليًا
        final localRates = await _loadExchangeRatesLocally();
        if (localRates != null) {
          _currentExchangeRates = localRates;
        }
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحميل أسعار الصرف',
        ErrorSeverity.medium,
      );
      
      // محاولة تحميل أسعار الصرف المخزنة محليًا
      final localRates = await _loadExchangeRatesLocally();
      if (localRates != null) {
        _currentExchangeRates = localRates;
      }
    }
  }
  
  /// تحميل رسوم المعاملات من الخادم أو التخزين المحلي
  Future<void> loadTransactionFees() async {
    try {
      // محاولة تحميل رسوم المعاملات من الخادم
      final response = await _apiService.get(
        '/admin/transaction-fees',
        useCache: true,
        cacheDuration: const Duration(hours: 1),
      );
      
      if (response != null && response['fees'] != null) {
        final Map<String, dynamic> fees = response['fees'];
        final Map<String, double> transactionFees = {};
        
        for (final entry in fees.entries) {
          transactionFees[entry.key] = double.parse(entry.value.toString());
        }
        
        _currentTransactionFees = transactionFees;
        
        // تخزين رسوم المعاملات محليًا
        await _storeTransactionFeesLocally(transactionFees);
      } else {
        // إذا فشل التحميل من الخادم، حاول تحميل رسوم المعاملات المخزنة محليًا
        final localFees = await _loadTransactionFeesLocally();
        if (localFees != null) {
          _currentTransactionFees = localFees;
        }
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحميل رسوم المعاملات',
        ErrorSeverity.medium,
      );
      
      // محاولة تحميل رسوم المعاملات المخزنة محليًا
      final localFees = await _loadTransactionFeesLocally();
      if (localFees != null) {
        _currentTransactionFees = localFees;
      }
    }
  }
  
  /// تحميل عناوين محافظ الإيداع من الخادم أو التخزين المحلي
  Future<void> loadDepositWalletAddresses() async {
    try {
      // محاولة تحميل عناوين محافظ الإيداع من الخادم
      final response = await _apiService.get(
        '/admin/deposit-wallet-addresses',
        useCache: true,
        cacheDuration: const Duration(hours: 1),
      );
      
      if (response != null && response['addresses'] != null) {
        final Map<String, dynamic> addresses = response['addresses'];
        final Map<String, String> walletAddresses = {};
        
        for (final entry in addresses.entries) {
          walletAddresses[entry.key] = entry.value.toString();
        }
        
        _depositWalletAddresses = walletAddresses;
        
        // تخزين عناوين محافظ الإيداع محليًا
        await _storeDepositWalletAddressesLocally(walletAddresses);
      } else {
        // إذا فشل التحميل من الخادم، حاول تحميل عناوين محافظ الإيداع المخزنة محليًا
        final localAddresses = await _loadDepositWalletAddressesLocally();
        if (localAddresses != null) {
          _depositWalletAddresses = localAddresses;
        }
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحميل عناوين محافظ الإيداع',
        ErrorSeverity.medium,
      );
      
      // محاولة تحميل عناوين محافظ الإيداع المخزنة محليًا
      final localAddresses = await _loadDepositWalletAddressesLocally();
      if (localAddresses != null) {
        _depositWalletAddresses = localAddresses;
      }
    }
  }
  
  /// تخزين أسعار الصرف محليًا
  Future<void> _storeExchangeRatesLocally(Map<String, double> rates) async {
    try {
      final data = {
        'rates': rates,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'exchange_rates',
        value: jsonEncode(data),
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تخزين أسعار الصرف محليًا',
        ErrorSeverity.low,
      );
    }
  }
  
  /// تخزين رسوم المعاملات محليًا
  Future<void> _storeTransactionFeesLocally(Map<String, double> fees) async {
    try {
      final data = {
        'fees': fees,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'transaction_fees',
        value: jsonEncode(data),
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تخزين رسوم المعاملات محليًا',
        ErrorSeverity.low,
      );
    }
  }
  
  /// تخزين عناوين محافظ الإيداع محليًا
  Future<void> _storeDepositWalletAddressesLocally(Map<String, String> addresses) async {
    try {
      final data = {
        'addresses': addresses,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'deposit_wallet_addresses',
        value: jsonEncode(data),
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تخزين عناوين محافظ الإيداع محليًا',
        ErrorSeverity.low,
      );
    }
  }
  
  /// تحميل أسعار الصرف المخزنة محليًا
  Future<Map<String, double>?> _loadExchangeRatesLocally() async {
    try {
      final json = await _secureStorage.read(key: 'exchange_rates');
      
      if (json != null) {
        final data = jsonDecode(json);
        final Map<String, dynamic> ratesData = data['rates'];
        final Map<String, double> rates = {};
        
        for (final entry in ratesData.entries) {
          rates[entry.key] = double.parse(entry.value.toString());
        }
        
        _lastRatesUpdateTime = DateTime.parse(data['timestamp']);
        
        return rates;
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحميل أسعار الصرف المخزنة محليًا',
        ErrorSeverity.low,
      );
    }
    
    return null;
  }
  
  /// تحميل رسوم المعاملات المخزنة محليًا
  Future<Map<String, double>?> _loadTransactionFeesLocally() async {
    try {
      final json = await _secureStorage.read(key: 'transaction_fees');
      
      if (json != null) {
        final data = jsonDecode(json);
        final Map<String, dynamic> feesData = data['fees'];
        final Map<String, double> fees = {};
        
        for (final entry in feesData.entries) {
          fees[entry.key] = double.parse(entry.value.toString());
        }
        
        return fees;
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحميل رسوم المعاملات المخزنة محليًا',
        ErrorSeverity.low,
      );
    }
    
    return null;
  }
  
  /// تحميل عناوين محافظ الإيداع المخزنة محليًا
  Future<Map<String, String>?> _loadDepositWalletAddressesLocally() async {
    try {
      final json = await _secureStorage.read(key: 'deposit_wallet_addresses');
      
      if (json != null) {
        final data = jsonDecode(json);
        final Map<String, dynamic> addressesData = data['addresses'];
        final Map<String, String> addresses = {};
        
        for (final entry in addressesData.entries) {
          addresses[entry.key] = entry.value.toString();
        }
        
        return addresses;
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحميل عناوين محافظ الإيداع المخزنة محليًا',
        ErrorSeverity.low,
      );
    }
    
    return null;
  }
  
  /// تحديث سعر الصرف (للمشرف فقط)
  Future<bool> updateExchangeRate(String currency, double newRate, String adminId) async {
    try {
      if (!supportedCurrencies.contains(currency)) {
        throw Exception('العملة غير مدعومة: $currency');
      }
      
      if (newRate <= 0) {
        throw Exception('سعر الصرف يجب أن يكون أكبر من صفر');
      }
      
      // تحديث سعر الصرف في الخادم
      final response = await _apiService.post(
        '/admin/exchange-rates/update',
        body: {
          'adminId': adminId,
          'currency': currency,
          'rate': newRate,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (response != null && response['success'] == true) {
        // تحديث سعر الصرف محليًا
        _currentExchangeRates[currency] = newRate;
        _lastRatesUpdateTime = DateTime.now();
        
        // تخزين أسعار الصرف المحدثة محليًا
        await _storeExchangeRatesLocally(_currentExchangeRates);
        
        // تسجيل عملية التحديث
        await _firebaseService.logAdminAction(
          adminId,
          'update_exchange_rate',
          {
            'currency': currency,
            'old_rate': _currentExchangeRates[currency],
            'new_rate': newRate,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحديث سعر الصرف',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// تحديث رسوم المعاملات (للمشرف فقط)
  Future<bool> updateTransactionFee(String currency, double newFee, String adminId) async {
    try {
      if (!supportedCurrencies.contains(currency)) {
        throw Exception('العملة غير مدعومة: $currency');
      }
      
      if (newFee < 0 || newFee > 10) {
        throw Exception('رسوم المعاملات يجب أن تكون بين 0% و 10%');
      }
      
      // تحديث رسوم المعاملات في الخادم
      final response = await _apiService.post(
        '/admin/transaction-fees/update',
        body: {
          'adminId': adminId,
          'currency': currency,
          'fee': newFee,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (response != null && response['success'] == true) {
        // تحديث رسوم المعاملات محليًا
        _currentTransactionFees[currency] = newFee;
        
        // تخزين رسوم المعاملات المحدثة محليًا
        await _storeTransactionFeesLocally(_currentTransactionFees);
        
        // تسجيل عملية التحديث
        await _firebaseService.logAdminAction(
          adminId,
          'update_transaction_fee',
          {
            'currency': currency,
            'old_fee': _currentTransactionFees[currency],
            'new_fee': newFee,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحديث رسوم المعاملات',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// تحديث عنوان محفظة الإيداع (للمشرف فقط)
  Future<bool> updateDepositWalletAddress(String currency, String newAddress, String adminId) async {
    try {
      if (!supportedDepositMethods.contains(currency)) {
        throw Exception('طريقة الإيداع غير مدعومة: $currency');
      }
      
      if (newAddress.isEmpty) {
        throw Exception('عنوان المحفظة لا يمكن أن يكون فارغًا');
      }
      
      // تحديث عنوان محفظة الإيداع في الخادم
      final response = await _apiService.post(
        '/admin/deposit-wallet-addresses/update',
        body: {
          'adminId': adminId,
          'currency': currency,
          'address': newAddress,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (response != null && response['success'] == true) {
        // تحديث عنوان محفظة الإيداع محليًا
        _depositWalletAddresses[currency] = newAddress;
        
        // تخزين عناوين محافظ الإيداع المحدثة محليًا
        await _storeDepositWalletAddressesLocally(_depositWalletAddresses);
        
        // تسجيل عملية التحديث
        await _firebaseService.logAdminAction(
          adminId,
          'update_deposit_wallet_address',
          {
            'currency': currency,
            'old_address': _depositWalletAddresses[currency],
            'new_address': newAddress,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحديث عنوان محفظة الإيداع',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// إضافة عملة جديدة (للمشرف فقط)
  Future<bool> addNewCurrency(String currency, double exchangeRate, double transactionFee, String adminId) async {
    try {
      if (supportedCurrencies.contains(currency)) {
        throw Exception('العملة موجودة بالفعل: $currency');
      }
      
      if (exchangeRate <= 0) {
        throw Exception('سعر الصرف يجب أن يكون أكبر من صفر');
      }
      
      if (transactionFee < 0 || transactionFee > 10) {
        throw Exception('رسوم المعاملات يجب أن تكون بين 0% و 10%');
      }
      
      // إضافة العملة الجديدة في الخادم
      final response = await _apiService.post(
        '/admin/currencies/add',
        body: {
          'adminId': adminId,
          'currency': currency,
          'exchangeRate': exchangeRate,
          'transactionFee': transactionFee,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (response != null && response['success'] == true) {
        // إضافة العملة الجديدة محليًا
        _currentExchangeRates[currency] = exchangeRate;
        _currentTransactionFees[currency] = transactionFee;
        
        // تخزين البيانات المحدثة محليًا
        await _storeExchangeRatesLocally(_currentExchangeRates);
        await _storeTransactionFeesLocally(_currentTransactionFees);
        
        // تسجيل عملية الإضافة
        await _firebaseService.logAdminAction(
          adminId,
          'add_new_currency',
          {
            'currency': currency,
            'exchange_rate': exchangeRate,
            'transaction_fee': transactionFee,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في إضافة عملة جديدة',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// إضافة طريقة إيداع جديدة (للمشرف فقط)
  Future<bool> addNewDepositMethod(String method, String walletAddress, String adminId) async {
    try {
      if (supportedDepositMethods.contains(method)) {
        throw Exception('طريقة الإيداع موجودة بالفعل: $method');
      }
      
      if (walletAddress.isEmpty) {
        throw Exception('عنوان المحفظة لا يمكن أن يكون فارغًا');
      }
      
      // إضافة طريقة الإيداع الجديدة في الخادم
      final response = await _apiService.post(
        '/admin/deposit-methods/add',
        body: {
          'adminId': adminId,
          'method': method,
          'walletAddress': walletAddress,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (response != null && response['success'] == true) {
        // إضافة طريقة الإيداع الجديدة محليًا
        _depositWalletAddresses[method] = walletAddress;
        
        // تخزين البيانات المحدثة محليًا
        await _storeDepositWalletAddressesLocally(_depositWalletAddresses);
        
        // تسجيل عملية الإضافة
        await _firebaseService.logAdminAction(
          adminId,
          'add_new_deposit_method',
          {
            'method': method,
            'wallet_address': walletAddress,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في إضافة طريقة إيداع جديدة',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// الحصول على سعر الصرف الحالي للعملة
  double getExchangeRate(String currency) {
    if (!supportedCurrencies.contains(currency)) {
      throw Exception('العملة غير مدعومة: $currency');
    }
    
    return _currentExchangeRates[currency] ?? _defaultExchangeRates[currency] ?? 1.0;
  }
  
  /// الحصول على رسوم المعاملات الحالية للعملة
  double getTransactionFee(String currency) {
    if (!supportedCurrencies.contains(currency)) {
      throw Exception('العملة غير مدعومة: $currency');
    }
    
    return _currentTransactionFees[currency] ?? _defaultTransactionFees[currency] ?? 1.0;
  }
  
  /// الحصول على عنوان محفظة الإيداع للعملة
  String getDepositWalletAddress(String currency) {
    if (!supportedDepositMethods.contains(currency)) {
      throw Exception('طريقة الإيداع غير مدعومة: $currency');
    }
    
    return _depositWalletAddresses[currency] ?? '';
  }
  
  /// الحصول على جميع أسعار الصرف الحالية
  Map<String, double> getAllExchangeRates() {
    return Map.from(_currentExchangeRates);
  }
  
  /// الحصول على جميع رسوم المعاملات الحالية
  Map<String, double> getAllTransactionFees() {
    return Map.from(_currentTransactionFees);
  }
  
  /// الحصول على جميع عناوين محافظ الإيداع
  Map<String, String> getAllDepositWalletAddresses() {
    return Map.from(_depositWalletAddresses);
  }
  
  /// تحويل مبلغ من عملة إلى أخرى
  double convert(double amount, String fromCurrency, String toCurrency) {
    if (!supportedCurrencies.contains(fromCurrency)) {
      throw Exception('العملة غير مدعومة: $fromCurrency');
    }
    
    if (!supportedCurrencies.contains(toCurrency)) {
      throw Exception('العملة غير مدعومة: $toCurrency');
    }
    
    if (amount < 0) {
      throw Exception('المبلغ يجب أن يكون أكبر من أو يساوي صفر');
    }
    
    // الحصول على أسعار الصرف
    final fromRate = getExchangeRate(fromCurrency);
    final toRate = getExchangeRate(toCurrency);
    
    // تحويل المبلغ إلى الليرة السورية أولاً ثم إلى العملة المطلوبة
    final amountInSYP = amount * fromRate;
    final convertedAmount = amountInSYP / toRate;
    
    return convertedAmount;
  }
  
  /// حساب رسوم المعاملة
  double calculateTransactionFee(double amount, String currency) {
    if (!supportedCurrencies.contains(currency)) {
      throw Exception('العملة غير مدعومة: $currency');
    }
    
    if (amount < 0) {
      throw Exception('المبلغ يجب أن يكون أكبر من أو يساوي صفر');
    }
    
    // الحصول على نسبة الرسوم
    final feePercentage = getTransactionFee(currency);
    
    // حساب الرسوم
    final fee = amount * (feePercentage / 100);
    
    return fee;
  }
  
  /// الحصول على تاريخ آخر تحديث لأسعار الصرف
  DateTime? getLastUpdateTime() {
    return _lastRatesUpdateTime;
  }
  
  /// التحقق مما إذا كانت العملة مدعومة
  bool isCurrencySupported(String currency) {
    return supportedCurrencies.contains(currency);
  }
  
  /// التحقق مما إذا كانت طريقة الإيداع مدعومة
  bool isDepositMethodSupported(String method) {
    return supportedDepositMethods.contains(method);
  }
  
  /// الحصول على قائمة العملات المدعومة
  List<String> getSupportedCurrencies() {
    return List.from(supportedCurrencies);
  }
  
  /// الحصول على قائمة طرق الإيداع المدعومة
  List<String> getSupportedDepositMethods() {
    return List.from(supportedDepositMethods);
  }
  
  /// حساب المستوى بناءً على الرصيد بالليرة السورية
  int calculateUserLevel(double balanceSYP) {
    if (balanceSYP < 100000) {
      return 1; // المستوى الأساسي
    } else if (balanceSYP < 500000) {
      return 2; // المستوى المتوسط
    } else if (balanceSYP < 1000000) {
      return 3; // المستوى المتقدم
    } else {
      return 4; // المستوى الممتاز
    }
  }
  
  /// حساب المستوى بناءً على الرصيد بأي عملة
  int calculateUserLevelForCurrency(double balance, String currency) {
    // تحويل الرصيد إلى الليرة السورية
    final balanceSYP = convert(balance, currency, 'SYP');
    
    // حساب المستوى بناءً على الرصيد بالليرة السورية
    return calculateUserLevel(balanceSYP);
  }
}
