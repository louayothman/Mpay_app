import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mpay_app/providers/state_management.dart';
import 'package:mpay_app/data/repositories/api_security_service_impl_enhanced.dart';
import 'package:mpay_app/domain/repositories/api_security_service.dart';

/// مزود خدمة الأمان
///
/// يوفر خدمة الأمان المحسنة مع دعم certificate pinning لجميع أجزاء التطبيق
class SecurityServiceProvider extends ChangeNotifier {
  final ApiSecurityService _securityService;
  
  SecurityServiceProvider() : _securityService = ApiSecurityServiceImplWithPinning() {
    _initialize();
  }
  
  // تهيئة خدمة الأمان
  Future<void> _initialize() async {
    await _securityService.initialize();
    notifyListeners();
  }
  
  // الحصول على خدمة الأمان
  ApiSecurityService get securityService => _securityService;
  
  // إنشاء عميل HTTP آمن
  Future<http.Client> createSecureClient() async {
    return await _securityService.createSecureClient();
  }
  
  // توليد رؤوس الأمان
  Future<Map<String, String>> generateSecurityHeaders() async {
    return await _securityService.generateSecurityHeaders();
  }
}
