import 'package:mpay_app/domain/repositories/payment_security_service.dart';
import 'package:mpay_app/domain/repositories/api_security_service.dart';
import 'package:mpay_app/data/repositories/api_security_service_impl.dart';
import 'package:mpay_app/data/repositories/security_utils_impl.dart';
import 'package:mpay_app/data/repositories/payment_gateway_service_impl.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:get_it/get_it.dart';

/// مزود التبعيات للتطبيق
/// 
/// يستخدم هذا الصف لتسجيل وإدارة التبعيات في التطبيق
/// باستخدام نمط Dependency Injection
class DependencyProvider {
  static final GetIt _instance = GetIt.instance;
  
  /// تهيئة مزود التبعيات
  static Future<void> initialize() async {
    // تسجيل الخدمات الأساسية
    _registerCoreServices();
    
    // تسجيل المستودعات
    _registerRepositories();
    
    // تسجيل حالات الاستخدام
    _registerUseCases();
    
    // تهيئة الخدمات التي تحتاج إلى تهيئة
    await _initializeServices();
  }
  
  /// تسجيل الخدمات الأساسية
  static void _registerCoreServices() {
    // تسجيل خدمات الأمان
    _instance.registerSingleton<ApiSecurityService>(ApiSecurityServiceImpl());
    _instance.registerSingleton<PaymentSecurityService>(SecurityUtilsImpl());
    
    // تسجيل خدمات أخرى
    _instance.registerSingleton<ConnectivityUtils>(ConnectivityUtils());
    _instance.registerSingleton<ErrorHandler>(ErrorHandler());
    _instance.registerSingleton<FirebaseService>(FirebaseService());
    
    // تسجيل خدمة تكامل API
    _instance.registerSingleton<ApiIntegrationService>(ApiIntegrationService());
  }
  
  /// تسجيل المستودعات
  static void _registerRepositories() {
    // تسجيل خدمة بوابة الدفع
    _instance.registerSingleton<PaymentGatewayServiceImpl>(
      PaymentGatewayServiceImpl(
        apiService: _instance<ApiIntegrationService>(),
        firebaseService: _instance<FirebaseService>(),
        connectivityUtils: _instance<ConnectivityUtils>(),
        errorHandler: _instance<ErrorHandler>(),
        securityService: _instance<PaymentSecurityService>(),
      ),
    );
  }
  
  /// تسجيل حالات الاستخدام
  static void _registerUseCases() {
    // سيتم تنفيذ هذا لاحقًا عند إضافة حالات استخدام جديدة
  }
  
  /// تهيئة الخدمات التي تحتاج إلى تهيئة
  static Future<void> _initializeServices() async {
    // تهيئة خدمة أمان API
    await _instance<ApiSecurityService>().initialize();
    
    // تهيئة خدمة تكامل API
    await _instance<ApiIntegrationService>().initialize();
  }
  
  /// الحصول على مثيل من نوع معين
  static T get<T extends Object>() {
    return _instance<T>();
  }
}
