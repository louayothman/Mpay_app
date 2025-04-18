import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  final Function onVerificationComplete;

  const TwoFactorAuthScreen({
    Key? key,
    required this.onVerificationComplete,
  }) : super(key: key);

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String _errorMessage = '';
  bool _isConnected = true;
  int _remainingAttempts = 3;
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _sendVerificationCode();
  }

  Future<void> _checkConnectivity() async {
    bool isConnected = await ConnectivityUtils.isConnected();
    setState(() {
      _isConnected = isConnected;
    });
  }

  Future<void> _sendVerificationCode() async {
    if (!_isConnected) {
      setState(() {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Generate a random 6-digit code
        final verificationCode = SecurityUtils.generateVerificationCode();
        
        // Store the code securely
        await SecurityUtils.storeVerificationCode(user.uid, verificationCode);
        
        // In a real app, you would send this code via SMS or email
        // For this implementation, we'll just print it to the console
        print('Verification code: $verificationCode');
        
        // In a real implementation, you would send the code to the user's phone or email
        // For example, using Firebase Cloud Functions to send SMS or email
        
        // Start countdown for resend button
        _startResendTimer();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء إرسال رمز التحقق: $e';
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60; // 60 seconds countdown
    });
    
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyCode() async {
    if (!_isConnected) {
      setState(() {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final isValid = await SecurityUtils.verifyCode(
            user.uid, 
            _codeController.text.trim()
          );
          
          if (isValid) {
            // Code is valid, proceed to the next screen
            widget.onVerificationComplete();
          } else {
            // Code is invalid
            setState(() {
              _remainingAttempts--;
              _errorMessage = 'رمز التحقق غير صحيح. المحاولات المتبقية: $_remainingAttempts';
              
              if (_remainingAttempts <= 0) {
                // Sign out the user after too many failed attempts
                FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء التحقق من الرمز: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق بخطوتين'),
        centerTitle: true,
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
                  // Icon
                  const Icon(
                    Icons.security,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    'التحقق بخطوتين',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'لقد أرسلنا رمز تحقق إلى هاتفك. يرجى إدخال الرمز المكون من 6 أرقام للمتابعة.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
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
                  
                  // Verification code field
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'رمز التحقق',
                      prefixIcon: const Icon(Icons.pin),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال رمز التحقق';
                      }
                      if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
                        return 'الرجاء إدخال رمز تحقق صالح مكون من 6 أرقام';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Verify button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'تحقق',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Resend code button
                  TextButton(
                    onPressed: _resendCountdown > 0 || _isResending ? null : _sendVerificationCode,
                    child: _isResending
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Text(
                            _resendCountdown > 0
                                ? 'إعادة إرسال الرمز (${_resendCountdown}s)'
                                : 'إعادة إرسال الرمز',
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
