import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:mpay_app/screens/auth/pin_screen.dart';

class SendScreen extends StatefulWidget {
  final String selectedCurrency;
  final double balance;

  const SendScreen({
    super.key,
    required this.selectedCurrency,
    required this.balance,
  });

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _formKey = GlobalKey<FormState>();
  final _receiverWalletController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  double _fee = 0.0;
  double _discount = 0.0;
  double _total = 0.0;
  String _receiverName = '';
  bool _receiverFound = false;
  
  @override
  void initState() {
    super.initState();
    _calculateFee();
  }
  
  @override
  void dispose() {
    _receiverWalletController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  void _calculateFee() async {
    try {
      // Get commission rates from system settings
      final settingsDoc = await _firestore.collection('system_settings').doc('general').get();
      
      if (settingsDoc.exists) {
        final settingsData = settingsDoc.data() as Map<String, dynamic>;
        final commissionRates = Map<String, dynamic>.from(settingsData['commissionRates'] ?? {});
        
        // Get user level for discount
        final user = _auth.currentUser;
        if (user != null) {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final userLevel = userData['level'] ?? 'bronze';
            
            // Get level discounts
            final levelDiscounts = Map<String, dynamic>.from(settingsData['levelDiscounts'] ?? {});
            
            setState(() {
              // Default commission rate is 2%
              double commissionRate = commissionRates['send']?.toDouble() ?? 0.02;
              
              // Default discount is 0%
              double discountRate = levelDiscounts[userLevel]?.toDouble() ?? 0.0;
              
              // Calculate fee based on entered amount
              double amount = double.tryParse(_amountController.text) ?? 0.0;
              _fee = amount * commissionRate;
              _discount = _fee * discountRate;
              _total = amount + _fee - _discount;
            });
          }
        }
      }
    } catch (e) {
      print('Error calculating fee: $e');
    }
  }
  
  Future<void> _searchReceiver() async {
    final receiverWalletId = _receiverWalletController.text.trim();
    
    if (receiverWalletId.isEmpty) {
      setState(() {
        _receiverFound = false;
        _receiverName = '';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Check if wallet exists
      final walletDoc = await _firestore.collection('wallets').doc(receiverWalletId).get();
      
      if (walletDoc.exists) {
        // Get user info
        final userDoc = await _firestore.collection('users').doc(receiverWalletId).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _receiverFound = true;
            _receiverName = '${userData['firstName']} ${userData['lastName']}';
          });
        } else {
          setState(() {
            _receiverFound = true;
            _receiverName = 'مستخدم Mpay';
          });
        }
      } else {
        setState(() {
          _receiverFound = false;
          _receiverName = '';
          _errorMessage = 'لم يتم العثور على المستلم';
        });
      }
    } catch (e) {
      setState(() {
        _receiverFound = false;
        _receiverName = '';
        _errorMessage = 'حدث خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _sendMoney() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (!_receiverFound) {
      setState(() {
        _errorMessage = 'الرجاء التحقق من رمز محفظة المستلم';
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
    
    if (_total > widget.balance) {
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
          // Create transaction
          final transactionRef = await _firestore.collection('transactions').add({
            'type': 'send',
            'senderId': user.uid,
            'receiverId': _receiverWalletController.text.trim(),
            'amount': amount,
            'currency': widget.selectedCurrency,
            'fee': _fee,
            'discount': _discount,
            'status': 'pending',
            'createdAt': Timestamp.now(),
            'completedAt': null,
            'notes': _noteController.text.trim(),
            'referenceId': '',
          });
          
          // Update sender's wallet
          await _firestore.collection('wallets').doc(user.uid).update({
            'balances.${widget.selectedCurrency}': FieldValue.increment(-_total),
            'updatedAt': Timestamp.now(),
          });
          
          // Update receiver's wallet
          await _firestore.collection('wallets').doc(_receiverWalletController.text.trim()).update({
            'balances.${widget.selectedCurrency}': FieldValue.increment(amount),
            'updatedAt': Timestamp.now(),
          });
          
          // Update transaction status
          await _firestore.collection('transactions').doc(transactionRef.id).update({
            'status': 'completed',
            'completedAt': Timestamp.now(),
          });
          
          // Create notification for receiver
          await _firestore.collection('notifications').add({
            'userId': _receiverWalletController.text.trim(),
            'type': 'transaction',
            'title': 'استلام أموال',
            'message': 'تم استلام ${amount.toString()} ${widget.selectedCurrency} من ${user.displayName ?? 'مستخدم Mpay'}',
            'isRead': false,
            'createdAt': Timestamp.now(),
            'data': {
              'transactionId': transactionRef.id,
              'amount': amount,
              'currency': widget.selectedCurrency,
            },
          });
          
          // Show success message and return to wallet screen
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال الأموال بنجاح')),
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
        title: const Text('إرسال الأموال'),
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
                    // Balance
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
                              '${_getCurrencySymbol(widget.selectedCurrency)} ${_formatAmount(widget.balance)} ${widget.selectedCurrency}',
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
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
                    
                    // Receiver Wallet ID
                    TextFormField(
                      controller: _receiverWalletController,
                      decoration: InputDecoration(
                        labelText: 'رمز محفظة المستلم',
                        hintText: 'أدخل رمز محفظة المستلم',
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchReceiver,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رمز محفظة المستلم';
                        }
                        if (value == _auth.currentUser?.uid) {
                          return 'لا يمكنك إرسال الأموال لنفسك';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _searchReceiver();
                        } else {
                          setState(() {
                            _receiverFound = false;
                            _receiverName = '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Receiver info
                    if (_receiverFound && _receiverName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'المستلم: $_receiverName',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    
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
                        if (amount > widget.balance) {
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
                        hintText: 'أضف ملاحظة للمستلم',
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
                                const Text('رسوم التحويل:'),
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
                                const Text(
                                  'المجموع:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                    
                    // Send Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendMoney,
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
                              'إرسال',
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
