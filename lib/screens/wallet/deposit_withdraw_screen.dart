import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/screens/auth/pin_screen.dart';

class DepositWithdrawScreen extends StatefulWidget {
  final bool isDeposit;
  final String selectedCurrency;

  const DepositWithdrawScreen({
    super.key, 
    required this.isDeposit,
    required this.selectedCurrency,
  });

  @override
  State<DepositWithdrawScreen> createState() => _DepositWithdrawScreenState();
}

class _DepositWithdrawScreenState extends State<DepositWithdrawScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _methods = [];
  Map<String, dynamic>? _selectedMethod;
  double _fee = 0.0;
  double _discount = 0.0;
  double _total = 0.0;
  double _balance = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Load payment/withdrawal methods
      final methodsQuery = await _firestore
          .collection(widget.isDeposit ? 'deposit_methods' : 'withdrawal_methods')
          .where('currencies', arrayContains: widget.selectedCurrency)
          .where('isActive', isEqualTo: true)
          .get();
      
      List<Map<String, dynamic>> methods = [];
      
      for (var doc in methodsQuery.docs) {
        final methodData = doc.data();
        methodData['id'] = doc.id;
        methods.add(methodData as Map<String, dynamic>);
      }
      
      // Load user balance
      final user = _auth.currentUser;
      if (user != null) {
        final walletDoc = await _firestore.collection('wallets').doc(user.uid).get();
        
        if (walletDoc.exists) {
          final walletData = walletDoc.data() as Map<String, dynamic>;
          final balances = Map<String, dynamic>.from(walletData['balances'] ?? {});
          
          setState(() {
            _balance = (balances[widget.selectedCurrency] as num?)?.toDouble() ?? 0.0;
          });
        }
      }
      
      // Load commission rates
      final settingsDoc = await _firestore.collection('system_settings').doc('general').get();
      
      if (settingsDoc.exists) {
        final settingsData = settingsDoc.data() as Map<String, dynamic>;
        final commissionRates = Map<String, dynamic>.from(settingsData['commissionRates'] ?? {});
        
        // Get user level for discount
        if (user != null) {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final userLevel = userData['level'] ?? 'bronze';
            
            // Get level discounts
            final levelDiscounts = Map<String, dynamic>.from(settingsData['levelDiscounts'] ?? {});
            
            setState(() {
              // Default commission rate is 1% for deposit, 2% for withdrawal
              double commissionRate = commissionRates[widget.isDeposit ? 'deposit' : 'withdraw']?.toDouble() ?? 
                                      (widget.isDeposit ? 0.01 : 0.02);
              
              // Default discount is 0%
              double discountRate = levelDiscounts[userLevel]?.toDouble() ?? 0.0;
              
              // Calculate fee based on entered amount
              double amount = double.tryParse(_amountController.text) ?? 0.0;
              _fee = amount * commissionRate;
              _discount = _fee * discountRate;
              _total = widget.isDeposit ? amount - _fee + _discount : amount + _fee - _discount;
            });
          }
        }
      }
      
      setState(() {
        _methods = methods;
        if (methods.isNotEmpty) {
          _selectedMethod = methods.first;
        }
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
  
  void _calculateFee() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    setState(() {
      _fee = amount * (widget.isDeposit ? 0.01 : 0.02); // Default rates
      _discount = _fee * 0.0; // Default discount
      _total = widget.isDeposit ? amount - _fee + _discount : amount + _fee - _discount;
    });
  }
  
  Future<void> _processTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedMethod == null) {
      setState(() {
        _errorMessage = 'الرجاء اختيار طريقة ${widget.isDeposit ? 'الإيداع' : 'السحب'}';
      });
      return;
    }
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    if (amount <= 0) {
      setState(() {
        _errorMessage = 'الرجاء إدخال مبلغ صحيح';
      });
      return;
    }
    
    if (!widget.isDeposit && amount > _balance) {
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
          // Create transaction record
          final transactionRef = await _firestore.collection('transactions').add({
            'type': widget.isDeposit ? 'deposit' : 'withdraw',
            'senderId': user.uid,
            'receiverId': user.uid,
            'amount': amount,
            'currency': widget.selectedCurrency,
            'fee': _fee,
            'discount': _discount,
            'status': 'pending',
            'createdAt': Timestamp.now(),
            'completedAt': null,
            'notes': _noteController.text.trim(),
            'methodId': _selectedMethod!['id'],
            'methodName': _selectedMethod!['name'],
            'referenceId': '',
          });
          
          if (widget.isDeposit) {
            // For deposit, create a deposit request
            await _firestore.collection('deposit_requests').add({
              'userId': user.uid,
              'amount': amount,
              'currency': widget.selectedCurrency,
              'fee': _fee,
              'discount': _discount,
              'total': _total,
              'methodId': _selectedMethod!['id'],
              'methodName': _selectedMethod!['name'],
              'status': 'pending',
              'createdAt': Timestamp.now(),
              'completedAt': null,
              'notes': _noteController.text.trim(),
              'transactionId': transactionRef.id,
            });
            
            // Show success message
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إرسال طلب الإيداع بنجاح، سيتم مراجعته من قبل الإدارة')),
            );
          } else {
            // For withdrawal, create a withdrawal request
            await _firestore.collection('withdrawal_requests').add({
              'userId': user.uid,
              'amount': amount,
              'currency': widget.selectedCurrency,
              'fee': _fee,
              'discount': _discount,
              'total': _total,
              'methodId': _selectedMethod!['id'],
              'methodName': _selectedMethod!['name'],
              'status': 'pending',
              'createdAt': Timestamp.now(),
              'completedAt': null,
              'notes': _noteController.text.trim(),
              'transactionId': transactionRef.id,
            });
            
            // Update user's wallet (reduce balance for withdrawal)
            await _firestore.collection('wallets').doc(user.uid).update({
              'balances.${widget.selectedCurrency}': FieldValue.increment(-amount),
              'updatedAt': Timestamp.now(),
            });
            
            // Show success message
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إرسال طلب السحب بنجاح، سيتم مراجعته من قبل الإدارة')),
            );
          }
          
          // Create notification
          await _firestore.collection('notifications').add({
            'userId': user.uid,
            'type': widget.isDeposit ? 'deposit' : 'withdraw',
            'title': widget.isDeposit ? 'طلب إيداع جديد' : 'طلب سحب جديد',
            'message': 'تم استلام طلب ${widget.isDeposit ? 'الإيداع' : 'السحب'} الخاص بك وسيتم مراجعته قريباً',
            'isRead': false,
            'createdAt': Timestamp.now(),
            'data': {
              'transactionId': transactionRef.id,
              'amount': amount,
              'currency': widget.selectedCurrency,
            },
          });
          
          // Return to wallet screen
          if (!mounted) return;
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
        title: Text(widget.isDeposit ? 'إيداع الأموال' : 'سحب الأموال'),
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
                    // Balance (for withdrawal)
                    if (!widget.isDeposit)
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
                                '${_getCurrencySymbol(widget.selectedCurrency)} ${_formatAmount(_balance)} ${widget.selectedCurrency}',
                                style: const TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!widget.isDeposit) const SizedBox(height: 24),
                    
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
                    
                    // Methods
                    if (_methods.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'لا توجد طرق ${widget.isDeposit ? 'إيداع' : 'سحب'} متاحة لهذه العملة',
                          style: TextStyle(color: Colors.orange.shade800),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اختر طريقة ${widget.isDeposit ? 'الإيداع' : 'السحب'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(_methods.length, (index) {
                            final method = _methods[index];
                            final isSelected = _selectedMethod?['id'] == method['id'];
                            
                            return RadioListTile<String>(
                              title: Text(method['name']),
                              subtitle: Text(method['description'] ?? ''),
                              value: method['id'],
                              groupValue: _selectedMethod?['id'],
                              onChanged: (value) {
                                setState(() {
                                  _selectedMethod = method;
                                });
                              },
                              activeColor: Theme.of(context).primaryColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    const SizedBox(height: 24),
                    
                    // Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        hintText: 'أدخل المبلغ',
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: widget.selectedCurrency,
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
                        if (!widget.isDeposit && amount > _balance) {
                          return 'المبلغ أكبر من الرصيد المتاح';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _calculateFee();
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Note
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'ملاحظة (اختياري)',
                        hintText: 'أضف ملاحظة للطلب',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Fee details
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
                              'تفاصيل العملية',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المبلغ:'),
                                Text(
                                  '${_getCurrencySymbol(widget.selectedCurrency)} ${_amountController.text.isEmpty ? '0.00' : _amountController.text} ${widget.selectedCurrency}',
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('رسوم العملية:'),
                                Text(
                                  '${_getCurrencySymbol(widget.selectedCurrency)} ${_formatAmount(_fee)} ${widget.selectedCurrency}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('خصم:'),
                                Text(
                                  '- ${_getCurrencySymbol(widget.selectedCurrency)} ${_formatAmount(_discount)} ${widget.selectedCurrency}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.isDeposit ? 'المبلغ المضاف للرصيد:' : 'المبلغ المستلم:',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_getCurrencySymbol(widget.selectedCurrency)} ${_formatAmount(_total)} ${widget.selectedCurrency}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    ElevatedButton(
                      onPressed: _methods.isEmpty || _isLoading ? null : _processTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: widget.isDeposit ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.isDeposit ? 'إيداع' : 'سحب',
                              style: const TextStyle(fontSize: 18),
                            ),
                    ),
                    
                    // Instructions
                    const SizedBox(height: 24),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isDeposit ? 'تعليمات الإيداع' : 'تعليمات السحب',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isDeposit
                                  ? '1. اختر طريقة الإيداع المناسبة\n'
                                    '2. أدخل المبلغ المراد إيداعه\n'
                                    '3. سيتم مراجعة طلبك من قبل الإدارة\n'
                                    '4. بعد الموافقة، سيتم إضافة المبلغ إلى رصيدك\n'
                                    '5. يمكنك متابعة حالة الطلب في سجل المعاملات'
                                  : '1. اختر طريقة السحب المناسبة\n'
                                    '2. أدخل المبلغ المراد سحبه\n'
                                    '3. سيتم مراجعة طلبك من قبل الإدارة\n'
                                    '4. بعد الموافقة، سيتم تحويل المبلغ إليك\n'
                                    '5. يمكنك متابعة حالة الطلب في سجل المعاملات',
                              style: const TextStyle(fontSize: 14),
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
}
