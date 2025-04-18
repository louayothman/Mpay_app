import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mpay_app/screens/auth/register_screen.dart';
import 'package:mpay_app/screens/auth/pin_screen.dart';
import 'package:mpay_app/screens/auth/forgot_password_screen.dart';
import 'package:mpay_app/screens/auth/two_factor_auth_screen.dart';
import 'package:mpay_app/screens/home/home_screen.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';
  String _userId = ''; // Temporary user ID for tracking login attempts
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initializeUserId();
  }

  Future<void> _checkConnectivity() async {
    bool isConnected = await ConnectivityUtils.isConnected();
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
  }

  Future<void> _initializeUserId() async {
    // Use email as temporary ID for tracking login attempts before authentication
    _userId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    // Load any existing login attempts from secure storage
    await SecurityUtils.loadLoginAttempts(_userId);
  }

  bool _isLoginBlocked() {
    final remainingAttempts = SecurityUtils.getRemainingLoginAttempts(_userId);
    return remainingAttempts <= 0;
  }

  int _getRemainingLoginAttempts() {
    return SecurityUtils.getRemainingLoginAttempts(_userId);
  }

  int _getLockoutTimeRemaining() {
    return SecurityUtils.getLockoutTimeRemaining(_userId);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Simplified authentication flow
  Future<void> _authenticate({required bool isGoogleSignIn}) async {
    // Check for internet connection
    if (!_isConnected) {
      _showError('لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.');
      return;
    }

    // Check if login is blocked due to too many attempts
    if (_isLoginBlocked()) {
      final remainingSeconds = _getLockoutTimeRemaining();
      final remainingMinutes = (remainingSeconds / 60).ceil();
      _showError('تم حظر تسجيل الدخول مؤقتًا بسبب محاولات متكررة. يرجى المحاولة مرة أخرى بعد $remainingMinutes دقيقة.');
      return;
    }

    // For email/password login, validate form first
    if (!isGoogleSignIn && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Track login attempt
      final canAttempt = await SecurityUtils.trackLoginAttempt(_userId);
      if (!canAttempt) {
        final remainingSeconds = _getLockoutTimeRemaining();
        final remainingMinutes = (remainingSeconds / 60).ceil();
        _showError('تم حظر تسجيل الدخول مؤقتًا بسبب محاولات متكررة. يرجى المحاولة مرة أخرى بعد $remainingMinutes دقيقة.');
        return;
      }

      // Perform authentication
      User? user;
      if (isGoogleSignIn) {
        user = await _performGoogleSignIn();
      } else {
        user = await _performEmailPasswordSignIn();
      }

      if (!mounted || user == null) return;

      // Reset login attempts on successful login
      await SecurityUtils.resetLoginAttempts(_userId);

      // Handle post-authentication navigation
      await _handlePostAuthNavigation(user, isGoogleSignIn);
    } catch (e) {
      _handleAuthError(e, isGoogleSignIn);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Email/password sign in
  Future<User?> _performEmailPasswordSignIn() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة';
          break;
        case 'too-many-requests':
          errorMessage = 'تم حظر الوصول مؤقتًا بسبب نشاط غير عادي. يرجى المحاولة لاحقًا.';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب. يرجى التواصل مع الدعم الفني.';
          break;
        default:
          errorMessage = 'حدث خطأ في تسجيل الدخول';
          // Log detailed error securely without exposing to UI
          SecurityUtils.logSecurityEvent(_userId, 'login_error', 'Error: ${e.code} - ${e.message}');
      }
      _showError(errorMessage);
      return null;
    }
  }

  // Google sign in
  Future<User?> _performGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      _showError('حدث خطأ في تسجيل الدخول باستخدام Google');
      SecurityUtils.logSecurityEvent(_userId, 'google_login_error', 'Error: $e');
      return null;
    }
  }

  // Handle post-authentication navigation
  Future<void> _handlePostAuthNavigation(User user, bool isGoogleSignIn) async {
    // Check if this is a new user (for Google sign-in)
    final metadata = user.metadata;
    final isNewUser = metadata.creationTime != null && 
                      metadata.lastSignInTime != null &&
                      metadata.creationTime!.isAtSameMomentAs(metadata.lastSignInTime!);

    if (isGoogleSignIn && isNewUser) {
      // New user, navigate to PIN creation
      _navigateTo(const PinScreen(isVerification: false));
      return;
    }

    // Check if 2FA is enabled for this user
    final isTwoFactorEnabled = await SecurityUtils.isTwoFactorEnabled(user.uid);
    
    if (isTwoFactorEnabled) {
      // Navigate to 2FA verification screen
      _navigateTo(TwoFactorAuthScreen(
        onVerificationComplete: () {
          _navigateTo(const PinScreen(isVerification: true));
        },
      ));
    } else {
      // Navigate to PIN verification
      _navigateTo(const PinScreen(isVerification: true));
    }
  }

  // Helper method to navigate and replace current screen
  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Show error message
  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
  }

  // Handle authentication errors
  void _handleAuthError(dynamic error, bool isGoogleSignIn) {
    String errorMessage;
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          errorMessage = 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة';
          break;
        case 'too-many-requests':
          errorMessage = 'تم حظر الوصول مؤقتًا بسبب نشاط غير عادي. يرجى المحاولة لاحقًا.';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب. يرجى التواصل مع الدعم الفني.';
          break;
        default:
          errorMessage = isGoogleSignIn 
              ? 'حدث خطأ في تسجيل الدخول باستخدام Google' 
              : 'حدث خطأ في تسجيل الدخول';
      }
    } else {
      errorMessage = isGoogleSignIn 
          ? 'حدث خطأ في تسجيل الدخول باستخدام Google' 
          : 'حدث خطأ غير متوقع أثناء تسجيل الدخول';
    }
    
    _showError(errorMessage);
    
    // Log detailed error securely without exposing to UI
    SecurityUtils.logSecurityEvent(
      _userId, 
      isGoogleSignIn ? 'google_login_error' : 'login_error', 
      'Error: $error'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ErrorHandlingWrapper(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo.png',
                      height: 120,
                      width: 120,
                      semanticLabel: 'شعار تطبيق MPay',
                    ),
                    const SizedBox(height: 32),
                    
                    // Title
                    const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Connectivity warning
                    if (!_isConnected)
                      _buildInfoBox(
                        message: 'لا يوجد اتصال بالإنترنت. بعض الميزات قد لا تعمل بشكل صحيح.',
                        icon: Icons.wifi_off,
                        color: Colors.orange,
                      ),
                    if (!_isConnected) const SizedBox(height: 16),
                    
                    // Error message
                    if (_errorMessage.isNotEmpty)
                      _buildInfoBox(
                        message: _errorMessage,
                        icon: Icons.error_outline,
                        color: Colors.red,
                      ),
                    if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
                    
                    // Login attempts info
                    if (!_isLoginBlocked() && _getRemainingLoginAttempts() < 5)
                      _buildInfoBox(
                        message: 'محاولات تسجيل الدخول المتبقية: ${_getRemainingLoginAttempts()}',
                        icon: Icons.info_outline,
                        color: Colors.blue,
                      ),
                    if (!_isLoginBlocked() && _getRemainingLoginAttempts() < 5) const SizedBox(height: 16),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'الرجاء إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Forgot password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Login button
                    ElevatedButton(
                      onPressed: _isLoading || _isLoginBlocked() 
                          ? null 
                          : () => _authenticate(isGoogleSignIn: false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.0),
                            )
                          : const Text(
                              'تسجيل الدخول',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Google sign in
                    OutlinedButton.icon(
                      onPressed: _isLoading || _isLoginBlocked() 
                          ? null 
                          : () => _authenticate(isGoogleSignIn: true),
                      icon: Image.asset(
                        'assets/google_logo.png',
                        height: 24,
                        width: 24,
                        semanticLabel: 'شعار Google',
                      ),
                      label: const Text('تسجيل الدخول باستخدام Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Register link
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'ليس لديك حساب؟ ',
                        style: TextStyle(color: Colors.grey.shade700),
                        children: [
                          TextSpan(
                            text: 'إنشاء حساب جديد',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to build info boxes with consistent styling
  Widget _buildInfoBox({
    required String message,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
