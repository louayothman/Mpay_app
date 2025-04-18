import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/screens/auth/pin_screen.dart';

class ExchangeScreen extends StatefulWidget {
  final Map<String, double> balances;
  final String selectedCurrency;

  const ExchangeScreen({
    super.key,
    required this.balances,
    required this.selectedCurrency,
  });

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _fromCurrency = '';
  String _toCurrency = '';
  List<String> _supportedCurrencies = ['USD', 'SYP', 'EUR', 'SAR', 'AED', 'TRY'];
  Map<String, Map<String, double>> _exchangeRates = {};
  double _exchangeRate = 0.0;
  double _toAmount = 0.0;
  double _fee = 0.0;
  double _discount = 0.0;
  double _total = 0.0;
  
  @override
  void initState() {
    super.initState();
    _fromCurrency = widget.selectedCurrency;
    _toCurrency = _supportedCurrencies.firstWhere(
      (currency) => currency != _fromCurrency,
      orElse: () => _supportedCurrencies[0],
    );
    _loadExchangeRates();
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
  
  Future<void> _loadExchangeRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get exchange rates from system settings
      final settingsDoc = await _firestore.collection('system_settings').doc('general').get();
      
      if (settingsDoc.exists) {
        final settingsData = settingsDoc.data() as Map<String, dynamic>;
        final rates = Map<String, dynamic>.from(settingsData['exchangeRates'] ?? {});
        
        // Convert to proper format
        Map<String, Map<String, double>> formattedRates = {};
        
        for (var entry in rates.entries) {
          final key = entry.key;
          if (key.contains('_')) {
            final currencies = key.split('_');
            final fromCurrency = currencies[0];
            final toCurrency = currencies[1];
            
            formattedRates[fromCurrency] ??= {};
            formattedRates[fromCurrency]![toCurrency] = (entry.value as num).toDouble();
          }
        }
        
        setState(() {
          _exchangeRates = formattedRates;
          _updateExchangeRate();
        });
        
        // Get commission rates and user level for discount
        final commissionRates = Map<String, dynamic>.from(settingsData['commissionRates'] ?? {});
        
        final user = _auth.currentUser;
        if (user != null) {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final userLevel = userData['level'] ?? 'bronze';
            
            // Get level discounts
            final levelDiscounts = Map<String, dynamic>.from(settingsData['levelDiscounts'] ?? {});
            
            setState(() {
              // Default commission rate is 5%
              double commissionRate = commissionRates['exchange']?.toDouble() ?? 0.05;
              
              // Default discount is 0%
              double discountRate = levelDiscounts[userLevel]?.toDouble() ?? 0.0;
              
              // Calculate fee based on entered amount
              double amount = double.tryParse(_amountController.text) ?? 0.0;
              _fee = amount * commissionRate;
              _discount = _fee * discountRate;
              _total = amount + _fee - _discount;
              
              // Calculate to amount
              _calculateToAmount();
            });
          }
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
  
  void _updateExchangeRate() {
    if (_exchangeRates.containsKey(_fromCurrency) && 
        _exchangeRates[_fromCurrency]!.containsKey(_toCurrency)) {
      setState(() {
        _exchangeRate = _exchangeRates[_fromCurrency]![_toCurrency]!;
        _calculateToAmount();
      });
    } else {
      setState(() {
        _exchangeRate = 0.0;
        _toAmount = 0.0;
      });
    }
  }
  
  void _calculateToAmount() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _toAmount = amount * _exchangeRate;
    });
  }
  
  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _updateExchangeRate();
    });
  }
  
  Future<void> _exchange() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    if (amount <= 0) {
      setState(() {
        _errorMessage = 'الرجاء إدخال مبلغ صحيح';
      });
      return;
    }
    
    if (_total > (widget.balances[_fromCurrency] ?? 0.0)) {
      setState(() {
        _errorMessage = 'رصيد غير كافٍ';
      });
      return;
    }
    
    if (_exchangeRate <= 0) {
      setState(() {
        _errorMessage = 'سعر الصرف غير متوفر';
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
          // Create exchange record
          final exchangeRef = await _firestore.collection('exchanges').add({
            'userId': user.uid,
            'fromCurrency': _fromCurrency,
            'toCurrency': _toCurrency,
            'fromAmount': amount,
            'toAmount': _toAmount,
            'exchangeRate': _exchangeRate,
            'fee': _fee,
            'discount': _discount,
            'createdAt': Timestamp.now(),
            'status': 'pending',
          });
          
          // Update user's wallet
          await _firestore.collection('wallets').doc(user.uid).update({
            'balances.$_fromCurrency': FieldValue.increment(-_total),
            'balances.$_toCurrency': FieldValue.increment(_toAmount),
            'updatedAt': Timestamp.now(),
          });
          
          // Update exchange status
          await _firestore.collection('exchanges').doc(exchangeRef.id).update({
            'status': 'completed',
          });
          
          // Create transaction record
          await _firestore.collection('transactions').add({
            'type': 'exchange',
            'senderId': user.uid,
            'receiverId': user.uid,
            'amount': amount,
            'currency': _fromCurrency,
            'fee': _fee,
            'discount': _discount,
            'status': 'completed',
            'createdAt': Timestamp.now(),
            'completedAt': Timestamp.now(),
            'notes': 'تحويل من $_fromCurrency إلى $_toCurrency',
            'referenceId': exchangeRef.id,
          });
          
          // Create notification
          await _firestore.collection('notifications').add({
            'userId': user.uid,
            'type': 'exchange',
            'title': 'مبادلة ناجحة',
            'message': 'تم تحويل ${amount.toString()} $_fromCurrency إلى ${_toAmount.toStringAsFixed(2)} $_toCurrency',
            'isRead': false,
            'createdAt': Timestamp.now(),
            'data': {
              'exchangeId': exchangeRef.id,
              'fromAmount': amount,
              'fromCurrency': _fromCurrency,
              'toAmount': _toAmount,
              'toCurrency': _toCurrency,
            },
          });
          
          // Show success message and return to wallet screen
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت المبادلة بنجاح')),
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
        title: const Text('مبادلة العملات'),
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
                    
                    // Currency selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'من',
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
                                        _updateExchangeRate();
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
                            onPressed: _swapCurrencies,
                            icon: const Icon(Icons.swap_horiz),
                            tooltip: 'تبديل العملات',
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إلى',
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
                                        _updateExchangeRate();
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
                    
                    // Exchange rate
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'سعر الصرف',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1 $_fromCurrency = ${_formatAmount(_exchangeRate)} $_toCurrency',
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                              '${_getCurrencySymbol(_fromCurrency)} ${_formatAmount(widget.balances[_fromCurrency] ?? 0.0)} $_fromCurrency',
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        if (amount > (widget.balances[_fromCurrency] ?? 0.0)) {
                          return 'المبلغ أكبر من الرصيد المتاح';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _calculateToAmount();
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // To amount
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المبلغ بعد التحويل',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_getCurrencySymbol(_toCurrency)} ${_formatAmount(_toAmount)} $_toCurrency',
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
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
                                  '${_getCurrencySymbol(_fromCurrency)} ${_amountController.text.isEmpty ? '0.00' : _amountController.text} $_fromCurrency',
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('رسوم التحويل:'),
                                Text(
                                  '${_getCurrencySymbol(_fromCurrency)} ${_formatAmount(_fee)} $_fromCurrency',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('خصم:'),
                                Text(
                                  '- ${_getCurrencySymbol(_fromCurrency)} ${_formatAmount(_discount)} $_fromCurrency',
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
                                  '${_getCurrencySymbol(_fromCurrency)} ${_formatAmount(_total)} $_fromCurrency',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Exchange Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _exchange,
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
                              'تنفيذ المبادلة',
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
