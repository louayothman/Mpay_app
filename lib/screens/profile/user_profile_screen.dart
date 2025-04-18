import 'package:flutter/material.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';
import 'package:mpay_app/theme/app_theme.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/screens/wallet/user_dashboard_charts.dart';
import 'package:mpay_app/screens/auth/identity_verification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mpay_app/utils/cache_manager.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheManager _cacheManager = CacheManager();
  
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _userData;
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يجب تسجيل الدخول للوصول إلى هذه الصفحة';
        });
        return;
      }
      
      // Try to get data from cache first
      final cachedData = await _cacheManager.getData('user_profile_${user.uid}');
      if (cachedData != null) {
        setState(() {
          _userData = cachedData;
          _isLoading = false;
        });
      }
      
      // Get fresh data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'لم يتم العثور على بيانات المستخدم';
        });
        return;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Cache the data
      await _cacheManager.saveData('user_profile_${user.uid}', userData);
      
      setState(() {
        _userData = userData;
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
  
  String _getVerificationStatusText(String status) {
    switch (status) {
      case 'unverified':
        return 'غير موثق';
      case 'pending':
        return 'قيد المراجعة';
      case 'verified':
        return 'موثق';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
  
  Color _getVerificationStatusColor(String status) {
    switch (status) {
      case 'unverified':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getVerificationStatusIcon(String status) {
    switch (status) {
      case 'unverified':
        return Icons.person;
      case 'pending':
        return Icons.pending;
      case 'verified':
        return Icons.verified_user;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.person;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'تحديث البيانات',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'المعلومات الشخصية'),
            Tab(text: 'الإحصائيات'),
            Tab(text: 'الإعدادات'),
          ],
        ),
      ),
      body: ErrorHandlingWrapper(
        onRetry: _loadUserData,
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
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Personal Information Tab
                        _buildPersonalInfoTab(),
                        
                        // Statistics Tab
                        _buildStatisticsTab(),
                        
                        // Settings Tab
                        _buildSettingsTab(),
                      ],
                    ),
        ),
      ),
    );
  }
  
  Widget _buildPersonalInfoTab() {
    final user = _auth.currentUser;
    if (user == null || _userData == null) {
      return const Center(
        child: Text('لم يتم العثور على بيانات المستخدم'),
      );
    }
    
    final verificationStatus = _userData!['verificationStatus'] ?? 'unverified';
    final level = _userData!['level'] ?? 'bronze';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Avatar and name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.purple.withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userData!['fullName'] ?? user.displayName ?? 'المستخدم',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Level and verification status
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(level).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: _getLevelColor(level),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'المستوى',
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _getLevelName(level),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getLevelColor(level),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _getVerificationStatusColor(verificationStatus).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getVerificationStatusIcon(verificationStatus),
                                color: _getVerificationStatusColor(verificationStatus),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'حالة التوثيق',
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _getVerificationStatusText(verificationStatus),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getVerificationStatusColor(verificationStatus),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Verification button
                  if (verificationStatus == 'unverified' || verificationStatus == 'rejected')
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const IdentityVerificationScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.verified_user),
                        label: Text(
                          verificationStatus == 'rejected' ? 'إعادة تقديم طلب التوثيق' : 'توثيق الحساب',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  
                  // Rejection reason
                  if (verificationStatus == 'rejected' && _userData!['rejectionReason'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'سبب رفض طلب التوثيق:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userData!['rejectionReason'],
                              style: TextStyle(
                                color: Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Personal information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المعلومات الشخصية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'الاسم الكامل',
                    value: _userData!['fullName'] ?? 'غير محدد',
                  ),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: 'البريد الإلكتروني',
                    value: user.email ?? 'غير محدد',
                  ),
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'رقم الهاتف',
                    value: _userData!['phone'] ?? 'غير محدد',
                  ),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'العنوان',
                    value: _userData!['address'] ?? 'غير محدد',
                  ),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'تاريخ الانضمام',
                    value: _userData!['createdAt'] != null
                        ? _formatDate(_userData!['createdAt'] as Timestamp)
                        : 'غير محدد',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Referral information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'معلومات الإحالة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.code,
                    label: 'رمز الإحالة الخاص بك',
                    value: _userData!['referralCode'] ?? user.uid.substring(0, 8),
                    isCopyable: true,
                  ),
                  _buildInfoRow(
                    icon: Icons.people,
                    label: 'عدد المستخدمين المحالين',
                    value: (_userData!['referredUsers']?.length ?? 0).toString(),
                  ),
                  _buildInfoRow(
                    icon: Icons.attach_money,
                    label: 'عمولات الإحالة',
                    value: '\$${_userData!['referralCommission'] ?? 0}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatisticsTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text('لم يتم العثور على بيانات المستخدم'),
      );
    }
    
    return UserDashboardCharts(userId: user.uid);
  }
  
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account settings
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إعدادات الحساب',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    icon: Icons.edit,
                    title: 'تعديل الملف الشخصي',
                    subtitle: 'تعديل معلوماتك الشخصية',
                    onTap: () {
                      // Navigate to edit profile screen
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.lock,
                    title: 'تغيير كلمة المرور',
                    subtitle: 'تحديث كلمة المرور الخاصة بك',
                    onTap: () {
                      // Navigate to change password screen
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.pin,
                    title: 'تغيير رمز PIN',
                    subtitle: 'تحديث رمز PIN الخاص بك',
                    onTap: () {
                      // Navigate to change PIN screen
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Appearance settings
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إعدادات المظهر',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    icon: Icons.dark_mode,
                    title: 'الوضع الداكن',
                    subtitle: 'تبديل بين الوضع الفاتح والداكن',
                    trailing: Switch(
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (value) {
                        // Toggle theme
                      },
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.language,
                    title: 'اللغة',
                    subtitle: 'تغيير لغة التطبيق',
                    onTap: () {
                      // Show language selection dialog
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Notification settings
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إعدادات الإشعارات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    icon: Icons.notifications,
                    title: 'إشعارات المعاملات',
                    subtitle: 'تلقي إشعارات عند إجراء معاملات',
                    trailing: Switch(
                      value: _userData?['notificationSettings']?['transactions'] ?? true,
                      onChanged: (value) {
                        // Update notification settings
                      },
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.security,
                    title: 'إشعارات الأمان',
                    subtitle: 'تلقي إشعارات عند تسجيل الدخول أو تغيير الإعدادات',
                    trailing: Switch(
                      value: _userData?['notificationSettings']?['security'] ?? true,
                      onChanged: (value) {
                        // Update notification settings
                      },
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.campaign,
                    title: 'إشعارات الترويج',
                    subtitle: 'تلقي إشعارات حول العروض والتحديثات',
                    trailing: Switch(
                      value: _userData?['notificationSettings']?['promotions'] ?? true,
                      onChanged: (value) {
                        // Update notification settings
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Security settings
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إعدادات الأمان',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    icon: Icons.fingerprint,
                    title: 'المصادقة البيومترية',
                    subtitle: 'استخدام بصمة الإصبع أو التعرف على الوجه لتسجيل الدخول',
                    trailing: Switch(
                      value: _userData?['securitySettings']?['biometric'] ?? false,
                      onChanged: (value) {
                        // Update security settings
                      },
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.security,
                    title: 'المصادقة الثنائية',
                    subtitle: 'تفعيل المصادقة الثنائية لزيادة الأمان',
                    trailing: Switch(
                      value: _userData?['securitySettings']?['twoFactor'] ?? false,
                      onChanged: (value) {
                        // Update security settings
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Support and about
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الدعم والمعلومات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    icon: Icons.help,
                    title: 'مركز المساعدة',
                    subtitle: 'الحصول على المساعدة والدعم',
                    onTap: () {
                      // Navigate to help center
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.policy,
                    title: 'سياسة الخصوصية',
                    subtitle: 'قراءة سياسة الخصوصية الخاصة بنا',
                    onTap: () {
                      // Navigate to privacy policy
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.description,
                    title: 'شروط الخدمة',
                    subtitle: 'قراءة شروط الخدمة الخاصة بنا',
                    onTap: () {
                      // Navigate to terms of service
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.info,
                    title: 'عن التطبيق',
                    subtitle: 'معلومات عن التطبيق والإصدار',
                    onTap: () {
                      // Show about dialog
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _auth.signOut();
                if (!mounted) return;
                
                // Navigate to login screen
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isCopyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.purple,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isCopyable)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                // Copy to clipboard
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم نسخ $value إلى الحافظة')),
                );
              },
              tooltip: 'نسخ',
            ),
        ],
      ),
    );
  }
  
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.purple,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}/${date.month}/${date.day}';
  }
}
