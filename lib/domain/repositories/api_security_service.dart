import 'package:mpay_app/domain/repositories/api_security_service.dart';

/// واجهة لخدمات أمان API
abstract class ApiSecurityService {
  /// تهيئة خدمات أمان API
  Future<void> initialize();
  
  /// إنشاء عميل HTTP آمن مع التحقق من الشهادات
  Future<dynamic> createSecureClient();
  
  /// التحقق من صحة شهادة SSL/TLS
  bool validateCertificate(dynamic cert, String host, int port);
  
  /// توليد رؤوس أمان API
  Future<Map<String, String>> generateSecurityHeaders();
  
  /// تخزين رمز المصادقة بشكل آمن
  Future<void> storeAuthToken(String token, DateTime expiryTime);
  
  /// الحصول على رمز المصادقة المخزن بشكل آمن
  Future<String?> getStoredAuthToken();
  
  /// الحصول على وقت انتهاء صلاحية رمز المصادقة المخزن
  Future<DateTime?> getStoredAuthTokenExpiry();
  
  /// مسح رمز المصادقة المخزن
  Future<void> clearStoredAuthToken();
  
  /// تسجيل حدث أمني
  Future<void> logSecurityEvent(String userId, String eventType, String details);
}
