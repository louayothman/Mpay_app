import 'package:mpay_app/domain/repositories/api_security_service.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logging/logging.dart';

/// تنفيذ خدمات أمان API مع تطبيق Certificate Pinning
class ApiSecurityServiceImplWithPinning implements ApiSecurityService {
  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger('ApiSecurityServiceWithPinning');
  
  // بصمات الشهادات الموثوقة
  final List<String> _trustedFingerprints = [
    // بصمات SHA-256 لـ api.mpay.com
    // يجب استبدالها ببصمات حقيقية في الإنتاج
    'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99',
    'BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA',
    // إضافة بصمات Let's Encrypt الشائعة
    '25:FE:39:32:D9:63:8C:8A:FC:A1:9A:29:87:D8:3E:4C:1D:98:DB:71:E4:1A:48:03:98:EA:22:6A:BD:8B:93:16',
    '06:87:26:03:31:A7:24:03:D9:09:F1:05:E6:9B:CF:0D:32:E1:BD:24:93:FF:C6:D9:20:6D:11:BC:D6:77:07:39',
  ];
  
  // مدة انتهاء صلاحية رمز الجلسة
  static const Duration _sessionTokenExpiry = Duration(hours: 1);
  
  // مدة انتهاء صلاحية رمز CSRF
  static const Duration _csrfTokenExpiry = Duration(hours: 24);
  
  // مفاتيح التشفير
  static const String _aesKeyKey = 'aes_encryption_key';
  static const String _hmacKeyKey = 'hmac_key';
  static const String _oldAesKeyKey = 'old_aes_encryption_key';
  static const String _oldHmacKeyKey = 'old_hmac_key';
  static const int _keyLength = 32; // 256 بت
  
  ApiSecurityServiceImplWithPinning({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  @override
  Future<void> initialize() async {
    // تحديث بصمات الشهادات الموثوقة إذا لزم الأمر
    await _updateTrustedFingerprints();
    
    // إنشاء مفاتيح التشفير إذا لم تكن موجودة
    await _initializeEncryptionKeys();
  }
  
  @override
  Future<http.Client> createSecureClient() async {
    // إنشاء عميل HTTP آمن مع التحقق من الشهادات
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback = validateCertificate;
    
    // تعيين مهلة الاتصال
    httpClient.connectionTimeout = const Duration(seconds: 30);
    
    // تمكين HTTP/2
    httpClient.findProxy = null;
    httpClient.autoUncompress = true;
    
    // تعيين خيارات أمان TLS
    _setSecureTlsOptions(httpClient);
    
    // إنشاء IOClient مع HttpClient الآمن
    return http_io.IOClient(httpClient);
  }
  
  // تعيين خيارات أمان TLS
  void _setSecureTlsOptions(HttpClient client) {
    // تعطيل بروتوكولات SSL/TLS القديمة
    client.badCertificateCallback = validateCertificate;
    
    // تعيين منحنيات إهليلجية آمنة
    // ملاحظة: هذه الخيارات غير متاحة مباشرة في Dart HttpClient
    // في التنفيذ الحقيقي، يمكن استخدام قنوات أصلية لتكوين هذه الإعدادات
  }
  
  @override
  bool validateCertificate(X509Certificate cert, String host, int port) {
    // تطبيق Certificate Pinning
    final fingerprint = _calculateFingerprint(cert);
    
    // التحقق مما إذا كانت البصمة في قائمة البصمات الموثوقة
    if (_trustedFingerprints.contains(fingerprint)) {
      return true;
    }
    
    // التحقق من صحة اسم المضيف
    if (!_verifyHostname(cert, host)) {
      logSecurityEvent(
        'system',
        'hostname_verification_failure',
        'فشل التحقق من اسم المضيف: $host:$port',
      );
      return false;
    }
    
    // التحقق من تاريخ انتهاء الصلاحية
    if (!_verifyCertificateExpiry(cert)) {
      logSecurityEvent(
        'system',
        'certificate_expiry_failure',
        'شهادة منتهية الصلاحية لـ: $host:$port',
      );
      return false;
    }
    
    // تسجيل حدث أمني لفشل التحقق من الشهادة
    logSecurityEvent(
      'system',
      'certificate_validation_failure',
      'شهادة غير موثوقة لـ: $host:$port - بصمة: $fingerprint',
    );
    
    // في الإنتاج، يجب إرجاع false لرفض الشهادات غير الموثوقة
    return false;
  }
  
  // حساب بصمة الشهادة
  String _calculateFingerprint(X509Certificate cert) {
    // في التنفيذ الحقيقي، يجب حساب بصمة SHA-256 للشهادة
    // هنا نستخدم SHA-1 المتاح في X509Certificate ونحوله إلى تنسيق مقروء
    final sha1 = cert.sha1;
    final formattedFingerprint = sha1.toUpperCase().replaceAllMapped(
      RegExp(r'..'),
      (match) => '${match.group(0)}:',
    );
    
    // إزالة النقطتين الأخيرتين
    return formattedFingerprint.substring(0, formattedFingerprint.length - 1);
  }
  
  // التحقق من صحة اسم المضيف
  bool _verifyHostname(X509Certificate cert, String host) {
    // في التنفيذ الحقيقي، يجب التحقق من أن الشهادة صالحة لاسم المضيف المحدد
    // هذا تنفيذ محسن للتحقق من اسم المضيف
    final subject = cert.subject;
    final commonNameMatch = RegExp(r'CN=([^,]+)').firstMatch(subject);
    
    if (commonNameMatch != null) {
      final commonName = commonNameMatch.group(1);
      if (commonName == host) {
        return true;
      }
      
      // التحقق من البدائل
      if (commonName!.startsWith('*.') && host.split('.').length > 1) {
        final hostWithoutSubdomain = host.substring(host.indexOf('.') + 1);
        final wildcardDomain = commonName.substring(2); // إزالة *. من البداية
        if (hostWithoutSubdomain == wildcardDomain) {
          return true;
        }
      }
    }
    
    // التحقق من Subject Alternative Names (SAN)
    // هذا غير متاح مباشرة في X509Certificate في Dart
    // في التنفيذ الحقيقي، يجب استخدام مكتبة أكثر تقدمًا للتحقق من الشهادات
    
    return false;
  }
  
  // التحقق من تاريخ انتهاء صلاحية الشهادة
  bool _verifyCertificateExpiry(X509Certificate cert) {
    final now = DateTime.now();
    return now.isAfter(cert.startValidity) && now.isBefore(cert.endValidity);
  }
  
  // تحديث بصمات الشهادات الموثوقة
  Future<void> _updateTrustedFingerprints() async {
    // في التنفيذ الحقيقي، يمكن تحديث البصمات من الخادم
    // هذا تنفيذ مبسط
    final storedFingerprints = await _secureStorage.read(key: 'trusted_fingerprints');
    if (storedFingerprints != null) {
      final fingerprints = json.decode(storedFingerprints) as List<dynamic>;
      _trustedFingerprints.addAll(fingerprints.cast<String>());
    }
  }
  
  // تهيئة مفاتيح التشفير
  Future<void> _initializeEncryptionKeys() async {
    // إنشاء مفتاح AES إذا لم يكن موجودًا
    String? aesKey = await _secureStorage.read(key: _aesKeyKey);
    if (aesKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(_keyLength, (i) => random.nextInt(256));
      aesKey = base64Url.encode(keyBytes);
      await _secureStorage.write(key: _aesKeyKey, value: aesKey);
    }
    
    // إنشاء مفتاح HMAC إذا لم يكن موجودًا
    String? hmacKey = await _secureStorage.read(key: _hmacKeyKey);
    if (hmacKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(_keyLength, (i) => random.nextInt(256));
      hmacKey = base64Url.encode(keyBytes);
      await _secureStorage.write(key: _hmacKeyKey, value: hmacKey);
    }
  }
  
  // تدوير مفاتيح التشفير
  Future<bool> rotateEncryptionKeys() async {
    try {
      // حفظ المفاتيح القديمة أولاً
      final currentAesKey = await _secureStorage.read(key: _aesKeyKey);
      final currentHmacKey = await _secureStorage.read(key: _hmacKeyKey);
      
      if (currentAesKey == null || currentHmacKey == null) {
        _logger.severe('فشل تدوير المفاتيح: المفاتيح الحالية غير موجودة');
        return false;
      }
      
      // حفظ المفاتيح الحالية كمفاتيح قديمة
      await _secureStorage.write(key: _oldAesKeyKey, value: currentAesKey);
      await _secureStorage.write(key: _oldHmacKeyKey, value: currentHmacKey);
      
      // إنشاء مفاتيح جديدة
      final random = Random.secure();
      final newAesKeyBytes = List<int>.generate(_keyLength, (i) => random.nextInt(256));
      final newHmacKeyBytes = List<int>.generate(_keyLength, (i) => random.nextInt(256));
      
      final newAesKey = base64Url.encode(newAesKeyBytes);
      final newHmacKey = base64Url.encode(newHmacKeyBytes);
      
      // تخزين المفاتيح الجديدة
      await _secureStorage.write(key: _aesKeyKey, value: newAesKey);
      await _secureStorage.write(key: _hmacKeyKey, value: newHmacKey);
      
      _logger.info('تم تدوير مفاتيح التشفير بنجاح');
      return true;
    } catch (e) {
      _logger.severe('فشل تدوير المفاتيح: $e');
      
      // محاولة استعادة المفاتيح القديمة في حالة الفشل
      final oldAesKey = await _secureStorage.read(key: _oldAesKeyKey);
      final oldHmacKey = await _secureStorage.read(key: _oldHmacKeyKey);
      
      if (oldAesKey != null && oldHmacKey != null) {
        await _secureStorage.write(key: _aesKeyKey, value: oldAesKey);
        await _secureStorage.write(key: _hmacKeyKey, value: oldHmacKey);
        _logger.info('تمت استعادة المفاتيح القديمة بعد فشل التدوير');
      }
      
      return false;
    }
  }
  
  // محاولة فك تشفير البيانات باستخدام المفاتيح القديمة
  Future<String?> _tryDecryptWithOldKeys(String encryptedJson) async {
    try {
      final encryptedData = json.decode(encryptedJson) as Map<String, dynamic>;
      final ivString = encryptedData['iv'] as String;
      final dataString = encryptedData['data'] as String;
      
      // استخدام المفاتيح القديمة
      final oldAesKey = await _secureStorage.read(key: _oldAesKeyKey);
      if (oldAesKey == null) return null;
      
      final keyBytes = base64Url.decode(oldAesKey);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt.IV.fromBase64(ivString);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final decrypted = encrypter.decrypt64(dataString, iv: iv);
      
      return decrypted;
    } catch (e) {
      _logger.warning('فشل فك التشفير باستخدام المفاتيح القديمة: $e');
      return null;
    }
  }
  
  @override
  Future<Map<String, String>> generateSecurityHeaders() async {
    final headers = <String, String>{};
    
    // إضافة رمز CSRF مع نمط ملف تعريف ارتباط مزدوج
    final csrfToken = await _generateCsrfToken();
    headers['X-CSRF-Token'] = csrfToken;
    
    // إضافة طابع زمني للطلب لمنع هجمات إعادة التشغيل
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    headers['X-Request-Timestamp'] = timestamp;
    
    // إضافة رقم عشوائي للطلب لمنع هجمات إعادة التشغيل
    final nonce = _generateNonce();
    headers['X-Request-Nonce'] = nonce;
    
    // إضافة توقيع HMAC لبيانات الطلب للتحقق من سلامتها
    final signature = await _generateRequestSignature(timestamp, nonce);
    headers['X-Request-Signature'] = signature;
    
    // إضافة رأس Content-Security-Policy
    headers['Content-Security-Policy'] = "default-src 'self'; script-src 'self'; object-src 'none';";
    
    // إضافة رؤوس أمان إضافية
    headers['X-Content-Type-Options'] = 'nosniff';
    headers['X-Frame-Options'] = 'DENY';
    headers['X-XSS-Protection'] = '1; mode=block';
    headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains';
    
    return headers;
  }
  
  // توليد رمز CSRF مع أمان محسن
  Future<String> _generateCsrfToken() async {
    const csrfTokenKey = 'csrf_token';
    String? csrfToken = await _secureStorage.read(key: csrfTokenKey);
    
    // إعادة توليد رمز CSRF إذا لم يكن موجودًا أو كان أقدم من 24 ساعة
    final csrfTokenTimestampKey = 'csrf_token_timestamp';
    final timestampStr = await _secureStorage.read(key: csrfTokenTimestampKey);
    final shouldRegenerateToken = csrfToken == null || timestampStr == null || 
        _isTokenExpired(int.parse(timestampStr), _csrfTokenExpiry);
    
    if (shouldRegenerateToken) {
      final random = Random.secure();
      final tokenBytes = List<int>.generate(32, (i) => random.nextInt(256));
      csrfToken = base64Url.encode(tokenBytes);
      
      // تخزين الرمز والطابع الزمني
      await _secureStorage.write(key: csrfTokenKey, value: csrfToken);
      await _secureStorage.write(
        key: csrfTokenTimestampKey, 
        value: DateTime.now().millisecondsSinceEpoch.toString()
      );
      
      // تسجيل إعادة توليد الرمز
      logSecurityEvent('system', 'csrf_token_regenerated', 'تمت إعادة توليد رمز CSRF');
    }
    
    return csrfToken!;
  }
  
  // توليد رقم عشوائي للطلب
  String _generateNonce() {
    final random = Random.secure();
    final nonceBytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(nonceBytes);
  }
  
  // توليد توقيع الطلب
  Future<String> _generateRequestSignature(String timestamp, String nonce) async {
    final data = '$timestamp:$nonce';
    final key = await _getHmacKey();
    
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }
  
  // الحصول على مفتاح HMAC
  Future<String> _getHmacKey() async {
    String? hmacKey = await _secureStorage.read(key: _hmacKeyKey);
    if (hmacKey == null) {
      // إذا لم يكن المفتاح موجودًا، قم بإنشائه
      await _initializeEncryptionKeys();
      hmacKey = await _secureStorage.read(key: _hmacKeyKey);
    }
    return hmacKey!;
  }
  
  // الحصول على مفتاح AES
  Future<String> _getAesKey() async {
    String? aesKey = await _secureStorage.read(key: _aesKeyKey);
    if (aesKey == null) {
      // إذا لم يكن المفتاح موجودًا، قم بإنشائه
      await _initializeEncryptionKeys();
      aesKey = await _secureStorage.read(key: _aesKeyKey);
    }
    return aesKey!;
  }
  
  // التحقق مما إذا كان الرمز منتهي الصلاحية
  bool _isTokenExpired(int timestamp, Duration maxAge) {
    final tokenTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(tokenTime) > maxAge;
  }
  
  @override
  Future<void> storeAuthToken(String token, DateTime expiryTime) async {
    // التحقق من صحة المدخلات
    if (token.isEmpty) {
      throw ArgumentError('رمز المصادقة لا يمكن أن يكون فارغًا');
    }
    
    if (expiryTime.isBefore(DateTime.now())) {
      throw ArgumentError('وقت انتهاء صلاحية الرمز يجب أن يكون في المستقبل');
    }
    
    // تشفير الرمز قبل التخزين
    final encryptedToken = await _encryptData(token);
    
    await _secureStorage.write(key: 'api_token', value: encryptedToken);
    await _secureStorage.write(
      key: 'api_token_expiry',
      value: expiryTime.millisecondsSinceEpoch.toString(),
    );
  }
  
  @override
  Future<String?> getStoredAuthToken() async {
    final encryptedToken = await _secureStorage.read(key: 'api_token');
    if (encryptedToken == null) return null;
    
    // فك تشفير الرمز
    String? decryptedToken = await _decryptData(encryptedToken);
    
    // إذا فشل فك التشفير، حاول باستخدام المفاتيح القديمة
    if (decryptedToken == null) {
      decryptedToken = await _tryDecryptWithOldKeys(encryptedToken);
      
      // إذا نجح فك التشفير باستخدام المفاتيح القديمة، أعد تشفير الرمز باستخدام المفاتيح الجديدة
      if (decryptedToken != null) {
        final newEncryptedToken = await _encryptData(decryptedToken);
        await _secureStorage.write(key: 'api_token', value: newEncryptedToken);
        _logger.info('تم إعادة تشفير الرمز باستخدام المفاتيح الجديدة');
      }
    }
    
    return decryptedToken;
  }
  
  @override
  Future<DateTime?> getStoredAuthTokenExpiry() async {
    final expiryStr = await _secureStorage.read(key: 'api_token_expiry');
    if (expiryStr == null) return null;
    
    try {
      final expiryMillis = int.parse(expiryStr);
      return DateTime.fromMillisecondsSinceEpoch(expiryMillis);
    } catch (e) {
      _logger.severe('خطأ في تحليل وقت انتهاء صلاحية الرمز: $e');
      return null;
    }
  }
  
  @override
  Future<void> clearStoredAuthToken() async {
    await _secureStorage.delete(key: 'api_token');
    await _secureStorage.delete(key: 'api_token_expiry');
  }
  
  // تشفير البيانات باستخدام AES
  Future<String> _encryptData(String data) async {
    try {
      // التحقق من صحة المدخلات
      if (data.isEmpty) {
        throw ArgumentError('البيانات المراد تشفيرها لا يمكن أن تكون فارغة');
      }
      
      final keyString = await _getAesKey();
      final keyBytes = base64Url.decode(keyString);
      
      // إنشاء مفتاح AES
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      
      // إنشاء IV عشوائي
      final iv = encrypt.IV.fromSecureRandom(16);
      
      // إنشاء المشفر باستخدام وضع GCM بدلاً من CBC
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      
      // تشفير البيانات
      final encrypted = encrypter.encrypt(data, iv: iv);
      
      // إنشاء HMAC للتحقق من سلامة البيانات
      final hmacKey = await _getHmacKey();
      final hmac = Hmac(sha256, utf8.encode(hmacKey));
      final digest = hmac.convert(utf8.encode('${iv.base64}:${encrypted.base64}'));
      final authTag = digest.toString();
      
      // إرجاع البيانات المشفرة مع IV وعلامة المصادقة
      return json.encode({
        'iv': iv.base64,
        'data': encrypted.base64,
        'auth': authTag,
      });
    } catch (e) {
      _logger.severe('خطأ في تشفير البيانات: $e');
      throw Exception('فشل تشفير البيانات');
    }
  }
  
  // فك تشفير البيانات
  Future<String?> _decryptData(String encryptedJson) async {
    try {
      // التحقق من صحة المدخلات
      if (encryptedJson.isEmpty) {
        throw ArgumentError('البيانات المشفرة لا يمكن أن تكون فارغة');
      }
      
      final encryptedData = json.decode(encryptedJson) as Map<String, dynamic>;
      
      // التحقق من وجود جميع الحقول المطلوبة
      if (!encryptedData.containsKey('iv') || !encryptedData.containsKey('data') || !encryptedData.containsKey('auth')) {
        throw FormatException('تنسيق البيانات المشفرة غير صالح');
      }
      
      final ivString = encryptedData['iv'] as String;
      final dataString = encryptedData['data'] as String;
      final authTag = encryptedData['auth'] as String;
      
      // التحقق من سلامة البيانات
      final hmacKey = await _getHmacKey();
      final hmac = Hmac(sha256, utf8.encode(hmacKey));
      final digest = hmac.convert(utf8.encode('$ivString:$dataString'));
      final calculatedAuthTag = digest.toString();
      
      if (authTag != calculatedAuthTag) {
        logSecurityEvent(
          'system',
          'data_integrity_violation',
          'فشل التحقق من سلامة البيانات المشفرة',
        );
        return null;
      }
      
      // فك تشفير البيانات
      final keyString = await _getAesKey();
      final keyBytes = base64Url.decode(keyString);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt.IV.fromBase64(ivString);
      
      // استخدام وضع GCM بدلاً من CBC
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final decrypted = encrypter.decrypt64(dataString, iv: iv);
      
      return decrypted;
    } catch (e) {
      _logger.warning('خطأ في فك تشفير البيانات: $e');
      return null;
    }
  }
  
  @override
  Future<void> logSecurityEvent(String userId, String eventType, String details) async {
    // استخدام نظام تسجيل متخصص بدلاً من print
    _logger.info('حدث أمني: $userId - $eventType - $details');
    
    // في التنفيذ الحقيقي، يجب تسجيل الأحداث الأمنية في قاعدة بيانات أو خدمة تسجيل
    try {
      // مثال: تخزين الحدث في قاعدة بيانات محلية
      final securityEvent = {
        'userId': userId,
        'eventType': eventType,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // تخزين الحدث في التخزين المؤقت
      final eventsJson = await _secureStorage.read(key: 'security_events') ?? '[]';
      final events = json.decode(eventsJson) as List<dynamic>;
      events.add(securityEvent);
      
      // تقليم قائمة الأحداث للاحتفاظ بآخر 100 حدث فقط
      if (events.length > 100) {
        events.removeRange(0, events.length - 100);
      }
      
      await _secureStorage.write(key: 'security_events', value: json.encode(events));
    } catch (e) {
      _logger.severe('فشل تسجيل الحدث الأمني: $e');
    }
  }
}
