import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mpay_app/utils/performance_utils.dart';
import 'package:mpay_app/services/firestore_service.dart';
import 'package:mpay_app/utils/cache_manager.dart';
import 'package:mpay_app/utils/currency_converter.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/error_handler.dart';

/// مزود حالة المحفظة
///
/// يدير حالة المحفظة ويوفر واجهة موحدة للوصول إلى بيانات المحفظة
/// ويقلل من استخدام setState في شاشات المحفظة المختلفة
class WalletStateProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final CacheManager _cacheManager = CacheManager();
  final CurrencyConverter _currencyConverter = CurrencyConverter(
    apiService: ApiIntegrationService(),
    firebaseService: FirebaseService(),
    errorHandler: ErrorHandler(),
  );
  
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // قائمة العملات المدعومة
  List<String> _supportedCurrencies = [];

  // الوصول إلى البيانات
  Map<String, dynamic>? get walletData => _walletData;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<String> get supportedCurrencies => _supportedCurrencies;

  WalletStateProvider() {
    _initializeCurrencies();
    _loadWalletData();
  }

  /// تهيئة قائمة العملات المدعومة
  Future<void> _initializeCurrencies() async {
    try {
      final currencies = _currencyConverter.getSupportedCurrencies();
      _supportedCurrencies = currencies;
      notifyListeners();
    } catch (e) {
      // استخدام قائمة افتراضية في حالة فشل الحصول على العملات المدعومة
      _supportedCurrencies = [
        'SYP',  // ليرة سورية
        'USD',  // دولار أمريكي
        'EUR',  // يورو
        'TRY',  // ليرة تركية
        'SAR',  // ريال سعودي
        'AED',  // درهم إماراتي
        'USDT', // تيثر
        'BTC',  // بيتكوين
        'ETH',  // إيثريوم
      ];
      notifyListeners();
    }
  }

  /// تحميل بيانات المحفظة
  Future<void> _loadWalletData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // محاولة الحصول على بيانات المحفظة من ذاكرة التخزين المؤقت أولاً
      final walletData = await _cacheManager.getWalletData(forceRefresh: false);
      
      _walletData = walletData;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تحميل بيانات المحفظة: $e';
      notifyListeners();
    }
  }

  /// تحديث بيانات المحفظة
  Future<void> refreshWalletData() async {
    await _loadWalletData();
  }

  /// الحصول على رصيد عملة معينة
  double getBalance(String currency) {
    if (_walletData == null || !_walletData!.containsKey('balances')) {
      return 0.0;
    }
    
    final balances = _walletData!['balances'] as Map<String, dynamic>?;
    if (balances == null) {
      return 0.0;
    }
    
    return balances[currency] as double? ?? 0.0;
  }

  /// حساب إجمالي الرصيد بالدولار الأمريكي
  Future<double> calculateTotalBalanceInUSD() async {
    // استخدام compute لنقل العملية الثقيلة إلى خيط منفصل
    return ComputeHelper.runInBackground<_BalanceCalculationParams, double>(
      _calculateTotalBalanceHelper,
      _BalanceCalculationParams(
        supportedCurrencies: _supportedCurrencies,
        walletData: _walletData,
        // تمرير نسخة من أسعار الصرف لتجنب الاتصال بالشبكة في الخيط المنفصل
        exchangeRates: _currencyConverter.getAllExchangeRates(),
      ),
    );
  }

  /// دالة مساعدة لحساب إجمالي الرصيد في خيط منفصل
  static double _calculateTotalBalanceHelper(_BalanceCalculationParams params) {
    double totalBalance = 0;
    final walletData = params.walletData;
    final exchangeRates = params.exchangeRates;
    
    if (walletData == null || !walletData.containsKey('balances')) {
      return 0.0;
    }
    
    final balances = walletData['balances'] as Map<String, dynamic>?;
    if (balances == null) {
      return 0.0;
    }
    
    for (var currency in params.supportedCurrencies) {
      double balance = balances[currency] as double? ?? 0.0;
      
      // تحويل الرصيد إلى الدولار الأمريكي باستخدام أسعار الصرف
      try {
        double exchangeRate = exchangeRates[currency] ?? 1.0;
        totalBalance += balance / exchangeRate;
      } catch (e) {
        // استخدام أسعار صرف مبسطة في حالة فشل الحصول على أسعار الصرف
        if (currency == 'USD' || currency == 'USDT') {
          totalBalance += balance;
        } else if (currency == 'EUR') {
          totalBalance += balance * 1.1; // سعر صرف مبسط
        } else if (currency == 'BTC') {
          totalBalance += balance * 60000; // سعر صرف مبسط
        } else if (currency == 'ETH') {
          totalBalance += balance * 3000; // سعر صرف مبسط
        } else if (currency == 'SYP') {
          totalBalance += balance * 0.0004; // سعر صرف مبسط
        } else if (currency == 'TRY') {
          totalBalance += balance * 0.03; // سعر صرف مبسط
        } else if (currency == 'SAR') {
          totalBalance += balance * 0.27; // سعر صرف مبسط
        } else if (currency == 'AED') {
          totalBalance += balance * 0.27; // سعر صرف مبسط
        } else {
          totalBalance += balance * 1; // افتراضي
        }
      }
    }
    
    return totalBalance;
  }

  /// الحصول على المعاملات الأخيرة
  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 5}) async {
    if (_walletData == null || !_walletData!.containsKey('transactions')) {
      return [];
    }
    
    final transactions = _walletData!['transactions'] as List<dynamic>?;
    if (transactions == null) {
      return [];
    }
    
    // استخدام compute لنقل العملية إلى خيط منفصل
    return ComputeHelper.runInBackground<_TransactionParams, List<Map<String, dynamic>>>(
      _processTransactionsHelper,
      _TransactionParams(
        transactions: transactions,
        limit: limit,
      ),
    );
  }

  /// دالة مساعدة لمعالجة المعاملات في خيط منفصل
  static List<Map<String, dynamic>> _processTransactionsHelper(_TransactionParams params) {
    final transactions = params.transactions;
    final limit = params.limit;
    
    // تحويل المعاملات إلى قائمة من Map
    final List<Map<String, dynamic>> result = [];
    for (var i = 0; i < transactions.length && i < limit; i++) {
      result.add(transactions[i] as Map<String, dynamic>);
    }
    
    return result;
  }
}

/// مزود حالة المصادقة
///
/// يدير حالة المصادقة ويوفر واجهة موحدة للوصول إلى بيانات المستخدم
/// ويقلل من استخدام setState في شاشات المصادقة المختلفة
class AuthStateProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String? _userId;
  String? _userName;
  String? _userEmail;

  // الوصول إلى البيانات
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  /// تسجيل الدخول
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // هنا يتم تنفيذ عملية تسجيل الدخول
      await Future.delayed(const Duration(seconds: 1));
      
      _isAuthenticated = true;
      _userId = "user123";
      _userName = "أحمد محمد";
      _userEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تسجيل الدخول: $e';
      notifyListeners();
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // هنا يتم تنفيذ عملية تسجيل الخروج
      await Future.delayed(const Duration(milliseconds: 500));
      
      _isAuthenticated = false;
      _userId = null;
      _userName = null;
      _userEmail = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تسجيل الخروج: $e';
      notifyListeners();
    }
  }

  /// التسجيل
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // هنا يتم تنفيذ عملية التسجيل
      await Future.delayed(const Duration(seconds: 1));
      
      _isAuthenticated = true;
      _userId = "user123";
      _userName = name;
      _userEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في التسجيل: $e';
      notifyListeners();
      return false;
    }
  }
}

/// فئة مساعدة لتمرير معلمات حساب الرصيد
class _BalanceCalculationParams {
  final List<String> supportedCurrencies;
  final Map<String, dynamic>? walletData;
  final Map<String, double> exchangeRates;

  _BalanceCalculationParams({
    required this.supportedCurrencies,
    required this.walletData,
    required this.exchangeRates,
  });
}

/// فئة مساعدة لتمرير معلمات معالجة المعاملات
class _TransactionParams {
  final List<dynamic> transactions;
  final int limit;

  _TransactionParams({
    required this.transactions,
    required this.limit,
  });
}
