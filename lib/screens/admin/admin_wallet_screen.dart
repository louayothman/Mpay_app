import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mpay_app/models/data_models.dart';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _isAdmin = false;
  Map<String, double> _balances = {};
  List<Map<String, dynamic>> _depositAddresses = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final isAdmin = userData['isAdmin'] ?? false;
          
          setState(() {
            _isAdmin = isAdmin;
          });
          
          if (isAdmin) {
            await _loadAdminData();
          }
        }
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
  
  Future<void> _loadAdminData() async {
    try {
      // Load admin wallet balances
      final adminWalletDoc = await _firestore.collection('admin_wallet').doc('main').get();
      
      if (adminWalletDoc.exists) {
        final walletData = adminWalletDoc.data() as Map<String, dynamic>;
        final balances = walletData['balances'] as Map<String, dynamic>;
        
        Map<String, double> formattedBalances = {};
        
        for (var entry in balances.entries) {
          formattedBalances[entry.key] = (entry.value as num).toDouble();
        }
        
        setState(() {
          _balances = formattedBalances;
        });
      }
      
      // Load deposit addresses
      final depositAddressesDoc = await _firestore.collection('admin_wallet').doc('deposit_addresses').get();
      
      if (depositAddressesDoc.exists) {
        final addressesData = depositAddressesDoc.data() as Map<String, dynamic>;
        final addresses = addressesData['addresses'] as List<dynamic>;
        
        List<Map<String, dynamic>> formattedAddresses = [];
        
        for (var address in addresses) {
          formattedAddresses.add(address as Map<String, dynamic>);
        }
        
        setState(() {
          _depositAddresses = formattedAddresses;
        });
      }
      
      // Load recent transactions
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('isAdminTransaction', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      List<Map<String, dynamic>> transactions = [];
      
      for (var doc in transactionsQuery.docs) {
        final transactionData = doc.data();
        transactionData['id'] = doc.id;
        transactions.add(transactionData as Map<String, dynamic>);
      }
      
      setState(() {
        _recentTransactions = transactions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  String _formatAmount(double amount) {
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }
  
  String _getTransactionTypeText(String type) {
    switch (type) {
      case 'deposit':
        return 'إيداع';
      case 'withdraw':
        return 'سحب';
      case 'transfer':
        return 'تحويل';
      case 'exchange':
        return 'مبادلة';
      case 'fee':
        return 'رسوم';
      case 'refund':
        return 'استرداد';
      case 'adjustment':
        return 'تعديل';
      default:
        return type;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محفظة المشرف'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const Center(
                  child: Text(
                    'ليس لديك صلاحية الوصول إلى هذه الصفحة',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAdminData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Admin wallet balances
                        const Text(
                          'أرصدة المحفظة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _balances.length,
                          itemBuilder: (context, index) {
                            final currency = _balances.keys.elementAt(index);
                            final balance = _balances[currency]!;
                            
                            return _buildBalanceCard(currency, balance);
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Deposit addresses
                        const Text(
                          'عناوين الإيداع',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: _depositAddresses.map((address) {
                            return _buildDepositAddressCard(
                              currency: address['currency'],
                              address: address['address'],
                              network: address['network'],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Recent transactions
                        const Text(
                          'أحدث المعاملات',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: _recentTransactions.map((transaction) {
                            return _buildTransactionCard(transaction);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildBalanceCard(String currency, double balance) {
    Color cardColor;
    IconData currencyIcon;
    
    switch (currency) {
      case 'USD':
        cardColor = Colors.green.shade100;
        currencyIcon = Icons.attach_money;
        break;
      case 'EUR':
        cardColor = Colors.blue.shade100;
        currencyIcon = Icons.euro;
        break;
      case 'SYP':
        cardColor = Colors.red.shade100;
        currencyIcon = Icons.money;
        break;
      case 'SAR':
        cardColor = Colors.purple.shade100;
        currencyIcon = Icons.money;
        break;
      case 'AED':
        cardColor = Colors.orange.shade100;
        currencyIcon = Icons.money;
        break;
      case 'TRY':
        cardColor = Colors.teal.shade100;
        currencyIcon = Icons.money;
        break;
      default:
        cardColor = Colors.grey.shade100;
        currencyIcon = Icons.money;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  currencyIcon,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  getCurrencyName(currency),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _formatAmount(balance),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currency,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDepositAddressCard({
    required String currency,
    required String address,
    required String network,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    currency,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getCurrencyName(currency),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'شبكة: $network',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      // Copy address to clipboard
                    },
                    tooltip: 'نسخ العنوان',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final amount = (transaction['amount'] as num).toDouble();
    final currency = transaction['currency'] as String;
    final timestamp = transaction['timestamp'] as Timestamp;
    final status = transaction['status'] as String;
    final description = transaction['description'] as String?;
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: type == 'deposit' ? Colors.green.shade50 : Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type == 'deposit' ? Icons.add : Icons.remove,
                    color: type == 'deposit' ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTransactionTypeText(type),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(timestamp),
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
                      '${type == 'deposit' ? '+' : '-'} ${_formatAmount(amount)} $currency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: type == 'deposit' ? Colors.green : Colors.red,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
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
                                : 'فشلت',
                        style: TextStyle(
                          fontSize: 10,
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
            if (description != null && description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String getCurrencyName(String code) {
    switch (code) {
      case 'USD':
        return 'دولار أمريكي';
      case 'EUR':
        return 'يورو';
      case 'SYP':
        return 'ليرة سورية';
      case 'SAR':
        return 'ريال سعودي';
      case 'AED':
        return 'درهم إماراتي';
      case 'TRY':
        return 'ليرة تركية';
      default:
        return code;
    }
  }
}
