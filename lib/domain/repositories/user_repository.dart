import 'package:mpay_app/domain/entities/user/user.dart';

/// واجهة مستودع المستخدم
/// 
/// تحدد هذه الواجهة العمليات التي يمكن إجراؤها على المستخدم
/// بدون تحديد كيفية تنفيذ هذه العمليات
abstract class UserRepository {
  /// الحصول على معلومات المستخدم
  Future<User?> getUser(String userId);
  
  /// تسجيل مستخدم جديد
  Future<User?> registerUser(String name, String email, String password, String phoneNumber);
  
  /// تسجيل الدخول
  Future<User?> loginUser(String email, String password);
  
  /// تحديث معلومات المستخدم
  Future<bool> updateUser(User user);
  
  /// التحقق من صحة البريد الإلكتروني
  Future<bool> verifyEmail(String userId, String code);
  
  /// إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email);
  
  /// تغيير كلمة المرور
  Future<bool> changePassword(String userId, String oldPassword, String newPassword);
  
  /// تسجيل الخروج
  Future<bool> logoutUser(String userId);
  
  /// التحقق من حالة المصادقة
  Future<bool> isAuthenticated();
  
  /// الحصول على المستخدم الحالي
  Future<User?> getCurrentUser();
}
