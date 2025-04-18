import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _transactions = [];
  String _searchQuery = '';
  String _filterType = 'all';
  String _filterStatus = 'all';
  String _filterCurrency = 'all';
  
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            await _loadTransactions();
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
  
  Future<void> _loadTransactions() async {
    try {
      // Load transactions
      Query transactionsQuery = _firestore.collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(100);
      
      // Apply filters
      if (_filterType != 'all') {
        transactionsQuery = transactionsQuery.where('type', isEqualTo: _filterType);
      }
      
      if (_filterStatus != 'all') {
        transactionsQuery = transactionsQuery.where('status', isEqualTo: _filterStatus);
      }
      
      if (_filterCurrency != 'all') {
        transactionsQuery = transactionsQuery.where('currency', isEqualTo: _filterCurrency);
      }
      
      final transactionsSnapshot = await transactionsQuery.get();
      
      List<Map<String, dynamic>> transactions = [];
      
      for (var doc in transactionsSnapshot.docs) {
        final transactionData = doc.data() as Map<String, dynamic>;
        transactionData['id'] = doc.id;
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          final userId = transactionData['userId'] as String? ?? '';
          final description = transactionData['description'] as String? ?? '';
          final reference = transactionData['reference'] as String? ?? '';
          
          if (userId.contains(_searchQuery) ||
              description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              reference.toLowerCase().contains(_searchQuery.toLowerCase())) {
            transactions.add(transactionData);
          }
        } else {
          transactions.add(transactionData);
        }
      }
      
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  void _search() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
    _loadTransactions();
  }
  
  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _loadTransactions();
  }
  
  void _filterByType(String type) {
    setState(() {
      _filterType = type;
    });
    _loadTransactions();
  }
  
  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
    });
    _loadTransactions();
  }
  
  void _filterByCurrency(String currency) {
    setState(() {
      _filterCurrency = currency;
    });
    _loadTransactions();
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }
  
  String _formatAmount(double amount) {
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
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
  
  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'deposit':
        return Colors.green;
      case 'withdraw':
        return Colors.red;
      case 'transfer':
        return Colors.blue;
      case 'exchange':
        return Colors.orange;
      case 'fee':
        return Colors.purple;
      case 'refund':
        return Colors.teal;
      case 'adjustment':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getTransactionTypeIcon(String type) {
    switch (type) {
      case 'deposit':
        return Icons.add_circle_outline;
      case 'withdraw':
        return Icons.remove_circle_outline;
      case 'transfer':
        return Icons.swap_horiz;
      case 'exchange':
        return Icons.currency_exchange;
      case 'fee':
        return Icons.attach_money;
      case 'refund':
        return Icons.replay;
      case 'adjustment':
        return Icons.tune;
      default:
        return Icons.help;
    }
  }
  
  Future<void> _updateTransactionStatus(String transactionId, String newStatus) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة المعاملة إلى $newStatus')),
      );
      
      _loadTransactions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المعاملات'),
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
              : Column(
                  children: [
                    // Search and filter
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Search bar
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'بحث عن معاملة...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (_) => _search(),
                          ),
                          const SizedBox(height: 16),
                          
                          // Type filter
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: 'الكل',
                                  isSelected: _filterType == 'all',
                                  onSelected: () => _filterByType('all'),
                                ),
                                _buildFilterChip(
                                  label: 'إيداع',
                                  isSelected: _filterType == 'deposit',
                                  onSelected: () => _filterByType('deposit'),
                                  color: Colors.green,
                                ),
                                _buildFilterChip(
                                  label: 'سحب',
                                  isSelected: _filterType == 'withdraw',
                                  onSelected: () => _filterByType('withdraw'),
                                  color: Colors.red,
                                ),
                                _buildFilterChip(
                                  label: 'تحويل',
                                  isSelected: _filterType == 'transfer',
                                  onSelected: () => _filterByType('transfer'),
                                  color: Colors.blue,
                                ),
                                _buildFilterChip(
                                  label: 'مبادلة',
                                  isSelected: _filterType == 'exchange',
                                  onSelected: () => _filterByType('exchange'),
                                  color: Colors.orange,
                                ),
                                _buildFilterChip(
                                  label: 'رسوم',
                                  isSelected: _filterType == 'fee',
                                  onSelected: () => _filterByType('fee'),
                                  color: Colors.purple,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Status filter
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: 'كل الحالات',
                                  isSelected: _filterStatus == 'all',
                                  onSelected: () => _filterByStatus('all'),
                                ),
                                _buildFilterChip(
                                  label: 'مكتملة',
                                  isSelected: _filterStatus == 'completed',
                                  onSelected: () => _filterByStatus('completed'),
                                  color: Colors.green,
                                ),
                                _buildFilterChip(
                                  label: 'قيد الانتظار',
                                  isSelected: _filterStatus == 'pending',
                                  onSelected: () => _filterByStatus('pending'),
                                  color: Colors.orange,
                                ),
                                _buildFilterChip(
                                  label: 'فشلت',
                                  isSelected: _filterStatus == 'failed',
                                  onSelected: () => _filterByStatus('failed'),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Currency filter
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: 'كل العملات',
                                  isSelected: _filterCurrency == 'all',
                                  onSelected: () => _filterByCurrency('all'),
                                ),
                                _buildFilterChip(
                                  label: 'USD',
                                  isSelected: _filterCurrency == 'USD',
                                  onSelected: () => _filterByCurrency('USD'),
                                ),
                                _buildFilterChip(
                                  label: 'EUR',
                                  isSelected: _filterCurrency == 'EUR',
                                  onSelected: () => _filterByCurrency('EUR'),
                                ),
                                _buildFilterChip(
                                  label: 'SYP',
                                  isSelected: _filterCurrency == 'SYP',
                                  onSelected: () => _filterByCurrency('SYP'),
                                ),
                                _buildFilterChip(
                                  label: 'SAR',
                                  isSelected: _filterCurrency == 'SAR',
                                  onSelected: () => _filterByCurrency('SAR'),
                                ),
                                _buildFilterChip(
                                  label: 'AED',
                                  isSelected: _filterCurrency == 'AED',
                                  onSelected: () => _filterByCurrency('AED'),
                                ),
                                _buildFilterChip(
                                  label: 'TRY',
                                  isSelected: _filterCurrency == 'TRY',
                                  onSelected: () => _filterByCurrency('TRY'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Transaction count
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'عدد المعاملات: ${_transactions.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _loadTransactions,
                            icon: const Icon(Icons.refresh),
                            label: const Text('تحديث'),
                          ),
                        ],
                      ),
                    ),
                    
                    // Transactions list
                    Expanded(
                      child: _transactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.swap_horiz,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'لا توجد معاملات',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _transactions[index];
                                return _buildTransactionCard(transaction);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: color != null ? color.withOpacity(0.1) : null,
        selectedColor: color != null ? color.withOpacity(0.2) : null,
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected && color != null ? color : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
    );
  }
  
  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final id = transaction['id'];
    final type = transaction['type'] as String;
    final amount = (transaction['amount'] as num).toDouble();
    final currency = transaction['currency'] as String;
    final timestamp = transaction['timestamp'] as Timestamp;
    final status = transaction['status'] as String;
    final userId = transaction['userId'] as String?;
    final description = transaction['description'] as String?;
    final reference = transaction['reference'] as String?;
    final isAdminTransaction = transaction['isAdminTransaction'] as bool? ?? false;
    
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
                    color: _getTransactionTypeColor(type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTransactionTypeIcon(type),
                    color: _getTransactionTypeColor(type),
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
                      '${type == 'deposit' ? '+' : type == 'withdraw' ? '-' : ''} ${_formatAmount(amount)} $currency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: type == 'deposit' ? Colors.green : type == 'withdraw' ? Colors.red : Colors.blue,
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
            if (userId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'معرف المستخدم: $userId',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            if (description != null && description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
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
            if (reference != null && reference.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.numbers,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'رقم المرجع: $reference',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            if (isAdminTransaction)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'معاملة مشرف',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _updateTransactionStatus(id, 'completed'),
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('قبول'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _updateTransactionStatus(id, 'failed'),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
