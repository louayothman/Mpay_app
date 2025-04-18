import 'package:mpay_app/domain/entities/user/user.dart';
import 'package:mpay_app/domain/repositories/user_repository.dart';

/// حالة استخدام تسجيل مستخدم جديد
///
/// تنفذ منطق تسجيل مستخدم جديد في النظام
class RegisterUseCase {
  final UserRepository userRepository;

  RegisterUseCase(this.userRepository);

  /// تنفيذ عملية تسجيل مستخدم جديد
  ///
  /// يقوم بالتحقق من صحة البيانات ثم استدعاء المستودع لتسجيل المستخدم
  Future<User?> execute(String name, String email, String password, String phoneNumber) async {
    // التحقق من صحة البيانات
    if (name.isEmpty) {
      throw Exception('الاسم مطلوب');
    }
    
    if (!_isValidEmail(email)) {
      throw Exception('البريد الإلكتروني غير صالح');
    }
    
    if (!_isValidPassword(password)) {
      throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    }
    
    if (!_isValidPhoneNumber(phoneNumber)) {
      throw Exception('رقم الهاتف غير صالح');
    }
    
    // استدعاء المستودع لتسجيل المستخدم
    return await userRepository.registerUser(name, email, password, phoneNumber);
  }
  
  /// التحقق من صحة البريد الإلكتروني
  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(email);
  }
  
  /// التحقق من صحة كلمة المرور
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }
  
  /// التحقق من صحة رقم الهاتف
  bool _isValidPhoneNumber(String phoneNumber) {
    final phoneRegExp = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegExp.hasMatch(phoneNumber);
  }
}
