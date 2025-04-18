import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _userData = {};
  String _verificationStatus = 'unverified'; // unverified, pending, verified, rejected
  
  File? _idFrontImage;
  File? _idBackImage;
  File? _selfieImage;
  
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();
  
  String? _selectedIdType;
  List<String> _idTypes = ['بطاقة هوية', 'جواز سفر', 'رخصة قيادة'];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user data
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userData = userData;
            _verificationStatus = userData['verificationStatus'] ?? 'unverified';
            
            // Pre-fill form if data exists
            if (userData['fullName'] != null) {
              _fullNameController.text = userData['fullName'];
            } else if (userData['firstName'] != null && userData['lastName'] != null) {
              _fullNameController.text = '${userData['firstName']} ${userData['lastName']}';
            }
            
            _idNumberController.text = userData['idNumber'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _birthDateController.text = userData['birthDate'] ?? '';
            _selectedIdType = userData['idType'];
          });
          
          // Check if verification images exist
          try {
            await _storage.ref('verification/${user.uid}/id_front.jpg').getDownloadURL();
            setState(() {
              _idFrontImage = File('placeholder'); // Just to indicate image exists
            });
          } catch (e) {
            // Image doesn't exist, which is fine
          }
          
          try {
            await _storage.ref('verification/${user.uid}/id_back.jpg').getDownloadURL();
            setState(() {
              _idBackImage = File('placeholder'); // Just to indicate image exists
            });
          } catch (e) {
            // Image doesn't exist, which is fine
          }
          
          try {
            await _storage.ref('verification/${user.uid}/selfie.jpg').getDownloadURL();
            setState(() {
              _selfieImage = File('placeholder'); // Just to indicate image exists
            });
          } catch (e) {
            // Image doesn't exist, which is fine
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          if (type == 'front') {
            _idFrontImage = File(image.path);
          } else if (type == 'back') {
            _idBackImage = File(image.path);
          } else if (type == 'selfie') {
            _selfieImage = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  Future<void> _captureImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          if (type == 'front') {
            _idFrontImage = File(image.path);
          } else if (type == 'back') {
            _idBackImage = File(image.path);
          } else if (type == 'selfie') {
            _selfieImage = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_idFrontImage == null || (_selectedIdType != 'جواز سفر' && _idBackImage == null) || _selfieImage == null) {
      setState(() {
        _errorMessage = 'الرجاء تحميل جميع الصور المطلوبة';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Upload images to Firebase Storage
        if (_idFrontImage != null && _idFrontImage!.path != 'placeholder') {
          final frontRef = _storage.ref('verification/${user.uid}/id_front.jpg');
          await frontRef.putFile(_idFrontImage!);
        }
        
        if (_idBackImage != null && _idBackImage!.path != 'placeholder') {
          final backRef = _storage.ref('verification/${user.uid}/id_back.jpg');
          await backRef.putFile(_idBackImage!);
        }
        
        if (_selfieImage != null && _selfieImage!.path != 'placeholder') {
          final selfieRef = _storage.ref('verification/${user.uid}/selfie.jpg');
          await selfieRef.putFile(_selfieImage!);
        }
        
        // Update user data in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'fullName': _fullNameController.text.trim(),
          'idNumber': _idNumberController.text.trim(),
          'idType': _selectedIdType,
          'address': _addressController.text.trim(),
          'birthDate': _birthDateController.text.trim(),
          'verificationStatus': 'pending',
          'verificationSubmittedAt': Timestamp.now(),
        });
        
        // Create verification request
        await _firestore.collection('verification_requests').add({
          'userId': user.uid,
          'fullName': _fullNameController.text.trim(),
          'idNumber': _idNumberController.text.trim(),
          'idType': _selectedIdType,
          'address': _addressController.text.trim(),
          'birthDate': _birthDateController.text.trim(),
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'reviewedBy': null,
          'reviewedAt': null,
          'rejectionReason': null,
        });
        
        // Create notification
        await _firestore.collection('notifications').add({
          'userId': user.uid,
          'type': 'verification',
          'title': 'طلب توثيق الهوية',
          'message': 'تم استلام طلب توثيق الهوية الخاص بك وسيتم مراجعته قريباً',
          'isRead': false,
          'createdAt': Timestamp.now(),
          'data': {
            'verificationStatus': 'pending',
          },
        });
        
        // Show success message
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب التوثيق بنجاح، سيتم مراجعته من قبل الإدارة')),
        );
        
        // Reload data
        _loadUserData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _birthDateController.text = '${picked.year}/${picked.month}/${picked.day}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('توثيق الهوية الشخصية'),
      ),
      body: ErrorHandlingWrapper(
        onRetry: _loadUserData,
        child: ConnectivityAwareWidget(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status card
                      _buildStatusCard(),
                      const SizedBox(height: 24),
                      
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
                      
                      // Verification form
                      if (_verificationStatus == 'unverified' || _verificationStatus == 'rejected')
                        _buildVerificationForm(),
                      
                      // Pending verification
                      if (_verificationStatus == 'pending')
                        _buildPendingVerification(),
                      
                      // Verified status
                      if (_verificationStatus == 'verified')
                        _buildVerifiedStatus(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (_verificationStatus) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.verified_user;
        statusText = 'تم توثيق الهوية';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'قيد المراجعة';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'تم رفض التوثيق';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.person;
        statusText = 'غير موثق';
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: statusColor.withOpacity(0.2),
              child: Icon(
                statusIcon,
                size: 40,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _verificationStatus == 'unverified'
                  ? 'قم بتوثيق هويتك للوصول إلى مزايا إضافية'
                  : _verificationStatus == 'pending'
                      ? 'طلب التوثيق قيد المراجعة من قبل الإدارة'
                      : _verificationStatus == 'rejected'
                          ? 'تم رفض طلب التوثيق، يرجى إعادة المحاولة'
                          : 'تم توثيق هويتك بنجاح',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            if (_verificationStatus == 'rejected' && _userData['rejectionReason'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'سبب الرفض: ${_userData['rejectionReason']}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerificationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات الهوية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Full name
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'الاسم الكامل',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال الاسم الكامل';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // ID type
          DropdownButtonFormField<String>(
            value: _selectedIdType,
            decoration: InputDecoration(
              labelText: 'نوع الهوية',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _idTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedIdType = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء اختيار نوع الهوية';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // ID number
          TextFormField(
            controller: _idNumberController,
            decoration: InputDecoration(
              labelText: 'رقم الهوية',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال رقم الهوية';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Birth date
          TextFormField(
            controller: _birthDateController,
            decoration: InputDecoration(
              labelText: 'تاريخ الميلاد',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
            readOnly: true,
            onTap: () => _selectDate(context),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال تاريخ الميلاد';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Address
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'العنوان',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال العنوان';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          const Text(
            'صور الهوية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'يرجى تحميل صور واضحة للهوية الشخصية وصورة شخصية حديثة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // ID front image
          _buildImageUploader(
            title: 'صورة الوجه الأمامي للهوية',
            image: _idFrontImage,
            onPickImage: () => _pickImage('front'),
            onCaptureImage: () => _captureImage('front'),
          ),
          const SizedBox(height: 16),
          
          // ID back image (not required for passport)
          if (_selectedIdType != 'جواز سفر')
            _buildImageUploader(
              title: 'صورة الوجه الخلفي للهوية',
              image: _idBackImage,
              onPickImage: () => _pickImage('back'),
              onCaptureImage: () => _captureImage('back'),
            ),
          if (_selectedIdType != 'جواز سفر') const SizedBox(height: 16),
          
          // Selfie image
          _buildImageUploader(
            title: 'صورة شخصية حديثة',
            image: _selfieImage,
            onPickImage: () => _pickImage('selfie'),
            onCaptureImage: () => _captureImage('selfie'),
          ),
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitVerification,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إرسال طلب التوثيق',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImageUploader({
    required String title,
    required File? image,
    required VoidCallback onPickImage,
    required VoidCallback onCaptureImage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade400,
              width: 1,
            ),
          ),
          child: image == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اضغط لتحميل الصورة',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: onPickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('المعرض'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: onCaptureImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('الكاميرا'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : image.path == 'placeholder'
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'تم تحميل الصورة',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: onPickImage,
                            tooltip: 'تغيير الصورة',
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            image,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              onPressed: onPickImage,
                              tooltip: 'تغيير الصورة',
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
  
  Widget _buildPendingVerification() {
    return Column(
      children: [
        const Icon(
          Icons.hourglass_top,
          size: 64,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        const Text(
          'طلب التوثيق قيد المراجعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'تم استلام طلب توثيق الهوية الخاص بك وسيتم مراجعته من قبل الإدارة في أقرب وقت ممكن.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'سيتم إشعارك عند اكتمال المراجعة.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildVerifiedStatus() {
    return Column(
      children: [
        const Icon(
          Icons.verified_user,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        const Text(
          'تم توثيق الهوية بنجاح',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'تم توثيق هويتك بنجاح. يمكنك الآن الاستفادة من جميع مزايا التطبيق.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'معلومات الهوية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('الاسم الكامل', _userData['fullName'] ?? ''),
                _buildInfoRow('نوع الهوية', _userData['idType'] ?? ''),
                _buildInfoRow('رقم الهوية', _userData['idNumber'] ?? ''),
                _buildInfoRow('تاريخ الميلاد', _userData['birthDate'] ?? ''),
                _buildInfoRow('العنوان', _userData['address'] ?? ''),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
