import 'package:flutter/material.dart';
import 'package:mpay_app/services/firestore_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mpay_app/utils/performance_optimizer.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  
  String _selectedMethod = 'USDT (TRC20)';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _walletAddressController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _walletData;
  bool _isLoadingWallet = true;
  
  final List<String> _withdrawalMethods = [
    'USDT (TRC20)',
    'USDT (ERC20)',
    'Bitcoin (BTC)',
    'Ethereum (ETH)',
    'Sham cash',
  ];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoadingWallet = true;
    });
    
    try {
      final walletData = await _firestoreService.getWalletData(
        context: context,
        showLoading: false,
      );
      
      if (mounted) {
        setState(() {
          _walletData = walletData;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
        });
        ErrorHandler.showErrorSnackBar(
          context, 
          'فشل في تحميل بيانات المحفظة: $e'
        );
      }
    }
  }

  double _getAvailableBalance() {
    if (_walletData == null || !_walletData!.containsKey('balances')) {
      return 0.0;
    }
    
    final balances = _walletData!['balances'] as Map<String, dynamic>?;
    if (balances == null) {
      return 0.0;
    }
    
    // Extract currency from selected method
    String currency = _selectedMethod.split(' ')[0];
    if (_selectedMethod == 'Sham cash') {
      currency = 'ShamCash';
    }
    
    return balances[currency] as double? ?? 0.0;
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('لم يتم العثور على المستخدم');
      }
      
      final amount = double.parse(_amountController.text);
      final availableBalance = _getAvailableBalance();
      
      if (amount > availableBalance) {
        throw Exception('المبلغ المطلوب أكبر من الرصيد المتاح');
      }
      
      // Create withdrawal transaction
      final withdrawalData = {
        'userId': user.uid,
        'type': 'withdrawal',
        'method': _selectedMethod,
        'amount': amount,
        'status': 'pending',
        'walletAddress': _walletAddressController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'notes': 'بانتظار المراجعة من قبل المشرف',
      };
      
      // Create transaction
      await _firestoreService.createTransaction(
        context: context,
        transactionData: withdrawalData,
        showLoading: false,
      );
      
      // Update wallet balance (deduct amount)
      String currency = _selectedMethod.split(' ')[0];
      if (_selectedMethod == 'Sham cash') {
        currency = 'ShamCash';
      }
      
      await _firestoreService.updateWalletBalance(
        context: context,
        userId: user.uid,
        currency: currency,
        amount: -amount, // Negative amount for withdrawal
        showLoading: false,
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب السحب بنجاح وهو قيد المراجعة'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        setState(() {
          _amountController.clear();
          _walletAddressController.clear();
        });
        
        // Reload wallet data
        _loadWalletData();
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'فشل في إرسال طلب السحب: $e'
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _walletAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlingWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سحب الأموال'),
        ),
        body: _isLoadingWallet
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instructions card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تعليمات السحب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '1. اختر طريقة السحب المفضلة لديك\n'
                                '2. أدخل عنوان محفظتك الخاص بالعملة المختارة\n'
                                '3. أدخل المبلغ المراد سحبه\n'
                                '4. انقر على زر "إرسال طلب السحب"\n'
                                '5. انتظر موافقة المشرف على طلبك',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.amber),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'سيتم خصم المبلغ من محفظتك فوراً، وسيتم إرسال المبلغ إلى عنوان محفظتك بعد مراجعة الطلب من قبل المشرف',
                                        style: TextStyle(fontSize: 12),
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
                      
                      // Available balance
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الرصيد المتاح',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _getAvailableBalance().toString(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedMethod.split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Withdrawal method selection
                      const Text(
                        'اختر طريقة السحب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedMethod,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: _withdrawalMethods.map((String method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedMethod = newValue;
                            });
                          }
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Wallet address input
                      const Text(
                        'عنوان المحفظة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _walletAddressController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'أدخل عنوان محفظتك',
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال عنوان المحفظة';
                          }
                          
                          // Validate wallet address format based on selected method
                          if (_selectedMethod.contains('TRC20') && !value.startsWith('T')) {
                            return 'عنوان محفظة USDT (TRC20) غير صالح';
                          } else if (_selectedMethod.contains('ERC20') && !value.startsWith('0x')) {
                            return 'عنوان محفظة USDT (ERC20) غير صالح';
                          } else if (_selectedMethod.contains('BTC') && 
                                    !(value.startsWith('1') || value.startsWith('3') || value.startsWith('bc1'))) {
                            return 'عنوان محفظة Bitcoin غير صالح';
                          } else if (_selectedMethod.contains('ETH') && !value.startsWith('0x')) {
                            return 'عنوان محفظة Ethereum غير صالح';
                          }
                          
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Amount input
                      const Text(
                        'المبلغ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'أدخل مبلغ السحب',
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال المبلغ';
                          }
                          
                          try {
                            final amount = double.parse(value);
                            if (amount <= 0) {
                              return 'يجب أن يكون المبلغ أكبر من صفر';
                            }
                            
                            final availableBalance = _getAvailableBalance();
                            if (amount > availableBalance) {
                              return 'المبلغ المطلوب أكبر من الرصيد المتاح';
                            }
                          } catch (e) {
                            return 'الرجاء إدخال مبلغ صحيح';
                          }
                          
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitWithdrawal,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'إرسال طلب السحب',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
