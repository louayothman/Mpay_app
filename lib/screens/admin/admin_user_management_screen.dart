import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';
  String _filterStatus = 'all';
  
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
            await _loadUsers();
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
  
  Future<void> _loadUsers() async {
    try {
      // Load users
      Query usersQuery = _firestore.collection('users');
      
      // Apply filters
      if (_filterStatus != 'all') {
        usersQuery = usersQuery.where('status', isEqualTo: _filterStatus);
      }
      
      final usersSnapshot = await usersQuery.get();
      
      List<Map<String, dynamic>> users = [];
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          final email = userData['email'] as String? ?? '';
          final firstName = userData['firstName'] as String? ?? '';
          final lastName = userData['lastName'] as String? ?? '';
          final phone = userData['phone'] as String? ?? '';
          
          if (email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              firstName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              lastName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              phone.contains(_searchQuery)) {
            users.add(userData);
          }
        } else {
          users.add(userData);
        }
      }
      
      setState(() {
        _users = users;
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
    _loadUsers();
  }
  
  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _loadUsers();
  }
  
  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
    });
    _loadUsers();
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd').format(date);
  }
  
  String _getUserStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'suspended':
        return 'معلق';
      case 'blocked':
        return 'محظور';
      case 'pending':
        return 'قيد التفعيل';
      default:
        return status;
    }
  }
  
  Color _getUserStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  Future<void> _changeUserStatus(String userId, String newStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
      
      // Create notification
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'system',
        'title': 'تغيير حالة الحساب',
        'message': 'تم تغيير حالة حسابك إلى ${_getUserStatusText(newStatus)}',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'data': {
          'status': newStatus,
        },
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تغيير حالة المستخدم إلى ${_getUserStatusText(newStatus)}')),
      );
      
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  Future<void> _resetUserPassword(String userId, String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      // Create notification
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'system',
        'title': 'إعادة تعيين كلمة المرور',
        'message': 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'data': {},
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى $email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  Future<void> _deleteUser(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete user wallets
      await _firestore.collection('wallets').where('userId', isEqualTo: userId).get().then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
      
      // Delete user notifications
      await _firestore.collection('notifications').where('userId', isEqualTo: userId).get().then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
      
      // Delete user support tickets
      await _firestore.collection('support_tickets').where('userId', isEqualTo: userId).get().then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المستخدم بنجاح')),
      );
      
      _loadUsers();
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
        title: const Text('إدارة المستخدمين'),
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
                              hintText: 'بحث عن مستخدم...',
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
                          
                          // Status filter
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: 'الكل',
                                  isSelected: _filterStatus == 'all',
                                  onSelected: () => _filterByStatus('all'),
                                ),
                                _buildFilterChip(
                                  label: 'نشط',
                                  isSelected: _filterStatus == 'active',
                                  onSelected: () => _filterByStatus('active'),
                                  color: Colors.green,
                                ),
                                _buildFilterChip(
                                  label: 'معلق',
                                  isSelected: _filterStatus == 'suspended',
                                  onSelected: () => _filterByStatus('suspended'),
                                  color: Colors.orange,
                                ),
                                _buildFilterChip(
                                  label: 'محظور',
                                  isSelected: _filterStatus == 'blocked',
                                  onSelected: () => _filterByStatus('blocked'),
                                  color: Colors.red,
                                ),
                                _buildFilterChip(
                                  label: 'قيد التفعيل',
                                  isSelected: _filterStatus == 'pending',
                                  onSelected: () => _filterByStatus('pending'),
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // User count
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'عدد المستخدمين: ${_users.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _loadUsers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('تحديث'),
                          ),
                        ],
                      ),
                    ),
                    
                    // Users list
                    Expanded(
                      child: _users.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'لا يوجد مستخدمين',
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
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return _buildUserCard(user);
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
  
  Widget _buildUserCard(Map<String, dynamic> user) {
    final id = user['id'];
    final email = user['email'] as String? ?? '';
    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final phone = user['phone'] as String? ?? '';
    final status = user['status'] as String? ?? 'active';
    final createdAt = user['createdAt'] as Timestamp? ?? Timestamp.now();
    final isAdmin = user['isAdmin'] as bool? ?? false;
    final walletId = user['walletId'] as String? ?? '';
    
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
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getUserStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getUserStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getUserStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  phone.isNotEmpty ? phone : 'لا يوجد',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'تاريخ التسجيل: ${_formatDate(createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            if (walletId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'رمز المحفظة: $walletId',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            if (isAdmin)
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
                    'مشرف',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View details button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminUserDetailsScreen(userId: id),
                      ),
                    ).then((_) => _loadUsers());
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('عرض التفاصيل'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // More options button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'activate':
                        _changeUserStatus(id, 'active');
                        break;
                      case 'suspend':
                        _changeUserStatus(id, 'suspended');
                        break;
                      case 'block':
                        _changeUserStatus(id, 'blocked');
                        break;
                      case 'reset_password':
                        _resetUserPassword(id, email);
                        break;
                      case 'delete':
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('حذف المستخدم'),
                            content: const Text('هل أنت متأكد من حذف هذا المستخدم؟ لا يمكن التراجع عن هذا الإجراء.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('إلغاء'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteUser(id);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('حذف'),
                              ),
                            ],
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('تنشيط'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'suspend',
                      child: Row(
                        children: [
                          Icon(Icons.pause_circle, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('تعليق'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حظر'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset_password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('إعادة تعيين كلمة المرور'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminUserDetailsScreen extends StatefulWidget {
  final String userId;
  
  const AdminUserDetailsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _walletData = {};
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _supportTickets = [];
  
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
      // Load user data
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userData['id'] = userDoc.id;
        
        setState(() {
          _userData = userData;
        });
        
        // Load wallet data
        final walletId = userData['walletId'] as String? ?? '';
        
        if (walletId.isNotEmpty) {
          final walletDoc = await _firestore.collection('wallets').doc(walletId).get();
          
          if (walletDoc.exists) {
            final walletData = walletDoc.data() as Map<String, dynamic>;
            walletData['id'] = walletDoc.id;
            
            setState(() {
              _walletData = walletData;
            });
          }
        }
        
        // Load transactions
        final transactionsQuery = await _firestore
            .collection('transactions')
            .where('userId', isEqualTo: widget.userId)
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
          _transactions = transactions;
        });
        
        // Load support tickets
        final ticketsQuery = await _firestore
            .collection('support_tickets')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('createdAt', descending: true)
            .get();
        
        List<Map<String, dynamic>> tickets = [];
        
        for (var doc in ticketsQuery.docs) {
          final ticketData = doc.data();
          ticketData['id'] = doc.id;
          tickets.add(ticketData as Map<String, dynamic>);
        }
        
        setState(() {
          _supportTickets = tickets;
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
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }
  
  String _getUserStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'suspended':
        return 'معلق';
      case 'blocked':
        return 'محظور';
      case 'pending':
        return 'قيد التفعيل';
      default:
        return status;
    }
  }
  
  Color _getUserStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المستخدم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData.isEmpty
              ? const Center(
                  child: Text(
                    'لم يتم العثور على المستخدم',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      _userData['firstName'] != null && (_userData['firstName'] as String).isNotEmpty
                                          ? (_userData['firstName'] as String)[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _userData['email'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getUserStatusColor(_userData['status'] ?? 'active').withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getUserStatusText(_userData['status'] ?? 'active'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getUserStatusColor(_userData['status'] ?? 'active'),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              _buildInfoItem(
                                icon: Icons.phone,
                                title: 'رقم الهاتف',
                                value: _userData['phone'] ?? 'لا يوجد',
                              ),
                              _buildInfoItem(
                                icon: Icons.calendar_today,
                                title: 'تاريخ التسجيل',
                                value: _formatDate(_userData['createdAt'] ?? Timestamp.now()),
                              ),
                              _buildInfoItem(
                                icon: Icons.account_balance_wallet,
                                title: 'رمز المحفظة',
                                value: _userData['walletId'] ?? 'لا يوجد',
                              ),
                              _buildInfoItem(
                                icon: Icons.star,
                                title: 'المستوى',
                                value: _userData['level'] ?? 'برونزي',
                              ),
                              _buildInfoItem(
                                icon: Icons.person_add,
                                title: 'رمز الإحالة',
                                value: _userData['referralCode'] ?? 'لا يوجد',
                              ),
                              if (_userData['referredBy'] != null && (_userData['referredBy'] as String).isNotEmpty)
                                _buildInfoItem(
                                  icon: Icons.person,
                                  title: 'تمت الإحالة بواسطة',
                                  value: _userData['referredBy'],
                                ),
                              if (_userData['isAdmin'] == true)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        size: 16,
                                        color: Colors.purple.shade800,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'مشرف',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.purple.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Wallet balances
                      if (_walletData.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'أرصدة المحفظة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildWalletBalances(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      
                      // Recent transactions
                      const Text(
                        'أحدث المعاملات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _transactions.isEmpty
                          ? const Card(
                              elevation: 1,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text('لا توجد معاملات'),
                                ),
                              ),
                            )
                          : Column(
                              children: _transactions.map((transaction) {
                                return _buildTransactionCard(transaction);
                              }).toList(),
                            ),
                      const SizedBox(height: 24),
                      
                      // Support tickets
                      const Text(
                        'تذاكر الدعم الفني',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _supportTickets.isEmpty
                          ? const Card(
                              elevation: 1,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text('لا توجد تذاكر دعم فني'),
                                ),
                              ),
                            )
                          : Column(
                              children: _supportTickets.map((ticket) {
                                return _buildTicketCard(ticket);
                              }).toList(),
                            ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Text(
            '$title:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWalletBalances() {
    final balances = _walletData['balances'] as Map<String, dynamic>? ?? {};
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: balances.length,
      itemBuilder: (context, index) {
        final currency = balances.keys.elementAt(index);
        final balance = (balances[currency] as num).toDouble();
        
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
                      _getCurrencyName(currency),
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
      },
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
  
  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final id = ticket['id'];
    final subject = ticket['subject'];
    final category = ticket['category'];
    final status = ticket['status'];
    final createdAt = ticket['createdAt'] as Timestamp;
    
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
                  child: Icon(
                    _getTicketCategoryIcon(category),
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTicketStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTicketStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTicketStatusColor(status),
                      fontWeight: FontWeight.bold,
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
  
  IconData _getTicketCategoryIcon(String category) {
    switch (category) {
      case 'account':
        return Icons.person;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'transaction':
        return Icons.swap_horiz;
      case 'deposit':
        return Icons.add_circle_outline;
      case 'withdraw':
        return Icons.remove_circle_outline;
      case 'security':
        return Icons.security;
      case 'bug':
        return Icons.bug_report;
      case 'feature':
        return Icons.lightbulb;
      case 'other':
        return Icons.help;
      default:
        return Icons.help;
    }
  }
  
  String _getTicketStatusText(String status) {
    switch (status) {
      case 'open':
        return 'مفتوحة';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'resolved':
        return 'تم الحل';
      case 'closed':
        return 'مغلقة';
      default:
        return status;
    }
  }
  
  Color _getTicketStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  String _getCurrencyName(String code) {
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
