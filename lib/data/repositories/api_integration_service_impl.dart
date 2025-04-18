import 'package:mpay_app/domain/repositories/api_security_service.dart';
import 'package:mpay_app/core/di/dependency_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// خدمة تكامل API المحسنة
/// 
/// تستخدم هذه الخدمة لإجراء طلبات HTTP آمنة إلى واجهات API
class ApiIntegrationServiceImpl {
  final ApiSecurityService _securityService;
  
  // عناوين URL الأساسية للبيئات المختلفة
  static const String _productionBaseUrl = 'https://api.mpay.com/v1';
  static const String _stagingBaseUrl = 'https://staging-api.mpay.com/v1';
  static const String _developmentBaseUrl = 'https://dev-api.mpay.com/v1';
  
  // البيئة الحالية
  String _currentEnvironment = 'production';
  
  // مدة مهلة API
  Duration _timeoutDuration = const Duration(seconds: 30);
  
  // تكوين إعادة المحاولة
  int _maxRetries = 3;
  Duration _retryDelay = const Duration(seconds: 2);
  
  // تكوين التخزين المؤقت
  final Map<String, CachedResponse> _responseCache = {};
  final Duration _defaultCacheDuration = const Duration(minutes: 5);
  
  // الحد من معدل الطلبات
  final Map<String, DateTime> _lastRequestTimes = {};
  final Duration _minRequestInterval = const Duration(milliseconds: 500);
  
  // عميل HTTP آمن
  http.Client? _secureClient;
  
  ApiIntegrationServiceImpl({
    ApiSecurityService? securityService,
  }) : _securityService = securityService ?? DependencyProvider.get<ApiSecurityService>();
  
  // تهيئة الخدمة
  Future<void> initialize({
    String environment = 'production',
    Duration? timeout,
    int? maxRetries,
    Duration? retryDelay,
    Duration? cacheDuration,
    Duration? minRequestInterval,
  }) async {
    _currentEnvironment = environment;
    
    if (timeout != null) {
      _timeoutDuration = timeout;
    }
    
    if (maxRetries != null) {
      _maxRetries = maxRetries;
    }
    
    if (retryDelay != null) {
      _retryDelay = retryDelay;
    }
    
    if (minRequestInterval != null) {
      _minRequestInterval = minRequestInterval;
    }
    
    // تهيئة عميل HTTP آمن
    await _initializeSecureClient();
    
    // مسح التخزين المؤقت
    clearCache();
  }
  
  // تهيئة عميل HTTP آمن
  Future<void> _initializeSecureClient() async {
    _secureClient = await _securityService.createSecureClient();
  }
  
  // الحصول على عنوان URL الأساسي بناءً على البيئة الحالية
  String get baseUrl {
    switch (_currentEnvironment) {
      case 'production':
        return _productionBaseUrl;
      case 'staging':
        return _stagingBaseUrl;
      case 'development':
        return _developmentBaseUrl;
      default:
        return _productionBaseUrl;
    }
  }
  
  // تعيين رمز المصادقة
  Future<void> setAuthToken(String token, {Duration? expiresIn}) async {
    final expiryTime = DateTime.now().add(expiresIn ?? const Duration(hours: 1));
    await _securityService.storeAuthToken(token, expiryTime);
  }
  
  // مسح رمز المصادقة
  Future<void> clearAuthToken() async {
    await _securityService.clearStoredAuthToken();
  }
  
  // التحقق مما إذا كان الرمز صالحًا
  Future<bool> get isTokenValid async {
    final token = await _securityService.getStoredAuthToken();
    final expiryTime = await _securityService.getStoredAuthTokenExpiry();
    
    if (token == null || expiryTime == null) {
      return false;
    }
    
    // إضافة مخزن مؤقت مدته 5 دقائق قبل انتهاء الصلاحية الفعلي
    final expiryWithBuffer = expiryTime.subtract(const Duration(minutes: 5));
    return DateTime.now().isBefore(expiryWithBuffer);
  }
  
  // مسح التخزين المؤقت
  void clearCache() {
    _responseCache.clear();
  }
  
  // مسح إدخال تخزين مؤقت محدد
  void clearCacheEntry(String cacheKey) {
    _responseCache.remove(cacheKey);
  }
  
  // توليد مفتاح التخزين المؤقت
  String _generateCacheKey(String url, Map<String, dynamic>? queryParams, Map<String, dynamic>? body) {
    final buffer = StringBuffer(url);
    
    if (queryParams != null && queryParams.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        queryParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      buffer.write('?');
      buffer.write(sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&'));
    }
    
    if (body != null && body.isNotEmpty) {
      buffer.write('#');
      buffer.write(json.encode(body));
    }
    
    return buffer.toString();
  }
  
  // التحقق من الحد من معدل الطلبات
  bool _checkRateLimit(String endpoint) {
    final now = DateTime.now();
    
    if (_lastRequestTimes.containsKey(endpoint)) {
      final lastRequestTime = _lastRequestTimes[endpoint]!;
      final timeSinceLastRequest = now.difference(lastRequestTime);
      
      if (timeSinceLastRequest < _minRequestInterval) {
        return false;
      }
    }
    
    _lastRequestTimes[endpoint] = now;
    return true;
  }
  
  // الحصول على رؤوس مصادقة
  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final token = await _securityService.getStoredAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // إضافة رؤوس أمان
    final securityHeaders = await _securityService.generateSecurityHeaders();
    headers.addAll(securityHeaders);
    
    return headers;
  }
  
  // تنفيذ طلب HTTP مع منطق إعادة المحاولة
  Future<http.Response> _executeRequest(
    Future<http.Response> Function() requestFunction,
    String endpoint,
  ) async {
    if (!_checkRateLimit(endpoint)) {
      throw ApiException(
        'تم تجاوز الحد من معدل الطلبات للنقطة النهائية: $endpoint',
        429,
      );
    }
    
    // التأكد من تهيئة العميل الآمن
    if (_secureClient == null) {
      await _initializeSecureClient();
    }
    
    int retryCount = 0;
    
    while (true) {
      try {
        return await requestFunction().timeout(_timeoutDuration);
      } catch (e) {
        retryCount++;
        
        if (retryCount >= _maxRetries) {
          rethrow;
        }
        
        // التحقق مما إذا كان يجب إعادة محاولة الطلب بناءً على الخطأ
        final shouldRetry = _shouldRetryRequest(e);
        if (!shouldRetry) {
          rethrow;
        }
        
        // التأخير التصاعدي
        final delay = _retryDelay * retryCount;
        await Future.delayed(delay);
      }
    }
  }
  
  // تحديد ما إذا كان يجب إعادة محاولة الطلب
  bool _shouldRetryRequest(dynamic error) {
    if (error is SocketException || error is TimeoutException) {
      return true;
    }
    
    if (error is http.ClientException) {
      return true;
    }
    
    if (error is ApiException) {
      // إعادة المحاولة في حالة أخطاء الخادم (5xx) وليس في حالة أخطاء العميل (4xx)
      return error.statusCode >= 500 && error.statusCode < 600;
    }
    
    return false;
  }
  
  // معالجة استجابة API
  Future<dynamic> _processResponse(http.Response response, String endpoint) async {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      // استجابة ناجحة
      if (response.body.isEmpty) {
        return null;
      }
      
      try {
        return json.decode(response.body);
      } catch (e) {
        // تسجيل خطأ في تحليل الاستجابة
        await _securityService.logSecurityEvent(
          'system',
          'api_response_parse_error',
          'فشل في تحليل استجابة API للنقطة النهائية: $endpoint',
        );
        return response.body;
      }
    } else if (statusCode == 401) {
      // غير مصرح - مسح الرمز وإلقاء استثناء
      await clearAuthToken();
      throw ApiException(
        'وصول غير مصرح به. يرجى تسجيل الدخول مرة أخرى.',
        statusCode,
      );
    } else {
      // استجابة خطأ
      String errorMessage = 'فشل طلب API مع رمز الحالة: $statusCode';
      String errorCode = 'unknown_error';
      
      try {
        final errorBody = json.decode(response.body);
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'];
        } else if (errorBody['error'] != null) {
          errorMessage = errorBody['error'];
        }
        
        if (errorBody['code'] != null) {
          errorCode = errorBody['code'];
        }
        
        // تسجيل أحداث أمنية لرموز خطأ معينة
        if (statusCode == 403 || statusCode == 429) {
          await _securityService.logSecurityEvent(
            'system',
            'api_security_event',
            'خطأ API متعلق بالأمان: $statusCode - $errorCode',
          );
        }
      } catch (e) {
        // تجاهل أخطاء التحليل لاستجابات الخطأ
      }
      
      throw ApiException(errorMessage, statusCode, errorCode: errorCode);
    }
  }
  
  // طلب GET
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool useCache = false,
    Duration? cacheDuration,
    bool requiresAuth = true,
  }) async {
    final url = '$baseUrl$endpoint';
    final cacheKey = _generateCacheKey(url, queryParams, null);
    
    // التحقق من التخزين المؤقت إذا تم تمكينه
    if (useCache && _responseCache.containsKey(cacheKey)) {
      final cachedResponse = _responseCache[cacheKey]!;
      if (!cachedResponse.isExpired()) {
        return cachedResponse.data;
      }
    }
    
    // الحصول على رؤوس مصادقة
    final headers = await _getAuthenticatedHeaders();
    
    // بناء URI مع معلمات الاستعلام
    final uri = Uri.parse(url).replace(
      queryParameters: queryParams,
    );
    
    // تنفيذ الطلب
    final response = await _executeRequest(
      () => _secureClient!.get(uri, headers: headers),
      endpoint,
    );
    
    // معالجة الاستجابة
    final responseData = await _processResponse(response, endpoint);
    
    // تخزين الاستجابة في التخزين المؤقت إذا تم تمكينه
    if (useCache) {
      _responseCache[cacheKey] = CachedResponse(
        responseData,
        DateTime.now(),
        cacheDuration ?? _defaultCacheDuration,
      );
    }
    
    return responseData;
  }
  
  // طلب POST
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
    bool useCache = false,
    Duration? cacheDuration,
    bool requiresAuth = true,
  }) async {
    final url = '$baseUrl$endpoint';
    final cacheKey = _generateCacheKey(url, queryParams, body);
    
    // التحقق من التخزين المؤقت إذا تم تمكينه
    if (useCache && _responseCache.containsKey(cacheKey)) {
      final cachedResponse = _responseCache[cacheKey]!;
      if (!cachedResponse.isExpired()) {
        return cachedResponse.data;
      }
    }
    
    // الحصول على رؤوس مصادقة
    final headers = await _getAuthenticatedHeaders();
    
    // بناء URI مع معلمات الاستعلام
    final uri = Uri.parse(url).replace(
      queryParameters: queryParams,
    );
    
    // تنفيذ الطلب
    final response = await _executeRequest(
      () => _secureClient!.post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ),
      endpoint,
    );
    
    // معالجة الاستجابة
    final responseData = await _processResponse(response, endpoint);
    
    // تخزين الاستجابة في التخزين المؤقت إذا تم تمكينه
    if (useCache) {
      _responseCache[cacheKey] = CachedResponse(
        responseData,
        DateTime.now(),
        cacheDuration ?? _defaultCacheDuration,
      );
    }
    
    return responseData;
  }
  
  // طلب PUT
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final url = '$baseUrl$endpoint';
    
    // الحصول على رؤوس مصادقة
    final headers = await _getAuthenticatedHeaders();
    
    // بناء URI مع معلمات الاستعلام
    final uri = Uri.parse(url).replace(
      queryParameters: queryParams,
    );
    
    // تنفيذ الطلب
    final response = await _executeRequest(
      () => _secureClient!.put(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ),
      endpoint,
    );
    
    // معالجة الاستجابة
    return await _processResponse(response, endpoint);
  }
  
  // طلب DELETE
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final url = '$baseUrl$endpoint';
    
    // الحصول على رؤوس مصادقة
    final headers = await _getAuthenticatedHeaders();
    
    // بناء URI مع معلمات الاستعلام
    final uri = Uri.parse(url).replace(
      queryParameters: queryParams,
    );
    
    // تنفيذ الطلب
    final response = await _executeRequest(
      () => _secureClient!.delete(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ),
      endpoint,
    );
    
    // معالجة الاستجابة
    return await _processResponse(response, endpoint);
  }
}

/// استجابة مخزنة مؤقتًا
class CachedResponse {
  final dynamic data;
  final DateTime timestamp;
  final Duration duration;
  
  CachedResponse(this.data, this.timestamp, this.duration);
  
  bool isExpired() {
    final now = DateTime.now();
    return now.difference(timestamp) > duration;
  }
}

/// استثناء API
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? errorCode;
  
  ApiException(this.message, this.statusCode, {this.errorCode});
  
  @override
  String toString() {
    return 'ApiException: $message (Code: $statusCode${errorCode != null ? ', ErrorCode: $errorCode' : ''})';
  }
}
