import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/screens/auth/pin_screen.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeDeals = [];
  List<Map<String, dynamic>> _myDeals = [];
  String _selectedTab = 'active';
  
  @override
  void initState() {
    super.initState();
    _loadDeals();
  }
  
  Future<void> _loadDeals() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Load active deals
        final activeDealsQuery = await _firestore
            .collection('deals')
            .where('status', isEqualTo: 'active')
            .where('createdBy', isNotEqualTo: user.uid)
            .orderBy('createdBy')
            .orderBy('createdAt', descending: true)
            .get();
        
        List<Map<String, dynamic>> activeDeals = [];
        
        for (var doc in activeDealsQuery.docs) {
          final dealData = doc.data();
          dealData['id'] = doc.id;
          
          // Get creator info
          final creatorDoc = await _firestore.collection('users').doc(dealData['createdBy']).get();
          if (creatorDoc.exists) {
            final creatorData = creatorDoc.data() as Map<String, dynamic>;
            dealData['creatorName'] = '${creatorData['firstName']} ${creatorData['lastName']}';
            dealData['creatorRating'] = creatorData['rating'] ?? 0.0;
          } else {
            dealData['creatorName'] = 'مستخدم Mpay';
            dealData['creatorRating'] = 0.0;
          }
          
          activeDeals.add(dealData as Map<String, dynamic>);
        }
        
        // Load my deals
        final myDealsQuery = await _firestore
            .collection('deals')
            .where('createdBy', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();
        
        List<Map<String, dynamic>> myDeals = [];
        
        for (var doc in myDealsQuery.docs) {
          final dealData = doc.data();
          dealData['id'] = doc.id;
          myDeals.add(dealData as Map<String, dynamic>);
        }
        
        setState(() {
          _activeDeals = activeDeals;
          _myDeals = myDeals;
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
  
  Future<void> _createDeal() async {
    // Navigate to create deal screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateDealScreen(),
      ),
    );
    
    if (result == true) {
      _loadDeals();
    }
  }
  
  Future<void> _acceptDeal(Map<String, dynamic> deal) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Navigate to PIN verification
        if (!mounted) return;
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PinScreen(isVerification: true),
          ),
        );
        
        // If PIN verification successful
        if (result == true) {
          // Update deal status
          await _firestore.collection('deals').doc(deal['id']).update({
            'status': 'in_progress',
            'acceptedBy': user.uid,
            'acceptedAt': Timestamp.now(),
          });
          
          // Create notification for deal creator
          await _firestore.collection('notifications').add({
            'userId': deal['createdBy'],
            'type': 'deal',
            'title': 'تم قبول صفقتك',
            'message': 'تم قبول صفقتك: ${deal['title']}',
            'isRead': false,
            'createdAt': Timestamp.now(),
            'data': {
              'dealId': deal['id'],
            },
          });
          
          // Show success message and reload deals
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم قبول الصفقة بنجاح')),
          );
          
          _loadDeals();
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
  
  Future<void> _cancelDeal(Map<String, dynamic> deal) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Update deal status
      await _firestore.collection('deals').doc(deal['id']).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
      
      // Show success message and reload deals
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الصفقة بنجاح')),
      );
      
      _loadDeals();
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
  
  String _formatAmount(double amount) {
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشطة';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغاة';
      default:
        return status;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفقات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeals,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createDeal,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tabs
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          title: 'الصفقات النشطة',
                          isSelected: _selectedTab == 'active',
                          onTap: () {
                            setState(() {
                              _selectedTab = 'active';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTabButton(
                          title: 'صفقاتي',
                          isSelected: _selectedTab == 'my',
                          onTap: () {
                            setState(() {
                              _selectedTab = 'my';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Deals list
                Expanded(
                  child: _selectedTab == 'active'
                      ? _buildActiveDeals()
                      : _buildMyDeals(),
                ),
              ],
            ),
    );
  }
  
  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  Widget _buildActiveDeals() {
    if (_activeDeals.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد صفقات نشطة حالياً',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeDeals.length,
      itemBuilder: (context, index) {
        final deal = _activeDeals[index];
        return _buildDealCard(deal, isMyDeal: false);
      },
    );
  }
  
  Widget _buildMyDeals() {
    if (_myDeals.isEmpty) {
      return const Center(
        child: Text(
          'لم تقم بإنشاء أي صفقات بعد',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myDeals.length,
      itemBuilder: (context, index) {
        final deal = _myDeals[index];
        return _buildDealCard(deal, isMyDeal: true);
      },
    );
  }
  
  Widget _buildDealCard(Map<String, dynamic> deal, {required bool isMyDeal}) {
    final fromCurrency = deal['fromCurrency'];
    final toCurrency = deal['toCurrency'];
    final fromAmount = (deal['fromAmount'] as num).toDouble();
    final toAmount = (deal['toAmount'] as num).toDouble();
    final exchangeRate = (deal['exchangeRate'] as num).toDouble();
    final status = deal['status'];
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    deal['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Creator info
            if (!isMyDeal)
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    deal['creatorName'],
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  Text(
                    (deal['creatorRating'] as num).toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            if (!isMyDeal) const SizedBox(height: 16),
            
            // Exchange details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'يعرض',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getCurrencySymbol(fromCurrency)} ${_formatAmount(fromAmount)} $fromCurrency',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.swap_horiz),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'يطلب',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getCurrencySymbol(toCurrency)} ${_formatAmount(toAmount)} $toCurrency',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Exchange rate
            Text(
              'سعر الصرف: 1 $fromCurrency = ${_formatAmount(exchangeRate)} $toCurrency',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            if (deal['description'] != null && deal['description'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الوصف:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deal['description'],
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isMyDeal && status == 'active')
                  ElevatedButton(
                    onPressed: () => _acceptDeal(deal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('قبول الصفقة'),
                  ),
                if (isMyDeal && status == 'active')
                  ElevatedButton(
                    onPressed: () => _cancelDeal(deal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إلغاء الصفقة'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateDealScreen extends StatefulWidget {
  const CreateDealScreen({super.key});

  @override
  State<CreateDealScreen> createState() => _CreateDealScreenState();
}

class _CreateDealScreenState extends State<CreateDealScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fromAmountController = TextEditingController();
  final _toAmountController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _fromCurrency = 'USD';
  String _toCurrency = 'SYP';
  List<String> _supportedCurrencies = ['USD', 'SYP', 'EUR', 'SAR', 'AED', 'TRY'];
  Map<String, double> _balances = {};
  
  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fromAmountController.dispose();
    _toAmountController.dispose();
    super.dispose();
  }
  
  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final walletDoc = await _firestore.collection('wallets').doc(user.uid).get();
        
        if (walletDoc.exists) {
          final walletData = walletDoc.data() as Map<String, dynamic>;
          setState(() {
            _balances = Map<String, double>.from(walletData['balances'] ?? {});
            
            // Ensure all supported currencies have a balance entry
            for (var currency in _supportedCurrencies) {
              _balances[currency] ??= 0.0;
            }
          });
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
  
  void _updateExchangeRate() {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0.0;
    final toAmount = double.tryParse(_toAmountController.text) ?? 0.0;
    
    if (fromAmount > 0 && toAmount > 0) {
      setState(() {
        // Calculate exchange rate
      });
    }
  }
  
  Future<void> _createDeal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0.0;
    final toAmount = double.tryParse(_toAmountController.text) ?? 0.0;
    
    if (fromAmount <= 0 || toAmount <= 0) {
      setState(() {
        _errorMessage = 'الرجاء إدخال مبالغ صحيحة';
      });
      return;
    }
    
    if (fromAmount > (_balances[_fromCurrency] ?? 0.0)) {
      setState(() {
        _errorMessage = 'رصيد غير كافٍ';
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
        // Navigate to PIN verification
        if (!mounted) return;
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PinScreen(isVerification: true),
          ),
        );
        
        // If PIN verification successful
        if (result == true) {
          // Calculate exchange rate
          final exchangeRate = toAmount / fromAmount;
          
          // Create deal
          await _firestore.collection('deals').add({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'fromCurrency': _fromCurrency,
            'toCurrency': _toCurrency,
            'fromAmount': fromAmount,
            'toAmount': toAmount,
            'exchangeRate': exchangeRate,
            'createdBy': user.uid,
            'createdAt': Timestamp.now(),
            'status': 'active',
            'acceptedBy': null,
            'acceptedAt': null,
            'completedAt': null,
          });
          
          // Show success message and return to deals screen
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الصفقة بنجاح')),
          );
          
          Navigator.pop(context, true);
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
  
  String _formatAmount(double amount) {
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء صفقة جديدة'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'عنوان الصفقة',
                        hintText: 'أدخل عنواناً مختصراً للصفقة',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال عنوان الصفقة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'وصف الصفقة (اختياري)',
                        hintText: 'أضف وصفاً للصفقة',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Currency selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'أعرض',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: _fromCurrency,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: _supportedCurrencies.map((currency) {
                                    return DropdownMenuItem<String>(
                                      value: currency,
                                      child: Text(
                                        '$currency (${_getCurrencySymbol(currency)})',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null && value != _fromCurrency) {
                                      setState(() {
                                        _fromCurrency = value;
                                        if (_fromCurrency == _toCurrency) {
                                          _toCurrency = _supportedCurrencies.firstWhere(
                                            (currency) => currency != _fromCurrency,
                                            orElse: () => _supportedCurrencies[0],
                                          );
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                final temp = _fromCurrency;
                                _fromCurrency = _toCurrency;
                                _toCurrency = temp;
                              });
                            },
                            icon: const Icon(Icons.swap_horiz),
                            tooltip: 'تبديل العملات',
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'أطلب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: _toCurrency,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: _supportedCurrencies.map((currency) {
                                    return DropdownMenuItem<String>(
                                      value: currency,
                                      child: Text(
                                        '$currency (${_getCurrencySymbol(currency)})',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null && value != _toCurrency) {
                                      setState(() {
                                        _toCurrency = value;
                                        if (_fromCurrency == _toCurrency) {
                                          _fromCurrency = _supportedCurrencies.firstWhere(
                                            (currency) => currency != _toCurrency,
                                            orElse: () => _supportedCurrencies[0],
                                          );
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Available balance
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
                              'الرصيد المتاح',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_getCurrencySymbol(_fromCurrency)} ${_formatAmount(_balances[_fromCurrency] ?? 0.0)} $_fromCurrency',
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Amounts
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fromAmountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'المبلغ المعروض',
                              hintText: 'أدخل المبلغ',
                              suffixText: _fromCurrency,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال المبلغ';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'الرجاء إدخال مبلغ صحيح';
                              }
                              if (amount > (_balances[_fromCurrency] ?? 0.0)) {
                                return 'المبلغ أكبر من الرصيد المتاح';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _updateExchangeRate();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _toAmountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'المبلغ المطلوب',
                              hintText: 'أدخل المبلغ',
                              suffixText: _toCurrency,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال المبلغ';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'الرجاء إدخال مبلغ صحيح';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _updateExchangeRate();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Create Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createDeal,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'إنشاء الصفقة',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
