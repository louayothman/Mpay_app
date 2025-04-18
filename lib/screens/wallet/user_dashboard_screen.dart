import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/screens/wallet/wallet_screen.dart';
import 'package:mpay_app/screens/wallet/transactions_screen.dart';
import 'package:mpay_app/screens/wallet/user_rating_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _walletData = {};
  String _selectedCurrency = 'USD';
  List<String> _supportedCurrencies = ['USD', 'SYP', 'EUR', 'SAR', 'AED', 'TRY'];
  int _unreadNotifications = 0;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user data
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
          });
        }
        
        // Get wallet data
        final walletDoc = await _firestore.collection('wallets').doc(user.uid).get();
        
        if (walletDoc.exists) {
          final walletData = walletDoc.data() as Map<String, dynamic>;
          setState(() {
            _walletData = walletData;
            
            // Ensure all supported currencies have a balance entry
            Map<String, double> balances = Map<String, double>.from(walletData['balances'] ?? {});
            for (var currency in _supportedCurrencies) {
              balances[currency] ??= 0.0;
            }
            _walletData['balances'] = balances;
          });
        }
        
        // Get unread notifications count
        final notificationsQuery = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .where('isRead', isEqualTo: false)
            .count()
            .get();
        
        setState(() {
          _unreadNotifications = notificationsQuery.count;
        });
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
  
  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'SYP':
        return 'ل.س';
      case 'SAR':
        return 'ر.س';
      case 'AED':
        return 'د.إ';
      case 'TRY':
        return '₺';
      default:
        return '';
    }
  }
  
  String _formatBalance(double balance) {
    return balance.toStringAsFixed(balance.truncateToDouble() == balance ? 0 : 2);
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
  
  void _shareReferralCode() {
    final referralCode = _userData['referralCode'] ?? '';
    if (referralCode.isNotEmpty) {
      final text = 'استخدم رمز الدعوة الخاص بي للتسجيل في تطبيق Mpay: $referralCode';
      Share.share(text);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // Navigate to notifications screen
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User info
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              child: Icon(Icons.person, size: 40),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _userData['email'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // User level
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getLevelColor(_userData['level'] ?? 'bronze').withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: _getLevelColor(_userData['level'] ?? 'bronze'),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'المستوى: ${_getLevelName(_userData['level'] ?? 'bronze')}',
                                    style: TextStyle(
                                      color: _getLevelColor(_userData['level'] ?? 'bronze'),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // User rating
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.thumb_up, color: Colors.blue, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'التقييم: ${(_userData['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  ' (${(_userData['totalRatings'] as num?)?.toString() ?? '0'} تقييم)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Wallet balance
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'رصيد المحفظة',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const WalletScreen(),
                                      ),
                                    ).then((_) => _loadUserData());
                                  },
                                  child: const Text('عرض المحفظة'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Currency chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _supportedCurrencies.map((currency) {
                                final balance = (_walletData['balances'] as Map<String, dynamic>)[currency] ?? 0.0;
                                return Chip(
                                  label: Text(
                                    '${_getCurrencySymbol(currency)} ${_formatBalance(balance is num ? balance.toDouble() : 0.0)} $currency',
                                  ),
                                  backgroundColor: Colors.grey.shade200,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Quick actions
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إجراءات سريعة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Actions grid
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              children: [
                                _buildActionItem(
                                  icon: Icons.history,
                                  label: 'المعاملات',
                                  color: Colors.blue,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TransactionsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionItem(
                                  icon: Icons.star,
                                  label: 'التقييمات',
                                  color: Colors.amber,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserRatingScreen(
                                          userId: _auth.currentUser!.uid,
                                          userName: '${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionItem(
                                  icon: Icons.support_agent,
                                  label: 'الدعم',
                                  color: Colors.green,
                                  onTap: () {
                                    // Navigate to support screen
                                  },
                                ),
                                _buildActionItem(
                                  icon: Icons.settings,
                                  label: 'الإعدادات',
                                  color: Colors.grey,
                                  onTap: () {
                                    // Navigate to settings screen
                                  },
                                ),
                                _buildActionItem(
                                  icon: Icons.person,
                                  label: 'الملف الشخصي',
                                  color: Colors.purple,
                                  onTap: () {
                                    // Navigate to profile screen
                                  },
                                ),
                                _buildActionItem(
                                  icon: Icons.security,
                                  label: 'الأمان',
                                  color: Colors.red,
                                  onTap: () {
                                    // Navigate to security screen
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Referral code
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'رمز الإحالة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Referral code
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _userData['referralCode'] ?? 'غير متوفر',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.share),
                                    onPressed: _shareReferralCode,
                                    tooltip: 'مشاركة',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Referral info
                            Text(
                              'عدد الإحالات: ${_userData['referralCount'] ?? 0}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'العمولات المكتسبة: ${_getCurrencySymbol('USD')} ${_formatBalance((_userData['referralEarnings'] as num?)?.toDouble() ?? 0.0)} USD',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            
                            // Referral instructions
                            const Text(
                              'شارك رمز الإحالة الخاص بك مع أصدقائك واكسب عمولة على كل معاملة يقومون بها!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Wallet ID
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'معلومات المحفظة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Wallet ID
                            const Text(
                              'رمز المحفظة:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _walletData['walletId'] ?? _auth.currentUser?.uid ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // QR Code
                            Center(
                              child: QrImageView(
                                data: _walletData['walletId'] ?? _auth.currentUser?.uid ?? '',
                                version: QrVersions.auto,
                                size: 150.0,
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
    );
  }
  
  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
