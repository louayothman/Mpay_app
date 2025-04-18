import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CommissionSystemScreen extends StatefulWidget {
  const CommissionSystemScreen({super.key});

  @override
  State<CommissionSystemScreen> createState() => _CommissionSystemScreenState();
}

class _CommissionSystemScreenState extends State<CommissionSystemScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  double _totalCommissions = 0.0;
  double _availableCommissions = 0.0;
  double _pendingCommissions = 0.0;
  double _withdrawnCommissions = 0.0;
  List<Map<String, dynamic>> _commissions = [];
  Map<String, dynamic> _commissionRates = {};
  
  @override
  void initState() {
    super.initState();
    _loadCommissionData();
  }
  
  Future<void> _loadCommissionData() async {
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
            _totalCommissions = (userData['totalCommissions'] as num?)?.toDouble() ?? 0.0;
            _availableCommissions = (userData['availableCommissions'] as num?)?.toDouble() ?? 0.0;
            _pendingCommissions = (userData['pendingCommissions'] as num?)?.toDouble() ?? 0.0;
            _withdrawnCommissions = (userData['withdrawnCommissions'] as num?)?.toDouble() ?? 0.0;
          });
        }
        
        // Get commission rates
        final settingsDoc = await _firestore.collection('system_settings').doc('commissions').get();
        
        if (settingsDoc.exists) {
          final settingsData = settingsDoc.data() as Map<String, dynamic>;
          setState(() {
            _commissionRates = Map<String, dynamic>.from(settingsData['rates'] ?? {});
          });
        }
        
        // Get commissions
        final commissionsQuery = await _firestore
            .collection('commissions')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();
        
        List<Map<String, dynamic>> commissions = [];
        
        for (var doc in commissionsQuery.docs) {
          final commissionData = doc.data();
          commissionData['id'] = doc.id;
          commissions.add(commissionData as Map<String, dynamic>);
        }
        
        setState(() {
          _commissions = commissions;
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
  
  Future<void> _withdrawCommissions() async {
    if (_availableCommissions <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد عمولات متاحة للسحب')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Create withdrawal request
        await _firestore.collection('commission_withdrawals').add({
          'userId': user.uid,
          'amount': _availableCommissions,
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'completedAt': null,
          'notes': '',
        });
        
        // Update user's commission balances
        await _firestore.collection('users').doc(user.uid).update({
          'availableCommissions': 0,
          'pendingCommissions': FieldValue.increment(_availableCommissions),
          'updatedAt': Timestamp.now(),
        });
        
        // Create notification
        await _firestore.collection('notifications').add({
          'userId': user.uid,
          'type': 'commission_withdrawal',
          'title': 'طلب سحب عمولات',
          'message': 'تم استلام طلب سحب العمولات الخاص بك وسيتم مراجعته قريباً',
          'isRead': false,
          'createdAt': Timestamp.now(),
          'data': {
            'amount': _availableCommissions,
          },
        });
        
        // Show success message
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب سحب العمولات بنجاح')),
        );
        
        // Reload data
        _loadCommissionData();
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
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }
  
  String _formatAmount(double amount) {
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
  
  String _getCommissionTypeText(String type) {
    switch (type) {
      case 'referral_registration':
        return 'تسجيل مستخدم محال';
      case 'referral_transaction':
        return 'معاملة مستخدم محال';
      case 'referral_deposit':
        return 'إيداع مستخدم محال';
      case 'referral_withdraw':
        return 'سحب مستخدم محال';
      case 'deal_completion':
        return 'إتمام صفقة';
      case 'exchange_fee':
        return 'رسوم مبادلة';
      default:
        return type;
    }
  }
  
  IconData _getCommissionTypeIcon(String type) {
    switch (type) {
      case 'referral_registration':
        return Icons.person_add;
      case 'referral_transaction':
        return Icons.swap_horiz;
      case 'referral_deposit':
        return Icons.add_circle_outline;
      case 'referral_withdraw':
        return Icons.remove_circle_outline;
      case 'deal_completion':
        return Icons.handshake;
      case 'exchange_fee':
        return Icons.currency_exchange;
      default:
        return Icons.attach_money;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام العمولات'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCommissionData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Commission balance card
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
                              'رصيد العمولات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Available commissions
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.green.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'العمولات المتاحة',
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '\$ ${_formatAmount(_availableCommissions)}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _availableCommissions > 0 ? _withdrawCommissions : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('سحب'),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            
                            // Other commission balances
                            Row(
                              children: [
                                Expanded(
                                  child: _buildBalanceItem(
                                    title: 'قيد الانتظار',
                                    amount: _pendingCommissions,
                                    icon: Icons.hourglass_empty,
                                    color: Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: _buildBalanceItem(
                                    title: 'تم سحبها',
                                    amount: _withdrawnCommissions,
                                    icon: Icons.check_circle,
                                    color: Colors.blue,
                                  ),
                                ),
                                Expanded(
                                  child: _buildBalanceItem(
                                    title: 'الإجمالي',
                                    amount: _totalCommissions,
                                    icon: Icons.bar_chart,
                                    color: Colors.purple,
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
                              title: 'عمولة الإحالة (تسجيل)',
                              rate: _commissionRates['referral_registration']?.toString() ?? '0',
                              description: 'دولار لكل مستخدم جديد يسجل باستخدام رمز الإحالة الخاص بك',
                              icon: Icons.person_add,
                            ),
                            _buildCommissionRateItem(
                              title: 'عمولة الإحالة (معاملات)',
                              rate: '${(_commissionRates['referral_transaction'] as num? ?? 0) * 100}%',
                              description: 'من رسوم كل معاملة يقوم بها المستخدم المُحال',
                              icon: Icons.swap_horiz,
                            ),
                            _buildCommissionRateItem(
                              title: 'عمولة إتمام الصفقات',
                              rate: '${(_commissionRates['deal_completion'] as num? ?? 0) * 100}%',
                              description: 'من قيمة كل صفقة تقوم بإتمامها',
                              icon: Icons.handshake,
                            ),
                            _buildCommissionRateItem(
                              title: 'عمولة المبادلة',
                              rate: '${(_commissionRates['exchange_fee'] as num? ?? 0) * 100}%',
                              description: 'من رسوم كل عملية مبادلة تقوم بها',
                              icon: Icons.currency_exchange,
                              isLast: true,
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
                              'كيف يعمل نظام العمولات؟',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Steps
                            _buildStepItem(
                              number: 1,
                              title: 'كسب العمولات',
                              description: 'اكسب العمولات من خلال الإحالات، إتمام الصفقات، والمبادلات',
                            ),
                            _buildStepItem(
                              number: 2,
                              title: 'تجميع العمولات',
                              description: 'يتم إضافة العمولات المكتسبة إلى رصيد العمولات المتاحة',
                            ),
                            _buildStepItem(
                              number: 3,
                              title: 'سحب العمولات',
                              description: 'اضغط على زر "سحب" لتحويل العمولات المتاحة إلى رصيدك',
                            ),
                            _buildStepItem(
                              number: 4,
                              title: 'استلام العمولات',
                              description: 'بعد موافقة الإدارة، سيتم إضافة العمولات إلى رصيد محفظتك',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Commissions history
                    const Text(
                      'سجل العمولات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Commissions list
                    _commissions.isEmpty
                        ? const Card(
                            elevation: 1,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'لا توجد عمولات في السجل',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Column(
                            children: _commissions.map((commission) {
                              return _buildCommissionItem(commission);
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildBalanceItem({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$ ${_formatAmount(amount)}',
          style: const TextStyle(
            fontSize: 14,
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
    required IconData icon,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
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
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      rate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
  
  Widget _buildCommissionItem(Map<String, dynamic> commission) {
    final type = commission['type'] as String;
    final amount = (commission['amount'] as num).toDouble();
    final status = commission['status'] as String;
    final createdAt = commission['createdAt'] as Timestamp;
    final description = commission['description'] ?? '';
    
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCommissionTypeIcon(type),
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCommissionTypeText(type),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  Text(
                    _formatDate(createdAt),
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
                  '\$ ${_formatAmount(amount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'completed'
                        ? Colors.green.shade100
                        : status == 'pending'
                            ? Colors.orange.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status == 'completed'
                        ? 'مكتملة'
                        : status == 'pending'
                            ? 'قيد الانتظار'
                            : 'ملغاة',
                    style: TextStyle(
                      fontSize: 12,
                      color: status == 'completed'
                          ? Colors.green.shade800
                          : status == 'pending'
                              ? Colors.orange.shade800
                              : Colors.red.shade800,
                    ),
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
