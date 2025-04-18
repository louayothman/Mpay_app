import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/cache_manager.dart';
import 'package:mpay_app/utils/logger.dart';
import 'package:mpay_app/utils/wallet_validator.dart';

class WalletProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheManager _cacheManager = CacheManager();
  
  Map<String, dynamic>? _walletData;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  Map<String, dynamic>? get walletData => _walletData;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  WalletProvider() {
    _initWalletData();
  }
  
  Future<void> _initWalletData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await loadWalletData();
      await loadTransactions();
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  Future<void> loadWalletData({bool forceRefresh = false}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Try to get wallet data from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _cacheManager.getWalletData(forceRefresh: false);
        if (cachedData != null) {
          _walletData = cachedData;
          _setLoading(false);
          notifyListeners();
          
          // التحقق من عمر البيانات المخزنة مؤقتاً قبل التحديث في الخلفية
          final cacheTimestamp = await _cacheManager.getCacheTimestamp('wallet_data');
          final now = DateTime.now();
          if (cacheTimestamp != null && now.difference(cacheTimestamp).inMinutes > 5) {
            // تحديث البيانات في الخلفية فقط إذا كانت البيانات المخزنة مؤقتاً قديمة
            _refreshWalletDataInBackground();
          }
          return;
        }
      }
      
      // Get wallet data from Firestore
      final walletDoc = await _firestore.collection('wallets').doc(user.uid).get();
      
      if (!walletDoc.exists) {
        // Create wallet if it doesn't exist
        await _createWallet(user.uid);
        return;
      }
      
      _walletData = walletDoc.data();
      
      // Cache wallet data
      await _cacheManager.cacheWalletData(_walletData!);
      
    } catch (e) {
      _setError('فشل في تحميل بيانات المحفظة: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> _refreshWalletDataInBackground() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Get fresh wallet data from Firestore
      final walletDoc = await _firestore.collection('wallets').doc(user.uid).get();
      
      if (!walletDoc.exists) return;
      
      final freshData = walletDoc.data();
      
      // Update wallet data if it's different
      if (_walletData != freshData) {
        _walletData = freshData;
        
        // Cache updated wallet data
        await _cacheManager.cacheWalletData(_walletData!);
        
        notifyListeners();
      }
    } catch (e) {
      // استخدام Logger بدلاً من print
      Logger.error('خطأ في تحديث البيانات في الخلفية', error: e);
    }
  }
  
  Future<void> _createWallet(String userId) async {
    try {
      final walletData = {
        'userId': userId,
        'balances': {
          'USDT': 0.0,
          'BTC': 0.0,
          'ETH': 0.0,
          'ShamCash': 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('wallets').doc(userId).set(walletData);
      
      _walletData = walletData;
      
      // Cache wallet data
      await _cacheManager.cacheWalletData(_walletData!);
      
    } catch (e) {
      _setError('فشل في إنشاء المحفظة: $e');
    }
  }
  
  Future<void> loadTransactions({int limit = 10, bool forceRefresh = false}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Try to get transactions from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedTransactions = await _cacheManager.getTransactions(forceRefresh: false);
        if (cachedTransactions != null) {
          _transactions = cachedTransactions;
          _setLoading(false);
          notifyListeners();
          
          // التحقق من عمر البيانات المخزنة مؤقتاً قبل التحديث في الخلفية
          final cacheTimestamp = await _cacheManager.getCacheTimestamp('transactions');
          final now = DateTime.now();
          if (cacheTimestamp != null && now.difference(cacheTimestamp).inMinutes > 5) {
            // تحديث البيانات في الخلفية فقط إذا كانت البيانات المخزنة مؤقتاً قديمة
            _refreshTransactionsInBackground(limit);
          }
          return;
        }
      }
      
      // Get transactions from Firestore
      final transactionsQuery = await _firestore.collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      _transactions = transactionsQuery.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
      
      // Cache transactions
      await _cacheManager.cacheTransactions(_transactions);
      
    } catch (e) {
      _setError('فشل في تحميل المعاملات: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> _refreshTransactionsInBackground(int limit) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Get fresh transactions from Firestore
      final transactionsQuery = await _firestore.collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      final freshTransactions = transactionsQuery.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
      
      // Update transactions if they're different
      if (_transactions.length != freshTransactions.length ||
          _transactions.any((t) => !freshTransactions.any((ft) => ft['id'] == t['id']))) {
        _transactions = freshTransactions;
        
        // Cache updated transactions
        await _cacheManager.cacheTransactions(_transactions);
        
        notifyListeners();
      }
    } catch (e) {
      // استخدام Logger بدلاً من print
      Logger.error('خطأ في تحديث المعاملات في الخلفية', error: e);
    }
  }
  
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
  
  Future<bool> createTransaction({
    required String type,
    required String method,
    required double amount,
    required String status,
    required String currency,
    String? walletAddress,
    String? receiptUrl,
    String? notes,
    BuildContext? context,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // التحقق من صحة المبلغ
      if (!WalletValidator.isValidAmount(amount)) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }
      
      // التحقق من صحة عنوان المحفظة إذا تم توفيره
      if (walletAddress != null && walletAddress.isNotEmpty) {
        if (!WalletValidator.isValidAddress(walletAddress, currency)) {
          throw Exception('عنوان المحفظة غير صالح');
        }
      }
      
      // Create transaction data
      final transactionData = {
        'userId': user.uid,
        'type': type,
        'method': method,
        'amount': amount,
        'status': status,
        'currency': currency,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      if (walletAddress != null) {
        transactionData['walletAddress'] = walletAddress;
      }
      
      if (receiptUrl != null) {
        transactionData['receiptUrl'] = receiptUrl;
      }
      
      if (notes != null) {
        transactionData['notes'] = notes;
      }
      
      // Add transaction to Firestore
      final transactionRef = await _firestore.collection('transactions').add(transactionData);
      
      // Update local transactions list
      _transactions.insert(0, {
        'id': transactionRef.id,
        ...transactionData,
      });
      
      // Update cache
      await _cacheManager.cacheTransactions(_transactions);
      
      // If it's a withdrawal, update wallet balance
      if (type == 'withdrawal' && status == 'pending') {
        await updateBalance(currency, -amount, context);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في إنشاء المعاملة: $e');
      if (context != null) {
        ErrorHandler.showErrorSnackBar(context, 'فشل في إنشاء المعاملة: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> updateBalance(String currency, double amount, BuildContext? context) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Get current balance
      final currentBalance = getBalance(currency);
      
      // Calculate new balance
      final newBalance = currentBalance + amount;
      
      // Ensure balance doesn't go negative
      if (newBalance < 0) {
        throw Exception('الرصيد غير كافٍ');
      }
      
      // Update balance in Firestore
      await _firestore.collection('wallets').doc(user.uid).update({
        'balances.$currency': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local wallet data
      if (_walletData != null && _walletData!.containsKey('balances')) {
        final balances = _walletData!['balances'] as Map<String, dynamic>;
        balances[currency] = newBalance;
        _walletData!['updatedAt'] = FieldValue.serverTimestamp();
      }
      
      // Update cache
      await _cacheManager.cacheWalletData(_walletData!);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في تحديث الرصيد: $e');
      if (context != null) {
        ErrorHandler.showErrorSnackBar(context, 'فشل في تحديث الرصيد: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> cancelTransaction(String transactionId, BuildContext? context) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Get transaction data
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      
      if (!transactionDoc.exists) {
        throw Exception('المعاملة غير موجودة');
      }
      
      final transactionData = transactionDoc.data();
      
      if (transactionData == null) {
        throw Exception('بيانات المعاملة غير موجودة');
      }
      
      // Check if transaction belongs to user
      if (transactionData['userId'] != user.uid) {
        throw Exception('ليس لديك صلاحية إلغاء هذه المعاملة');
      }
      
      // Check if transaction is pending
      if (transactionData['status'] != 'pending') {
        throw Exception('لا يمكن إلغاء المعاملات المكتملة أو المرفوضة');
      }
      
      // Update transaction status
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'cancelled',
        'notes': 'تم إلغاء المعاملة من قبل المستخدم',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // If it's a withdrawal, refund the amount
      if (transactionData['type'] == 'withdrawal') {
        // استخدام حقل العملة المخزن مباشرة بدلاً من استخراجه من سلسلة نصية
        String currency = transactionData['currency'] ?? 'USDT'; // استخدام قيمة افتراضية في حالة عدم وجود الحقل للتوافق مع البيانات القديمة
        
        await updateBalance(currency, transactionData['amount'], context);
      }
      
      // Update local transactions list
      final index = _transactions.indexWhere((t) => t['id'] == transactionId);
      if (index != -1) {
        _transactions[index]['status'] = 'cancelled';
        _transactions[index]['notes'] = 'تم إلغاء المعاملة من قبل المستخدم';
        _transactions[index]['updatedAt'] = FieldValue.serverTimestamp();
      }
      
      // Update cache
      await _cacheManager.cacheTransactions(_transactions);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('فشل في إلغاء المعاملة: $e');
      if (context != null) {
        ErrorHandler.showErrorSnackBar(context, 'فشل في إلغاء المعاملة: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Build query
      Query query = _firestore.collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true);
      
      // Apply filters
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      // Apply limit
      query = query.limit(limit);
      
      // Execute query
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      _setError('فشل في تحميل سجل المعاملات: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  Future<Map<String, dynamic>?> getTransactionDetails(String transactionId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Get transaction data
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      
      if (!transactionDoc.exists) {
        throw Exception('المعاملة غير موجودة');
      }
      
      final transactionData = transactionDoc.data();
      
      if (transactionData == null) {
        throw Exception('بيانات المعاملة غير موجودة');
      }
      
      // Check if transaction belongs to user
      if (transactionData['userId'] != user.uid) {
        throw Exception('ليس لديك صلاحية عرض هذه المعاملة');
      }
      
      return {
        'id': transactionId,
        ...transactionData,
      };
    } catch (e) {
      _setError('فشل في تحميل تفاصيل المعاملة: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
}
