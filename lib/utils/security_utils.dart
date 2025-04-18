import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:mpay_app/utils/logger.dart';

/// Security utilities for the application
/// Provides authentication, encryption, and wallet validation functionality
class SecurityUtils {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Login attempt tracking for brute force protection
  static final Map<String, List<DateTime>> _loginAttempts = {};
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  // Key rotation constants
  static const Duration _keyRotationInterval = Duration(days: 30);
  static const String _lastKeyRotationKey = 'last_key_rotation_timestamp';
  static const String _keyVersionKey = 'current_key_version';
  static const String _recoveryModeKey = 'key_rotation_recovery_mode';
  
  /// Initialize API security features
  static Future<void> initializeApiSecurity() async {
    // Check if key rotation is needed
    await _checkAndRotateKeys();
  }
  
  /// Initialize payment security features
  static Future<void> initializePaymentSecurity() async {
    // Check if key rotation is needed
    await _checkAndRotateKeys();
  }
  
  /// Check if two-factor authentication is enabled for a user
  static Future<bool> isTwoFactorEnabled(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['twoFactorEnabled'] ?? false;
      }
      return false;
    } catch (e) {
      _logError('Error checking 2FA status', e);
      return false;
    }
  }
  
  /// Enable two-factor authentication for a user
  static Future<bool> enableTwoFactorAuth(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'twoFactorEnabled': true,
        'securityLevel': FieldValue.increment(1),
        'lastSecurityUpdate': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _logError('Error enabling 2FA', e);
      return false;
    }
  }
  
  /// Disable two-factor authentication for a user
  static Future<bool> disableTwoFactorAuth(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'twoFactorEnabled': false,
        'securityLevel': FieldValue.increment(-1),
        'lastSecurityUpdate': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _logError('Error disabling 2FA', e);
      return false;
    }
  }
  
  /// Store two-factor authentication secret for a user
  static Future<bool> storeTwoFactorSecret(String userId, String secret) async {
    try {
      // تخزين السر في التخزين الآمن المحلي بدلاً من Firestore
      await _secureStorage.write(key: 'twoFactorSecret_$userId', value: secret);
      return true;
    } catch (e) {
      _logError('Error storing 2FA secret', e);
      return false;
    }
  }
  
  /// Retrieve two-factor authentication secret for a user
  static Future<String?> retrieveTwoFactorSecret(String userId) async {
    try {
      // استرجاع السر من التخزين الآمن المحلي بدلاً من Firestore
      return await _secureStorage.read(key: 'twoFactorSecret_$userId');
    } catch (e) {
      _logError('Error retrieving 2FA secret', e);
      return null;
    }
  }
  
  /// Generate a random verification code for 2FA
  static String generateVerificationCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit code
  }
  
  /// Store verification code securely with expiration
  static Future<void> storeVerificationCode(String userId, String code) async {
    final expiryTime = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: 'verification_code_$userId', value: code);
    await _secureStorage.write(key: 'verification_code_expiry_$userId', value: expiryTime);
    
    // Add HMAC for code integrity verification
    final hmac = await _generateHmac(code, userId);
    await _secureStorage.write(key: 'verification_code_hmac_$userId', value: hmac);
  }
  
  /// Verify the code entered by the user with constant-time comparison
  static Future<bool> verifyCode(String userId, String enteredCode) async {
    final storedCode = await _secureStorage.read(key: 'verification_code_$userId');
    final expiryTimeStr = await _secureStorage.read(key: 'verification_code_expiry_$userId');
    final storedHmac = await _secureStorage.read(key: 'verification_code_hmac_$userId');
    
    if (storedCode == null || expiryTimeStr == null || storedHmac == null) {
      return false;
    }
    
    // Verify HMAC first to ensure code integrity
    final calculatedHmac = await _generateHmac(storedCode, userId);
    if (!_constantTimeEquals(calculatedHmac, storedHmac)) {
      _logSecurityEvent(userId, 'verification_code_tampered', 'Verification code HMAC mismatch');
      return false;
    }
    
    final expiryTime = int.parse(expiryTimeStr);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if code has expired
    if (now > expiryTime) {
      await _secureStorage.delete(key: 'verification_code_$userId');
      await _secureStorage.delete(key: 'verification_code_expiry_$userId');
      await _secureStorage.delete(key: 'verification_code_hmac_$userId');
      return false;
    }
    
    // Use constant-time comparison to prevent timing attacks
    return _constantTimeEquals(storedCode, enteredCode);
  }
  
  /// Constant-time string comparison to prevent timing attacks
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    
    return result == 0;
  }
  
  /// Securely store PIN with salt
  static Future<void> storePIN(String userId, String pin) async {
    final salt = _generateSalt();
    final hashedPin = _hashPinWithSalt(pin, salt);
    await _secureStorage.write(key: 'pin_salt_$userId', value: salt);
    await _secureStorage.write(key: 'pin_$userId', value: hashedPin);
    
    // Store PIN creation timestamp for rotation policy
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: 'pin_created_$userId', value: timestamp);
    
    // Add HMAC for PIN integrity verification
    final hmac = await _generateHmac(hashedPin, salt);
    await _secureStorage.write(key: 'pin_hmac_$userId', value: hmac);
  }
  
  /// Verify PIN
  static Future<bool> verifyPIN(String userId, String enteredPin) async {
    final storedSalt = await _secureStorage.read(key: 'pin_salt_$userId');
    final storedHashedPin = await _secureStorage.read(key: 'pin_$userId');
    final storedHmac = await _secureStorage.read(key: 'pin_hmac_$userId');
    
    if (storedSalt == null || storedHashedPin == null || storedHmac == null) {
      return false;
    }
    
    // Verify HMAC first to ensure PIN integrity
    final calculatedHmac = await _generateHmac(storedHashedPin, storedSalt);
    if (!_constantTimeEquals(calculatedHmac, storedHmac)) {
      _logSecurityEvent(userId, 'pin_tampered', 'PIN HMAC mismatch');
      return false;
    }
    
    final enteredHashedPin = _hashPinWithSalt(enteredPin, storedSalt);
    return _constantTimeEquals(storedHashedPin, enteredHashedPin);
  }
  
  /// Check if PIN needs rotation (older than 90 days)
  static Future<bool> isPinRotationNeeded(String userId) async {
    final createdStr = await _secureStorage.read(key: 'pin_created_$userId');
    if (createdStr == null) return false;
    
    final created = int.parse(createdStr);
    final now = DateTime.now().millisecondsSinceEpoch;
    final ninetyDaysInMillis = 90 * 24 * 60 * 60 * 1000;
    
    return (now - created) > ninetyDaysInMillis;
  }
  
  /// Generate random salt
  static String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
  
  /// Hash PIN with salt using SHA-256
  static String _hashPinWithSalt(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Generate HMAC for data integrity verification
  static Future<String> _generateHmac(String data, String key) async {
    final hmacKey = await _getOrCreateHmacKey();
    final hmac = Hmac(sha256, utf8.encode(hmacKey + key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }
  
  /// Get or create HMAC key
  static Future<String> _getOrCreateHmacKey() async {
    const hmacKeyName = 'hmac_master_key';
    String? hmacKey = await _secureStorage.read(key: hmacKeyName);
    
    if (hmacKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      hmacKey = base64Url.encode(keyBytes);
      await _secureStorage.write(key: hmacKeyName, value: hmacKey);
      
      // Store initial key rotation timestamp
      await _secureStorage.write(
        key: _lastKeyRotationKey,
        value: DateTime.now().millisecondsSinceEpoch.toString()
      );
      
      // Set initial key version
      await _secureStorage.write(key: _keyVersionKey, value: '1');
    }
    
    return hmacKey;
  }
  
  /// Check if password is strong
  static bool isPasswordStrong(String password) {
    // At least 8 characters
    if (password.length < 8) return false;
    
    // Contains at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    
    // Contains at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    
    // Contains at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    
    // Contains at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    
    // Check for common passwords
    if (_isCommonPassword(password)) return false;
    
    // Check for sequential characters
    if (_hasSequentialChars(password)) return false;
    
    return true;
  }
  
  /// Check if password is in common password list
  static bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', 'admin', '123456', 'qwerty', 'welcome',
      'password123', 'admin123', '12345678', '111111', 'abc123'
    ];
    return commonPasswords.contains(password.toLowerCase());
  }
  
  /// Check for sequential characters
  static bool _hasSequentialChars(String password) {
    const sequences = ['123456', 'abcdef', 'qwerty', 'asdfgh'];
    for (final seq in sequences) {
      if (password.toLowerCase().contains(seq)) return true;
    }
    return false;
  }
  
  /// Calculate password strength score (0-100)
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int score = 0;
    
    // Length contribution (up to 30 points)
    score += password.length * 2 > 30 ? 30 : password.length * 2;
    
    // Character variety contribution (up to 40 points)
    if (password.contains(RegExp(r'[A-Z]'))) score += 10;
    if (password.contains(RegExp(r'[a-z]'))) score += 10;
    if (password.contains(RegExp(r'[0-9]'))) score += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 10;
    
    // Deductions for weaknesses
    if (_isCommonPassword(password)) score -= 30;
    if (_hasSequentialChars(password)) score -= 20;
    
    // Ensure score is between 0 and 100
    return score < 0 ? 0 : (score > 100 ? 100 : score);
  }
  
  /// Get password strength message in Arabic
  static String getPasswordStrengthMessage(String password) {
    List<String> requirements = [];
    
    if (password.length < 8) {
      requirements.add('يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل');
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      requirements.add('يجب أن تحتوي على حرف كبير واحد على الأقل');
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      requirements.add('يجب أن تحتوي على حرف صغير واحد على الأقل');
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      requirements.add('يجب أن تحتوي على رقم واحد على الأقل');
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      requirements.add('يجب أن تحتوي على رمز خاص واحد على الأقل (!@#$%^&*(),.?":{}|<>)');
    }
    
    if (_isCommonPassword(password)) {
      requirements.add('كلمة المرور شائعة جداً وسهلة التخمين');
    }
    
    if (_hasSequentialChars(password)) {
      requirements.add('كلمة المرور تحتوي على تسلسل أحرف أو أرقام متتالية');
    }
    
    if (requirements.isEmpty) {
      final strength = calculatePasswordStrength(password);
      if (strength >= 80) {
        return 'كلمة المرور قوية جداً';
      } else if (strength >= 60) {
        return 'كلمة المرور قوية';
      } else {
        return 'كلمة المرور متوسطة القوة';
      }
    } else {
      return 'متطلبات كلمة المرور:\n${requirements.join('\n')}';
    }
  }
  
  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticate && isDeviceSupported;
    } on PlatformException catch (e) {
      _logError('Error checking biometric availability', e);
      return false;
    }
  }
  
  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      _logError('Error getting available biometrics', e);
      return [];
    }
  }
  
  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics({
    required String localizedReason,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      _logError('Error authenticating with biometrics', e);
      return false;
    }
  }
  
  /// Enable biometric authentication for a user
  static Future<bool> enableBiometricAuth(String userId) async {
    try {
      // First check if biometrics are available
      if (!await isBiometricAvailable()) {
        return false;
      }
      
      // Store biometric enabled flag
      await _secureStorage.write(key: 'biometric_enabled_$userId', value: 'true');
      
      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'biometricEnabled': true,
        'securityLevel': FieldValue.increment(1),
        'lastSecurityUpdate': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      _logError('Error enabling biometric auth', e);
      return false;
    }
  }
  
  /// Disable biometric authentication for a user
  static Future<bool> disableBiometricAuth(String userId) async {
    try {
      // Remove biometric enabled flag
      await _secureStorage.delete(key: 'biometric_enabled_$userId');
      
      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'biometricEnabled': false,
        'securityLevel': FieldValue.increment(-1),
        'lastSecurityUpdate': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      _logError('Error disabling biometric auth', e);
      return false;
    }
  }
  
  /// Check if biometric authentication is enabled for a user
  static Future<bool> isBiometricEnabled(String userId) async {
    try {
      final value = await _secureStorage.read(key: 'biometric_enabled_$userId');
      return value == 'true';
    } catch (e) {
      _logError('Error checking biometric status', e);
      return false;
    }
  }
  
  /// Encrypt data
  static Future<String> encryptData(String data) async {
    try {
      final key = await _getEncryptionKey();
      final iv = encrypt.IV.fromSecureRandom(16);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(data, iv: iv);
      
      // Combine IV and encrypted data
      final combined = base64Url.encode(iv.bytes) + '.' + encrypted.base64;
      return combined;
    } catch (e) {
      _logError('Error encrypting data', e);
      throw Exception('فشل في تشفير البيانات');
    }
  }
  
  /// Decrypt data
  static Future<String> decryptData(String encryptedData) async {
    try {
      final parts = encryptedData.split('.');
      if (parts.length != 2) {
        throw Exception('تنسيق البيانات المشفرة غير صالح');
      }
      
      final iv = encrypt.IV(base64Url.decode(parts[0]));
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      
      final key = await _getEncryptionKey();
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      _logError('Error decrypting data', e);
      throw Exception('فشل في فك تشفير البيانات');
    }
  }
  
  /// Get encryption key
  static Future<encrypt.Key> _getEncryptionKey() async {
    final versionStr = await _secureStorage.read(key: _keyVersionKey);
    final version = versionStr != null ? int.parse(versionStr) : 1;
    
    String? keyStr = await _secureStorage.read(key: 'encryption_key_v$version');
    
    if (keyStr == null) {
      // Create new key if not exists
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      keyStr = base64Url.encode(keyBytes);
      await _secureStorage.write(key: 'encryption_key_v$version', value: keyStr);
    }
    
    return encrypt.Key(base64Url.decode(keyStr));
  }
  
  /// Encrypt and store data
  static Future<void> encryptAndStore(String key, String data) async {
    final encrypted = await encryptData(data);
    await _secureStorage.write(key: key, value: encrypted);
  }
  
  /// Retrieve and decrypt data
  static Future<String?> retrieveDecrypted(String key) async {
    final encrypted = await _secureStorage.read(key: key);
    if (encrypted == null) return null;
    
    return await decryptData(encrypted);
  }
  
  /// Log error
  static void _logError(String message, dynamic error) {
    String errorString = error.toString();
    errorString = _filterSensitiveData(errorString);
    Logger.error(message, error: errorString);
  }
  
  /// Check if key rotation is needed
  static Future<void> _checkAndRotateKeys() async {
    try {
      // Check if key rotation is needed
      final lastRotationStr = await _secureStorage.read(key: _lastKeyRotationKey);
      if (lastRotationStr == null) {
        // Initialize key rotation timestamp if not exists
        await _secureStorage.write(
          key: _lastKeyRotationKey,
          value: DateTime.now().millisecondsSinceEpoch.toString()
        );
        await _secureStorage.write(key: _keyVersionKey, value: '1');
        return;
      }
      
      final lastRotation = int.parse(lastRotationStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if rotation interval has passed
      if ((now - lastRotation) > _keyRotationInterval.inMilliseconds) {
        await _rotateKeys();
      }
    } catch (e) {
      _logError('Error checking key rotation', e);
    }
  }
  
  /// Rotate encryption keys
  static Future<void> _rotateKeys() async {
    try {
      // التحقق من وجود وضع الاسترداد
      final recoveryMode = await _secureStorage.read(key: _recoveryModeKey);
      if (recoveryMode == 'true') {
        _logSecurityEvent('system', 'key_rotation_skipped', 'Key rotation skipped due to active recovery mode');
        return;
      }
      
      // Get current key version
      final versionStr = await _secureStorage.read(key: _keyVersionKey);
      final currentVersion = versionStr != null ? int.parse(versionStr) : 1;
      final newVersion = currentVersion + 1;
      
      // Create new HMAC key
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      final newHmacKey = base64Url.encode(keyBytes);
      
      // Store new key with version
      await _secureStorage.write(key: 'hmac_master_key_v$newVersion', value: newHmacKey);
      
      // Create new payment encryption key
      final paymentKeyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      final newPaymentKey = base64Url.encode(paymentKeyBytes);
      await _secureStorage.write(key: 'payment_encryption_key_v$newVersion', value: newPaymentKey);
      
      // Update current key version
      await _secureStorage.write(key: _keyVersionKey, value: newVersion.toString());
      
      // Update rotation timestamp
      await _secureStorage.write(
        key: _lastKeyRotationKey,
        value: DateTime.now().millisecondsSinceEpoch.toString()
      );
      
      // Re-encrypt sensitive data with new keys
      await _reencryptSensitiveData(currentVersion, newVersion);
      
      // Log key rotation
      _logSecurityEvent('system', 'key_rotation', 'Security keys rotated to version $newVersion');
    } catch (e) {
      _logError('Error rotating keys', e);
      
      try {
        // تحسين التعامل مع فشل تدوير المفاتيح
        // تعيين وضع الاسترداد
        await _secureStorage.write(key: _recoveryModeKey, value: 'true');
        
        // محاولة العودة إلى الإصدار السابق
        final versionStr = await _secureStorage.read(key: _keyVersionKey);
        if (versionStr != null) {
          final currentVersion = int.parse(versionStr);
          if (currentVersion > 1) {
            // محاولة العودة إلى الإصدار السابق
            await _secureStorage.write(key: _keyVersionKey, value: (currentVersion - 1).toString());
            
            // التحقق من نجاح العودة
            final newVersionStr = await _secureStorage.read(key: _keyVersionKey);
            if (newVersionStr == (currentVersion - 1).toString()) {
              _logSecurityEvent('system', 'key_rotation_failed', 'Successfully reverted to previous key version');
              
              // إعادة تعيين وضع الاسترداد بعد نجاح العودة
              await _secureStorage.write(key: _recoveryModeKey, value: 'false');
            } else {
              _logSecurityEvent('system', 'key_rotation_critical', 'Failed to revert to previous key version');
              // تنفيذ استراتيجية استرداد إضافية
              await _executeEmergencyKeyRecovery();
            }
          } else {
            _logSecurityEvent('system', 'key_rotation_critical', 'Cannot revert to previous version (current version is 1)');
            // تنفيذ استراتيجية استرداد إضافية
            await _executeEmergencyKeyRecovery();
          }
        } else {
          _logSecurityEvent('system', 'key_rotation_critical', 'Cannot determine current key version');
          // تنفيذ استراتيجية استرداد إضافية
          await _executeEmergencyKeyRecovery();
        }
      } catch (recoveryError) {
        _logError('Exception during key rotation recovery', recoveryError);
        _logSecurityEvent('system', 'key_rotation_critical', 'Recovery failed, manual intervention required');
      }
    }
  }
  
  /// استراتيجية استرداد إضافية للمفاتيح
  static Future<void> _executeEmergencyKeyRecovery() async {
    try {
      // إنشاء نسخة احتياطية من المفاتيح الحالية
      final allKeys = await _secureStorage.readAll();
      final backupTimestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      for (final entry in allKeys.entries) {
        if (entry.key.startsWith('encryption_key_') || 
            entry.key.startsWith('hmac_master_key_') || 
            entry.key.startsWith('payment_encryption_key_')) {
          await _secureStorage.write(key: '${entry.key}_backup_$backupTimestamp', value: entry.value);
        }
      }
      
      // إعادة تعيين المفاتيح الأساسية
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      final newKey = base64Url.encode(keyBytes);
      
      await _secureStorage.write(key: 'encryption_key_v1', value: newKey);
      await _secureStorage.write(key: 'hmac_master_key_v1', value: newKey);
      await _secureStorage.write(key: 'payment_encryption_key_v1', value: newKey);
      
      // إعادة تعيين إصدار المفتاح
      await _secureStorage.write(key: _keyVersionKey, value: '1');
      
      // تسجيل حدث الاسترداد الطارئ
      _logSecurityEvent('system', 'key_rotation_emergency', 'Emergency key recovery executed');
      
      // إعادة تعيين وضع الاسترداد بعد الانتهاء
      await _secureStorage.write(key: _recoveryModeKey, value: 'false');
    } catch (e) {
      _logError('Error in emergency key recovery', e);
      throw Exception('فشل في استرداد المفاتيح في حالة الطوارئ');
    }
  }
  
  /// Re-encrypt sensitive data with new keys
  static Future<void> _reencryptSensitiveData(int oldVersion, int newVersion) async {
    // This would re-encrypt all sensitive data with the new keys
    // Implementation depends on what sensitive data is stored
    // For example, re-encrypt API tokens, refresh tokens, etc.
    
    // Re-encrypt API token if exists
    final apiToken = await retrieveDecrypted('api_token');
    if (apiToken != null) {
      await encryptAndStore('api_token', apiToken);
    }
    
    // Re-encrypt refresh token if exists
    final refreshToken = await retrieveDecrypted('refresh_token');
    if (refreshToken != null) {
      await encryptAndStore('refresh_token', refreshToken);
    }
    
    // Re-encrypt payment tokens if exist
    final paymentToken = await retrieveDecrypted('payment_token');
    if (paymentToken != null) {
      await encryptAndStore('payment_token', paymentToken);
    }
    
    // Re-encrypt other sensitive data...
  }
  
  /// Filter sensitive data from logs and error messages
  static String _filterSensitiveData(String input) {
    // Filter out tokens
    input = input.replaceAll(RegExp(r'Bearer\s+[a-zA-Z0-9\._\-]+'), 'Bearer [FILTERED]');
    input = input.replaceAll(RegExp(r'eyJ[a-zA-Z0-9\._\-]+'), '[FILTERED_JWT]');
    
    // Filter out wallet addresses
    input = input.replaceAll(RegExp(r'0x[a-fA-F0-9]{40}'), '0x[FILTERED]');
    input = input.replaceAll(RegExp(r'T[a-zA-Z0-9]{33}'), 'T[FILTERED]');
    input = input.replaceAll(RegExp(r'(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}'), '[FILTERED_BTC_ADDRESS]');
    
    // Filter out email addresses
    input = input.replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '[FILTERED_EMAIL]');
    
    // Filter out phone numbers
    input = input.replaceAll(RegExp(r'\+?[0-9]{10,15}'), '[FILTERED_PHONE]');
    
    // Filter out API keys
    input = input.replaceAll(RegExp(r'key-[a-zA-Z0-9]{32,}'), '[FILTERED_API_KEY]');
    input = input.replaceAll(RegExp(r'sk_[a-zA-Z0-9]{24,}'), '[FILTERED_SECRET_KEY]');
    
    // Filter out credit card numbers
    input = input.replaceAll(RegExp(r'[0-9]{4}[ -]?[0-9]{4}[ -]?[0-9]{4}[ -]?[0-9]{4}'), '[FILTERED_CARD_NUMBER]');
    
    // Filter out CVV codes
    input = input.replaceAll(RegExp(r'CVV:?\s*[0-9]{3,4}'), 'CVV: [FILTERED]');
    
    // Filter out expiration dates
    input = input.replaceAll(RegExp(r'(0[1-9]|1[0-2])[/\-][0-9]{2,4}'), '[FILTERED_EXPIRY]');
    
    return input;
  }
  
  /// Log security event to local storage
  static void _logSecurityEvent(String userId, String eventType, String details) {
    // استخدام Logger بدلاً من print
    Logger.warning('SECURITY EVENT: $eventType - $details (User: $userId)');
    
    // In production, would log to Firestore as implemented in logSecurityEvent method
  }
}
