import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mpay_app/screens/home/home_screen.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'dart:async';

class PinScreen extends StatefulWidget {
  final bool isVerification;

  const PinScreen({super.key, required this.isVerification});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final List<String> _pin = ['', '', '', ''];
  int _currentIndex = 0;
  bool _isLoading = false;
  String _errorMessage = '';
  String _confirmPin = '';
  bool _isConnected = true;
  int _pinAttempts = 0;
  Timer? _lockoutTimer;
  int _lockoutSeconds = 0;
  bool _isPinLocked = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    if (widget.isVerification) {
      _loadPinAttempts();
    }
  }

  Future<void> _checkConnectivity() async {
    bool isConnected = await ConnectivityUtils.isConnected();
    setState(() {
      _isConnected = isConnected;
    });
  }

  Future<void> _loadPinAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pinAttempts = prefs.getInt('pin_attempts') ?? 0;
      final lockoutUntil = prefs.getInt('pin_lockout_until');
      
      if (lockoutUntil != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (lockoutUntil > now) {
          _isPinLocked = true;
          _lockoutSeconds = (lockoutUntil - now) ~/ 1000;
          _startLockoutTimer();
        } else {
          // Lockout period has expired
          _resetPinAttempts();
        }
      }
    });
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_lockoutSeconds > 0) {
          _lockoutSeconds--;
        } else {
          _isPinLocked = false;
          _resetPinAttempts();
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resetPinAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pin_attempts', 0);
    await prefs.remove('pin_lockout_until');
    setState(() {
      _pinAttempts = 0;
      _isPinLocked = false;
    });
  }

  Future<void> _incrementPinAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (_pinAttempts + 1);
    await prefs.setInt('pin_attempts', attempts);
    
    setState(() {
      _pinAttempts = attempts;
    });
    
    // If too many failed attempts, lock the PIN
    if (_pinAttempts >= 5) {
      final lockoutDuration = 5 * 60 * 1000; // 5 minutes in milliseconds
      final lockoutUntil = DateTime.now().millisecondsSinceEpoch + lockoutDuration;
      await prefs.setInt('pin_lockout_until', lockoutUntil);
      
      setState(() {
        _isPinLocked = true;
        _lockoutSeconds = lockoutDuration ~/ 1000;
      });
      
      _startLockoutTimer();
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isVerification ? 'التحقق من رمز PIN' : 'إنشاء رمز PIN'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title and instructions
              Text(
                widget.isVerification ? 'أدخل رمز PIN الخاص بك' : 'أنشئ رمز PIN جديد',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.isVerification
                    ? 'الرجاء إدخال رمز PIN المكون من 4 أرقام للوصول إلى حسابك'
                    : 'الرجاء إنشاء رمز PIN مكون من 4 أرقام لتأمين حسابك',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Connectivity warning
              if (!_isConnected)
                ConnectivityUtils.connectivityBanner(_isConnected),
              if (!_isConnected) const SizedBox(height: 16),

              // Lockout message
              if (_isPinLocked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'تم تجاوز الحد المسموح من المحاولات',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى المحاولة مرة أخرى بعد ${_lockoutSeconds ~/ 60}:${(_lockoutSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              if (_isPinLocked) const SizedBox(height: 24),

              // Error message
              if (_errorMessage.isNotEmpty && !_isPinLocked)
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
              if (_errorMessage.isNotEmpty && !_isPinLocked) const SizedBox(height: 24),

              // PIN display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentIndex > index
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _currentIndex > index
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : null,
                    ),
                    child: Center(
                      child: _currentIndex > index
                          ? const Icon(Icons.circle, size: 24)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Number pad
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    // Numbers 1-9
                    if (index < 9) {
                      return _buildNumberButton(index + 1);
                    }
                    // Left button (empty)
                    else if (index == 9) {
                      return const SizedBox();
                    }
                    // Number 0
                    else if (index == 10) {
                      return _buildNumberButton(0);
                    }
                    // Delete button
                    else {
                      return _buildDeleteButton();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    return InkWell(
      onTap: (_isLoading || _isPinLocked) ? null : () => _onNumberPressed(number.toString()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: (_isLoading || _isPinLocked) ? Colors.grey.shade200 : null,
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: (_isLoading || _isPinLocked) ? Colors.grey.shade400 : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: (_isLoading || _isPinLocked) ? null : _onDeletePressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: (_isLoading || _isPinLocked) ? Colors.grey.shade200 : null,
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined, 
            size: 24,
            color: (_isLoading || _isPinLocked) ? Colors.grey.shade400 : null,
          ),
        ),
      ),
    );
  }

  void _onNumberPressed(String number) {
    if (_currentIndex < 4) {
      setState(() {
        _pin[_currentIndex] = number;
        _currentIndex++;
        _errorMessage = '';
      });

      // Check if PIN is complete
      if (_currentIndex == 4) {
        _onPinComplete();
      }
    }
  }

  void _onDeletePressed() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _pin[_currentIndex] = '';
      });
    }
  }

  void _onPinComplete() async {
    final enteredPin = _pin.join();

    if (widget.isVerification) {
      _verifyPin(enteredPin);
    } else {
      if (_confirmPin.isEmpty) {
        // First entry - store PIN for confirmation
        setState(() {
          _confirmPin = enteredPin;
          _currentIndex = 0;
          _pin.fillRange(0, 4, '');
          _errorMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تأكيد رمز PIN')),
        );
      } else {
        // Confirm PIN
        if (enteredPin == _confirmPin) {
          _createPin(enteredPin);
        } else {
          setState(() {
            _confirmPin = '';
            _currentIndex = 0;
            _pin.fillRange(0, 4, '');
            _errorMessage = 'رموز PIN غير متطابقة. الرجاء المحاولة مرة أخرى.';
          });
        }
      }
    }
  }

  Future<void> _verifyPin(String pin) async {
    if (!_isConnected && widget.isVerification) {
      setState(() {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
        _currentIndex = 0;
        _pin.fillRange(0, 4, '');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('لم يتم العثور على المستخدم');
      }

      final isValid = await SecurityUtils.verifyPIN(user.uid, pin);

      if (isValid) {
        // PIN is correct, reset attempts and navigate to home screen
        await _resetPinAttempts();
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        // PIN is incorrect
        await _incrementPinAttempts();
        
        setState(() {
          _currentIndex = 0;
          _pin.fillRange(0, 4, '');
          if (_pinAttempts >= 5) {
            _errorMessage = 'تم تجاوز الحد المسموح من المحاولات. يرجى المحاولة لاحقًا.';
          } else {
            _errorMessage = 'رمز PIN غير صحيح. المحاولات المتبقية: ${5 - _pinAttempts}';
          }
        });
      }
    } catch (e) {
      setState(() {
        _currentIndex = 0;
        _pin.fillRange(0, 4, '');
        _errorMessage = 'حدث خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPin(String pin) async {
    if (!_isConnected) {
      setState(() {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
        _currentIndex = 0;
        _pin.fillRange(0, 4, '');
        _confirmPin = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('لم يتم العثور على المستخدم');
      }

      // Store PIN securely using SecurityUtils
      await SecurityUtils.storePIN(user.uid, pin);

      if (!mounted) return;
      
      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
        _currentIndex = 0;
        _pin.fillRange(0, 4, '');
        _confirmPin = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
