import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mpay_app/screens/auth/login_screen.dart';
import 'package:mpay_app/screens/auth/pin_screen.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _errorMessage = '';
  bool _isConnected = true;
  String _passwordStrengthMessage = '';
  bool _isPasswordStrong = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    bool isConnected = await ConnectivityUtils.isConnected();
    setState(() {
      _isConnected = isConnected;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      _passwordStrengthMessage = SecurityUtils.getPasswordStrengthMessage(password);
      _isPasswordStrong = SecurityUtils.isStrongPassword(password);
    });
  }

  Future<void> _registerWithEmailAndPassword() async {
    if (!_isConnected) {
      setState(() {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        setState(() {
          _errorMessage = 'يجب الموافقة على الشروط والأحكام للمتابعة';
        });
        return;
      }

      if (!_isPasswordStrong) {
        setState(() {
          _errorMessage = 'يرجى استخدام كلمة مرور أقوى: $_passwordStrengthMessage';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Create user in Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Generate unique referral code
        String referralCode = await _generateReferralCode();

        // Check if referral code is valid
        String referredBy = '';
        if (_referralCodeController.text.isNotEmpty) {
          try {
            QuerySnapshot referrerQuery = await ConnectivityUtils.retryOperation(() => 
              FirebaseFirestore.instance
                .collection('users')
                .where('referralCode', isEqualTo: _referralCodeController.text.trim())
                .limit(1)
                .get()
            );

            if (referrerQuery.docs.isNotEmpty) {
              referredBy = referrerQuery.docs.first.id;
              // Update referrer's referral count
              await FirebaseFirestore.instance.collection('users').doc(referredBy).update({
                'referralCount': FieldValue.increment(1),
              });
            }
          } catch (e) {
            print('Error checking referral code: $e');
            // Continue registration even if referral code check fails
          }
        }

        // Create user in Firestore
        await ConnectivityUtils.retryOperation(() => 
          FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': Timestamp.now(),
            'lastLogin': Timestamp.now(),
            'isVerified': false,
            'level': 'bronze',
            'totalTransactions': 0.0,
            'referralCode': referralCode,
            'referredBy': referredBy,
            'referralCount': 0,
            'fcmToken': '',
            'isAdmin': false,
            'adminPermissions': [],
            'profilePicture': '',
            'twoFactorEnabled': false,
            'dailyLimits': {
              'USD': 50.0,
              'SYP': 500000.0,
              'EUR': 45.0,
              'SAR': 187.5,
              'AED': 183.5,
              'TRY': 1600.0,
            },
          })
        );

        // Create wallet for user
        await ConnectivityUtils.retryOperation(() => 
          FirebaseFirestore.instance.collection('wallets').doc(userCredential.user!.uid).set({
            'walletId': userCredential.user!.uid,
            'balances': {
              'USD': 0.0,
              'SYP': 0.0,
              'EUR': 0.0,
              'SAR': 0.0,
              'AED': 0.0,
              'TRY': 0.0,
            },
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          })
        );

        if (!mounted) return;

        // Navigate to PIN creation screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PinScreen(isVerification: false),
          ),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'weak-password') {
            _errorMessage = 'كلمة المرور ضعيفة جدًا';
          } else if (e.code == 'email-already-in-use') {
            _errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
          } else if (e.code == 'invalid-email') {
            _errorMessage = 'البريد الإلكتروني غير صالح';
          } else if (e.code == 'operation-not-allowed') {
            _errorMessage = 'تسجيل البريد الإلكتروني وكلمة المرور غير مفعل';
          } else if (e.code == 'network-request-failed') {
            _errorMessage = 'فشل الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت';
          } else {
            _errorMessage = 'حدث خطأ في إنشاء الحساب: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _registerWithGoogle() async {
    if (!_isConnected) {
      setState(() {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
      });
      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'يجب الموافقة على الشروط والأحكام للمتابعة';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Check if this is a new user
      final User? user = FirebaseAuth.instance.currentUser;
      final metadata = user?.metadata;
      
      if (metadata != null && 
          metadata.creationTime != null && 
          metadata.lastSignInTime != null &&
          metadata.creationTime!.isAtSameMomentAs(metadata.lastSignInTime!)) {
        
        // Generate unique referral code
        String referralCode = await _generateReferralCode();

        // Check if referral code is valid
        String referredBy = '';
        if (_referralCodeController.text.isNotEmpty) {
          try {
            QuerySnapshot referrerQuery = await ConnectivityUtils.retryOperation(() => 
              FirebaseFirestore.instance
                .collection('users')
                .where('referralCode', isEqualTo: _referralCodeController.text.trim())
                .limit(1)
                .get()
            );

            if (referrerQuery.docs.isNotEmpty) {
              referredBy = referrerQuery.docs.first.id;
              // Update referrer's referral count
              await FirebaseFirestore.instance.collection('users').doc(referredBy).update({
                'referralCount': FieldValue.increment(1),
              });
            }
          } catch (e) {
            print('Error checking referral code: $e');
            // Continue registration even if referral code check fails
          }
        }

        // Create user in Firestore
        await ConnectivityUtils.retryOperation(() => 
          FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'firstName': googleUser.displayName?.split(' ').first ?? '',
            'lastName': googleUser.displayName?.split(' ').last ?? '',
            'email': googleUser.email,
            'createdAt': Timestamp.now(),
            'lastLogin': Timestamp.now(),
            'isVerified': false,
            'level': 'bronze',
            'totalTransactions': 0.0,
            'referralCode': referralCode,
            'referredBy': referredBy,
            'referralCount': 0,
            'fcmToken': '',
            'isAdmin': false,
            'adminPermissions': [],
            'profilePicture': googleUser.photoUrl ?? '',
            'twoFactorEnabled': false,
            'dailyLimits': {
              'USD': 50.0,
              'SYP': 500000.0,
              'EUR': 45.0,
              'SAR': 187.5,
              'AED': 183.5,
              'TRY': 1600.0,
            },
          })
        );

        // Create wallet for user
        await ConnectivityUtils.retryOperation(() => 
          FirebaseFirestore.instance.collection('wallets').doc(userCredential.user!.uid).set({
            'walletId': userCredential.user!.uid,
            'balances': {
              'USD': 0.0,
              'SYP': 0.0,
              'EUR': 0.0,
              'SAR': 0.0,
              'AED': 0.0,
              'TRY': 0.0,
            },
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          })
        );

        if (!mounted) return;

        // Navigate to PIN creation screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PinScreen(isVerification: false),
          ),
        );
      } else {
        // Existing user, navigate to login flow
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في التسجيل باستخدام Google: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _generateReferralCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code;
    bool isUnique = false;
    
    // Generate a code and check if it's unique
    do {
      code = String.fromCharCodes(
        Iterable.generate(
          8,
          (_) => chars.codeUnitAt((random + _) % chars.length),
        ),
      );
      
      try {
        // Check if code already exists
        QuerySnapshot codeQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('referralCode', isEqualTo: code)
            .limit(1)
            .get();
            
        isUnique = codeQuery.docs.isEmpty;
      } catch (e) {
        print('Error checking referral code uniqueness: $e');
        // If we can't check, assume it's unique to avoid infinite loop
        isUnique = true;
      }
    } while (!isUnique);
    
    return code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
      ),
      body: SafeArea(
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
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 24),
                  
                  // Connectivity warning
                  if (!_isConnected)
                    ConnectivityUtils.connectivityBanner(_isConnected),
                  if (!_isConnected) const SizedBox(height: 16),
                  
                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
                  
                  // First Name field
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم الأول',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الاسم الأول';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Last Name field
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم الأخير',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الاسم الأخير';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
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
                    onChanged: _checkPasswordStrength,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Password strength indicator
                  if (_passwordController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isPasswordStrong ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _passwordStrengthMessage,
                        style: TextStyle(
                          color: _isPasswordStrong ? Colors.green.shade800 : Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Confirm Password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء تأكيد كلمة المرور';
                      }
                      if (value != _passwordController.text) {
                        return 'كلمات المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Referral Code field
                  TextFormField(
                    controller: _referralCodeController,
                    decoration: InputDecoration(
                      labelText: 'رمز الدعوة (اختياري)',
                      prefixIcon: const Icon(Icons.card_giftcard),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Terms and Conditions
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'أوافق على ',
                            style: TextStyle(color: Colors.grey.shade700),
                            children: [
                              TextSpan(
                                text: 'الشروط والأحكام',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Navigate to Terms and Conditions
                                    // TODO: Implement Terms and Conditions screen
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Register button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _registerWithEmailAndPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'إنشاء حساب',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Google sign up
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _registerWithGoogle,
                    icon: Image.asset(
                      'assets/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    label: const Text('التسجيل باستخدام Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Login link
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'لديك حساب بالفعل؟ ',
                      style: TextStyle(color: Colors.grey.shade700),
                      children: [
                        TextSpan(
                          text: 'تسجيل الدخول',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
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
    );
  }
}
