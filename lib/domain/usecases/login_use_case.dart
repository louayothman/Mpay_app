import 'package:mpay_app/domain/entities/user/user.dart';
import 'package:mpay_app/domain/repositories/user_repository.dart';
import 'package:mpay_app/domain/exceptions/auth_exceptions.dart';
import 'dart:async';

/// حالة استخدام تسجيل الدخول
///
/// تنفذ منطق تسجيل الدخول للمستخدم مع التعامل المناسب مع حالات الفشل
class LoginUseCase {
  final UserRepository userRepository;
  
  // عدد محاولات إعادة المحاولة القصوى
  static const int _maxRetries = 3;
  
  // مدة الانتظار بين المحاولات (بالثواني)
  static const int _retryDelaySeconds = 2;

  LoginUseCase(this.userRepository);

  /// تنفيذ عملية تسجيل الدخول
  ///
  /// يقوم بالتحقق من صحة البيانات ثم استدعاء المستودع لتسجيل الدخول
  /// مع التعامل المناسب مع حالات الفشل المختلفة
  Future<User> execute(String email, String password) async {
    // التحقق من صحة المدخلات
    _validateInputs(email, password);
    
    // محاولة تسجيل الدخول مع إعادة المحاولة في حالة فشل الاتصال
    return await _executeWithRetry(email, password);
  }
  
  /// التحقق من صحة المدخلات
  void _validateInputs(String email, String password) {
    // التحقق من أن البريد الإلكتروني وكلمة المرور ليسا فارغين
    if (email.isEmpty) {
      throw InvalidCredentialsException('البريد الإلكتروني مطلوب');
    }
    
    if (password.isEmpty) {
      throw InvalidCredentialsException('كلمة المرور مطلوبة');
    }
    
    // التحقق من صحة البريد الإلكتروني
    if (!_isValidEmail(email)) {
      throw InvalidCredentialsException('البريد الإلكتروني غير صالح');
    }

    // التحقق من صحة كلمة المرور
    if (!_isValidPassword(password)) {
      throw InvalidCredentialsException('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    }
  }
  
  /// تنفيذ تسجيل الدخول مع إعادة المحاولة في حالة فشل الاتصال
  Future<User> _executeWithRetry(String email, String password) async {
    int retryCount = 0;
    
    while (true) {
      try {
        // محاولة تسجيل الدخول
        final user = await userRepository.loginUser(email, password);
        
        // التحقق من أن المستخدم ليس فارغًا
        if (user == null) {
          throw AuthenticationFailedException('فشل تسجيل الدخول: بيانات المستخدم غير صحيحة');
        }
        
        return user;
      } on ConnectionException catch (e) {
        // إعادة المحاولة في حالة فشل الاتصال فقط
        retryCount++;
        
        if (retryCount >= _maxRetries) {
          throw ConnectionException('فشل الاتصال بعد $_maxRetries محاولات: ${e.message}');
        }
        
        // الانتظار قبل إعادة المحاولة
        await Future.delayed(Duration(seconds: _retryDelaySeconds * retryCount));
      } on AuthenticationFailedException catch (e) {
        // إعادة رمي استثناءات المصادقة دون إعادة المحاولة
        throw AuthenticationFailedException('فشل تسجيل الدخول: ${e.message}');
      } on InvalidCredentialsException catch (e) {
        // إعادة رمي استثناءات البيانات غير الصالحة دون إعادة المحاولة
        throw InvalidCredentialsException(e.message);
      } catch (e) {
        // التعامل مع الاستثناءات الأخرى
        throw AuthenticationFailedException('حدث خطأ غير متوقع أثناء تسجيل الدخول: $e');
      }
    }
  }

  /// التحقق من صحة البريد الإلكتروني
  bool _isValidEmail(String email) {
    // تحسين التعبير النمطي للبريد الإلكتروني
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$'
    );
    return emailRegExp.hasMatch(email);
  }

  /// التحقق من صحة كلمة المرور
  bool _isValidPassword(String password) {
    // التحقق من طول كلمة المرور وتعقيدها
    if (password.length < 6) {
      return false;
    }
    
    // يمكن إضافة المزيد من التحققات هنا مثل التحقق من وجود أحرف كبيرة وصغيرة وأرقام ورموز
    // لكن تم الاكتفاء بالتحقق من الطول للحفاظ على البساطة
    
    return true;
  }
}
