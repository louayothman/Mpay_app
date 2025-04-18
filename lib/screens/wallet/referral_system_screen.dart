import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReferralSystemScreen extends StatefulWidget {
  const ReferralSystemScreen({super.key});

  @override
  State<ReferralSystemScreen> createState() => _ReferralSystemScreenState();
}

class _ReferralSystemScreenState extends State<ReferralSystemScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String _referralCode = '';
  int _referralCount = 0;
  double _totalEarnings = 0.0;
  List<Map<String, dynamic>> _referrals = [];
  Map<String, dynamic> _referralRates = {};
  
  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }
  
  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user data
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _referralCode = userData['referralCode'] ?? '';
            _referralCount = (userData['referralCount'] as num?)?.toInt() ?? 0;
            _totalEarnings = (userData['referralEarnings'] as num?)?.toDouble() ?? 0.0;
          });
        }
        
        // Get referral rates
        final settingsDoc = await _firestore.collection('system_settings').doc('referrals').get();
        
        if (settingsDoc.exists) {
          final settingsData = settingsDoc.data() as Map<String, dynamic>;
          setState(() {
            _referralRates = Map<String, dynamic>.from(settingsData['rates'] ?? {});
          });
        }
        
        // Get referrals
        final referralsQuery = await _firestore
            .collection('referrals')
            .where('referrerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();
        
        List<Map<String, dynamic>> referrals = [];
        
        for (var doc in referralsQuery.docs) {
          final referralData = doc.data();
          
          // Get referred user info
          final referredUserDoc = await _firestore.collection('users').doc(referralData['referredId']).get();
          if (referredUserDoc.exists) {
            final referredUserData = referredUserDoc.data() as Map<String, dynamic>;
            referralData['referredName'] = '${referredUserData['firstName']} ${referredUserData['lastName']}';
            referralData['referredEmail'] = referredUserData['email'];
          }
          
          referrals.add(referralData as Map<String, dynamic>);
        }
        
        setState(() {
          _referrals = referrals;
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
  
  void _shareReferralCode() {
    if (_referralCode.isNotEmpty) {
      final text = 'استخدم رمز الدعوة الخاص بي للتسجيل في تطبيق Mpay: $_referralCode';
      Share.share(text);
    }
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}/${date.month}/${date.day}';
  }
  
  String _formatAmount(double amount) {
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام الإحالة'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReferralData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Referral code card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'رمز الإحالة الخاص بك',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // QR Code
                            QrImageView(
                              data: _referralCode,
                              version: QrVersions.auto,
                              size: 150.0,
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
                                      _referralCode,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('تم نسخ رمز الإحالة')),
                                      );
                                    },
                                    tooltip: 'نسخ',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Share button
                            ElevatedButton.icon(
                              onPressed: _shareReferralCode,
                              icon: const Icon(Icons.share),
                              label: const Text('مشاركة رمز الإحالة'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Statistics card
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
                              'إحصائيات الإحالة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Statistics
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.people,
                                    title: 'عدد الإحالات',
                                    value: _referralCount.toString(),
                                    color: Colors.blue,
                                  ),
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.attach_money,
                                    title: 'إجمالي العمولات',
                                    value: '\$ ${_formatAmount(_totalEarnings)}',
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Commission rates card
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
                              'معدلات العمولة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Commission rates
                            _buildCommissionRateItem(
                              title: 'عمولة التسجيل',
                              rate: _referralRates['registration']?.toString() ?? '0',
                              description: 'دولار لكل مستخدم جديد يسجل باستخدام رمز الإحالة الخاص بك',
                            ),
                            _buildCommissionRateItem(
                              title: 'عمولة المعاملات',
                              rate: '${(_referralRates['transaction'] as num? ?? 0) * 100}%',
                              description: 'من رسوم كل معاملة يقوم بها المستخدم المُحال',
                            ),
                            _buildCommissionRateItem(
                              title: 'عمولة الإيداع',
                              rate: '${(_referralRates['deposit'] as num? ?? 0) * 100}%',
                              description: 'من رسوم كل عملية إيداع يقوم بها المستخدم المُحال',
                            ),
                            _buildCommissionRateItem(
                              title: 'عمولة السحب',
                              rate: '${(_referralRates['withdraw'] as num? ?? 0) * 100}%',
                              description: 'من رسوم كل عملية سحب يقوم بها المستخدم المُحال',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // How it works card
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
                              'كيف يعمل نظام الإحالة؟',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Steps
                            _buildStepItem(
                              number: 1,
                              title: 'شارك رمز الإحالة',
                              description: 'شارك رمز الإحالة الخاص بك مع أصدقائك وعائلتك',
                            ),
                            _buildStepItem(
                              number: 2,
                              title: 'تسجيل الأصدقاء',
                              description: 'عندما يقوم صديقك بالتسجيل باستخدام رمز الإحالة الخاص بك، ستحصل على عمولة التسجيل',
                            ),
                            _buildStepItem(
                              number: 3,
                              title: 'كسب العمولات',
                              description: 'احصل على نسبة من رسوم كل معاملة يقوم بها صديقك',
                            ),
                            _buildStepItem(
                              number: 4,
                              title: 'سحب العمولات',
                              description: 'يمكنك سحب العمولات المكتسبة في أي وقت',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Referrals list
                    const Text(
                      'قائمة الإحالات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Referrals
                    _referrals.isEmpty
                        ? const Card(
                            elevation: 1,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'لم تقم بإحالة أي مستخدمين بعد',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Column(
                            children: _referrals.map((referral) {
                              return _buildReferralItem(referral);
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
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
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCommissionRateItem({
    required String title,
    required String rate,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.percent,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      rate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepItem({
    required int number,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.blue.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: isLast ? 0 : 16),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildReferralItem(Map<String, dynamic> referral) {
    final referredName = referral['referredName'] ?? 'مستخدم Mpay';
    final referredEmail = referral['referredEmail'] ?? '';
    final createdAt = referral['createdAt'] as Timestamp;
    final earnings = (referral['earnings'] as num?)?.toDouble() ?? 0.0;
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              child: Icon(Icons.person),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    referredName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (referredEmail.isNotEmpty)
                    Text(
                      referredEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  Text(
                    'تاريخ التسجيل: ${_formatDate(createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$ ${_formatAmount(earnings)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'العمولات',
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
    );
  }
}
