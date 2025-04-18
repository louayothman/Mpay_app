import 'package:flutter/material.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';

class PaymentGatewayService {
  final ApiIntegrationService _apiService = ApiIntegrationService();
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  final ErrorHandler _errorHandler = ErrorHandler();
  final SecurityUtils _securityUtils = SecurityUtils();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  // Supported payment gateways
  static const List<String> supportedGateways = [
    'stripe',
    'paypal',
    'crypto',
    'sham_cash',
    'bank_transfer',
  ];
  
  // Supported cryptocurrencies
  static const List<String> supportedCryptoCurrencies = [
    'USDT_TRC20',
    'USDT_ERC20',
    'BTC',
    'ETH',
  ];
  
  // Transaction thresholds for additional confirmation
  static const Map<String, double> _transactionThresholds = {
    'USD': 1000.0,
    'EUR': 1000.0,
    'SYP': 500000.0,
    'BTC': 0.05,
    'ETH': 1.0,
    'USDT': 1000.0,
  };
  
  // Session timeout duration
  static const Duration _sessionTimeout = Duration(minutes: 15);
  DateTime? _lastActivityTime;
  
  // Singleton pattern
  static final PaymentGatewayService _instance = PaymentGatewayService._internal();
  
  factory PaymentGatewayService() {
    return _instance;
  }
  
  PaymentGatewayService._internal();
  
  // Initialize the service
  Future<void> initialize() async {
    // Ensure API service is initialized
    await _apiService.initialize();
    
    // Initialize security features
    await _securityUtils.initializePaymentSecurity();
    
    // Reset last activity time
    _updateLastActivityTime();
  }
  
  // Update last activity time
  void _updateLastActivityTime() {
    _lastActivityTime = DateTime.now();
  }
  
  // Check if session is active
  bool _isSessionActive() {
    if (_lastActivityTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_lastActivityTime!) < _sessionTimeout;
  }
  
  // Ensure session is active
  void _ensureSessionActive() {
    if (!_isSessionActive()) {
      throw PaymentException(
        'Session expired. Please authenticate again.',
        'session_expired',
      );
    }
    
    // Update last activity time
    _updateLastActivityTime();
  }
  
  // Get available payment methods for a user
  Future<List<PaymentMethod>> getAvailablePaymentMethods(String userId) async {
    try {
      _ensureSessionActive();
      
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Return cached payment methods if available
        final cachedMethods = await _getCachedPaymentMethods(userId);
        if (cachedMethods.isNotEmpty) {
          return cachedMethods;
        }
        
        throw PaymentException(
          'No internet connection available',
          'connectivity_error',
        );
      }
      
      // Get payment methods from API
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
      
      // Cache payment methods securely
      await _securelyStorePaymentMethods(userId, paymentMethods);
      
      return paymentMethods;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get available payment methods',
        ErrorSeverity.medium,
      );
      
      // Try to get cached payment methods as fallback
      final cachedMethods = await _getCachedPaymentMethods(userId);
      if (cachedMethods.isNotEmpty) {
        return cachedMethods;
      }
      
      // Return default payment methods if all else fails
      return _getDefaultPaymentMethods();
    }
  }
  
  // Get cached payment methods
  Future<List<PaymentMethod>> _getCachedPaymentMethods(String userId) async {
    try {
      final cachedJson = await _secureStorage.read(key: 'payment_methods_$userId');
      
      if (cachedJson != null) {
        final Map<String, dynamic> cachedData = jsonDecode(cachedJson);
        
        // Verify data integrity with HMAC
        final String storedHmac = cachedData['hmac'];
        final List<dynamic> methodsJson = cachedData['methods'];
        
        final calculatedHmac = await _securityUtils._generateHmac(
          jsonEncode(methodsJson),
          'payment_methods_$userId',
        );
        
        if (calculatedHmac != storedHmac) {
          // Data integrity violation
          await _securityUtils.logSecurityEvent(
            userId,
            'data_integrity_violation',
            'HMAC verification failed for cached payment methods',
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
      // Ignore cache errors
      _errorHandler.handleError(
        e,
        'Error retrieving cached payment methods',
        ErrorSeverity.low,
      );
    }
    
    return [];
  }
  
  // Securely store payment methods
  Future<void> _securelyStorePaymentMethods(String userId, List<PaymentMethod> methods) async {
    try {
      final methodsJson = methods.map((method) => method.toJson()).toList();
      
      // Generate HMAC for data integrity
      final hmac = await _securityUtils._generateHmac(
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
      // Ignore cache errors
      _errorHandler.handleError(
        e,
        'Error storing payment methods',
        ErrorSeverity.low,
      );
    }
  }
  
  // Get default payment methods
  List<PaymentMethod> _getDefaultPaymentMethods() {
    return [
      PaymentMethod(
        id: 'crypto',
        name: 'Cryptocurrency',
        description: 'Pay with cryptocurrency',
        icon: Icons.currency_bitcoin,
        isEnabled: true,
        supportedCurrencies: ['USD', 'EUR'],
        paymentType: PaymentType.crypto,
        processingFee: 0.0,
        minAmount: 10.0,
        maxAmount: 10000.0,
      ),
      PaymentMethod(
        id: 'sham_cash',
        name: 'Sham Cash',
        description: 'Pay with Sham Cash',
        icon: Icons.account_balance_wallet,
        isEnabled: true,
        supportedCurrencies: ['USD', 'EUR', 'SYP'],
        paymentType: PaymentType.electronic,
        processingFee: 1.0,
        minAmount: 5.0,
        maxAmount: 5000.0,
      ),
    ];
  }
  
  // Get cryptocurrency wallet addresses
  Future<Map<String, String>> getCryptoWalletAddresses() async {
    try {
      _ensureSessionActive();
      
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Return cached wallet addresses if available
        final cachedAddresses = await _getSecurelyCachedWalletAddresses();
        if (cachedAddresses.isNotEmpty) {
          return cachedAddresses;
        }
        
        throw PaymentException(
          'No internet connection available',
          'connectivity_error',
        );
      }
      
      // Get wallet addresses from API
      final response = await _apiService.get(
        '/payments/crypto/wallets',
        useCache: true,
        cacheDuration: const Duration(days: 1),
      );
      
      final Map<String, String> walletAddresses = {};
      
      if (response['wallets'] != null && response['wallets'] is Map) {
        for (final entry in response['wallets'].entries) {
          final address = entry.value.toString();
          
          // Validate wallet address format
          if (_securityUtils.validateWalletAddress(entry.key, address)) {
            walletAddresses[entry.key] = address;
          } else {
            // Log invalid wallet address
            await _securityUtils.logSecurityEvent(
              'system',
              'invalid_wallet_address',
              'Invalid wallet address format for ${entry.key}',
            );
          }
        }
      }
      
      // Cache wallet addresses securely
      await _securelyStoreWalletAddresses(walletAddresses);
      
      return walletAddresses;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get cryptocurrency wallet addresses',
        ErrorSeverity.medium,
      );
      
      // Try to get cached wallet addresses as fallback
      final cachedAddresses = await _getSecurelyCachedWalletAddresses();
      if (cachedAddresses.isNotEmpty) {
        return cachedAddresses;
      }
      
      // Return default wallet addresses if all else fails
      return _getDefaultWalletAddresses();
    }
  }
  
  // Get securely cached wallet addresses
  Future<Map<String, String>> _getSecurelyCachedWalletAddresses() async {
    try {
      final cachedJson = await _secureStorage.read(key: 'crypto_wallets');
      
      if (cachedJson != null) {
        final Map<String, dynamic> cachedData = jsonDecode(cachedJson);
        
        // Verify data integrity with HMAC
        final String storedHmac = cachedData['hmac'];
        final Map<String, dynamic> walletsData = cachedData['wallets'];
        
        final calculatedHmac = await _securityUtils._generateHmac(
          jsonEncode(walletsData),
          'crypto_wallets',
        );
        
        if (calculatedHmac != storedHmac) {
          // Data integrity violation
          await _securityUtils.logSecurityEvent(
            'system',
            'data_integrity_violation',
            'HMAC verification failed for cached wallet addresses',
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
      // Ignore cache errors
      _errorHandler.handleError(
        e,
        'Error retrieving cached wallet addresses',
        ErrorSeverity.low,
      );
    }
    
    return {};
  }
  
  // Securely store wallet addresses
  Future<void> _securelyStoreWalletAddresses(Map<String, String> addresses) async {
    try {
      // Generate HMAC for data integrity
      final hmac = await _securityUtils._generateHmac(
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
      // Ignore cache errors
      _errorHandler.handleError(
        e,
        'Error storing wallet addresses',
        ErrorSeverity.low,
      );
    }
  }
  
  // Get default wallet addresses
  Map<String, String> _getDefaultWalletAddresses() {
    // Use placeholder addresses that are clearly marked as examples
    return {
      'USDT_TRC20': 'EXAMPLE_TRON_ADDRESS_DO_NOT_USE',
      'USDT_ERC20': 'EXAMPLE_ETH_ADDRESS_DO_NOT_USE',
      'BTC': 'EXAMPLE_BTC_ADDRESS_DO_NOT_USE',
      'ETH': 'EXAMPLE_ETH_ADDRESS_DO_NOT_USE',
    };
  }
  
  // Submit deposit request
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
          'No internet connection available',
          'connectivity_error',
        );
      }
      
      // Validate deposit request
      _validateDepositRequest(
        paymentMethodId,
        amount,
        currency,
        cryptoCurrency,
        walletAddress,
      );
      
      // Check if additional confirmation is required
      final requiresConfirmation = _requiresAdditionalConfirmation(amount, currency);
      
      // Prepare request data
      final requestData = {
        'userId': userId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
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
      
      // Encrypt sensitive data
      final encryptedData = await _securityUtils.encryptPaymentData(requestData);
      
      // Upload proof image if provided
      String? proofImageUrl;
      if (proofImagePath != null) {
        proofImageUrl = await _firebaseService.uploadDepositProofImage(
          userId,
          proofImagePath,
        );
      }
      
      // Submit deposit request
      final response = await _apiService.post(
        '/payments/deposit',
        body: {
          'encryptedData': encryptedData,
          'proofImageUrl': proofImageUrl,
        },
      );
      
      // Process response
      final depositId = response['depositId'];
      final status = response['status'];
      final message = response['message'];
      
      // Save deposit request to secure storage
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
        'Failed to submit deposit request',
        ErrorSeverity.high,
      );
      
      String errorMessage = 'Failed to process deposit request';
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
  
  // Validate deposit request
  void _validateDepositRequest(
    String paymentMethodId,
    double amount,
    String currency,
    String? cryptoCurrency,
    String? walletAddress,
  ) {
    // Check if payment method is supported
    if (!supportedGateways.contains(paymentMethodId)) {
      throw PaymentException(
        'Unsupported payment method',
        'invalid_payment_method',
      );
    }
    
    // Check amount
    if (amount <= 0) {
      throw PaymentException(
        'Invalid amount',
        'invalid_amount',
      );
    }
    
    // Check currency
    if (currency.isEmpty) {
      throw PaymentException(
        'Invalid currency',
        'invalid_currency',
      );
    }
    
    // Check crypto currency if applicable
    if (paymentMethodId == 'crypto' && cryptoCurrency != null) {
      if (!supportedCryptoCurrencies.contains(cryptoCurrency)) {
        throw PaymentException(
          'Unsupported cryptocurrency',
          'invalid_crypto_currency',
        );
      }
      
      // Validate wallet address if provided
      if (walletAddress != null && !walletAddress.isEmpty) {
        if (!_securityUtils.validateWalletAddress(cryptoCurrency, walletAddress)) {
          throw PaymentException(
            'Invalid wallet address format',
            'invalid_wallet_address',
          );
        }
      }
    }
  }
  
  // Check if transaction requires additional confirmation
  bool _requiresAdditionalConfirmation(double amount, String currency) {
    final threshold = _transactionThresholds[currency] ?? 1000.0;
    return amount >= threshold;
  }
  
  // Securely store deposit request
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
        'id': depositId,
        'type': 'deposit',
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'currency': currency,
        'status': status,
        'proofImageUrl': proofImageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Get existing transactions
      final existingTransactionsJson = await _secureStorage.read(key: 'transactions_$userId');
      List<Map<String, dynamic>> transactions = [];
      
      if (existingTransactionsJson != null) {
        final Map<String, dynamic> existingData = jsonDecode(existingTransactionsJson);
        
        // Verify data integrity with HMAC
        final String storedHmac = existingData['hmac'];
        final List<dynamic> transactionsData = existingData['transactions'];
        
        final calculatedHmac = await _securityUtils._generateHmac(
          jsonEncode(transactionsData),
          'transactions_$userId',
        );
        
        if (calculatedHmac == storedHmac) {
          transactions = List<Map<String, dynamic>>.from(transactionsData);
        } else {
          // Data integrity violation
          await _securityUtils.logSecurityEvent(
            userId,
            'data_integrity_violation',
            'HMAC verification failed for transactions',
          );
        }
      }
      
      // Add new transaction
      transactions.add(depositData);
      
      // Generate HMAC for data integrity
      final hmac = await _securityUtils._generateHmac(
        jsonEncode(transactions),
        'transactions_$userId',
      );
      
      final dataToStore = {
        'transactions': transactions,
        'hmac': hmac,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'transactions_$userId',
        value: jsonEncode(dataToStore),
      );
    } catch (e) {
      // Log error but don't throw
      _errorHandler.handleError(
        e,
        'Failed to save deposit request to secure storage',
        ErrorSeverity.low,
      );
    }
  }
  
  // Submit withdrawal request
  Future<WithdrawalResult> submitWithdrawalRequest({
    required String userId,
    required String paymentMethodId,
    required double amount,
    required String currency,
    required String? destinationAddress,
    String? cryptoCurrency,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _ensureSessionActive();
      
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw PaymentException(
          'No internet connection available',
          'connectivity_error',
        );
      }
      
      // Validate withdrawal request
      _validateWithdrawalRequest(
        paymentMethodId,
        amount,
        currency,
        destinationAddress,
        cryptoCurrency,
      );
      
      // Check if additional confirmation is required
      final requiresConfirmation = _requiresAdditionalConfirmation(amount, currency);
      
      // Check user balance
      final hasBalance = await _checkUserBalance(userId, amount, currency);
      if (!hasBalance) {
        throw PaymentException(
          'Insufficient balance',
          'insufficient_balance',
        );
      }
      
      // Prepare request data
      final requestData = {
        'userId': userId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'currency': currency,
        'destinationAddress': destinationAddress,
        'cryptoCurrency': cryptoCurrency,
        'timestamp': DateTime.now().toIso8601String(),
        'requiresAdditionalConfirmation': requiresConfirmation,
      };
      
      if (additionalData != null) {
        requestData.addAll(additionalData);
      }
      
      // Encrypt sensitive data
      final encryptedData = await _securityUtils.encryptPaymentData(requestData);
      
      // Submit withdrawal request
      final response = await _apiService.post(
        '/payments/withdrawal',
        body: {
          'encryptedData': encryptedData,
        },
      );
      
      // Process response
      final withdrawalId = response['withdrawalId'];
      final status = response['status'];
      final message = response['message'];
      
      // Save withdrawal request to secure storage
      await _securelyStoreWithdrawalRequest(
        userId,
        withdrawalId,
        paymentMethodId,
        amount,
        currency,
        status,
        destinationAddress,
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
        'Failed to submit withdrawal request',
        ErrorSeverity.high,
      );
      
      String errorMessage = 'Failed to process withdrawal request';
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
  
  // Validate withdrawal request
  void _validateWithdrawalRequest(
    String paymentMethodId,
    double amount,
    String currency,
    String? destinationAddress,
    String? cryptoCurrency,
  ) {
    // Check if payment method is supported
    if (!supportedGateways.contains(paymentMethodId)) {
      throw PaymentException(
        'Unsupported payment method',
        'invalid_payment_method',
      );
    }
    
    // Check amount
    if (amount <= 0) {
      throw PaymentException(
        'Invalid amount',
        'invalid_amount',
      );
    }
    
    // Check currency
    if (currency.isEmpty) {
      throw PaymentException(
        'Invalid currency',
        'invalid_currency',
      );
    }
    
    // Check destination address
    if (destinationAddress == null || destinationAddress.isEmpty) {
      throw PaymentException(
        'Destination address is required',
        'missing_destination_address',
      );
    }
    
    // Check crypto currency if applicable
    if (paymentMethodId == 'crypto') {
      if (cryptoCurrency == null || !supportedCryptoCurrencies.contains(cryptoCurrency)) {
        throw PaymentException(
          'Unsupported or missing cryptocurrency',
          'invalid_crypto_currency',
        );
      }
      
      // Validate destination address
      if (!_securityUtils.validateWalletAddress(cryptoCurrency, destinationAddress)) {
        throw PaymentException(
          'Invalid destination address format',
          'invalid_destination_address',
        );
      }
    }
  }
  
  // Check user balance
  Future<bool> _checkUserBalance(String userId, double amount, String currency) async {
    try {
      final response = await _apiService.get(
        '/users/$userId/balance',
        queryParams: {'currency': currency},
        useCache: false,
      );
      
      if (response['balance'] != null) {
        final double balance = double.parse(response['balance'].toString());
        return balance >= amount;
      }
      
      return false;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to check user balance',
        ErrorSeverity.medium,
      );
      return false;
    }
  }
  
  // Securely store withdrawal request
  Future<void> _securelyStoreWithdrawalRequest(
    String userId,
    String withdrawalId,
    String paymentMethodId,
    double amount,
    String currency,
    String status,
    String? destinationAddress,
  ) async {
    try {
      final withdrawalData = {
        'id': withdrawalId,
        'type': 'withdrawal',
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'currency': currency,
        'status': status,
        'destinationAddress': destinationAddress,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Get existing transactions
      final existingTransactionsJson = await _secureStorage.read(key: 'transactions_$userId');
      List<Map<String, dynamic>> transactions = [];
      
      if (existingTransactionsJson != null) {
        final Map<String, dynamic> existingData = jsonDecode(existingTransactionsJson);
        
        // Verify data integrity with HMAC
        final String storedHmac = existingData['hmac'];
        final List<dynamic> transactionsData = existingData['transactions'];
        
        final calculatedHmac = await _securityUtils._generateHmac(
          jsonEncode(transactionsData),
          'transactions_$userId',
        );
        
        if (calculatedHmac == storedHmac) {
          transactions = List<Map<String, dynamic>>.from(transactionsData);
        } else {
          // Data integrity violation
          await _securityUtils.logSecurityEvent(
            userId,
            'data_integrity_violation',
            'HMAC verification failed for transactions',
          );
        }
      }
      
      // Add new transaction
      transactions.add(withdrawalData);
      
      // Generate HMAC for data integrity
      final hmac = await _securityUtils._generateHmac(
        jsonEncode(transactions),
        'transactions_$userId',
      );
      
      final dataToStore = {
        'transactions': transactions,
        'hmac': hmac,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'transactions_$userId',
        value: jsonEncode(dataToStore),
      );
    } catch (e) {
      // Log error but don't throw
      _errorHandler.handleError(
        e,
        'Failed to save withdrawal request to secure storage',
        ErrorSeverity.low,
      );
    }
  }
  
  // Get user transactions
  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      _ensureSessionActive();
      
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      // Try to get transactions from secure storage first
      final localTransactions = await _getSecurelyStoredTransactions(userId);
      
      if (!hasConnection) {
        return localTransactions;
      }
      
      // Get transactions from API
      final response = await _apiService.get(
        '/users/$userId/transactions',
        useCache: true,
        cacheDuration: const Duration(minutes: 30),
      );
      
      final List<Transaction> transactions = [];
      
      if (response['transactions'] != null && response['transactions'] is List) {
        for (final transaction in response['transactions']) {
          transactions.add(Transaction.fromJson(transaction));
        }
      }
      
      // Update local cache
      await _securelyStoreTransactions(userId, transactions);
      
      return transactions;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get user transactions',
        ErrorSeverity.medium,
      );
      
      // Return local transactions as fallback
      return await _getSecurelyStoredTransactions(userId);
    }
  }
  
  // Get securely stored transactions
  Future<List<Transaction>> _getSecurelyStoredTransactions(String userId) async {
    try {
      final transactionsJson = await _secureStorage.read(key: 'transactions_$userId');
      
      if (transactionsJson != null) {
        final Map<String, dynamic> storedData = jsonDecode(transactionsJson);
        
        // Verify data integrity with HMAC
        final String storedHmac = storedData['hmac'];
        final List<dynamic> transactionsData = storedData['transactions'];
        
        final calculatedHmac = await _securityUtils._generateHmac(
          jsonEncode(transactionsData),
          'transactions_$userId',
        );
        
        if (calculatedHmac != storedHmac) {
          // Data integrity violation
          await _securityUtils.logSecurityEvent(
            userId,
            'data_integrity_violation',
            'HMAC verification failed for transactions',
          );
          return [];
        }
        
        final List<Transaction> transactions = [];
        for (final transaction in transactionsData) {
          transactions.add(Transaction.fromJson(transaction));
        }
        
        return transactions;
      }
    } catch (e) {
      // Ignore cache errors
      _errorHandler.handleError(
        e,
        'Error retrieving stored transactions',
        ErrorSeverity.low,
      );
    }
    
    return [];
  }
  
  // Securely store transactions
  Future<void> _securelyStoreTransactions(String userId, List<Transaction> transactions) async {
    try {
      final transactionsJson = transactions.map((transaction) => transaction.toJson()).toList();
      
      // Generate HMAC for data integrity
      final hmac = await _securityUtils._generateHmac(
        jsonEncode(transactionsJson),
        'transactions_$userId',
      );
      
      final dataToStore = {
        'transactions': transactionsJson,
        'hmac': hmac,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: 'transactions_$userId',
        value: jsonEncode(dataToStore),
      );
    } catch (e) {
      // Ignore cache errors
      _errorHandler.handleError(
        e,
        'Error storing transactions',
        ErrorSeverity.low,
      );
    }
  }
  
  // End user session
  Future<void> endSession() async {
    _lastActivityTime = null;
  }
}

// Payment Method class
class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool isEnabled;
  final List<String> supportedCurrencies;
  final PaymentType paymentType;
  final double processingFee;
  final double minAmount;
  final double maxAmount;
  
  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isEnabled,
    required this.supportedCurrencies,
    required this.paymentType,
    required this.processingFee,
    required this.minAmount,
    required this.maxAmount,
  });
  
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: _getIconFromString(json['icon']),
      isEnabled: json['isEnabled'] ?? true,
      supportedCurrencies: List<String>.from(json['supportedCurrencies'] ?? []),
      paymentType: _getPaymentTypeFromString(json['paymentType']),
      processingFee: double.parse(json['processingFee']?.toString() ?? '0.0'),
      minAmount: double.parse(json['minAmount']?.toString() ?? '0.0'),
      maxAmount: double.parse(json['maxAmount']?.toString() ?? '0.0'),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': _getStringFromIcon(icon),
      'isEnabled': isEnabled,
      'supportedCurrencies': supportedCurrencies,
      'paymentType': _getStringFromPaymentType(paymentType),
      'processingFee': processingFee,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
    };
  }
  
  static IconData _getIconFromString(String? iconString) {
    switch (iconString) {
      case 'currency_bitcoin':
        return Icons.currency_bitcoin;
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance':
        return Icons.account_balance;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
  
  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.currency_bitcoin) {
      return 'currency_bitcoin';
    } else if (icon == Icons.credit_card) {
      return 'credit_card';
    } else if (icon == Icons.account_balance) {
      return 'account_balance';
    } else if (icon == Icons.account_balance_wallet) {
      return 'account_balance_wallet';
    } else {
      return 'payment';
    }
  }
  
  static PaymentType _getPaymentTypeFromString(String? typeString) {
    switch (typeString) {
      case 'crypto':
        return PaymentType.crypto;
      case 'bank':
        return PaymentType.bank;
      case 'card':
        return PaymentType.card;
      case 'electronic':
        return PaymentType.electronic;
      default:
        return PaymentType.other;
    }
  }
  
  static String _getStringFromPaymentType(PaymentType type) {
    switch (type) {
      case PaymentType.crypto:
        return 'crypto';
      case PaymentType.bank:
        return 'bank';
      case PaymentType.card:
        return 'card';
      case PaymentType.electronic:
        return 'electronic';
      case PaymentType.other:
        return 'other';
    }
  }
}

// Payment Type enum
enum PaymentType {
  crypto,
  bank,
  card,
  electronic,
  other,
}

// Transaction class
class Transaction {
  final String id;
  final String type;
  final String paymentMethodId;
  final double amount;
  final String currency;
  final String status;
  final String? proofImageUrl;
  final String? destinationAddress;
  final DateTime timestamp;
  
  Transaction({
    required this.id,
    required this.type,
    required this.paymentMethodId,
    required this.amount,
    required this.currency,
    required this.status,
    this.proofImageUrl,
    this.destinationAddress,
    required this.timestamp,
  });
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      paymentMethodId: json['paymentMethodId'],
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'],
      status: json['status'],
      proofImageUrl: json['proofImageUrl'],
      destinationAddress: json['destinationAddress'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'paymentMethodId': paymentMethodId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'proofImageUrl': proofImageUrl,
      'destinationAddress': destinationAddress,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Deposit Result class
class DepositResult {
  final bool success;
  final String? depositId;
  final String status;
  final String message;
  final String? errorCode;
  
  DepositResult({
    required this.success,
    this.depositId,
    required this.status,
    required this.message,
    this.errorCode,
  });
}

// Withdrawal Result class
class WithdrawalResult {
  final bool success;
  final String? withdrawalId;
  final String status;
  final String message;
  final String? errorCode;
  
  WithdrawalResult({
    required this.success,
    this.withdrawalId,
    required this.status,
    required this.message,
    this.errorCode,
  });
}

// Payment Exception class
class PaymentException implements Exception {
  final String message;
  final String code;
  
  PaymentException(this.message, this.code);
  
  @override
  String toString() {
    return 'PaymentException: $message (Code: $code)';
  }
}
