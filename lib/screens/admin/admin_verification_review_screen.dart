import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mpay_app/screens/auth/identity_verification_screen.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';

class AdminVerificationReviewScreen extends StatefulWidget {
  const AdminVerificationReviewScreen({super.key});

  @override
  State<AdminVerificationReviewScreen> createState() => _AdminVerificationReviewScreenState();
}

class _AdminVerificationReviewScreenState extends State<AdminVerificationReviewScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _pendingRequests = [];
  Map<String, dynamic>? _selectedRequest;
  String? _idFrontUrl;
  String? _idBackUrl;
  String? _selfieUrl;
  final _rejectionReasonController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }
  
  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _selectedRequest = null;
      _idFrontUrl = null;
      _idBackUrl = null;
      _selfieUrl = null;
    });
    
    try {
      // Check if current user is admin
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يجب تسجيل الدخول للوصول إلى هذه الصفحة';
        });
        return;
      }
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || !(userDoc.data() as Map<String, dynamic>)['isAdmin']) {
        setState(() {
          _errorMessage = 'ليس لديك صلاحية للوصول إلى هذه الصفحة';
        });
        return;
      }
      
      // Get pending verification requests
      final requestsQuery = await _firestore
          .collection('verification_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      
      List<Map<String, dynamic>> requests = [];
      
      for (var doc in requestsQuery.docs) {
        final requestData = doc.data();
        requestData['id'] = doc.id;
        
        // Get user info
        final userDoc = await _firestore.collection('users').doc(requestData['userId']).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          requestData['email'] = userData['email'];
          requestData['level'] = userData['level'] ?? 'bronze';
        }
        
        requests.add(requestData as Map<String, dynamic>);
      }
      
      setState(() {
        _pendingRequests = requests;
      });
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
  
  Future<void> _selectRequest(Map<String, dynamic> request) async {
    setState(() {
      _isLoading = true;
      _selectedRequest = request;
      _idFrontUrl = null;
      _idBackUrl = null;
      _selfieUrl = null;
      _rejectionReasonController.text = '';
    });
    
    try {
      // Get verification images
      try {
        final frontUrl = await _storage.ref('verification/${request['userId']}/id_front.jpg').getDownloadURL();
        setState(() {
          _idFrontUrl = frontUrl;
        });
      } catch (e) {
        // Image doesn't exist
      }
      
      try {
        final backUrl = await _storage.ref('verification/${request['userId']}/id_back.jpg').getDownloadURL();
        setState(() {
          _idBackUrl = backUrl;
        });
      } catch (e) {
        // Image doesn't exist
      }
      
      try {
        final selfieUrl = await _storage.ref('verification/${request['userId']}/selfie.jpg').getDownloadURL();
        setState(() {
          _selfieUrl = selfieUrl;
        });
      } catch (e) {
        // Image doesn't exist
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _approveRequest() async {
    if (_selectedRequest == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Update verification request
      await _firestore.collection('verification_requests').doc(_selectedRequest!['id']).update({
        'status': 'approved',
        'reviewedBy': user.uid,
        'reviewedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      // Update user data
      await _firestore.collection('users').doc(_selectedRequest!['userId']).update({
        'verificationStatus': 'verified',
        'verificationApprovedAt': Timestamp.now(),
      });
      
      // Create notification
      await _firestore.collection('notifications').add({
        'userId': _selectedRequest!['userId'],
        'type': 'verification',
        'title': 'تم توثيق الهوية',
        'message': 'تمت الموافقة على طلب توثيق الهوية الخاص بك',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'data': {
          'verificationStatus': 'verified',
        },
      });
      
      // Check if user level needs to be upgraded
      final userDoc = await _firestore.collection('users').doc(_selectedRequest!['userId']).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final currentLevel = userData['level'] ?? 'bronze';
        
        if (currentLevel == 'bronze') {
          // Upgrade to silver after verification
          await _firestore.collection('users').doc(_selectedRequest!['userId']).update({
            'level': 'silver',
          });
          
          // Create notification for level upgrade
          await _firestore.collection('notifications').add({
            'userId': _selectedRequest!['userId'],
            'type': 'level_upgrade',
            'title': 'ترقية المستوى',
            'message': 'تمت ترقية مستواك إلى فضي بعد توثيق الهوية',
            'isRead': false,
            'createdAt': Timestamp.now(),
            'data': {
              'newLevel': 'silver',
              'oldLevel': 'bronze',
            },
          });
        }
      }
      
      // Show success message
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الموافقة على طلب التوثيق بنجاح')),
      );
      
      // Reload requests
      _loadPendingRequests();
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
  
  Future<void> _rejectRequest() async {
    if (_selectedRequest == null) return;
    
    if (_rejectionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال سبب الرفض')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Update verification request
      await _firestore.collection('verification_requests').doc(_selectedRequest!['id']).update({
        'status': 'rejected',
        'reviewedBy': user.uid,
        'reviewedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'rejectionReason': _rejectionReasonController.text.trim(),
      });
      
      // Update user data
      await _firestore.collection('users').doc(_selectedRequest!['userId']).update({
        'verificationStatus': 'rejected',
        'rejectionReason': _rejectionReasonController.text.trim(),
      });
      
      // Create notification
      await _firestore.collection('notifications').add({
        'userId': _selectedRequest!['userId'],
        'type': 'verification',
        'title': 'تم رفض طلب التوثيق',
        'message': 'تم رفض طلب توثيق الهوية الخاص بك',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'data': {
          'verificationStatus': 'rejected',
          'rejectionReason': _rejectionReasonController.text.trim(),
        },
      });
      
      // Show success message
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض طلب التوثيق بنجاح')),
      );
      
      // Reload requests
      _loadPendingRequests();
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة طلبات التوثيق'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRequests,
          ),
        ],
      ),
      body: ErrorHandlingWrapper(
        onRetry: _loadPendingRequests,
        child: ConnectivityAwareWidget(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    )
                  : _pendingRequests.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد طلبات توثيق قيد الانتظار',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : Row(
                          children: [
                            // Requests list
                            SizedBox(
                              width: 300,
                              child: Card(
                                margin: const EdgeInsets.all(8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'طلبات التوثيق (${_pendingRequests.length})',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _pendingRequests.length,
                                        itemBuilder: (context, index) {
                                          final request = _pendingRequests[index];
                                          final isSelected = _selectedRequest != null && 
                                                            _selectedRequest!['id'] == request['id'];
                                          
                                          return ListTile(
                                            title: Text(request['fullName'] ?? ''),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(request['email'] ?? ''),
                                                Text('تاريخ الطلب: ${_formatDate(request['createdAt'] as Timestamp)}'),
                                              ],
                                            ),
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.purple.withOpacity(0.2),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.purple,
                                              ),
                                            ),
                                            selected: isSelected,
                                            selectedTileColor: Colors.purple.withOpacity(0.1),
                                            onTap: () => _selectRequest(request),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Request details
                            Expanded(
                              child: _selectedRequest == null
                                  ? const Center(
                                      child: Text(
                                        'اختر طلب توثيق لعرض التفاصيل',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    )
                                  : Card(
                                      margin: const EdgeInsets.all(8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // User info
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 30,
                                                  backgroundColor: Colors.purple.withOpacity(0.2),
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 30,
                                                    color: Colors.purple,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _selectedRequest!['fullName'] ?? '',
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        _selectedRequest!['email'] ?? '',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: _getLevelColor(_selectedRequest!['level'] ?? 'bronze').withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text(
                                                              'المستوى: ${_getLevelName(_selectedRequest!['level'] ?? 'bronze')}',
                                                              style: TextStyle(
                                                                color: _getLevelColor(_selectedRequest!['level'] ?? 'bronze'),
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 32),
                                            
                                            // ID info
                                            const Text(
                                              'معلومات الهوية',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            _buildInfoRow('نوع الهوية', _selectedRequest!['idType'] ?? ''),
                                            _buildInfoRow('رقم الهوية', _selectedRequest!['idNumber'] ?? ''),
                                            _buildInfoRow('تاريخ الميلاد', _selectedRequest!['birthDate'] ?? ''),
                                            _buildInfoRow('العنوان', _selectedRequest!['address'] ?? ''),
                                            _buildInfoRow('تاريخ الطلب', _formatDate(_selectedRequest!['createdAt'] as Timestamp)),
                                            const SizedBox(height: 24),
                                            
                                            // ID images
                                            const Text(
                                              'صور الهوية',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            
                                            // Images grid
                                            GridView.count(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 16,
                                              mainAxisSpacing: 16,
                                              children: [
                                                // ID front
                                                _buildImageCard(
                                                  title: 'صورة الوجه الأمامي للهوية',
                                                  imageUrl: _idFrontUrl,
                                                ),
                                                
                                                // ID back (if not passport)
                                                _buildImageCard(
                                                  title: _selectedRequest!['idType'] == 'جواز سفر'
                                                      ? 'صورة إضافية للجواز'
                                                      : 'صورة الوجه الخلفي للهوية',
                                                  imageUrl: _idBackUrl,
                                                ),
                                                
                                                // Selfie
                                                _buildImageCard(
                                                  title: 'صورة شخصية',
                                                  imageUrl: _selfieUrl,
                                                  gridColumnSpan: 2,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            
                                            // Rejection reason
                                            if (_selectedRequest != null)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'سبب الرفض (في حالة الرفض)',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextFormField(
                                                    controller: _rejectionReasonController,
                                                    maxLines: 3,
                                                    decoration: InputDecoration(
                                                      hintText: 'أدخل سبب الرفض هنا...',
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                ],
                                              ),
                                            
                                            // Action buttons
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: _approveRequest,
                                                    icon: const Icon(Icons.check_circle),
                                                    label: const Text('موافقة'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: _rejectRequest,
                                                    icon: const Icon(Icons.cancel),
                                                    label: const Text('رفض'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImageCard({
    required String title,
    required String? imageUrl,
    int gridColumnSpan = 1,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: gridColumnSpan,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: imageUrl == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'الصورة غير متوفرة',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: OptimizedImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: const Center(child: CircularProgressIndicator()),
                          errorWidget: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error,
                                  size: 48,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'حدث خطأ في تحميل الصورة',
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}/${date.month}/${date.day}';
  }
  
  String _getLevelName(String level) {
    switch (level) {
      case 'bronze':
        return 'برونزي';
      case 'silver':
        return 'فضي';
      case 'gold':
        return 'ذهبي';
      case 'platinum':
        return 'بلاتيني';
      default:
        return level;
    }
  }
  
  Color _getLevelColor(String level) {
    switch (level) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey.shade500;
      case 'gold':
        return Colors.amber;
      case 'platinum':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
}
