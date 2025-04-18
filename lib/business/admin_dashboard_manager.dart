import 'package:flutter/material.dart';
import 'package:mpay_app/domain/entities/user/user.dart';
import 'package:mpay_app/utils/currency_converter.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';

/// مدير لوحة تحكم المشرف
///
/// يوفر وظائف لإدارة لوحة تحكم المشرف، بما في ذلك إدارة أسعار الصرف وحسابات المستخدمين والتقارير
class AdminDashboardManager {
  final ApiIntegrationService _apiService;
  final FirebaseService _firebaseService;
  final ErrorHandler _errorHandler;
  final CurrencyConverter _currencyConverter;
  final FlutterSecureStorage _secureStorage;
  
  // Singleton pattern
  static final AdminDashboardManager _instance = AdminDashboardManager._internal();
  
  factory AdminDashboardManager({
    required ApiIntegrationService apiService,
    required FirebaseService firebaseService,
    required ErrorHandler errorHandler,
    required CurrencyConverter currencyConverter,
    FlutterSecureStorage? secureStorage,
  }) {
    _instance._apiService = apiService;
    _instance._firebaseService = firebaseService;
    _instance._errorHandler = errorHandler;
    _instance._currencyConverter = currencyConverter;
    _instance._secureStorage = secureStorage ?? const FlutterSecureStorage();
    return _instance;
  }
  
  AdminDashboardManager._internal()
      : _apiService = ApiIntegrationService(),
        _firebaseService = FirebaseService(),
        _errorHandler = ErrorHandler(),
        _currencyConverter = CurrencyConverter(
          apiService: ApiIntegrationService(),
          firebaseService: FirebaseService(),
          errorHandler: ErrorHandler(),
        ),
        _secureStorage = const FlutterSecureStorage();
  
  /// تهيئة مدير لوحة تحكم المشرف
  Future<void> initialize() async {
    try {
      await _currencyConverter.initialize();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تهيئة مدير لوحة تحكم المشرف',
        ErrorSeverity.high,
      );
    }
  }
  
  /// التحقق مما إذا كان المستخدم مشرفًا
  Future<bool> isAdmin(String userId) async {
    try {
      final response = await _apiService.get(
        '/admin/check',
        queryParams: {'userId': userId},
      );
      
      return response != null && response['isAdmin'] == true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في التحقق من صلاحيات المشرف',
        ErrorSeverity.medium,
      );
      
      return false;
    }
  }
  
  /// الحصول على معلومات المشرف
  Future<Map<String, dynamic>?> getAdminInfo(String adminId) async {
    try {
      final response = await _apiService.get(
        '/admin/info',
        queryParams: {'adminId': adminId},
      );
      
      return response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على معلومات المشرف',
        ErrorSeverity.medium,
      );
      
      return null;
    }
  }
  
  /// تحديث سعر الصرف
  Future<bool> updateExchangeRate(String currency, double newRate, String adminId) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      // تحديث سعر الصرف
      final success = await _currencyConverter.updateExchangeRate(currency, newRate, adminId);
      
      if (success) {
        // تسجيل عملية التحديث
        await _firebaseService.logAdminAction(
          adminId,
          'update_exchange_rate',
          {
            'currency': currency,
            'new_rate': newRate,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحديث سعر الصرف',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// تحديث رسوم المعاملات
  Future<bool> updateTransactionFee(String currency, double newFee, String adminId) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      // تحديث رسوم المعاملات
      final success = await _currencyConverter.updateTransactionFee(currency, newFee, adminId);
      
      if (success) {
        // تسجيل عملية التحديث
        await _firebaseService.logAdminAction(
          adminId,
          'update_transaction_fee',
          {
            'currency': currency,
            'new_fee': newFee,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحديث رسوم المعاملات',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// تحديث عنوان محفظة الإيداع
  Future<bool> updateDepositWalletAddress(String currency, String newAddress, String adminId) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      // تحديث عنوان محفظة الإيداع
      final success = await _currencyConverter.updateDepositWalletAddress(currency, newAddress, adminId);
      
      if (success) {
        // تسجيل عملية التحديث
        await _firebaseService.logAdminAction(
          adminId,
          'update_deposit_wallet_address',
          {
            'currency': currency,
            'new_address': newAddress,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تحديث عنوان محفظة الإيداع',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// إضافة عملة جديدة
  Future<bool> addNewCurrency(String currency, double exchangeRate, double transactionFee, String adminId) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      // إضافة العملة الجديدة
      final success = await _currencyConverter.addNewCurrency(currency, exchangeRate, transactionFee, adminId);
      
      if (success) {
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
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في إضافة عملة جديدة',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// إضافة طريقة إيداع جديدة
  Future<bool> addNewDepositMethod(String method, String walletAddress, String adminId) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      // إضافة طريقة الإيداع الجديدة
      final success = await _currencyConverter.addNewDepositMethod(method, walletAddress, adminId);
      
      if (success) {
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
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في إضافة طريقة إيداع جديدة',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// الحصول على جميع أسعار الصرف
  Future<Map<String, double>> getAllExchangeRates() async {
    try {
      return _currencyConverter.getAllExchangeRates();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على أسعار الصرف',
        ErrorSeverity.medium,
      );
      
      return {};
    }
  }
  
  /// الحصول على جميع رسوم المعاملات
  Future<Map<String, double>> getAllTransactionFees() async {
    try {
      return _currencyConverter.getAllTransactionFees();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على رسوم المعاملات',
        ErrorSeverity.medium,
      );
      
      return {};
    }
  }
  
  /// الحصول على جميع عناوين محافظ الإيداع
  Future<Map<String, String>> getAllDepositWalletAddresses() async {
    try {
      return _currencyConverter.getAllDepositWalletAddresses();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على عناوين محافظ الإيداع',
        ErrorSeverity.medium,
      );
      
      return {};
    }
  }
  
  /// الحصول على قائمة المستخدمين
  Future<List<User>> getAllUsers(String adminId) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      final response = await _apiService.get(
        '/admin/users',
        queryParams: {'adminId': adminId},
      );
      
      final List<User> users = [];
      
      if (response != null && response['users'] != null && response['users'] is List) {
        for (final userData in response['users']) {
          users.add(User.fromJson(userData));
        }
      }
      
      return users;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على قائمة المستخدمين',
        ErrorSeverity.high,
      );
      
      return [];
    }
  }
  
  /// الحصول على معلومات مستخدم محدد
  Future<User?> getUserDetails(String userId, String adminId) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      final response = await _apiService.get(
        '/admin/users/$userId',
        queryParams: {'adminId': adminId},
      );
      
      if (response != null && response['user'] != null) {
        return User.fromJson(response['user']);
      }
      
      return null;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على معلومات المستخدم',
        ErrorSeverity.medium,
      );
      
      return null;
    }
  }
  
  /// تعطيل حساب مستخدم
  Future<bool> disableUserAccount(String userId, String adminId, String reason) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      final response = await _apiService.post(
        '/admin/users/$userId/disable',
        body: {
          'adminId': adminId,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      final success = response != null && response['success'] == true;
      
      if (success) {
        // تسجيل عملية التعطيل
        await _firebaseService.logAdminAction(
          adminId,
          'disable_user_account',
          {
            'userId': userId,
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تعطيل حساب المستخدم',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// تفعيل حساب مستخدم
  Future<bool> enableUserAccount(String userId, String adminId, String reason) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      final response = await _apiService.post(
        '/admin/users/$userId/enable',
        body: {
          'adminId': adminId,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      final success = response != null && response['success'] == true;
      
      if (success) {
        // تسجيل عملية التفعيل
        await _firebaseService.logAdminAction(
          adminId,
          'enable_user_account',
          {
            'userId': userId,
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تفعيل حساب المستخدم',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// الحصول على تقرير المعاملات
  Future<Map<String, dynamic>?> getTransactionsReport(
    String adminId, {
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    String? transactionType,
  }) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      final queryParams = {
        'adminId': adminId,
      };
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      if (currency != null) {
        queryParams['currency'] = currency;
      }
      
      if (transactionType != null) {
        queryParams['transactionType'] = transactionType;
      }
      
      final response = await _apiService.get(
        '/admin/reports/transactions',
        queryParams: queryParams,
      );
      
      return response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على تقرير المعاملات',
        ErrorSeverity.high,
      );
      
      return null;
    }
  }
  
  /// الحصول على تقرير المستخدمين
  Future<Map<String, dynamic>?> getUsersReport(
    String adminId, {
    DateTime? startDate,
    DateTime? endDate,
    int? userLevel,
  }) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      final queryParams = {
        'adminId': adminId,
      };
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      if (userLevel != null) {
        queryParams['userLevel'] = userLevel.toString();
      }
      
      final response = await _apiService.get(
        '/admin/reports/users',
        queryParams: queryParams,
      );
      
      return response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على تقرير المستخدمين',
        ErrorSeverity.high,
      );
      
      return null;
    }
  }
  
  /// إنشاء حساب مشرف جديد
  Future<bool> createAdminAccount(
    String adminId,
    String newAdminEmail,
    String newAdminName,
    String newAdminPassword,
  ) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      final response = await _apiService.post(
        '/admin/create',
        body: {
          'adminId': adminId,
          'email': newAdminEmail,
          'name': newAdminName,
          'password': newAdminPassword,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      final success = response != null && response['success'] == true;
      
      if (success) {
        // تسجيل عملية إنشاء حساب مشرف جديد
        await _firebaseService.logAdminAction(
          adminId,
          'create_admin_account',
          {
            'newAdminEmail': newAdminEmail,
            'newAdminName': newAdminName,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في إنشاء حساب مشرف جديد',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
  
  /// الحصول على معلومات تسجيل الدخول للمشرف
  Future<Map<String, String>?> getAdminLoginInfo() async {
    try {
      return {
        'email': 'admin@mpay.com',
        'password': 'Admin@123',
      };
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في الحصول على معلومات تسجيل الدخول للمشرف',
        ErrorSeverity.low,
      );
      
      return null;
    }
  }
  
  /// تهيئة محفظة المشرف بأرصدة كبيرة
  Future<bool> initializeAdminWallet(String adminId) async {
    try {
      // التحقق من صلاحيات المشرف
      final isAdminUser = await isAdmin(adminId);
      if (!isAdminUser) {
        throw Exception('ليس لديك صلاحيات كافية لتنفيذ هذه العملية');
      }
      
      final currencies = _currencyConverter.getSupportedCurrencies();
      final largeBalance = 999999999999.0;
      
      // تهيئة محفظة المشرف بأرصدة كبيرة لكل عملة مدعومة
      final response = await _apiService.post(
        '/admin/wallet/initialize',
        body: {
          'adminId': adminId,
          'balances': Map.fromIterable(
            currencies,
            key: (currency) => currency,
            value: (_) => largeBalance,
          ),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      final success = response != null && response['success'] == true;
      
      if (success) {
        // تسجيل عملية تهيئة محفظة المشرف
        await _firebaseService.logAdminAction(
          adminId,
          'initialize_admin_wallet',
          {
            'currencies': currencies,
            'balance': largeBalance,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      
      return success;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'فشل في تهيئة محفظة المشرف',
        ErrorSeverity.high,
      );
      
      return false;
    }
  }
}
