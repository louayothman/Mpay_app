import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Authentication service for handling user authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  
  // Keys for secure storage
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastLoginAttemptKey = 'last_login_attempt';
  static const String _lockoutEndTimeKey = 'lockout_end_time';
  
  // Maximum number of failed login attempts before lockout
  static const int _maxLoginAttempts = 5;
  
  // Lockout duration in minutes
  static const int _lockoutDurationMinutes = 15;
  
  /// Check if user is currently locked out
  Future<bool> isLockedOut() async {
    final lockoutEndTimeStr = await _secureStorage.read(key: _lockoutEndTimeKey);
    if (lockoutEndTimeStr == null) {
      return false;
    }
    
    try {
      final lockoutEndTime = DateTime.parse(lockoutEndTimeStr);
      return DateTime.now().isBefore(lockoutEndTime);
    } catch (e) {
      // If date parsing fails, reset lockout status
      await _secureStorage.delete(key: _lockoutEndTimeKey);
      return false;
    }
  }
  
  /// Get remaining lockout time in minutes
  Future<int> getRemainingLockoutTime() async {
    final lockoutEndTimeStr = await _secureStorage.read(key: _lockoutEndTimeKey);
    if (lockoutEndTimeStr == null) {
      return 0;
    }
    
    try {
      final lockoutEndTime = DateTime.parse(lockoutEndTimeStr);
      if (DateTime.now().isAfter(lockoutEndTime)) {
        return 0;
      }
      
      final difference = lockoutEndTime.difference(DateTime.now());
      return (difference.inSeconds / 60).ceil();
    } catch (e) {
      // If date parsing fails, reset lockout status
      await _secureStorage.delete(key: _lockoutEndTimeKey);
      return 0;
    }
  }
  
  /// Record failed login attempt
  Future<void> _recordFailedLoginAttempt() async {
    // Get current attempts
    int attempts = 0;
    final attemptsStr = await _secureStorage.read(key: _loginAttemptsKey);
    if (attemptsStr != null) {
      try {
        attempts = int.parse(attemptsStr);
      } catch (e) {
        // If parsing fails, reset attempts
        attempts = 0;
      }
    }
    
    // Increment attempts
    attempts++;
    
    // Store updated attempts
    await _secureStorage.write(key: _loginAttemptsKey, value: attempts.toString());
    await _secureStorage.write(key: _lastLoginAttemptKey, value: DateTime.now().toIso8601String());
    
    // Check if should lock out
    if (attempts >= _maxLoginAttempts) {
      final lockoutEndTime = DateTime.now().add(Duration(minutes: _lockoutDurationMinutes));
      await _secureStorage.write(key: _lockoutEndTimeKey, value: lockoutEndTime.toIso8601String());
    }
  }
  
  /// Reset login attempts after successful login
  Future<void> _resetLoginAttempts() async {
    await _secureStorage.delete(key: _loginAttemptsKey);
    await _secureStorage.delete(key: _lastLoginAttemptKey);
    await _secureStorage.delete(key: _lockoutEndTimeKey);
  }
  
  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
  
  /// Validate password strength
  bool _isValidPassword(String password) {
    // At least 8 characters, with at least one letter and one number
    return password.length >= 8 && 
           password.contains(RegExp(r'[a-zA-Z]')) && 
           password.contains(RegExp(r'[0-9]'));
  }
  
  /// Check internet connectivity
  Future<bool> _checkConnectivity(BuildContext context) async {
    final isConnected = await _connectivityUtils.isConnected();
    if (!isConnected) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.'
      );
      return false;
    }
    return true;
  }
  
  /// Sign in with email and password with error handling
  Future<UserCredential?> signInWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String password,
    bool showLoading = true,
  }) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'يرجى إدخال البريد الإلكتروني وكلمة المرور'
      );
      return null;
    }
    
    if (!_isValidEmail(email)) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'يرجى إدخال بريد إلكتروني صحيح'
      );
      return null;
    }
    
    // Check if user is locked out
    final locked = await isLockedOut();
    if (locked) {
      final remainingMinutes = await getRemainingLockoutTime();
      ErrorHandler.showErrorSnackBar(
        context, 
        'تم تجاوز الحد الأقصى لمحاولات تسجيل الدخول. يرجى المحاولة مرة أخرى بعد $remainingMinutes دقيقة.'
      );
      return null;
    }
    
    // Check internet connectivity
    if (!await _checkConnectivity(context)) {
      return null;
    }
    
    try {
      final result = await ErrorHandler.handleNetworkOperation(
        context: context,
        operation: () => _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
        loadingMessage: 'جاري تسجيل الدخول...',
        successMessage: 'تم تسجيل الدخول بنجاح',
        errorMessage: 'فشل في تسجيل الدخول',
        showLoadingDialog: showLoading,
        showSuccessMessage: false, // Don't show success message for login
      );
      
      // Reset login attempts on successful login
      if (result != null) {
        await _resetLoginAttempts();
      }
      
      return result;
    } catch (e) {
      // Record failed login attempt
      await _recordFailedLoginAttempt();
      
      // Check if this attempt caused a lockout
      final locked = await isLockedOut();
      if (locked) {
        ErrorHandler.showErrorSnackBar(
          context, 
          'تم تجاوز الحد الأقصى لمحاولات تسجيل الدخول. تم قفل الحساب لمدة $_lockoutDurationMinutes دقيقة.'
        );
      } else {
        // Show specific error messages based on error type
        String errorMessage = 'فشل في تسجيل الدخول';
        
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'لم يتم العثور على حساب بهذا البريد الإلكتروني';
              break;
            case 'wrong-password':
              errorMessage = 'كلمة المرور غير صحيحة';
              break;
            case 'user-disabled':
              errorMessage = 'تم تعطيل هذا الحساب';
              break;
            case 'too-many-requests':
              errorMessage = 'تم تجاوز الحد الأقصى لمحاولات تسجيل الدخول. يرجى المحاولة لاحقاً';
              break;
            case 'invalid-email':
              errorMessage = 'البريد الإلكتروني غير صحيح';
              break;
          }
        }
        
        ErrorHandler.showErrorSnackBar(context, errorMessage);
      }
      
      return null;
    }
  }
  
  /// Register with email and password with error handling
  Future<UserCredential?> registerWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String password,
    bool showLoading = true,
  }) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'يرجى إدخال البريد الإلكتروني وكلمة المرور'
      );
      return null;
    }
    
    if (!_isValidEmail(email)) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'يرجى إدخال بريد إلكتروني صحيح'
      );
      return null;
    }
    
    if (!_isValidPassword(password)) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل وتتضمن حرفاً واحداً ورقماً واحداً على الأقل'
      );
      return null;
    }
    
    // Check internet connectivity
    if (!await _checkConnectivity(context)) {
      return null;
    }
    
    try {
      return await ErrorHandler.handleNetworkOperation(
        context: context,
        operation: () => _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
        loadingMessage: 'جاري إنشاء الحساب...',
        successMessage: 'تم إنشاء الحساب بنجاح',
        errorMessage: 'فشل في إنشاء الحساب',
        showLoadingDialog: showLoading,
        showSuccessMessage: false, // Don't show success message for registration
      );
    } catch (e) {
      // Show specific error messages based on error type
      String errorMessage = 'فشل في إنشاء الحساب';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
            break;
          case 'invalid-email':
            errorMessage = 'البريد الإلكتروني غير صحيح';
            break;
          case 'weak-password':
            errorMessage = 'كلمة المرور ضعيفة جداً';
            break;
          case 'operation-not-allowed':
            errorMessage = 'تسجيل الحسابات معطل حالياً';
            break;
        }
      }
      
      ErrorHandler.showErrorSnackBar(context, errorMessage);
      return null;
    }
  }
  
  /// Reset password with error handling
  Future<void> resetPassword({
    required BuildContext context,
    required String email,
    bool showLoading = true,
  }) async {
    // Validate inputs
    if (email.isEmpty) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'يرجى إدخال البريد الإلكتروني'
      );
      return;
    }
    
    if (!_isValidEmail(email)) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'يرجى إدخال بريد إلكتروني صحيح'
      );
      return;
    }
    
    // Check internet connectivity
    if (!await _checkConnectivity(context)) {
      return;
    }
    
    try {
      await ErrorHandler.handleNetworkOperation(
        context: context,
        operation: () => _auth.sendPasswordResetEmail(email: email),
        loadingMessage: 'جاري إرسال رابط إعادة تعيين كلمة المرور...',
        successMessage: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
        errorMessage: 'فشل في إرسال رابط إعادة تعيين كلمة المرور',
        showLoadingDialog: showLoading,
        showSuccessMessage: true,
      );
    } catch (e) {
      // Show specific error messages based on error type
      String errorMessage = 'فشل في إرسال رابط إعادة تعيين كلمة المرور';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'لم يتم العثور على حساب بهذا البريد الإلكتروني';
            break;
          case 'invalid-email':
            errorMessage = 'البريد الإلكتروني غير صحيح';
            break;
        }
      }
      
      ErrorHandler.showErrorSnackBar(context, errorMessage);
    }
  }
  
  /// Sign out with error handling
  Future<void> signOut({
    required BuildContext context,
    bool showLoading = true,
  }) async {
    // Check internet connectivity
    if (!await _checkConnectivity(context)) {
      return;
    }
    
    try {
      await ErrorHandler.handleNetworkOperation(
        context: context,
        operation: () => _auth.signOut(),
        loadingMessage: 'جاري تسجيل الخروج...',
        successMessage: 'تم تسجيل الخروج بنجاح',
        errorMessage: 'فشل في تسجيل الخروج',
        showLoadingDialog: showLoading,
        showSuccessMessage: false, // Don't show success message for logout
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'فشل في تسجيل الخروج');
    }
  }
  
  /// Update user profile with error handling
  Future<void> updateProfile({
    required BuildContext context,
    String? displayName,
    String? photoURL,
    bool showLoading = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return;
    }
    
    // Check internet connectivity
    if (!await _checkConnectivity(context)) {
      return;
    }
    
    try {
      await ErrorHandler.handleNetworkOperation(
        context: context,
        operation: () => user.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        ),
        loadingMessage: 'جاري تحديث الملف الشخصي...',
        successMessage: 'تم تحديث الملف الشخصي بنجاح',
        errorMessage: 'فشل في تحديث الملف الشخصي',
        showLoadingDialog: showLoading,
        showSuccessMessage: true,
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'فشل في تحديث الملف الشخصي');
    }
  }
  
  /// Update email with error handling
  Future<void> updateEmail({
    required BuildContext context,
    required String newEmail,
    bool showLoading = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return;
    }
    
    // Validate inputs
    if (newEmail.isEmpty) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'يرجى إدخال البريد الإلكتروني الجديد'
      );
      return;
    }
    
    if (!_isValidEmail(newEmail)) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'يرجى إدخال بريد إلكتروني صحيح'
      );
      return;
    }
    
    // Check internet connectivity
    if (!await _checkConnectivity(context)) {
      return;
    }
    
    try {
      await ErrorHandler.handleNetworkOperation(
        context: context,
        operation: () => user.updateEmail(newEmail),
        loadingMessage: 'جاري تحديث البريد الإلكتروني...',
        successMessage: 'تم تحديث البريد الإلكتروني بنجاح',
        errorMessage: 'فشل في تحديث البريد الإلكتروني',
        showLoadingDialog: showLoading,
        showSuccessMessage: true,
      );
    } catch (e) {
      // Show specific error messages based on error type
      String errorMessage = 'فشل في تحديث البريد الإلكتروني';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
            break;
          case 'invalid-email':
            errorMessage = 'البريد الإلكتروني غير صحيح';
            break;
          case 'requires-recent-login':
            errorMessage = 'تحتاج إلى إعادة تسجيل الدخول قبل تحديث البريد الإلكتروني';
            break;
        }
      }
      
      ErrorHandler.showErrorSnackBar(context, errorMessage);
    }
  }
  
  /// Update password with error handling
  Future<void> updatePassword({
    required BuildContext context,
    required String newPassword,
    bool showLoading = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return;
    }
    
    // Validate inputs
    if (newPassword.isEmpty) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'يرجى إدخال كلمة المرور الجديدة'
      );
      return;
    }
    
    if (!_isValidPassword(newPassword)) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل وتتضمن حرفاً واحداً ورقماً واحداً على الأقل'
      );
      return;
    }
    
    // Check internet connectivity
    if (!await _checkConnectivity(context)) {
      return;
    }
    
    try {
      await ErrorHandler.handleNetworkOperation(
        context: context,
        operation: () => user.updatePassword(newPassword),
        loadingMessage: 'جاري تحديث كلمة المرور...',
        successMessage: 'تم تحديث كلمة المرور بنجاح',
        errorMessage: 'فشل في تحديث كلمة المرور',
        showLoadingDialog: showLoading,
        showSuccessMessage: true,
      );
    } catch (e) {
      // Show specific error messages based on error type
      String errorMessage = 'فشل في تحديث كلمة المرور';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'كلمة المرور ضعيفة جداً';
            break;
          case 'requires-recent-login':
            errorMessage = 'تحتاج إلى إعادة تسجيل الدخول قبل تحديث كلمة المرور';
            break;
        }
      }
      
      ErrorHandler.showErrorSnackBar(context, errorMessage);
    }
  }
  
  /// Re-authenticate user with error handling
  Future<UserCredential?> reauthenticate({
    required BuildContext context,
    required String email,
    required String password,
    bool showLoading = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return null;
    }
    
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'يرجى إدخال البريد الإلكتروني وكلمة المرور'
      );
      return null;
    }
    
    // Check internet connectivity
    if (!await _checkConnectivity(context)) {
      return null;
    }
    
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    
    try {
      return await ErrorHandler.handleNetworkOperation(
        context: context,
        operation: () => user.reauthenticateWithCredential(credential),
        loadingMessage: 'جاري إعادة المصادقة...',
        successMessage: 'تمت إعادة المصادقة بنجاح',
        errorMessage: 'فشل في إعادة المصادقة',
        showLoadingDialog: showLoading,
        showSuccessMessage: false, // Don't show success message for reauthentication
      );
    } catch (e) {
      // Show specific error messages based on error type
      String errorMessage = 'فشل في إعادة المصادقة';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-mismatch':
            errorMessage = 'بيانات الاعتماد المقدمة لا تتطابق مع المستخدم الحالي';
            break;
          case 'user-not-found':
            errorMessage = 'لم يتم العثور على المستخدم';
            break;
          case 'invalid-credential':
            errorMessage = 'بيانات الاعتماد غير صالحة';
            break;
          case 'invalid-email':
            errorMessage = 'البريد الإلكتروني غير صحيح';
            break;
          case 'wrong-password':
            errorMessage = 'كلمة المرور غير صحيحة';
            break;
        }
      }
      
      ErrorHandler.showErrorSnackBar(context, errorMessage);
      return null;
    }
  }
  
  /// Delete user account with error handling
  Future<void> deleteAccount({
    required BuildContext context,
    bool showLoading = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return;
    }
    
    // Check internet connectivity
    if (!await _checkConnectivity(context)) {
      return;
    }
    
    try {
      await ErrorHandler.handleNetworkOperation(
        context: context,
        operation: () => user.delete(),
        loadingMessage: 'جاري حذف الحساب...',
        successMessage: 'تم حذف الحساب بنجاح',
        errorMessage: 'فشل في حذف الحساب',
        showLoadingDialog: showLoading,
        showSuccessMessage: true,
      );
    } catch (e) {
      // Show specific error messages based on error type
      String errorMessage = 'فشل في حذف الحساب';
      
      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          errorMessage = 'تحتاج إلى إعادة تسجيل الدخول قبل حذف الحساب';
        }
      }
      
      ErrorHandler.showErrorSnackBar(context, errorMessage);
    }
  }
  
  /// Get current user with error handling
  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  /// Check if user is signed in
  bool isUserSignedIn() {
    return _auth.currentUser != null;
  }
  
  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Store sensitive data securely
  Future<void> storeSecureData(String key, String value) async {
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }
    await _secureStorage.write(key: key, value: value);
  }
  
  /// Retrieve sensitive data securely
  Future<String?> getSecureData(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }
    return await _secureStorage.read(key: key);
  }
  
  /// Delete sensitive data securely
  Future<void> deleteSecureData(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }
    await _secureStorage.delete(key: key);
  }
  
  /// Store map data securely
  Future<void> storeSecureMap(String key, Map<String, dynamic> value) async {
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }
    
    if (value == null) {
      throw ArgumentError('Value cannot be null');
    }
    
    try {
      final jsonString = jsonEncode(value);
      await _secureStorage.write(key: key, value: jsonString);
    } catch (e) {
      throw Exception('Failed to store secure map: $e');
    }
  }
  
  /// Retrieve map data securely
  Future<Map<String, dynamic>?> getSecureMap(String key) async {
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }
    
    try {
      final jsonString = await _secureStorage.read(key: key);
      if (jsonString == null) {
        return null;
      }
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to retrieve secure map: $e');
    }
  }
}
