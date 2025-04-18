import 'package:flutter/material.dart';
import 'package:mpay_app/utils/logger.dart';

/// مدير الأخطاء المخصص
///
/// يوفر واجهة موحدة للتعامل مع الأخطاء وعرضها للمستخدم
class ErrorHandler {
  // سجل الأخطاء
  static final List<String> _errorLog = [];
  
  // الحد الأقصى لعدد الأخطاء المحفوظة في السجل
  static const int _maxLogSize = 100;
  
  // مستويات خطورة الأخطاء
  enum ErrorSeverity {
    low,    // منخفضة
    medium, // متوسطة
    high,   // عالية
    critical // حرجة
  }
  
  /// تسجيل خطأ في السجل
  static void logError(String error, {ErrorSeverity severity = ErrorSeverity.medium, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '$timestamp [${_getSeverityString(severity)}] $error';
    
    // إضافة معلومات تتبع المكدس إذا كانت متوفرة
    final fullLogEntry = stackTrace != null ? '$logEntry\n$stackTrace' : logEntry;
    
    // إضافة الخطأ إلى السجل
    _errorLog.add(fullLogEntry);
    
    // التأكد من عدم تجاوز الحد الأقصى لحجم السجل
    if (_errorLog.length > _maxLogSize) {
      _errorLog.removeAt(0);
    }
    
    // استخدام Logger بدلاً من print
    switch (severity) {
      case ErrorSeverity.low:
        Logger.debug(fullLogEntry);
        break;
      case ErrorSeverity.medium:
        Logger.warning(fullLogEntry);
        break;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        Logger.error(error, stackTrace: stackTrace);
        break;
    }
    
    // إرسال الأخطاء الحرجة إلى خدمة تتبع الأخطاء
    if (severity == ErrorSeverity.critical) {
      _sendErrorToTrackingService(error, stackTrace);
    }
  }
  
  /// الحصول على سجل الأخطاء
  static List<String> getErrorLog() {
    return List.unmodifiable(_errorLog);
  }
  
  /// مسح سجل الأخطاء
  static void clearErrorLog() {
    _errorLog.clear();
  }
  
  /// عرض شريط خطأ للمستخدم
  static void showErrorSnackBar(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    // تسجيل الخطأ
    logError(message, severity: ErrorSeverity.medium);
    
    // عرض شريط الخطأ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  /// عرض حوار خطأ للمستخدم
  static Future<void> showErrorDialog(BuildContext context, String title, String message) async {
    // تسجيل الخطأ
    logError(message, severity: ErrorSeverity.high);
    
    // عرض حوار الخطأ
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('حسناً'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  /// عرض حوار خطأ مع خيارات متعددة
  static Future<String?> showErrorDialogWithOptions(
    BuildContext context, 
    String title, 
    String message, 
    Map<String, String> options
  ) async {
    // تسجيل الخطأ
    logError(message, severity: ErrorSeverity.high);
    
    // عرض حوار الخطأ مع خيارات
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: options.entries.map((entry) {
            return TextButton(
              child: Text(entry.value),
              onPressed: () {
                Navigator.of(context).pop(entry.key);
              },
            );
          }).toList(),
        );
      },
    );
  }
  
  /// عرض حوار خطأ مع إمكانية إعادة المحاولة
  static Future<bool> showRetryDialog(
    BuildContext context, 
    String title, 
    String message
  ) async {
    // تسجيل الخطأ
    logError(message, severity: ErrorSeverity.medium);
    
    // عرض حوار الخطأ مع خيار إعادة المحاولة
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('إعادة المحاولة'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }
  
  /// تحويل مستوى الخطورة إلى نص
  static String _getSeverityString(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return 'منخفضة';
      case ErrorSeverity.medium:
        return 'متوسطة';
      case ErrorSeverity.high:
        return 'عالية';
      case ErrorSeverity.critical:
        return 'حرجة';
      default:
        return 'غير معروفة';
    }
  }
  
  /// إرسال الخطأ إلى خدمة تتبع الأخطاء
  static void _sendErrorToTrackingService(String error, StackTrace? stackTrace) {
    // في التطبيق الحقيقي، يجب استخدام خدمة تتبع الأخطاء مثل Firebase Crashlytics
    // هنا نستخدم Logger بدلاً من print
    Logger.error('خطأ حرج تم إرساله إلى خدمة تتبع الأخطاء', error: error, stackTrace: stackTrace);
  }
  
  /// الحصول على رسالة خطأ مخصصة بناءً على نوع الاستثناء
  static String getCustomErrorMessage(Exception exception) {
    if (exception is InvalidCredentialsException) {
      return 'بيانات الاعتماد غير صالحة: ${exception.message}';
    } else if (exception is AuthenticationFailedException) {
      return 'فشل المصادقة: ${exception.message}';
    } else if (exception is ConnectionException) {
      return 'خطأ في الاتصال: ${exception.message}';
    } else if (exception is TimeoutException) {
      return 'انتهت مهلة الاتصال: ${exception.message}';
    } else if (exception is AccountBlockedException) {
      final unlockTime = exception.unlockTime;
      if (unlockTime != null) {
        return 'الحساب محظور: ${exception.message}. سيتم إلغاء الحظر في: ${_formatDateTime(unlockTime)}';
      } else {
        return 'الحساب محظور: ${exception.message}';
      }
    } else if (exception is AccountNotActivatedException) {
      return 'الحساب غير مفعل: ${exception.message}';
    } else if (exception is InvalidInputException) {
      return 'مدخلات غير صالحة: ${exception.message}';
    } else if (exception is InsufficientFundsException) {
      return 'رصيد غير كافٍ: ${exception.message}';
    } else if (exception is TransactionFailedException) {
      return 'فشلت المعاملة: ${exception.message}';
    } else if (exception is LimitExceededException) {
      return 'تم تجاوز الحد: ${exception.message}';
    } else if (exception is UnsupportedCurrencyException) {
      return 'عملة غير مدعومة: ${exception.message}';
    } else if (exception is UnsupportedPaymentMethodException) {
      return 'طريقة دفع غير مدعومة: ${exception.message}';
    } else if (exception is DuplicateTransactionException) {
      return 'معاملة مكررة: ${exception.message}';
    } else if (exception is DataNotFoundException) {
      return 'لم يتم العثور على البيانات: ${exception.message}';
    } else if (exception is DataCorruptedException) {
      return 'البيانات تالفة: ${exception.message}';
    } else if (exception is InvalidDataFormatException) {
      return 'تنسيق بيانات غير صالح: ${exception.message}';
    } else if (exception is SynchronizationFailedException) {
      return 'فشل المزامنة: ${exception.message}';
    } else if (exception is DataConflictException) {
      return 'تضارب في البيانات: ${exception.message}';
    } else if (exception is DataExpiredException) {
      return 'البيانات منتهية الصلاحية: ${exception.message}';
    } else if (exception is AccountNotFoundException) {
      return 'الحساب غير موجود: ${exception.message}';
    } else if (exception is AccountAlreadyExistsException) {
      return 'الحساب موجود مسبقاً: ${exception.message}';
    } else if (exception is SessionExpiredException) {
      return 'انتهت صلاحية الجلسة: ${exception.message}';
    } else if (exception is InsufficientPermissionsException) {
      return 'صلاحيات غير كافية: ${exception.message}';
    } else if (exception is VerificationCodeInvalidException) {
      return 'رمز التحقق غير صالح: ${exception.message}';
    } else if (exception is VerificationCodeExpiredException) {
      return 'انتهت صلاحية رمز التحقق: ${exception.message}';
    } else if (exception is VerificationAttemptsExceededException) {
      return 'تم تجاوز عدد محاولات التحقق: ${exception.message}';
    } else if (exception is WeakPasswordException) {
      return 'كلمة المرور ضعيفة: ${exception.message}';
    } else if (exception is InvalidEmailException) {
      return 'البريد الإلكتروني غير صالح: ${exception.message}';
    } else if (exception is LogoutFailedException) {
      return 'فشل تسجيل الخروج: ${exception.message}';
    } else if (exception is PasswordResetFailedException) {
      return 'فشل إعادة تعيين كلمة المرور: ${exception.message}';
    } else if (exception is PasswordChangeFailedException) {
      return 'فشل تغيير كلمة المرور: ${exception.message}';
    } else if (exception is ProfileUpdateFailedException) {
      return 'فشل تحديث الملف الشخصي: ${exception.message}';
    } else if (exception is TransactionNotFoundException) {
      return 'المعاملة غير موجودة: ${exception.message}';
    } else if (exception is TransactionExpiredException) {
      return 'انتهت صلاحية المعاملة: ${exception.message}';
    } else if (exception is TransactionCancelledException) {
      return 'تم إلغاء المعاملة: ${exception.message}';
    } else if (exception is TransactionRejectedException) {
      return 'تم رفض المعاملة: ${exception.message}';
    } else if (exception is InvalidWalletAddressException) {
      return 'عنوان المحفظة غير صالح: ${exception.message}';
    } else if (exception is InvalidAmountException) {
      return 'المبلغ غير صالح: ${exception.message}';
    } else if (exception is PaymentGatewayException) {
      return 'خطأ في بوابة الدفع: ${exception.message}';
    } else if (exception is TransferFailedException) {
      return 'فشل التحويل: ${exception.message}';
    } else if (exception is SaveFailedException) {
      return 'فشل الحفظ: ${exception.message}';
    } else if (exception is LoadFailedException) {
      return 'فشل التحميل: ${exception.message}';
    } else if (exception is DeleteFailedException) {
      return 'فشل الحذف: ${exception.message}';
    } else if (exception is UpdateFailedException) {
      return 'فشل التحديث: ${exception.message}';
    } else if (exception is QueryFailedException) {
      return 'فشل الاستعلام: ${exception.message}';
    } else if (exception is ValidationFailedException) {
      return 'فشل التحقق من صحة البيانات: ${exception.message}';
    } else if (exception is EncryptionFailedException) {
      return 'فشل التشفير: ${exception.message}';
    } else if (exception is DecryptionFailedException) {
      return 'فشل فك التشفير: ${exception.message}';
    } else if (exception is CacheFailedException) {
      return 'فشل التخزين المؤقت: ${exception.message}';
    } else if (exception is LocalStorageFailedException) {
      return 'فشل التخزين المحلي: ${exception.message}';
    } else {
      return 'حدث خطأ غير متوقع: $exception';
    }
  }
  
  /// تنسيق التاريخ والوقت
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// معالجة الاستثناءات بشكل آمن
  static T? handleSafely<T>(Function() operation, {
    String? errorMessage,
    T? defaultValue,
    ErrorSeverity severity = ErrorSeverity.medium,
    BuildContext? context,
  }) {
    try {
      return operation() as T?;
    } catch (e, stackTrace) {
      final message = errorMessage ?? 'حدث خطأ أثناء تنفيذ العملية: $e';
      logError(message, severity: severity, stackTrace: stackTrace);
      
      if (context != null) {
        showErrorSnackBar(context, message);
      }
      
      return defaultValue;
    }
  }
  
  /// تنفيذ عملية مع إعادة المحاولة
  static Future<T?> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? errorMessage,
    T? defaultValue,
    ErrorSeverity severity = ErrorSeverity.medium,
    BuildContext? context,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        attempts++;
        
        final message = errorMessage ?? 'فشلت المحاولة $attempts من $maxRetries: $e';
        logError(message, severity: severity, stackTrace: stackTrace);
        
        if (attempts >= maxRetries) {
          if (context != null) {
            showErrorSnackBar(context, 'فشلت العملية بعد $maxRetries محاولات');
          }
          return defaultValue;
        }
        
        // انتظار قبل إعادة المحاولة
        await Future.delayed(delay * attempts);
      }
    }
    
    return defaultValue;
  }
}

// استيراد الاستثناءات
import 'package:mpay_app/domain/exceptions/auth_exceptions.dart';
import 'package:mpay_app/domain/exceptions/transaction_exceptions.dart';
import 'package:mpay_app/domain/exceptions/data_exceptions.dart';
