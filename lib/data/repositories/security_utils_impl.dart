import 'package:mpay_app/domain/repositories/payment_security_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:mpay_app/utils/wallet_validator.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

/// تنفيذ خدمات الأمان المتعلقة بالمدفوعات
class SecurityUtilsImpl implements PaymentSecurityService {
  final FlutterSecureStorage _secureStorage;
  final FirebaseFirestore _firestore;
  
  // مفاتيح التخزين
  static const String _keyVersionKey = 'current_key_version';
  static const String _lastKeyRotationKey = 'last_key_rotation_timestamp';
  static const String _encryptionKeyKey = 'payment_encryption_key';
  static const String _hmacKeyKey = 'hmac_master_key';
  
  SecurityUtilsImpl({
    FlutterSecureStorage? secureStorage,
    FirebaseFirestore? firestore,
  }) : 
    _secureStorage = secureStorage ?? const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    ),
    _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Future<void> initializePaymentSecurity() async {
    // التحقق مما إذا كان تدوير المفاتيح مطلوبًا
    await _checkAndRotateKeys();
    
    // التأكد من وجود مفاتيح التشفير
    await _initializeEncryptionKeys();
  }
  
  // تهيئة مفاتيح التشفير
  Future<void> _initializeEncryptionKeys() async {
    // إنشاء مفتاح التشفير إذا لم يكن موجودًا
    String? encryptionKey = await _secureStorage.read(key: _encryptionKeyKey);
    if (encryptionKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      encryptionKey = base64Url.encode(keyBytes);
      await _secureStorage.write(key: _encryptionKeyKey, value: encryptionKey);
    }
    
    // إنشاء مفتاح HMAC إذا لم يكن موجودًا
    String? hmacKey = await _secureStorage.read(key: _hmacKeyKey);
    if (hmacKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      hmacKey = base64Url.encode(keyBytes);
      await _secureStorage.write(key: _hmacKeyKey, value: hmacKey);
    }
  }
  
  @override
  Future<String> generateHmac(String data, String key) async {
    final hmacKey = await _getOrCreateHmacKey();
    final hmac = Hmac(sha256, utf8.encode(hmacKey + key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }
  
  @override
  bool validateWalletAddress(String cryptoCurrency, String address) {
    if (address.isEmpty) return false;
    
    try {
      switch (cryptoCurrency.toUpperCase()) {
        case 'BTC':
          return WalletValidator.validate(address: address, network: 'bitcoin');
        case 'ETH':
        case 'USDT_ERC20':
          return WalletValidator.validate(address: address, network: 'ethereum');
        case 'USDT_TRC20':
          return WalletValidator.validate(address: address, network: 'tron');
        default:
          // للعملات غير المدعومة، نتحقق فقط من الطول والأحرف المسموح بها
          return WalletValidator.validateGenericAddress(address);
      }
    } catch (e) {
      _logError('Error validating wallet address', e);
      return false;
    }
  }
  
  @override
  Future<String> encryptPaymentData(Map<String, dynamic> data) async {
    final jsonData = jsonEncode(data);
    final encryptionKey = await _getOrCreatePaymentEncryptionKey();
    
    // استخدام تشفير AES مع وضع CBC وتبطين PKCS7
    final keyBytes = base64Url.decode(encryptionKey);
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    
    // توليد IV عشوائي لكل عملية تشفير
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    
    // تشفير البيانات
    final encrypted = encrypter.encrypt(jsonData, iv: iv);
    
    // إنشاء النتيجة مع البيانات المشفرة و IV
    final result = {
      'data': encrypted.base64,
      'iv': iv.base64,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // توليد HMAC للبيانات المشفرة للتحقق من سلامتها
    final hmac = await generateHmac(jsonEncode(result), 'payment_data');
    result['hmac'] = hmac;
    
    // إضافة إصدار المفتاح لدعم تدوير المفاتيح
    final keyVersion = await _secureStorage.read(key: _keyVersionKey) ?? '1';
    result['version'] = keyVersion;
    
    return jsonEncode(result);
  }
  
  @override
  Future<void> logSecurityEvent(String userId, String eventType, String details) async {
    try {
      await _firestore.collection('security_logs').add({
        'userId': userId,
        'eventType': eventType,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': await _getDeviceInfo(),
      });
    } catch (e) {
      _logError('Error logging security event', e);
    }
  }
  
  // الحصول على أو إنشاء مفتاح HMAC
  Future<String> _getOrCreateHmacKey() async {
    String? hmacKey = await _secureStorage.read(key: _hmacKeyKey);
    
    if (hmacKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      hmacKey = base64Url.encode(keyBytes);
      await _secureStorage.write(key: _hmacKeyKey, value: hmacKey);
      
      // تخزين الطابع الزمني الأولي لتدوير المفتاح
      await _secureStorage.write(
        key: _lastKeyRotationKey,
        value: DateTime.now().millisecondsSinceEpoch.toString()
      );
      
      // تعيين إصدار المفتاح الأولي
      await _secureStorage.write(key: _keyVersionKey, value: '1');
    }
    
    return hmacKey;
  }
  
  // الحصول على أو إنشاء مفتاح تشفير المدفوعات
  Future<String> _getOrCreatePaymentEncryptionKey() async {
    String? encryptionKey = await _secureStorage.read(key: _encryptionKeyKey);
    
    if (encryptionKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      encryptionKey = base64Url.encode(keyBytes);
      await _secureStorage.write(key: _encryptionKeyKey, value: encryptionKey);
    }
    
    return encryptionKey;
  }
  
  // التحقق من الحاجة إلى تدوير المفاتيح وتنفيذه إذا لزم الأمر
  Future<void> _checkAndRotateKeys() async {
    final lastRotationStr = await _secureStorage.read(key: _lastKeyRotationKey);
    if (lastRotationStr == null) {
      // لم يتم تدوير المفاتيح من قبل، تعيين الطابع الزمني الحالي
      await _secureStorage.write(
        key: _lastKeyRotationKey,
        value: DateTime.now().millisecondsSinceEpoch.toString()
      );
      return;
    }
    
    final lastRotation = int.parse(lastRotationStr);
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;
    
    if ((now - lastRotation) > thirtyDaysInMillis) {
      // تدوير المفاتيح
      await _rotateKeys();
      
      // تحديث الطابع الزمني
      await _secureStorage.write(
        key: _lastKeyRotationKey,
        value: now.toString()
      );
    }
  }
  
  // تدوير المفاتيح
  Future<void> _rotateKeys() async {
    // الحصول على إصدار المفتاح الحالي
    final currentVersionStr = await _secureStorage.read(key: _keyVersionKey) ?? '0';
    final currentVersion = int.parse(currentVersionStr);
    final newVersion = currentVersion + 1;
    
    // إنشاء مفاتيح جديدة
    final random = Random.secure();
    
    // تدوير مفتاح HMAC
    final hmacKeyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    final newHmacKey = base64Url.encode(hmacKeyBytes);
    await _secureStorage.write(key: '${_hmacKeyKey}_v$newVersion', value: newHmacKey);
    
    // تدوير مفتاح تشفير المدفوعات
    final paymentKeyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    final newPaymentKey = base64Url.encode(paymentKeyBytes);
    await _secureStorage.write(key: '${_encryptionKeyKey}_v$newVersion', value: newPaymentKey);
    
    // تحديث المفاتيح الرئيسية
    await _secureStorage.write(key: _hmacKeyKey, value: newHmacKey);
    await _secureStorage.write(key: _encryptionKeyKey, value: newPaymentKey);
    
    // تحديث إصدار المفتاح الحالي
    await _secureStorage.write(key: _keyVersionKey, value: newVersion.toString());
    
    // تسجيل حدث تدوير المفاتيح
    await logSecurityEvent('system', 'key_rotation', 'Security keys rotated to version $newVersion');
  }
  
  // الحصول على معلومات الجهاز للتسجيل الأمني
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // سيتم إضافة التنفيذ حسب الحاجة
    return {
      'platform': 'flutter',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  // تسجيل الأخطاء
  void _logError(String message, dynamic error) {
    // يمكن استبدال هذا بنظام تسجيل أكثر تفصيلاً
    print('$message: $error');
  }
  
  // فك تشفير البيانات المشفرة
  Future<Map<String, dynamic>?> decryptPaymentData(String encryptedData) async {
    try {
      final encryptedJson = jsonDecode(encryptedData) as Map<String, dynamic>;
      
      // التحقق من سلامة البيانات باستخدام HMAC
      final storedHmac = encryptedJson['hmac'] as String;
      
      // إزالة HMAC من البيانات قبل التحقق
      final dataToVerify = Map<String, dynamic>.from(encryptedJson);
      dataToVerify.remove('hmac');
      
      final calculatedHmac = await generateHmac(jsonEncode(dataToVerify), 'payment_data');
      
      if (calculatedHmac != storedHmac) {
        await logSecurityEvent(
          'system',
          'data_integrity_violation',
          'فشل التحقق من HMAC للبيانات المشفرة',
        );
        return null;
      }
      
      // الحصول على مفتاح التشفير المناسب بناءً على الإصدار
      final version = encryptedJson['version'] as String? ?? '1';
      final encryptionKey = await _getEncryptionKeyByVersion(version);
      
      if (encryptionKey == null) {
        await logSecurityEvent(
          'system',
          'key_not_found',
          'مفتاح التشفير غير موجود للإصدار $version',
        );
        return null;
      }
      
      // فك تشفير البيانات
      final keyBytes = base64Url.decode(encryptionKey);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt.IV.fromBase64(encryptedJson['iv'] as String);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      
      final decrypted = encrypter.decrypt64(encryptedJson['data'] as String, iv: iv);
      
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      await logSecurityEvent(
        'system',
        'decryption_error',
        'خطأ في فك تشفير البيانات: $e',
      );
      return null;
    }
  }
  
  // الحصول على مفتاح التشفير بناءً على الإصدار
  Future<String?> _getEncryptionKeyByVersion(String version) async {
    if (version == '1') {
      return await _secureStorage.read(key: _encryptionKeyKey);
    } else {
      return await _secureStorage.read(key: '${_encryptionKeyKey}_v$version');
    }
  }
}
