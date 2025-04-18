import 'package:mpay_app/domain/repositories/payment_gateway_interface.dart';
import 'package:mpay_app/domain/repositories/payment_security_service.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/fee_calculator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

/// تنفيذ واجهة بوابة الدفع
///
/// توفر هذه الفئة تنفيذًا لواجهة بوابة الدفع وتتعامل مع جميع عمليات الدفع
/// بما في ذلك الإيداع والسحب وتحويل العملات
class PaymentGatewayServiceImpl implements PaymentGatewayInterface {
  final ApiIntegrationService _apiService;
  final FirebaseService _firebaseService;
  final ConnectivityUtils _connectivityUtils;
  final ErrorHandler _errorHandler;
  final PaymentSecurityService _securityService;
  final FlutterSecureStorage _secureStorage;
  final FeeCalculator _feeCalculator;
  
  // العملات المشفرة المدعومة
  static const List<String> supportedCryptoCurrencies = [
    'USDT_TRC20',
    'USDT_ERC20',
    'BTC',
    'ETH',
  ];
  
  // عتبات المعاملات للتأكيد الإضافي
  static const Map<String, double> _transactionThresholds = {
    'USD': 1000.0,
    'EUR': 1000.0,
    'SYP': 500000.0,
    'TRY': 20000.0,
    'SAR': 5000.0,
    'AED': 5000.0,
    'BTC': 0.05,
    'ETH': 1.0,
    'USDT': 1000.0,
  };
  
  // مدة انتهاء الجلسة
  static const Duration _sessionTimeout = Duration(minutes: 15);
  DateTime? _lastActivityTime;
  
  PaymentGatewayServiceImpl({
    required ApiIntegrationService apiService,
    required FirebaseService firebaseService,
    required ConnectivityUtils connectivityUtils,
    required ErrorHandler errorHandler,
    required PaymentSecurityService securityService,
    FlutterSecureStorage? secureStorage,
    FeeCalculator? feeCalculator,
  }) : 
    _apiService = apiService,
    _firebaseService = firebaseService,
    _connectivityUtils = connectivityUtils,
    _errorHandler = errorHandler,
    _securityService = securityService,
    _secureStorage = secureStorage ?? const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    ),
    _feeCalculator = feeCalculator ?? FeeCalculator();
  
  @override
  Future<void> initialize() async {
    // التأكد من تهيئة خدمة API
    await _apiService.initialize();
    
    // تهيئة ميزات الأمان
    await _securityService.initializePaymentSecurity();
    
    // إعادة تعيين وقت النشاط الأخير
    _updateLastActivityTime();
  }
  
  // تحديث وقت النشاط الأخير
  void _updateLastActivityTime() {
    _lastActivityTime = DateTime.now();
  }
  
  // التحقق مما إذا كانت الجلسة نشطة
  bool _isSessionActive() {
    if (_lastActivityTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_lastActivityTime!) < _sessionTimeout;
  }
  
  // التأكد من أن الجلسة نشطة
  void _ensureSessionActive() {
    if (!_isSessionActive()) {
      throw PaymentException(
        'انتهت الجلسة. يرجى إعادة المصادقة.',
        'session_expired',
      );
    }
    
    // تحديث وقت النشاط الأخير
    _updateLastActivityTime();
  }
  
  @override
  Future<List<PaymentMethod>> getAvailablePaymentMethods(String userId) async {
    try {
      _ensureSessionActive();
      
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // إرجاع طرق الدفع المخزنة مؤقتًا إذا كانت متوفرة
        final cachedMethods = await _getCachedPaymentMethods(userId);
        if (cachedMethods.isNotEmpty) {
          return cachedMethods;
        }
        
        throw PaymentException(
          'لا يوجد اتصال بالإنترنت متاح',
          'connectivity_error',
        );
      }
      
      // الحصول على طرق الدفع من API
      final response = await _apiService.get(
        '/payments/methods',
        queryParams: {'userId': userId},
        useCache: true,
        cacheDuration: const Duration(hours: 1),
      );
      
      final List<PaymentMethod> paymentMethods = [];
      
      if (response['methods'] != null && response['methods'] is List) {
        for (final method in response['methods']) {
          paymentMethods.add(PaymentMethod.fromJson(method));
        }
      }
      
      // تخزين طرق الدفع بشكل آمن
      await _securelyStorePaymentMethods(userId, paymentMethods);
      
      return paymentMethods;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على طرق الدفع المتاحة',
        ErrorSeverity.medium,
      );
      
      // محاولة الحصول على طرق الدفع المخزنة مؤقتًا كبديل
      final cachedMethods = await _getCachedPaymentMethods(userId);
      if (cachedMethods.isNotEmpty) {
        return cachedMethods;
      }
      
      // إرجاع طرق الدفع الافتراضية إذا فشلت جميع المحاولات الأخرى
      return _getDefaultPaymentMethods();
    }
  }
  
  // الحصول على طرق الدفع المخزنة مؤقتًا
  Future<List<PaymentMethod>> _getCachedPaymentMethods(String userId) async {
    try {
      final cachedJson = await _secureStorage.read(key: 'payment_methods_$userId');
      
      if (cachedJson != null) {
        final Map<String, dynamic> cachedData = jsonDecode(cachedJson);
        
        // التحقق من سلامة البيانات باستخدام HMAC
        final String storedHmac = cachedData['hmac'];
        final List<dynamic> methodsJson = cachedData['methods'];
        
        final calculatedHmac = await _securityService.generateHmac(
          jsonEncode(methodsJson),
          'payment_methods_$userId',
        );
        
        if (calculatedHmac != storedHmac) {
          // انتهاك سلامة البيانات
          await _securityService.logSecurityEvent(
            userId,
            'data_integrity_violation',
            'فشل التحقق من HMAC لطرق الدفع المخزنة مؤقتًا',
          );
          return [];
        }
        
        final List<PaymentMethod> paymentMethods = [];
        for (final method in methodsJson) {
          paymentMethods.add(PaymentMethod.fromJson(method));
        }
        
        return paymentMethods;
      }
    } catch (e) {
      // تجاهل أخطاء التخزين المؤقت
      _errorHandler.handleError(
        e,
        'خطأ في استرجاع طرق الدفع المخزنة مؤقتًا',
        ErrorSeverity.low,
      );
    }
    
    return [];
  }
  
  // تخزين طرق الدفع بشكل آمن
  Future<void> _securelyStorePaymentMethods(String userId, List<PaymentMethod> methods) async {
    try {
      final methodsJson = methods.map((method) => method.toJson()).toList();
      
      // توليد HMAC لسلامة البيانات
      final hmac = await _securityService.generateHmac(
        jsonEncode(methodsJson),
        'payment_methods_$userId',
      );
      
      final dataToStore = {
        'methods': methodsJson,
        'hmac': hmac,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'payment_methods_$userId',
        value: jsonEncode(dataToStore),
      );
    } catch (e) {
      // تجاهل أخطاء التخزين المؤقت
      _errorHandler.handleError(
        e,
        'خطأ في تخزين طرق الدفع',
        ErrorSeverity.low,
      );
    }
  }
  
  // الحصول على طرق الدفع الافتراضية
  List<PaymentMethod> _getDefaultPaymentMethods() {
    return [
      PaymentMethod(
        id: 'crypto',
        name: 'العملات المشفرة',
        description: 'الدفع بالعملات المشفرة',
        icon: Icons.currency_bitcoin,
        isEnabled: true,
        supportedCurrencies: ['USD', 'EUR', 'SYP', 'TRY', 'SAR', 'AED'],
        paymentType: PaymentType.crypto,
        processingFee: 0.0,
        minAmount: 10.0,
        maxAmount: 10000.0,
      ),
      PaymentMethod(
        id: 'sham_cash',
        name: 'شام كاش',
        description: 'الدفع بواسطة شام كاش',
        icon: Icons.account_balance_wallet,
        isEnabled: true,
        supportedCurrencies: ['USD', 'EUR', 'SYP', 'TRY', 'SAR', 'AED'],
        paymentType: PaymentType.electronic,
        processingFee: 1.0,
        minAmount: 5.0,
        maxAmount: 5000.0,
      ),
    ];
  }
  
  @override
  Future<Map<String, String>> getCryptoWalletAddresses() async {
    try {
      _ensureSessionActive();
      
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // إرجاع عناوين المحفظة المخزنة مؤقتًا إذا كانت متوفرة
        final cachedAddresses = await _getSecurelyCachedWalletAddresses();
        if (cachedAddresses.isNotEmpty) {
          return cachedAddresses;
        }
        
        throw PaymentException(
          'لا يوجد اتصال بالإنترنت متاح',
          'connectivity_error',
        );
      }
      
      // الحصول على عناوين المحفظة من API
      final response = await _apiService.get(
        '/payments/crypto/wallets',
        useCache: true,
        cacheDuration: const Duration(days: 1),
      );
      
      final Map<String, String> walletAddresses = {};
      
      if (response['wallets'] != null && response['wallets'] is Map) {
        for (final entry in response['wallets'].entries) {
          final address = entry.value.toString();
          
          // التحقق من صحة تنسيق عنوان المحفظة
          if (_securityService.validateWalletAddress(entry.key, address)) {
            walletAddresses[entry.key] = address;
          } else {
            // تسجيل عنوان محفظة غير صالح
            await _securityService.logSecurityEvent(
              'system',
              'invalid_wallet_address',
              'تنسيق عنوان محفظة غير صالح لـ ${entry.key}',
            );
          }
        }
      }
      
      // تخزين عناوين المحفظة بشكل آمن
      await _securelyStoreWalletAddresses(walletAddresses);
      
      return walletAddresses;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على عناوين محفظة العملات المشفرة',
        ErrorSeverity.medium,
      );
      
      // محاولة الحصول على عناوين المحفظة المخزنة مؤقتًا كبديل
      final cachedAddresses = await _getSecurelyCachedWalletAddresses();
      if (cachedAddresses.isNotEmpty) {
        return cachedAddresses;
      }
      
      // إرجاع عناوين المحفظة الافتراضية إذا فشلت جميع المحاولات الأخرى
      return _getDefaultWalletAddresses();
    }
  }
  
  // الحصول على عناوين المحفظة المخزنة مؤقتًا بشكل آمن
  Future<Map<String, String>> _getSecurelyCachedWalletAddresses() async {
    try {
      final cachedJson = await _secureStorage.read(key: 'crypto_wallets');
      
      if (cachedJson != null) {
        final Map<String, dynamic> cachedData = jsonDecode(cachedJson);
        
        // التحقق من سلامة البيانات باستخدام HMAC
        final String storedHmac = cachedData['hmac'];
        final Map<String, dynamic> walletsData = cachedData['wallets'];
        
        final calculatedHmac = await _securityService.generateHmac(
          jsonEncode(walletsData),
          'crypto_wallets',
        );
        
        if (calculatedHmac != storedHmac) {
          // انتهاك سلامة البيانات
          await _securityService.logSecurityEvent(
            'system',
            'data_integrity_violation',
            'فشل التحقق من HMAC لعناوين المحفظة المخزنة مؤقتًا',
          );
          return {};
        }
        
        final Map<String, String> walletAddresses = {};
        for (final entry in walletsData.entries) {
          walletAddresses[entry.key] = entry.value.toString();
        }
        
        return walletAddresses;
      }
    } catch (e) {
      // تجاهل أخطاء التخزين المؤقت
      _errorHandler.handleError(
        e,
        'خطأ في استرجاع عناوين المحفظة المخزنة مؤقتًا',
        ErrorSeverity.low,
      );
    }
    
    return {};
  }
  
  // تخزين عناوين المحفظة بشكل آمن
  Future<void> _securelyStoreWalletAddresses(Map<String, String> addresses) async {
    try {
      // توليد HMAC لسلامة البيانات
      final hmac = await _securityService.generateHmac(
        jsonEncode(addresses),
        'crypto_wallets',
      );
      
      final dataToStore = {
        'wallets': addresses,
        'hmac': hmac,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'crypto_wallets',
        value: jsonEncode(dataToStore),
      );
    } catch (e) {
      // تجاهل أخطاء التخزين المؤقت
      _errorHandler.handleError(
        e,
        'خطأ في تخزين عناوين المحفظة',
        ErrorSeverity.low,
      );
    }
  }
  
  // الحصول على عناوين المحفظة الافتراضية
  Map<String, String> _getDefaultWalletAddresses() {
    // استخدام عناوين مؤقتة مميزة بوضوح كأمثلة
    return {
      'USDT_TRC20': 'EXAMPLE_TRON_ADDRESS_DO_NOT_USE',
      'USDT_ERC20': 'EXAMPLE_ETH_ADDRESS_DO_NOT_USE',
      'BTC': 'EXAMPLE_BTC_ADDRESS_DO_NOT_USE',
      'ETH': 'EXAMPLE_ETH_ADDRESS_DO_NOT_USE',
    };
  }
  
  @override
  Future<DepositResult> submitDepositRequest({
    required String userId,
    required String paymentMethodId,
    required double amount,
    required String currency,
    required String? reference,
    required String? proofImagePath,
    String? cryptoCurrency,
    String? walletAddress,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _ensureSessionActive();
      
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw PaymentException(
          'لا يوجد اتصال بالإنترنت متاح',
          'connectivity_error',
        );
      }
      
      // التحقق من صحة طلب الإيداع
      _validateDepositRequest(
        paymentMethodId,
        amount,
        currency,
        cryptoCurrency,
        walletAddress,
      );
      
      // حساب الرسوم
      final fees = _feeCalculator.calculateDepositFees(amount, currency);
      
      // التحقق مما إذا كان التأكيد الإضافي مطلوبًا
      final requiresConfirmation = _requiresAdditionalConfirmation(amount, currency);
      
      // إعداد بيانات الطلب
      final requestData = {
        'userId': userId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'fees': fees,
        'totalAmount': amount - fees, // المبلغ الصافي بعد خصم الرسوم
        'currency': currency,
        'reference': reference,
        'cryptoCurrency': cryptoCurrency,
        'walletAddress': walletAddress,
        'timestamp': DateTime.now().toIso8601String(),
        'requiresAdditionalConfirmation': requiresConfirmation,
      };
      
      if (additionalData != null) {
        requestData.addAll(additionalData);
      }
      
      // تشفير البيانات الحساسة
      final encryptedData = await _securityService.encryptPaymentData(requestData);
      
      // تحميل صورة الإثبات إذا تم توفيرها
      String? proofImageUrl;
      if (proofImagePath != null) {
        proofImageUrl = await _firebaseService.uploadDepositProofImage(
          userId,
          proofImagePath,
        );
      }
      
      // إرسال طلب الإيداع
      final response = await _apiService.post(
        '/payments/deposit',
        body: {
          'encryptedData': encryptedData,
          'proofImageUrl': proofImageUrl,
        },
      );
      
      // معالجة الاستجابة
      final depositId = response['depositId'];
      final status = response['status'];
      final message = response['message'];
      
      // حفظ طلب الإيداع في التخزين الآمن
      await _securelyStoreDepositRequest(
        userId,
        depositId,
        paymentMethodId,
        amount,
        currency,
        status,
        proofImageUrl,
      );
      
      return DepositResult(
        success: true,
        depositId: depositId,
        status: status,
        message: message,
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في إرسال طلب الإيداع',
        ErrorSeverity.high,
      );
      
      String errorMessage = 'فشل في معالجة طلب الإيداع';
      String errorCode = 'unknown_error';
      
      if (e is PaymentException) {
        errorMessage = e.message;
        errorCode = e.code;
      }
      
      return DepositResult(
        success: false,
        depositId: null,
        status: 'failed',
        message: errorMessage,
        errorCode: errorCode,
      );
    }
  }
  
  // التحقق من صحة طلب الإيداع
  void _validateDepositRequest(
    String paymentMethodId,
    double amount,
    String currency,
    String? cryptoCurrency,
    String? walletAddress,
  ) {
    if (amount <= 0) {
      throw PaymentException(
        'المبلغ يجب أن يكون أكبر من صفر',
        'invalid_amount',
      );
    }
    
    if (paymentMethodId == 'crypto') {
      if (cryptoCurrency == null || cryptoCurrency.isEmpty) {
        throw PaymentException(
          'يجب تحديد العملة المشفرة للإيداع',
          'missing_crypto_currency',
        );
      }
      
      if (!supportedCryptoCurrencies.contains(cryptoCurrency)) {
        throw PaymentException(
          'العملة المشفرة غير مدعومة: $cryptoCurrency',
          'unsupported_crypto_currency',
        );
      }
      
      if (walletAddress == null || walletAddress.isEmpty) {
        throw PaymentException(
          'يجب تحديد عنوان المحفظة للإيداع',
          'missing_wallet_address',
        );
      }
      
      if (!_securityService.validateWalletAddress(cryptoCurrency, walletAddress)) {
        throw PaymentException(
          'عنوان المحفظة غير صالح: $walletAddress',
          'invalid_wallet_address',
        );
      }
    }
  }
  
  // التحقق مما إذا كان التأكيد الإضافي مطلوبًا
  bool _requiresAdditionalConfirmation(double amount, String currency) {
    final threshold = _transactionThresholds[currency] ?? 1000.0;
    return amount >= threshold;
  }
  
  // تخزين طلب الإيداع بشكل آمن
  Future<void> _securelyStoreDepositRequest(
    String userId,
    String depositId,
    String paymentMethodId,
    double amount,
    String currency,
    String status,
    String? proofImageUrl,
  ) async {
    try {
      final depositData = {
        'depositId': depositId,
        'userId': userId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'currency': currency,
        'status': status,
        'proofImageUrl': proofImageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // توليد HMAC لسلامة البيانات
      final hmac = await _securityService.generateHmac(
        jsonEncode(depositData),
        'deposit_$depositId',
      );
      
      final dataToStore = {
        'deposit': depositData,
        'hmac': hmac,
      };
      
      await _secureStorage.write(
        key: 'deposit_$depositId',
        value: jsonEncode(dataToStore),
      );
      
      // تحديث قائمة الإيداعات للمستخدم
      await _updateUserDepositsList(userId, depositId);
    } catch (e) {
      // تجاهل أخطاء التخزين المؤقت
      _errorHandler.handleError(
        e,
        'خطأ في تخزين طلب الإيداع',
        ErrorSeverity.low,
      );
    }
  }
  
  // تحديث قائمة الإيداعات للمستخدم
  Future<void> _updateUserDepositsList(String userId, String depositId) async {
    try {
      final depositsListJson = await _secureStorage.read(key: 'user_deposits_$userId');
      
      List<String> depositsList = [];
      if (depositsListJson != null) {
        final Map<String, dynamic> depositsData = jsonDecode(depositsListJson);
        depositsList = List<String>.from(depositsData['deposits']);
      }
      
      if (!depositsList.contains(depositId)) {
        depositsList.add(depositId);
      }
      
      // توليد HMAC لسلامة البيانات
      final hmac = await _securityService.generateHmac(
        jsonEncode(depositsList),
        'user_deposits_$userId',
      );
      
      final dataToStore = {
        'deposits': depositsList,
        'hmac': hmac,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'user_deposits_$userId',
        value: jsonEncode(dataToStore),
      );
    } catch (e) {
      // تجاهل أخطاء التخزين المؤقت
      _errorHandler.handleError(
        e,
        'خطأ في تحديث قائمة الإيداعات للمستخدم',
        ErrorSeverity.low,
      );
    }
  }
  
  @override
  Future<WithdrawalResult> submitWithdrawalRequest({
    required String userId,
    required String paymentMethodId,
    required double amount,
    required String currency,
    required String? destinationAddress,
    required String? bankAccountInfo,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _ensureSessionActive();
      
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw PaymentException(
          'لا يوجد اتصال بالإنترنت متاح',
          'connectivity_error',
        );
      }
      
      // التحقق من صحة طلب السحب
      _validateWithdrawalRequest(
        paymentMethodId,
        amount,
        currency,
        destinationAddress,
        bankAccountInfo,
      );
      
      // حساب الرسوم
      final fees = _feeCalculator.calculateWithdrawalFees(amount, currency);
      
      // المبلغ الإجمالي مع الرسوم
      final totalAmount = amount + fees;
      
      // التحقق مما إذا كان التأكيد الإضافي مطلوبًا
      final requiresConfirmation = _requiresAdditionalConfirmation(amount, currency);
      
      // إعداد بيانات الطلب
      final requestData = {
        'userId': userId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'fees': fees,
        'totalAmount': totalAmount,
        'currency': currency,
        'destinationAddress': destinationAddress,
        'bankAccountInfo': bankAccountInfo,
        'timestamp': DateTime.now().toIso8601String(),
        'requiresAdditionalConfirmation': requiresConfirmation,
      };
      
      if (additionalData != null) {
        requestData.addAll(additionalData);
      }
      
      // تشفير البيانات الحساسة
      final encryptedData = await _securityService.encryptPaymentData(requestData);
      
      // إرسال طلب السحب
      final response = await _apiService.post(
        '/payments/withdraw',
        body: {
          'encryptedData': encryptedData,
        },
      );
      
      // معالجة الاستجابة
      final withdrawalId = response['withdrawalId'];
      final status = response['status'];
      final message = response['message'];
      
      // حفظ طلب السحب في التخزين الآمن
      await _securelyStoreWithdrawalRequest(
        userId,
        withdrawalId,
        paymentMethodId,
        amount,
        fees,
        totalAmount,
        currency,
        status,
      );
      
      return WithdrawalResult(
        success: true,
        withdrawalId: withdrawalId,
        status: status,
        message: message,
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في إرسال طلب السحب',
        ErrorSeverity.high,
      );
      
      String errorMessage = 'فشل في معالجة طلب السحب';
      String errorCode = 'unknown_error';
      
      if (e is PaymentException) {
        errorMessage = e.message;
        errorCode = e.code;
      }
      
      return WithdrawalResult(
        success: false,
        withdrawalId: null,
        status: 'failed',
        message: errorMessage,
        errorCode: errorCode,
      );
    }
  }
  
  // التحقق من صحة طلب السحب
  void _validateWithdrawalRequest(
    String paymentMethodId,
    double amount,
    String currency,
    String? destinationAddress,
    String? bankAccountInfo,
  ) {
    if (amount <= 0) {
      throw PaymentException(
        'المبلغ يجب أن يكون أكبر من صفر',
        'invalid_amount',
      );
    }
    
    if (paymentMethodId == 'crypto') {
      if (destinationAddress == null || destinationAddress.isEmpty) {
        throw PaymentException(
          'يجب تحديد عنوان الوجهة للسحب',
          'missing_destination_address',
        );
      }
      
      // التحقق من صحة تنسيق عنوان الوجهة
      if (!_securityService.validateWalletAddress(currency, destinationAddress)) {
        throw PaymentException(
          'عنوان الوجهة غير صالح: $destinationAddress',
          'invalid_destination_address',
        );
      }
    } else if (paymentMethodId == 'bank_transfer') {
      if (bankAccountInfo == null || bankAccountInfo.isEmpty) {
        throw PaymentException(
          'يجب تحديد معلومات الحساب المصرفي للسحب',
          'missing_bank_account_info',
        );
      }
    }
  }
  
  // تخزين طلب السحب بشكل آمن
  Future<void> _securelyStoreWithdrawalRequest(
    String userId,
    String withdrawalId,
    String paymentMethodId,
    double amount,
    double fees,
    double totalAmount,
    String currency,
    String status,
  ) async {
    try {
      final withdrawalData = {
        'withdrawalId': withdrawalId,
        'userId': userId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'fees': fees,
        'totalAmount': totalAmount,
        'currency': currency,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // توليد HMAC لسلامة البيانات
      final hmac = await _securityService.generateHmac(
        jsonEncode(withdrawalData),
        'withdrawal_$withdrawalId',
      );
      
      final dataToStore = {
        'withdrawal': withdrawalData,
        'hmac': hmac,
      };
      
      await _secureStorage.write(
        key: 'withdrawal_$withdrawalId',
        value: jsonEncode(dataToStore),
      );
      
      // تحديث قائمة السحوبات للمستخدم
      await _updateUserWithdrawalsList(userId, withdrawalId);
    } catch (e) {
      // تجاهل أخطاء التخزين المؤقت
      _errorHandler.handleError(
        e,
        'خطأ في تخزين طلب السحب',
        ErrorSeverity.low,
      );
    }
  }
  
  // تحديث قائمة السحوبات للمستخدم
  Future<void> _updateUserWithdrawalsList(String userId, String withdrawalId) async {
    try {
      final withdrawalsListJson = await _secureStorage.read(key: 'user_withdrawals_$userId');
      
      List<String> withdrawalsList = [];
      if (withdrawalsListJson != null) {
        final Map<String, dynamic> withdrawalsData = jsonDecode(withdrawalsListJson);
        withdrawalsList = List<String>.from(withdrawalsData['withdrawals']);
      }
      
      if (!withdrawalsList.contains(withdrawalId)) {
        withdrawalsList.add(withdrawalId);
      }
      
      // توليد HMAC لسلامة البيانات
      final hmac = await _securityService.generateHmac(
        jsonEncode(withdrawalsList),
        'user_withdrawals_$userId',
      );
      
      final dataToStore = {
        'withdrawals': withdrawalsList,
        'hmac': hmac,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'user_withdrawals_$userId',
        value: jsonEncode(dataToStore),
      );
    } catch (e) {
      // تجاهل أخطاء التخزين المؤقت
      _errorHandler.handleError(
        e,
        'خطأ في تحديث قائمة السحوبات للمستخدم',
        ErrorSeverity.low,
      );
    }
  }
  
  @override
  Future<ExchangeResult> exchangeCurrency({
    required String userId,
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    try {
      _ensureSessionActive();
      
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw PaymentException(
          'لا يوجد اتصال بالإنترنت متاح',
          'connectivity_error',
        );
      }
      
      // التحقق من صحة طلب تبادل العملات
      _validateExchangeRequest(fromCurrency, toCurrency, amount);
      
      // حساب الرسوم
      final fees = _feeCalculator.calculateCurrencyExchangeFees(amount, fromCurrency, toCurrency);
      
      // المبلغ الصافي بعد خصم الرسوم
      final netAmount = amount - fees;
      
      // الحصول على سعر الصرف
      final exchangeRate = await _getExchangeRate(fromCurrency, toCurrency);
      
      // حساب المبلغ المحول
      final convertedAmount = netAmount * exchangeRate;
      
      // التحقق مما إذا كان التأكيد الإضافي مطلوبًا
      final requiresConfirmation = _requiresAdditionalConfirmation(amount, fromCurrency);
      
      // إعداد بيانات الطلب
      final requestData = {
        'userId': userId,
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'amount': amount,
        'fees': fees,
        'netAmount': netAmount,
        'exchangeRate': exchangeRate,
        'convertedAmount': convertedAmount,
        'timestamp': DateTime.now().toIso8601String(),
        'requiresAdditionalConfirmation': requiresConfirmation,
      };
      
      // تشفير البيانات الحساسة
      final encryptedData = await _securityService.encryptPaymentData(requestData);
      
      // إرسال طلب تبادل العملات
      final response = await _apiService.post(
        '/payments/exchange',
        body: {
          'encryptedData': encryptedData,
        },
      );
      
      // معالجة الاستجابة
      final exchangeId = response['exchangeId'];
      final status = response['status'];
      final message = response['message'];
      
      // حفظ طلب تبادل العملات في التخزين الآمن
      await _securelyStoreExchangeRequest(
        userId,
        exchangeId,
        fromCurrency,
        toCurrency,
        amount,
        fees,
        netAmount,
        exchangeRate,
        convertedAmount,
        status,
      );
      
      return ExchangeResult(
        success: true,
        exchangeId: exchangeId,
        status: status,
        message: message,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        amount: amount,
        fees: fees,
        netAmount: netAmount,
        exchangeRate: exchangeRate,
        convertedAmount: convertedAmount,
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في إرسال طلب تبادل العملات',
        ErrorSeverity.high,
      );
      
      String errorMessage = 'فشل في معالجة طلب تبادل العملات';
      String errorCode = 'unknown_error';
      
      if (e is PaymentException) {
        errorMessage = e.message;
        errorCode = e.code;
      }
      
      return ExchangeResult(
        success: false,
        exchangeId: null,
        status: 'failed',
        message: errorMessage,
        errorCode: errorCode,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        amount: amount,
        fees: 0,
        netAmount: 0,
        exchangeRate: 0,
        convertedAmount: 0,
      );
    }
  }
  
  // التحقق من صحة طلب تبادل العملات
  void _validateExchangeRequest(
    String fromCurrency,
    String toCurrency,
    double amount,
  ) {
    if (amount <= 0) {
      throw PaymentException(
        'المبلغ يجب أن يكون أكبر من صفر',
        'invalid_amount',
      );
    }
    
    if (fromCurrency == toCurrency) {
      throw PaymentException(
        'لا يمكن تبادل العملة بنفسها',
        'same_currency',
      );
    }
  }
  
  // الحصول على سعر الصرف
  Future<double> _getExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      final response = await _apiService.get(
        '/payments/exchange-rate',
        queryParams: {
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
        },
        useCache: true,
        cacheDuration: const Duration(minutes: 5),
      );
      
      return response['rate'];
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على سعر الصرف',
        ErrorSeverity.medium,
      );
      
      // إرجاع سعر صرف افتراضي في حالة الفشل
      return _getDefaultExchangeRate(fromCurrency, toCurrency);
    }
  }
  
  // الحصول على سعر صرف افتراضي
  double _getDefaultExchangeRate(String fromCurrency, String toCurrency) {
    // أسعار صرف افتراضية مبسطة
    final Map<String, Map<String, double>> defaultRates = {
      'USD': {
        'EUR': 0.85,
        'SYP': 2500.0,
        'TRY': 30.0,
        'SAR': 3.75,
        'AED': 3.67,
        'USDT': 1.0,
        'BTC': 0.000025,
        'ETH': 0.0005,
      },
      'EUR': {
        'USD': 1.18,
        'SYP': 2950.0,
        'TRY': 35.0,
        'SAR': 4.4,
        'AED': 4.3,
        'USDT': 1.18,
        'BTC': 0.000029,
        'ETH': 0.00059,
      },
      'SYP': {
        'USD': 0.0004,
        'EUR': 0.00034,
        'TRY': 0.012,
        'SAR': 0.0015,
        'AED': 0.0015,
        'USDT': 0.0004,
        'BTC': 0.00000001,
        'ETH': 0.0000002,
      },
      'TRY': {
        'USD': 0.033,
        'EUR': 0.029,
        'SYP': 83.0,
        'SAR': 0.125,
        'AED': 0.122,
        'USDT': 0.033,
        'BTC': 0.0000008,
        'ETH': 0.000017,
      },
      'SAR': {
        'USD': 0.27,
        'EUR': 0.23,
        'SYP': 670.0,
        'TRY': 8.0,
        'AED': 0.98,
        'USDT': 0.27,
        'BTC': 0.000007,
        'ETH': 0.00013,
      },
      'AED': {
        'USD': 0.27,
        'EUR': 0.23,
        'SYP': 680.0,
        'TRY': 8.2,
        'SAR': 1.02,
        'USDT': 0.27,
        'BTC': 0.000007,
        'ETH': 0.00013,
      },
      'USDT': {
        'USD': 1.0,
        'EUR': 0.85,
        'SYP': 2500.0,
        'TRY': 30.0,
        'SAR': 3.75,
        'AED': 3.67,
        'BTC': 0.000025,
        'ETH': 0.0005,
      },
      'BTC': {
        'USD': 40000.0,
        'EUR': 34000.0,
        'SYP': 100000000.0,
        'TRY': 1200000.0,
        'SAR': 150000.0,
        'AED': 147000.0,
        'USDT': 40000.0,
        'ETH': 20.0,
      },
      'ETH': {
        'USD': 2000.0,
        'EUR': 1700.0,
        'SYP': 5000000.0,
        'TRY': 60000.0,
        'SAR': 7500.0,
        'AED': 7340.0,
        'USDT': 2000.0,
        'BTC': 0.05,
      },
    };
    
    if (defaultRates.containsKey(fromCurrency) && defaultRates[fromCurrency]!.containsKey(toCurrency)) {
      return defaultRates[fromCurrency]![toCurrency]!;
    }
    
    // إذا لم يتم العثور على سعر صرف، إرجاع 1.0 كقيمة افتراضية
    return 1.0;
  }
  
  // تخزين طلب تبادل العملات بشكل آمن
  Future<void> _securelyStoreExchangeRequest(
    String userId,
    String exchangeId,
    String fromCurrency,
    String toCurrency,
    double amount,
    double fees,
    double netAmount,
    double exchangeRate,
    double convertedAmount,
    String status,
  ) async {
    try {
      final exchangeData = {
        'exchangeId': exchangeId,
        'userId': userId,
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'amount': amount,
        'fees': fees,
        'netAmount': netAmount,
        'exchangeRate': exchangeRate,
        'convertedAmount': convertedAmount,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // توليد HMAC لسلامة البيانات
      final hmac = await _securityService.generateHmac(
        jsonEncode(exchangeData),
        'exchange_$exchangeId',
      );
      
      final dataToStore = {
        'exchange': exchangeData,
        'hmac': hmac,
      };
      
      await _secureStorage.write(
        key: 'exchange_$exchangeId',
        value: jsonEncode(dataToStore),
      );
      
      // تحديث قائمة تبادلات العملات للمستخدم
      await _updateUserExchangesList(userId, exchangeId);
    } catch (e) {
      // تجاهل أخطاء التخزين المؤقت
      _errorHandler.handleError(
        e,
        'خطأ في تخزين طلب تبادل العملات',
        ErrorSeverity.low,
      );
    }
  }
  
  // تحديث قائمة تبادلات العملات للمستخدم
  Future<void> _updateUserExchangesList(String userId, String exchangeId) async {
    try {
      final exchangesListJson = await _secureStorage.read(key: 'user_exchanges_$userId');
      
      List<String> exchangesList = [];
      if (exchangesListJson != null) {
        final Map<String, dynamic> exchangesData = jsonDecode(exchangesListJson);
        exchangesList = List<String>.from(exchangesData['exchanges']);
      }
      
      if (!exchangesList.contains(exchangeId)) {
        exchangesList.add(exchangeId);
      }
      
      // توليد HMAC لسلامة البيانات
      final hmac = await _securityService.generateHmac(
        jsonEncode(exchangesList),
        'user_exchanges_$userId',
      );
      
      final dataToStore = {
        'exchanges': exchangesList,
        'hmac': hmac,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'user_exchanges_$userId',
        value: jsonEncode(dataToStore),
      );
    } catch (e) {
      // تجاهل أخطاء التخزين المؤقت
      _errorHandler.handleError(
        e,
        'خطأ في تحديث قائمة تبادلات العملات للمستخدم',
        ErrorSeverity.low,
      );
    }
  }
}
