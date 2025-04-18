import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _userName;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  Future<bool> login(String email, String password) async {
    // هنا يتم تنفيذ عملية تسجيل الدخول
    // في هذا المثال، نقوم بمحاكاة نجاح تسجيل الدخول
    await Future.delayed(const Duration(seconds: 1));
    
    _isAuthenticated = true;
    _userId = "user123";
    _userName = "أحمد محمد";
    _userEmail = email;
    
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    // هنا يتم تنفيذ عملية تسجيل الخروج
    await Future.delayed(const Duration(milliseconds: 500));
    
    _isAuthenticated = false;
    _userId = null;
    _userName = null;
    _userEmail = null;
    
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    // هنا يتم تنفيذ عملية التسجيل
    await Future.delayed(const Duration(seconds: 1));
    
    _isAuthenticated = true;
    _userId = "user123";
    _userName = name;
    _userEmail = email;
    
    notifyListeners();
    return true;
  }
}

class WalletProvider extends ChangeNotifier {
  double _balance = 12345.67;
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  double get balance => _balance;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  WalletProvider() {
    // تهيئة بعض المعاملات الافتراضية
    _transactions = [
      Transaction(
        id: "tx1",
        title: "تحويل إلى محمد",
        amount: -120.0,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: TransactionType.transfer,
      ),
      Transaction(
        id: "tx2",
        title: "استلام من سارة",
        amount: 350.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.receive,
      ),
      Transaction(
        id: "tx3",
        title: "مشتريات - متجر الإلكترونيات",
        amount: -499.99,
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.purchase,
      ),
    ];
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    // محاكاة تحميل المعاملات من API
    await Future.delayed(const Duration(seconds: 1));

    // هنا يمكن إضافة المزيد من المعاملات أو تحديث القائمة الحالية

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMoney(String recipient, double amount) async {
    if (amount <= 0 || amount > _balance) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    // محاكاة إرسال الأموال عبر API
    await Future.delayed(const Duration(seconds: 1));

    _balance -= amount;
    
    final transaction = Transaction(
      id: "tx${_transactions.length + 1}",
      title: "تحويل إلى $recipient",
      amount: -amount,
      date: DateTime.now(),
      type: TransactionType.transfer,
    );
    
    _transactions.insert(0, transaction);
    
    _isLoading = false;
    notifyListeners();
    
    return true;
  }

  Future<bool> receiveMoney(String sender, double amount) async {
    if (amount <= 0) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    // محاكاة استلام الأموال عبر API
    await Future.delayed(const Duration(seconds: 1));

    _balance += amount;
    
    final transaction = Transaction(
      id: "tx${_transactions.length + 1}",
      title: "استلام من $sender",
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.receive,
    );
    
    _transactions.insert(0, transaction);
    
    _isLoading = false;
    notifyListeners();
    
    return true;
  }
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? description;
  final String? category;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.description,
    this.category,
  });
}

enum TransactionType {
  transfer,
  receive,
  purchase,
  deposit,
  withdrawal,
}
