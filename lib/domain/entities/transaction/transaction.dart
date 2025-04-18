import 'package:equatable/equatable.dart';

/// كيان المعاملة الأساسي في طبقة المنطق التجاري
/// 
/// يمثل هذا الكيان معاملة مالية في النظام ويحتوي على البيانات الأساسية للمعاملة
/// بدون أي تفاصيل تتعلق بطريقة تخزين البيانات أو عرضها
class Transaction extends Equatable {
  final String id;
  final String userId;
  final TransactionType type;
  final String currency;
  final double amount;
  final TransactionStatus status;
  final String method;
  final DateTime timestamp;
  final String? description;
  final String? referenceId;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.currency,
    required this.amount,
    required this.status,
    required this.method,
    required this.timestamp,
    this.description,
    this.referenceId,
  });

  @override
  List<Object?> get props => [
    id, 
    userId, 
    type, 
    currency, 
    amount, 
    status, 
    method, 
    timestamp, 
    description, 
    referenceId
  ];
  
  /// إنشاء نسخة جديدة من المعاملة مع تحديث بعض الخصائص
  Transaction copyWith({
    TransactionStatus? status,
    String? description,
    String? referenceId,
  }) {
    return Transaction(
      id: this.id,
      userId: this.userId,
      type: this.type,
      currency: this.currency,
      amount: this.amount,
      status: status ?? this.status,
      method: this.method,
      timestamp: this.timestamp,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
    );
  }
  
  /// التحقق مما إذا كانت المعاملة مكتملة
  bool get isCompleted => status == TransactionStatus.completed;
  
  /// التحقق مما إذا كانت المعاملة قيد الانتظار
  bool get isPending => status == TransactionStatus.pending;
  
  /// التحقق مما إذا كانت المعاملة مرفوضة
  bool get isRejected => status == TransactionStatus.rejected;
}

/// أنواع المعاملات في النظام
enum TransactionType {
  deposit,
  withdrawal,
  transfer,
  exchange,
}

/// حالات المعاملات في النظام
enum TransactionStatus {
  pending,
  completed,
  rejected,
}
