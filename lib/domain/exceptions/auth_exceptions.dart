import 'package:flutter/material.dart';

/// استثناءات المصادقة
/// 
/// تعريف الاستثناءات المتعلقة بعمليات المصادقة وإدارة الحسابات

/// استثناء بيانات الاعتماد غير الصالحة
class InvalidCredentialsException implements Exception {
  final String message;
  
  InvalidCredentialsException(this.message);
  
  @override
  String toString() => 'InvalidCredentialsException: $message';
}

/// استثناء فشل المصادقة
class AuthenticationFailedException implements Exception {
  final String message;
  
  AuthenticationFailedException(this.message);
  
  @override
  String toString() => 'AuthenticationFailedException: $message';
}

/// استثناء خطأ في الاتصال
class ConnectionException implements Exception {
  final String message;
  
  ConnectionException(this.message);
  
  @override
  String toString() => 'ConnectionException: $message';
}

/// استثناء انتهاء مهلة الاتصال
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}

/// استثناء حظر الحساب
class AccountBlockedException implements Exception {
  final String message;
  final DateTime? unlockTime;
  
  AccountBlockedException(this.message, {this.unlockTime});
  
  @override
  String toString() {
    if (unlockTime != null) {
      return 'AccountBlockedException: $message (Unlock time: $unlockTime)';
    }
    return 'AccountBlockedException: $message';
  }
}

/// استثناء الحساب غير المفعل
class AccountNotActivatedException implements Exception {
  final String message;
  
  AccountNotActivatedException(this.message);
  
  @override
  String toString() => 'AccountNotActivatedException: $message';
}

/// استثناء المدخلات غير الصالحة
class InvalidInputException implements Exception {
  final String message;
  
  InvalidInputException(this.message);
  
  @override
  String toString() => 'InvalidInputException: $message';
}

/// استثناء عدم وجود الحساب
class AccountNotFoundException implements Exception {
  final String message;
  
  AccountNotFoundException(this.message);
  
  @override
  String toString() => 'AccountNotFoundException: $message';
}

/// استثناء الحساب موجود مسبقاً
class AccountAlreadyExistsException implements Exception {
  final String message;
  
  AccountAlreadyExistsException(this.message);
  
  @override
  String toString() => 'AccountAlreadyExistsException: $message';
}

/// استثناء انتهاء صلاحية الجلسة
class SessionExpiredException implements Exception {
  final String message;
  
  SessionExpiredException(this.message);
  
  @override
  String toString() => 'SessionExpiredException: $message';
}

/// استثناء عدم وجود صلاحيات كافية
class InsufficientPermissionsException implements Exception {
  final String message;
  
  InsufficientPermissionsException(this.message);
  
  @override
  String toString() => 'InsufficientPermissionsException: $message';
}

/// استثناء فشل التحقق من صحة رمز التحقق
class VerificationCodeInvalidException implements Exception {
  final String message;
  
  VerificationCodeInvalidException(this.message);
  
  @override
  String toString() => 'VerificationCodeInvalidException: $message';
}

/// استثناء انتهاء صلاحية رمز التحقق
class VerificationCodeExpiredException implements Exception {
  final String message;
  
  VerificationCodeExpiredException(this.message);
  
  @override
  String toString() => 'VerificationCodeExpiredException: $message';
}

/// استثناء تجاوز عدد محاولات التحقق
class VerificationAttemptsExceededException implements Exception {
  final String message;
  final int maxAttempts;
  
  VerificationAttemptsExceededException(this.message, this.maxAttempts);
  
  @override
  String toString() => 'VerificationAttemptsExceededException: $message (Max attempts: $maxAttempts)';
}

/// استثناء كلمة المرور ضعيفة
class WeakPasswordException implements Exception {
  final String message;
  
  WeakPasswordException(this.message);
  
  @override
  String toString() => 'WeakPasswordException: $message';
}

/// استثناء البريد الإلكتروني غير صالح
class InvalidEmailException implements Exception {
  final String message;
  
  InvalidEmailException(this.message);
  
  @override
  String toString() => 'InvalidEmailException: $message';
}

/// استثناء فشل تسجيل الخروج
class LogoutFailedException implements Exception {
  final String message;
  
  LogoutFailedException(this.message);
  
  @override
  String toString() => 'LogoutFailedException: $message';
}

/// استثناء فشل إعادة تعيين كلمة المرور
class PasswordResetFailedException implements Exception {
  final String message;
  
  PasswordResetFailedException(this.message);
  
  @override
  String toString() => 'PasswordResetFailedException: $message';
}

/// استثناء فشل تغيير كلمة المرور
class PasswordChangeFailedException implements Exception {
  final String message;
  
  PasswordChangeFailedException(this.message);
  
  @override
  String toString() => 'PasswordChangeFailedException: $message';
}

/// استثناء فشل تحديث الملف الشخصي
class ProfileUpdateFailedException implements Exception {
  final String message;
  
  ProfileUpdateFailedException(this.message);
  
  @override
  String toString() => 'ProfileUpdateFailedException: $message';
}
