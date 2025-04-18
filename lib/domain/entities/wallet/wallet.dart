import 'package:equatable/equatable.dart';

/// كيان المحفظة الأساسي في طبقة المنطق التجاري
/// 
/// يمثل هذا الكيان محفظة المستخدم ويحتوي على البيانات الأساسية للمحفظة
/// بدون أي تفاصيل تتعلق بطريقة تخزين البيانات أو عرضها
class Wallet extends Equatable {
  final String id;
  final String userId;
  final Map<String, double> balances;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balances,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id, 
    userId, 
    balances, 
    isActive, 
    createdAt, 
    updatedAt
  ];
  
  /// الحصول على رصيد عملة معينة
  double getBalance(String currency) {
    return balances[currency] ?? 0.0;
  }
  
  /// إنشاء نسخة جديدة من المحفظة مع تحديث بعض الخصائص
  Wallet copyWith({
    Map<String, double>? balances,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: this.id,
      userId: this.userId,
      balances: balances ?? Map.from(this.balances),
      isActive: isActive ?? this.isActive,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
  
  /// إضافة رصيد لعملة معينة
  Wallet addBalance(String currency, double amount) {
    final newBalances = Map<String, double>.from(balances);
    newBalances[currency] = (newBalances[currency] ?? 0.0) + amount;
    return copyWith(
      balances: newBalances,
      updatedAt: DateTime.now(),
    );
  }
  
  /// خصم رصيد من عملة معينة
  /// 
  /// يرجع null إذا كان الرصيد غير كافٍ
  Wallet? subtractBalance(String currency, double amount) {
    final currentBalance = balances[currency] ?? 0.0;
    if (currentBalance < amount) {
      return null; // رصيد غير كافٍ
    }
    
    final newBalances = Map<String, double>.from(balances);
    newBalances[currency] = currentBalance - amount;
    return copyWith(
      balances: newBalances,
      updatedAt: DateTime.now(),
    );
  }
}
