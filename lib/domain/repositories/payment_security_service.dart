import 'package:mpay_app/domain/repositories/security_repository.dart';

/// واجهة لخدمات الأمان المتعلقة بالمدفوعات
/// 
/// تحدد هذه الواجهة العمليات الأمنية المتعلقة بالمدفوعات
/// بدون تحديد كيفية تنفيذ هذه العمليات
abstract class PaymentSecurityService {
  /// توليد HMAC للتحقق من سلامة البيانات
  Future<String> generateHmac(String data, String key);
  
  /// التحقق من صحة عنوان المحفظة
  bool validateWalletAddress(String cryptoCurrency, String address);
  
  /// تشفير بيانات الدفع
  Future<String> encryptPaymentData(Map<String, dynamic> data);
  
  /// تسجيل حدث أمني
  Future<void> logSecurityEvent(String userId, String eventType, String details);
  
  /// تهيئة ميزات أمان المدفوعات
  Future<void> initializePaymentSecurity();
}
