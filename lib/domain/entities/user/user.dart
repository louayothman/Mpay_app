import 'package:equatable/equatable.dart';

/// كيان المستخدم الأساسي في طبقة المنطق التجاري
/// 
/// يمثل هذا الكيان المستخدم في النظام ويحتوي على البيانات الأساسية للمستخدم
/// بدون أي تفاصيل تتعلق بطريقة تخزين البيانات أو عرضها
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final bool isVerified;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.isVerified,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
  });

  @override
  List<Object?> get props => [
    id, 
    name, 
    email, 
    phoneNumber, 
    isVerified, 
    role, 
    createdAt, 
    lastLoginAt
  ];
  
  /// إنشاء نسخة جديدة من المستخدم مع تحديث بعض الخصائص
  User copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    bool? isVerified,
    UserRole? role,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      createdAt: this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// أدوار المستخدمين في النظام
enum UserRole {
  user,
  admin,
  support,
}
