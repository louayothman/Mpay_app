import 'package:flutter/material.dart';
import 'package:mpay_app/theme/app_theme.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';

class IdentityVerificationScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userEmail;

  const IdentityVerificationScreen({
    Key? key,
    required this.userId,
    this.userName,
    this.userEmail,
  }) : super(key: key);

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  final SecurityUtils _securityUtils = SecurityUtils();
  
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _frontIdImage;
  File? _backIdImage;
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;
  
  VerificationStatus _verificationStatus = VerificationStatus.notVerified;
  String? _verificationMessage;
  DateTime? _verificationDate;
  
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  
  bool _hasInternetConnection = true;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimationController();
    
    _checkInternetConnection();
    _loadUserVerificationStatus();
    
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      _fullNameController.text = widget.userName!;
    }
  }
  
  void _initializeAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
    
    _animationController!.forward();
  }
  
  @override
  void dispose() {
    // Safely dispose animation controller
    _animationController?.stop();
    _animationController?.dispose();
    _animationController = null;
    
    // Dispose text controllers
    _fullNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _checkInternetConnection() async {
    bool hasConnection = await _connectivityUtils.checkInternetConnection();
    if (mounted) {
      setState(() {
        _hasInternetConnection = hasConnection;
      });
    }
  }
  
  Future<void> _loadUserVerificationStatus() async {
    if (!_hasInternetConnection) {
      if (mounted) {
        setState(() {
          _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
        });
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      final verificationData = await _firebaseService.getUserVerificationStatus(widget.userId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          
          if (verificationData != null) {
            _verificationStatus = _getVerificationStatusFromString(verificationData['status']);
            _verificationMessage = verificationData['message'];
            
            if (verificationData['verificationDate'] != null) {
              _verificationDate = DateTime.parse(verificationData['verificationDate']);
            }
            
            if (verificationData['idNumber'] != null) {
              _idNumberController.text = verificationData['idNumber'];
            }
            
            if (verificationData['fullName'] != null && _fullNameController.text.isEmpty) {
              _fullNameController.text = verificationData['fullName'];
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ أثناء تحميل حالة التحقق. يرجى المحاولة مرة أخرى.';
        });
      }
    }
  }
  
  VerificationStatus _getVerificationStatusFromString(String? status) {
    switch (status) {
      case 'verified':
        return VerificationStatus.verified;
      case 'pending':
        return VerificationStatus.pending;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.notVerified;
    }
  }
  
  Future<void> _pickImage(ImageSource source, bool isFrontId) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (pickedFile != null && mounted) {
        setState(() {
          if (isFrontId) {
            _frontIdImage = File(pickedFile.path);
          } else {
            _backIdImage = File(pickedFile.path);
          }
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في اختيار الصورة: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
        });
      }
    }
  }
  
  void _showImageSourceDialog(bool isFrontId) {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFrontId ? 'اختر صورة الوجه الأمامي للهوية' : 'اختر صورة الوجه الخلفي للهوية',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      title: 'الكاميرا',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera, isFrontId);
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      title: 'المعرض',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery, isFrontId);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedFeedbackButton(
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_frontIdImage == null || _backIdImage == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'يرجى تحميل صور الهوية (الوجه الأمامي والخلفي).';
        });
      }
      return;
    }
    
    if (!_hasInternetConnection) {
      if (mounted) {
        setState(() {
          _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
        });
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
        _successMessage = null;
      });
    }
    
    try {
      // Encrypt sensitive data before sending
      final encryptedIdNumber = await _securityUtils.encryptSensitiveData(_idNumberController.text);
      
      // Upload images to Firebase Storage
      final frontIdUrl = await _firebaseService.uploadVerificationImage(
        widget.userId,
        _frontIdImage!,
        'front_id',
      );
      
      final backIdUrl = await _firebaseService.uploadVerificationImage(
        widget.userId,
        _backIdImage!,
        'back_id',
      );
      
      // Submit verification request
      await _firebaseService.submitVerificationRequest(
        userId: widget.userId,
        fullName: _fullNameController.text,
        idNumber: encryptedIdNumber,
        frontIdUrl: frontIdUrl,
        backIdUrl: backIdUrl,
        userEmail: widget.userEmail,
      );
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _verificationStatus = VerificationStatus.pending;
          _successMessage = 'تم إرسال طلب التحقق بنجاح. سيتم مراجعته من قبل الإدارة.';
          _verificationMessage = 'طلبك قيد المراجعة. سيتم إعلامك عند اكتمال المراجعة.';
          _verificationDate = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'حدث خطأ أثناء إرسال طلب التحقق. يرجى المحاولة مرة أخرى.';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: 'التحقق من الهوية',
        centerTitle: true,
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_animationController == null || _fadeAnimation == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return FadeTransition(
      opacity: _fadeAnimation!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            if (_verificationStatus != VerificationStatus.verified)
              _buildVerificationForm(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (_verificationStatus) {
      case VerificationStatus.verified:
        statusColor = Theme.of(context).colorScheme.primary;
        statusIcon = Icons.verified_user;
        statusText = 'تم التحقق';
        break;
      case VerificationStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'قيد المراجعة';
        break;
      case VerificationStatus.rejected:
        statusColor = Theme.of(context).colorScheme.error;
        statusIcon = Icons.cancel;
        statusText = 'مرفوض';
        break;
      case VerificationStatus.notVerified:
        statusColor = Colors.grey;
        statusIcon = Icons.person_outline;
        statusText = 'غير محقق';
        break;
    }
    
    return AdaptiveCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'حالة التحقق:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              StatusBadge(
                status: statusText,
                size: 16,
                showAnimation: _verificationStatus == VerificationStatus.pending,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_verificationMessage != null) ...[
            Text(
              _verificationMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
          ],
          if (_verificationDate != null) ...[
            Text(
              'تاريخ آخر تحديث: ${_formatDate(_verificationDate!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_verificationStatus == VerificationStatus.verified) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'تم التحقق من هويتك بنجاح. يمكنك الآن الاستفادة من جميع ميزات التطبيق.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          if (_verificationStatus == VerificationStatus.rejected) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'يمكنك إعادة تقديم طلب التحقق مع التأكد من صحة المعلومات والصور المقدمة.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildVerificationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات التحقق',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى تقديم المعلومات التالية للتحقق من هويتك. سيتم مراجعة المعلومات من قبل فريق الإدارة.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          AdaptiveTextField(
            controller: _fullNameController,
            labelText: 'الاسم الكامل',
            hintText: 'أدخل الاسم الكامل كما هو في الهوية',
            prefixIcon: const Icon(Icons.person),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال الاسم الكامل';
              }
              if (value.length < 3) {
                return 'يجب أن يكون الاسم أكثر من 3 أحرف';
              }
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          AdaptiveTextField(
            controller: _idNumberController,
            labelText: 'رقم الهوية',
            hintText: 'أدخل رقم الهوية الوطنية',
            prefixIcon: const Icon(Icons.credit_card),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال رقم الهوية';
              }
              if (value.length < 8) {
                return 'يجب أن يكون رقم الهوية صحيحًا';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Text(
            'صور الهوية',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى تحميل صورة واضحة للوجه الأمامي والخلفي لبطاقة الهوية.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIdImageSelector(
                  title: 'الوجه الأمامي',
                  image: _frontIdImage,
                  onTap: () => _showImageSourceDialog(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIdImageSelector(
                  title: 'الوجه الخلفي',
                  image: _backIdImage,
                  onTap: () => _showImageSourceDialog(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitVerification,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text(
                      'إرسال طلب التحقق',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildIdImageSelector({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      image,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'انقر لتحميل الصورة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

enum VerificationStatus {
  notVerified,
  pending,
  verified,
  rejected,
}

class StatusBadge extends StatelessWidget {
  final String status;
  final double size;
  final bool showAnimation;

  const StatusBadge({
    Key? key,
    required this.status,
    this.size = 14,
    this.showAnimation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'تم التحقق':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        break;
      case 'قيد المراجعة':
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        break;
      case 'مرفوض':
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAnimation)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: size,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedFeedbackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BoxBorder? border;
  final BorderRadius? borderRadius;

  const AnimatedFeedbackButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).colorScheme.primary,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            border: border,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Center(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
