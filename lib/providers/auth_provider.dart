import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecurityUtils _securityUtils = SecurityUtils();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAdmin = false;
  int _loginAttempts = 0;
  DateTime? _lastLoginAttempt;
  bool _isLocked = false;
  
  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _isAdmin;
  bool get isLocked => _isLocked;
  
  AuthProvider() {
    _initAuthState();
  }
  
  Future<void> _initAuthState() async {
    _setLoading(true);
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      
      if (user != null) {
        await _loadUserData();
      } else {
        _isAdmin = false;
      }
      
      notifyListeners();
    });
    
    // Load login attempts from shared preferences
    await _loadLoginAttempts();
    
    _setLoading(false);
  }
  
  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        _isAdmin = userData?['isAdmin'] == true;
      }
    } catch (e) {
      _error = 'Failed to load user data: $e';
    }
  }
  
  Future<void> _loadLoginAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    _loginAttempts = prefs.getInt('login_attempts') ?? 0;
    
    final lastAttemptMillis = prefs.getInt('last_login_attempt');
    if (lastAttemptMillis != null) {
      _lastLoginAttempt = DateTime.fromMillisecondsSinceEpoch(lastAttemptMillis);
    }
    
    // Check if account is locked
    if (_loginAttempts >= 5 && _lastLoginAttempt != null) {
      final lockDuration = const Duration(minutes: 15);
      final unlockTime = _lastLoginAttempt!.add(lockDuration);
      
      if (DateTime.now().isBefore(unlockTime)) {
        _isLocked = true;
      } else {
        // Reset if lock period has passed
        await _resetLoginAttempts();
      }
    }
  }
  
  Future<void> _incrementLoginAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    _loginAttempts++;
    _lastLoginAttempt = DateTime.now();
    
    await prefs.setInt('login_attempts', _loginAttempts);
    await prefs.setInt('last_login_attempt', _lastLoginAttempt!.millisecondsSinceEpoch);
    
    if (_loginAttempts >= 5) {
      _isLocked = true;
    }
  }
  
  Future<void> _resetLoginAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    _loginAttempts = 0;
    _isLocked = false;
    
    await prefs.setInt('login_attempts', 0);
    notifyListeners();
  }
  
  Duration? getRemainingLockTime() {
    if (!_isLocked || _lastLoginAttempt == null) return null;
    
    final lockDuration = const Duration(minutes: 15);
    final unlockTime = _lastLoginAttempt!.add(lockDuration);
    final remaining = unlockTime.difference(DateTime.now());
    
    return remaining.isNegative ? null : remaining;
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  Future<bool> signIn(String email, String password, BuildContext context) async {
    if (_isLocked) {
      final remaining = getRemainingLockTime();
      if (remaining != null) {
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;
        _setError('الحساب مقفل. حاول مرة أخرى بعد $minutes:${seconds.toString().padLeft(2, '0')} دقيقة');
        return false;
      }
    }
    
    _setLoading(true);
    _setError(null);
    
    try {
      // تمت إزالة التحقق من قوة كلمة المرور عند تسجيل الدخول
      
      // Sign in with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = userCredential.user;
      
      if (_user != null) {
        await _loadUserData();
        await _resetLoginAttempts();
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          errorMessage = 'البريد الإلكتروني غير صالح';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب';
          break;
        default:
          errorMessage = 'حدث خطأ أثناء تسجيل الدخول: ${e.message}';
      }
      
      _setError(errorMessage);
      await _incrementLoginAttempts();
      
      if (_isLocked) {
        final remaining = getRemainingLockTime();
        if (remaining != null) {
          final minutes = remaining.inMinutes;
          final seconds = remaining.inSeconds % 60;
          _setError('تم تجاوز الحد الأقصى لمحاولات تسجيل الدخول. الحساب مقفل لمدة $minutes:${seconds.toString().padLeft(2, '0')} دقيقة');
        }
      }
      
      return false;
    } catch (e) {
      _setError('حدث خطأ أثناء تسجيل الدخول: $e');
      await _incrementLoginAttempts();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> signUp(String email, String password, String firstName, String lastName, String? referralCode, BuildContext context) async {
    _setLoading(true);
    _setError(null);
    
    try {
      // Validate password strength
      if (!_securityUtils.isPasswordStrong(password)) {
        throw Exception('كلمة المرور ضعيفة. يجب أن تحتوي على 8 أحرف على الأقل وتتضمن أحرف كبيرة وصغيرة وأرقام ورموز خاصة.');
      }
      
      // Create user with Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = userCredential.user;
      
      if (_user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(_user!.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'referralCode': _securityUtils.generateReferralCode(),
          'referredBy': referralCode,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'level': 1,
          'points': 0,
          'status': 'active',
        });
        
        // Create wallet document
        await _firestore.collection('wallets').doc(_user!.uid).set({
          'userId': _user!.uid,
          'balances': {
            'USDT': 0.0,
            'BTC': 0.0,
            'ETH': 0.0,
            'ShamCash': 0.0,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // If user was referred, update referrer's points
        if (referralCode != null && referralCode.isNotEmpty) {
          final referrerQuery = await _firestore
              .collection('users')
              .where('referralCode', isEqualTo: referralCode)
              .limit(1)
              .get();
          
          if (referrerQuery.docs.isNotEmpty) {
            final referrerId = referrerQuery.docs.first.id;
            await _firestore.collection('users').doc(referrerId).update({
              'points': FieldValue.increment(100),
            });
            
            // Create referral record
            await _firestore.collection('referrals').add({
              'referrerId': referrerId,
              'referredId': _user!.uid,
              'status': 'completed',
              'points': 100,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
        
        await _loadUserData();
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
          break;
        case 'invalid-email':
          errorMessage = 'البريد الإلكتروني غير صالح';
          break;
        case 'operation-not-allowed':
          errorMessage = 'تسجيل الحساب بالبريد الإلكتروني وكلمة المرور غير مفعل';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور ضعيفة جدًا';
          break;
        default:
          errorMessage = 'حدث خطأ أثناء إنشاء الحساب: ${e.message}';
      }
      
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('حدث خطأ أثناء إنشاء الحساب: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> createPIN(String pin) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (_user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Validate PIN
      if (pin.length != 4 || int.tryParse(pin) == null) {
        throw Exception('يجب أن يتكون رمز PIN من 4 أرقام');
      }
      
      // Hash PIN before storing
      final hashedPin = await _securityUtils.hashPin(pin);
      
      // Store PIN in Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'pin': hashedPin,
        'pinCreatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      _setError('حدث خطأ أثناء إنشاء رمز PIN: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> verifyPIN(String pin) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (_user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Get stored PIN from Firestore
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      final storedHashedPin = userDoc.data()?['pin'];
      
      if (storedHashedPin == null) {
        throw Exception('لم يتم إنشاء رمز PIN بعد');
      }
      
      // Verify PIN
      final isValid = await _securityUtils.verifyPin(pin, storedHashedPin);
      
      if (!isValid) {
        _setError('رمز PIN غير صحيح');
        return false;
      }
      
      return true;
    } catch (e) {
      _setError('حدث خطأ أثناء التحقق من رمز PIN: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> resetPassword(String email, BuildContext context) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'البريد الإلكتروني غير صالح';
          break;
        case 'user-not-found':
          errorMessage = 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني';
          break;
        default:
          errorMessage = 'حدث خطأ أثناء إرسال رابط إعادة تعيين كلمة المرور: ${e.message}';
      }
      
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('حدث خطأ أثناء إرسال رابط إعادة تعيين كلمة المرور: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (_user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      
      await _firestore.collection('users').doc(_user!.uid).update(updateData);
      
      return true;
    } catch (e) {
      _setError('حدث خطأ أثناء تحديث الملف الشخصي: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (_user == null || _user!.email == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Validate new password strength
      if (!_securityUtils.isPasswordStrong(newPassword)) {
        throw Exception('كلمة المرور الجديدة ضعيفة. يجب أن تحتوي على 8 أحرف على الأقل وتتضمن أحرف كبيرة وصغيرة وأرقام ورموز خاصة.');
      }
      
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      
      await _user!.reauthenticateWithCredential(credential);
      
      // Change password
      await _user!.updatePassword(newPassword);
      
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'كلمة المرور الحالية غير صحيحة';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور الجديدة ضعيفة جدًا';
          break;
        case 'requires-recent-login':
          errorMessage = 'تتطلب هذه العملية إعادة تسجيل الدخول. الرجاء تسجيل الخروج وإعادة تسجيل الدخول ثم المحاولة مرة أخرى.';
          break;
        default:
          errorMessage = 'حدث خطأ أثناء تغيير كلمة المرور: ${e.message}';
      }
      
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('حدث خطأ أثناء تغيير كلمة المرور: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _auth.signOut();
      _user = null;
      _isAdmin = false;
    } catch (e) {
      _setError('حدث خطأ أثناء تسجيل الخروج: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> setupTwoFactorAuth() async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (_user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Generate 2FA secret
      final secret = _securityUtils.generateTwoFactorSecret();
      
      // Store 2FA secret in Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'twoFactorSecret': secret,
        'twoFactorEnabled': true,
        'twoFactorSetupAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      _setError('حدث خطأ أثناء إعداد المصادقة الثنائية: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> verifyTwoFactorCode(String code) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (_user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Get stored 2FA secret from Firestore
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      final secret = userDoc.data()?['twoFactorSecret'];
      
      if (secret == null) {
        throw Exception('لم يتم إعداد المصادقة الثنائية بعد');
      }
      
      // Verify 2FA code
      final isValid = _securityUtils.verifyTwoFactorCode(code, secret);
      
      if (!isValid) {
        _setError('رمز المصادقة الثنائية غير صحيح');
        return false;
      }
      
      return true;
    } catch (e) {
      _setError('حدث خطأ أثناء التحقق من رمز المصادقة الثنائية: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> disableTwoFactorAuth(String code) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (_user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      // Get stored 2FA secret from Firestore
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      final secret = userDoc.data()?['twoFactorSecret'];
      
      if (secret == null) {
        throw Exception('لم يتم إعداد المصادقة الثنائية بعد');
      }
      
      // Verify 2FA code
      final isValid = _securityUtils.verifyTwoFactorCode(code, secret);
      
      if (!isValid) {
        _setError('رمز المصادقة الثنائية غير صحيح');
        return false;
      }
      
      // Disable 2FA
      await _firestore.collection('users').doc(_user!.uid).update({
        'twoFactorEnabled': false,
      });
      
      return true;
    } catch (e) {
      _setError('حدث خطأ أثناء تعطيل المصادقة الثنائية: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
