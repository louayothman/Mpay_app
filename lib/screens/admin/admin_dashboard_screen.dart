import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _isAdmin = false;
  
  // Dashboard statistics
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _pendingUsers = 0;
  int _totalTransactions = 0;
  int _pendingTransactions = 0;
  int _totalDeposits = 0;
  int _totalWithdrawals = 0;
  Map<String, double> _totalBalances = {};
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _recentUsers = [];
  
  // Pagination variables
  static const int _pageSize = 10;
  DocumentSnapshot? _lastUserDocument;
  DocumentSnapshot? _lastTransactionDocument;
  bool _hasMoreUsers = true;
  bool _hasMoreTransactions = true;
  bool _isLoadingMoreUsers = false;
  bool _isLoadingMoreTransactions = false;
  
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
            await _loadDashboardData();
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
  
  Future<void> _loadDashboardData() async {
    try {
      // Reset pagination variables
      _lastUserDocument = null;
      _lastTransactionDocument = null;
      _hasMoreUsers = true;
      _hasMoreTransactions = true;
      
      // Load user statistics
      final usersQuery = await _firestore.collection('users').get();
      final activeUsersQuery = await _firestore.collection('users').where('status', isEqualTo: 'active').get();
      final pendingUsersQuery = await _firestore.collection('users').where('status', isEqualTo: 'pending').get();
      
      // Load transaction statistics
      final transactionsQuery = await _firestore.collection('transactions').get();
      final pendingTransactionsQuery = await _firestore.collection('transactions').where('status', isEqualTo: 'pending').get();
      final depositsQuery = await _firestore.collection('transactions').where('type', isEqualTo: 'deposit').get();
      final withdrawalsQuery = await _firestore.collection('transactions').where('type', isEqualTo: 'withdraw').get();
      
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
          _totalBalances = formattedBalances;
        });
      }
      
      // Load recent transactions with pagination
      await _loadTransactions(initial: true);
      
      // Load recent users with pagination
      await _loadUsers(initial: true);
      
      setState(() {
        _totalUsers = usersQuery.docs.length;
        _activeUsers = activeUsersQuery.docs.length;
        _pendingUsers = pendingUsersQuery.docs.length;
        _totalTransactions = transactionsQuery.docs.length;
        _pendingTransactions = pendingTransactionsQuery.docs.length;
        _totalDeposits = depositsQuery.docs.length;
        _totalWithdrawals = withdrawalsQuery.docs.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  // تحميل المعاملات مع دعم التقسيم إلى صفحات
  Future<void> _loadTransactions({bool initial = false}) async {
    if (_isLoadingMoreTransactions) return;
    
    setState(() {
      _isLoadingMoreTransactions = true;
    });
    
    try {
      Query query = _firestore.collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);
      
      if (!initial && _lastTransactionDocument != null) {
        query = query.startAfterDocument(_lastTransactionDocument!);
      }
      
      final querySnapshot = await query.get();
      
      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _hasMoreTransactions = false;
          _isLoadingMoreTransactions = false;
        });
        return;
      }
      
      _lastTransactionDocument = querySnapshot.docs.last;
      
      List<Map<String, dynamic>> transactions = [];
      
      for (var doc in querySnapshot.docs) {
        final transactionData = doc.data() as Map<String, dynamic>;
        transactionData['id'] = doc.id;
        transactions.add(transactionData);
      }
      
      setState(() {
        if (initial) {
          _recentTransactions = transactions;
        } else {
          _recentTransactions.addAll(transactions);
        }
        _hasMoreTransactions = querySnapshot.docs.length == _pageSize;
        _isLoadingMoreTransactions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMoreTransactions = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل المعاملات: $e')),
      );
    }
  }
  
  // تحميل المستخدمين مع دعم التقسيم إلى صفحات
  Future<void> _loadUsers({bool initial = false}) async {
    if (_isLoadingMoreUsers) return;
    
    setState(() {
      _isLoadingMoreUsers = true;
    });
    
    try {
      Query query = _firestore.collection('users')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);
      
      if (!initial && _lastUserDocument != null) {
        query = query.startAfterDocument(_lastUserDocument!);
      }
      
      final querySnapshot = await query.get();
      
      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _hasMoreUsers = false;
          _isLoadingMoreUsers = false;
        });
        return;
      }
      
      _lastUserDocument = querySnapshot.docs.last;
      
      List<Map<String, dynamic>> users = [];
      
      for (var doc in querySnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;
        users.add(userData);
      }
      
      setState(() {
        if (initial) {
          _recentUsers = users;
        } else {
          _recentUsers.addAll(users);
        }
        _hasMoreUsers = querySnapshot.docs.length == _pageSize;
        _isLoadingMoreUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMoreUsers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل المستخدمين: $e')),
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
        title: const Text('لوحة تحكم المشرف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
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
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics cards
                        _buildStatisticsSection(),
                        const SizedBox(height: 24),
                        
                        // Admin wallet balances
                        const Text(
                          'أرصدة المحفظة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildWalletBalances(),
                        const SizedBox(height: 24),
                        
                        // Recent transactions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'أحدث المعاملات',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminTransactionsScreen(),
                                  ),
                                );
                              },
                              child: const Text('عرض الكل'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _recentTransactions.isEmpty
                            ? const Card(
                                elevation: 1,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text('لا توجد معاملات حديثة'),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  ..._recentTransactions.map((transaction) {
                                    return _buildTransactionCard(transaction);
                                  }).toList(),
                                  if (_hasMoreTransactions)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: Center(
                                        child: _isLoadingMoreTransactions
                                            ? const CircularProgressIndicator()
                                            : ElevatedButton(
                                                onPressed: () => _loadTransactions(),
                                                child: const Text('تحميل المزيد'),
                                              ),
                                      ),
                                    ),
                                ],
                              ),
                        const SizedBox(height: 24),
                        
                        // Recent users
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'أحدث المستخدمين',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminUserManagementScreen(),
                                  ),
                                );
                              },
                              child: const Text('عرض الكل'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _recentUsers.isEmpty
                            ? const Card(
                                elevation: 1,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text('لا يوجد مستخدمين جدد'),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  ..._recentUsers.map((user) {
                                    return _buildUserCard(user);
                                  }).toList(),
                                  if (_hasMoreUsers)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: Center(
                                        child: _isLoadingMoreUsers
                                            ? const CircularProgressIndicator()
                                            : ElevatedButton(
                                                onPressed: () => _loadUsers(),
                                                child: const Text('تحميل المزيد'),
                                              ),
                                      ),
                                    ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 30,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'لوحة تحكم المشرف',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _auth.currentUser?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('الرئيسية'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('محفظة المشرف'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminWalletScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('إدارة المستخدمين'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminUserManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('إدارة المعاملات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminTransactionsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('إعدادات التطبيق'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to app settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              await _auth.signOut();
              Navigator.pop(context);
              // Navigate to login screen
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatisticsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'المستخدمين',
                value: _totalUsers.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'المستخدمين النشطين',
                value: _activeUsers.toString(),
                icon: Icons.person_outline,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'المعاملات',
                value: _totalTransactions.toString(),
                icon: Icons.swap_horiz,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'المعاملات المعلقة',
                value: _pendingTransactions.toString(),
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'الإيداعات',
                value: _totalDeposits.toString(),
                icon: Icons.arrow_downward,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'السحوبات',
                value: _totalWithdrawals.toString(),
                icon: Icons.arrow_upward,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWalletBalances() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._totalBalances.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatAmount(entry.value),
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (_totalBalances.isEmpty)
              const Center(
                child: Text('لا توجد أرصدة متاحة'),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final method = transaction['method'] as String? ?? '';
    final amount = (transaction['amount'] as num).toDouble();
    final status = transaction['status'] as String;
    final timestamp = transaction['timestamp'] as Timestamp?;
    
    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blue;
    }
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: type == 'deposit' ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            type == 'deposit' ? Icons.arrow_downward : Icons.arrow_upward,
            color: type == 'deposit' ? Colors.green : Colors.red,
          ),
        ),
        title: Row(
          children: [
            Text(
              _getTransactionTypeText(type),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(method),
            if (timestamp != null)
              Text(
                _formatDate(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: Text(
          '${type == 'deposit' ? '+' : '-'}${_formatAmount(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: type == 'deposit' ? Colors.green : Colors.red,
          ),
        ),
        onTap: () {
          // Navigate to transaction details
        },
      ),
    );
  }
  
  Widget _buildUserCard(Map<String, dynamic> user) {
    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final status = user['status'] as String? ?? 'active';
    final createdAt = user['createdAt'] as Timestamp?;
    
    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'suspended':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blue;
    }
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              '$firstName $lastName',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            if (createdAt != null)
              Text(
                'تاريخ التسجيل: ${_formatDate(createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        onTap: () {
          // Navigate to user details
        },
      ),
    );
  }
}

class AdminTransactionsScreen extends StatelessWidget {
  const AdminTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('شاشة إدارة المعاملات'),
      ),
    );
  }
}

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('شاشة إدارة المستخدمين'),
      ),
    );
  }
}

class AdminWalletScreen extends StatelessWidget {
  const AdminWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('شاشة محفظة المشرف'),
      ),
    );
  }
}
