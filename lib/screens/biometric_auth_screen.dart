import 'package:flutter/material.dart';
import 'package:mpay_app/theme/app_theme.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onAuthSuccess;
  final VoidCallback? onAuthFailure;
  final VoidCallback? onSkip;
  final bool isRequired;
  final String? nextRoute;

  const BiometricAuthScreen({
    Key? key,
    required this.userId,
    this.onAuthSuccess,
    this.onAuthFailure,
    this.onSkip,
    this.isRequired = false,
    this.nextRoute,
  }) : super(key: key);

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecurityUtils _securityUtils = SecurityUtils();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  final FirebaseService _firebaseService = FirebaseService();
  
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String? _errorMessage;
  String? _successMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<BiometricType> _availableBiometrics = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    
    _checkBiometricAvailability();
    _loadBiometricSettings();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _checkBiometricAvailability() async {
    bool canCheckBiometrics = false;
    List<BiometricType> availableBiometrics = [];
    
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (canCheckBiometrics) {
        availableBiometrics = await _localAuth.getAvailableBiometrics();
      }
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = 'فشل في التحقق من توفر المصادقة البيومترية: ${e.message}';
      });
    }
    
    if (mounted) {
      setState(() {
        _isBiometricAvailable = canCheckBiometrics && availableBiometrics.isNotEmpty;
        _availableBiometrics = availableBiometrics;
      });
    }
  }
  
  Future<void> _loadBiometricSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final isBiometricEnabled = prefs.getBool('biometric_enabled_${widget.userId}') ?? false;
      
      if (mounted) {
        setState(() {
          _isBiometricEnabled = isBiometricEnabled;
          _isLoading = false;
        });
      }
      
      // If biometric is required and enabled, authenticate immediately
      if (widget.isRequired && _isBiometricEnabled) {
        _authenticateWithBiometrics();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحميل إعدادات المصادقة البيومترية';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _toggleBiometricAuth(bool value) async {
    if (!_isBiometricAvailable) {
      setState(() {
        _errorMessage = 'المصادقة البيومترية غير متوفرة على هذا الجهاز';
      });
      return;
    }
    
    if (value) {
      // Authenticate before enabling
      final bool success = await _authenticateWithBiometrics(showFeedback: true);
      if (!success) {
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled_${widget.userId}', value);
      
      // Update user settings in Firebase if connected
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      if (hasConnection) {
        await _firebaseService.updateUserSettings(
          widget.userId,
          {'biometricEnabled': value},
        );
      }
      
      if (mounted) {
        setState(() {
          _isBiometricEnabled = value;
          _isLoading = false;
          _successMessage = value 
              ? 'تم تفعيل المصادقة البيومترية بنجاح' 
              : 'تم إلغاء تفعيل المصادقة البيومترية';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في تحديث إعدادات المصادقة البيومترية';
        });
      }
    }
  }
  
  Future<bool> _authenticateWithBiometrics({bool showFeedback = false}) async {
    if (!_isBiometricAvailable) {
      if (showFeedback) {
        setState(() {
          _errorMessage = 'المصادقة البيومترية غير متوفرة على هذا الجهاز';
        });
      }
      return false;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    bool authenticated = false;
    
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'قم بالمصادقة للوصول إلى حسابك',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (authenticated) {
            _successMessage = 'تمت المصادقة بنجاح';
            
            // Call the success callback if provided
            if (widget.onAuthSuccess != null) {
              Future.delayed(const Duration(milliseconds: 500), () {
                widget.onAuthSuccess!();
              });
            }
            
            // Navigate to next route if provided
            if (widget.nextRoute != null) {
              Future.delayed(const Duration(milliseconds: 800), () {
                Navigator.of(context).pushReplacementNamed(widget.nextRoute!);
              });
            }
          } else {
            _errorMessage = 'فشلت المصادقة البيومترية';
            
            // Call the failure callback if provided
            if (widget.onAuthFailure != null) {
              widget.onAuthFailure!();
            }
          }
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في المصادقة البيومترية: ${e.message}';
          
          // Call the failure callback if provided
          if (widget.onAuthFailure != null) {
            widget.onAuthFailure!();
          }
        });
      }
      authenticated = false;
    }
    
    return authenticated;
  }
  
  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'التعرف على الوجه';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'بصمة الإصبع';
    } else {
      return 'المصادقة البيومترية';
    }
  }
  
  IconData _getBiometricTypeIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else {
      return Icons.security;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: 'المصادقة البيومترية',
        centerTitle: true,
        showBackButton: !widget.isRequired,
      ),
      body: _isLoading && widget.isRequired
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }
  
  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Icon(
              _getBiometricTypeIcon(),
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              widget.isRequired
                  ? 'المصادقة مطلوبة'
                  : 'تفعيل المصادقة البيومترية',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.isRequired
                    ? 'يرجى استخدام ${_getBiometricTypeText()} للمصادقة والوصول إلى حسابك'
                    : 'قم بتفعيل ${_getBiometricTypeText()} لتسجيل الدخول بشكل أسرع وأكثر أماناً',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            if (!widget.isRequired) ...[
              _buildSettingsCard(),
              const SizedBox(height: 24),
            ],
            if (_isBiometricAvailable && (widget.isRequired || _isBiometricEnabled)) ...[
              AnimatedFeedbackButton(
                onPressed: () => _authenticateWithBiometrics(showFeedback: true),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getBiometricTypeIcon()),
                    const SizedBox(width: 12),
                    Text(
                      'المصادقة الآن',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.isRequired && widget.onSkip != null) ...[
              TextButton(
                onPressed: widget.onSkip,
                child: const Text('تخطي لهذه المرة'),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsCard() {
    return AdaptiveCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إعدادات المصادقة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'تفعيل ${_getBiometricTypeText()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              _isBiometricEnabled
                  ? 'سيتم طلب المصادقة البيومترية عند تسجيل الدخول'
                  : 'لن يتم طلب المصادقة البيومترية عند تسجيل الدخول',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            value: _isBiometricEnabled,
            onChanged: _isBiometricAvailable ? _toggleBiometricAuth : null,
            activeColor: Theme.of(context).colorScheme.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            secondary: Icon(
              _getBiometricTypeIcon(),
              color: _isBiometricAvailable
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          if (!_isBiometricAvailable) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'المصادقة البيومترية غير متوفرة على هذا الجهاز',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
