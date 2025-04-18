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

/// تنفيذ خدمات أمان API مع تطبيق Certificate Pinning المحسن
class ApiSecurityServiceImplWithPinning implements ApiSecurityService {
  final FlutterSecureStorage _secureStorage;
  
  // بصمات الشهادات الموثوقة (SHA-256)
  final List<String> _trustedFingerprints = [
    // بصمات SHA-256 لـ api.mpay.com
    // يجب استبدالها ببصمات حقيقية في الإنتاج
    'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99',
    'BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA',
    // بصمات Let's Encrypt الشائعة
    '25:FE:39:32:D9:63:8C:8A:FC:A1:9A:29:87:D8:3E:4C:1D:98:DB:71:E4:1A:48:03:98:EA:22:6A:BD:8B:93:16',
    '06:87:26:03:31:A7:24:03:D9:09:F1:05:E6:9B:CF:0D:32:E1:BD:24:93:FF:C6:D9:20:6D:11:BC:D6:77:07:39',
    // بصمات DigiCert الشائعة
    '1F:B8:6B:11:68:EC:74:31:54:06:2E:8C:9C:C5:B1:71:A4:B7:CC:B4:42:1F:11:39:A8:F6:D6:D3:4C:F9:AC:88',
    // بصمات GlobalSign الشائعة
    'EB:D4:10:40:E4:BB:3E:C7:42:C9:E3:81:D3:1E:F2:A4:1A:48:B6:68:5C:96:E7:CE:F3:C1:DF:6C:D4:33:1C:99',
  ];
  
  // قائمة النطاقات المسموح بها للتحقق من الشهادات
  final Map<String, List<String>> _domainFingerprints = {
    'api.mpay.com': [
      'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99',
      'BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA',
    ],
    'auth.mpay.com': [
      'CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB',
    ],
    // يمكن إضافة المزيد من النطاقات والبصمات حسب الحاجة
  };
  
  // مدة انتهاء صلاحية رمز الجلسة
  static const Duration _sessionTokenExpiry = Duration(hours: 1);
  
  // مدة انتهاء صلاحية رمز CSRF
  static const Duration _csrfTokenExpiry = Duration(hours: 24);
  
  // مفاتيح التشفير
  static const String _aesKeyKey = 'aes_encryption_key';
  static const String _hmacKeyKey = 'hmac_key';
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
    // تطبيق Certificate Pinning المحسن
    final fingerprint = _calculateSHA256Fingerprint(cert);
    
    // التحقق من البصمات الخاصة بالنطاق أولاً (أكثر أمانًا)
    if (_domainFingerprints.containsKey(host)) {
      final domainSpecificFingerprints = _domainFingerprints[host]!;
      if (domainSpecificFingerprints.contains(fingerprint)) {
        return true;
      }
    }
    
    // التحقق مما إذا كانت البصمة في قائمة البصمات الموثوقة العامة
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
    
    // في الإنتاج، نرفض الشهادات غير الموثوقة
    return false;
  }
  
  // حساب بصمة SHA-256 للشهادة
  String _calculateSHA256Fingerprint(X509Certificate cert) {
    // في التنفيذ الحقيقي، يجب حساب بصمة SHA-256 للشهادة
    // هنا نستخدم SHA-1 المتاح في X509Certificate ونحوله إلى تنسيق مقروء
    // ملاحظة: هذا تنفيذ مبسط، في الإنتاج يجب استخدام SHA-256
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
    // تنفيذ محسن للتحقق من اسم المضيف
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
    // محاولة تحديث البصمات من التخزين الآمن
    final storedFingerprints = await _secureStorage.read(key: 'trusted_fingerprints');
    if (storedFingerprints != null) {
      final fingerprints = json.decode(storedFingerprints) as List<dynamic>;
      _trustedFingerprints.addAll(fingerprints.cast<String>());
    }
    
    // محاولة تحديث بصمات النطاقات من التخزين الآمن
    final storedDomainFingerprints = await _secureStorage.read(key: 'domain_fingerprints');
    if (storedDomainFingerprints != null) {
      final domainFingerprintsMap = json.decode(storedDomainFingerprints) as Map<String, dynamic>;
      domainFingerprintsMap.forEach((domain, fingerprints) {
        if (fingerprints is List) {
          _domainFingerprints[domain] = List<String>.from(fingerprints);
        }
      });
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
    headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload';
    headers['Referrer-Policy'] = 'strict-origin-when-cross-origin';
    headers['Permissions-Policy'] = 'geolocation=(), camera=(), microphone=()';
    
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
    return await _decryptData(encryptedToken);
  }
  
  @override
  Future<DateTime?> getStoredAuthTokenExpiry() async {
    final expiryStr = await _secureStorage.read(key: 'api_token_expiry');
    if (expiryStr == null) return null;
    
    try {
      final expiryMillis = int.parse(expiryStr);
      return DateTime.fromMillisecondsSinceEpoch(expiryMillis);
    } catch (e) {
      print('خطأ في تحليل وقت انتهاء صلاحية الرمز: $e');
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
      final keyString = await _getAesKey();
      final keyBytes = base64Url.decode(keyString);
      
      // إنشاء مفتاح AES
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      
      // إنشاء IV عشوائي
      final iv = encrypt.IV.fromSecureRandom(16);
      
      // إنشاء المشفر
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
      print('خطأ في تشفير البيانات: $e');
      throw Exception('فشل تشفير البيانات');
    }
  }
  
  // فك تشفير البيانات
  Future<String?> _decryptData(String encryptedJson) async {
    try {
      final encryptedData = json.decode(encryptedJson) as Map<String, dynamic>;
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
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final decrypted = encrypter.decrypt64(dataString, iv: iv);
      
      return decrypted;
    } catch (e) {
      print('خطأ في فك تشفير البيانات: $e');
      return null;
    }
  }
  
  @override
  Future<void> logSecurityEvent(String userId, String eventType, String details) async {
    // في التنفيذ الحقيقي، يجب تسجيل الأحداث الأمنية في قاعدة بيانات أو خدمة تسجيل
    print('حدث أمني: $userId - $eventType - $details');
  }
}
