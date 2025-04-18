import 'package:flutter/material.dart';
import 'package:mpay_app/services/firestore_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mpay_app/services/storage_service.dart';
import 'package:mpay_app/utils/wallet_validator.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({Key? key}) : super(key: key);

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedMethod = 'USDT (TRC20)';
  final TextEditingController _amountController = TextEditingController();
  File? _receiptImage;
  bool _isLoading = false;
  String? _walletAddress;
  bool _isWalletAddressValid = true;
  String? _walletAddressError;
  
  final Map<String, String> _depositMethods = {
    'USDT (TRC20)': 'TNeMH7gG6KQW2dBirivmx21UmPmirpCXM7',
    'USDT (ERC20)': '0xee87AF29a5d8E2Fce943E8Aa026C69aDaB8bA5d7',
    'Bitcoin (BTC)': 'bc1qn5zte2eme8e7ypja7zug3au074cwtlywkpqwaw',
    'Ethereum (ETH)': '0xee87AF29a5d8E2Fce943E8Aa026C69aDaB8bA5d7',
    'Sham cash': 'f556772f72f0f6da35ea463e3c57942d',
  };

  @override
  void initState() {
    super.initState();
    _updateWalletAddress();
  }

  void _updateWalletAddress() {
    setState(() {
      _walletAddress = _depositMethods[_selectedMethod];
      _validateWalletAddress();
    });
  }

  // التحقق من صحة عنوان المحفظة
  void _validateWalletAddress() {
    if (_walletAddress == null || _walletAddress!.isEmpty) {
      setState(() {
        _isWalletAddressValid = false;
        _walletAddressError = 'عنوان المحفظة غير متوفر';
      });
      return;
    }

    try {
      bool isValid = false;
      String network = '';

      // التحقق من نوع العنوان بناءً على طريقة الإيداع المختارة
      if (_selectedMethod.contains('USDT (TRC20)')) {
        isValid = WalletValidator.validate(
          address: _walletAddress!,
          network: 'tron',
        );
        network = 'Tron (TRC20)';
      } else if (_selectedMethod.contains('USDT (ERC20)') || _selectedMethod.contains('Ethereum')) {
        isValid = WalletValidator.validate(
          address: _walletAddress!,
          network: 'ethereum',
        );
        network = 'Ethereum (ERC20)';
      } else if (_selectedMethod.contains('Bitcoin')) {
        isValid = WalletValidator.validate(
          address: _walletAddress!,
          network: 'bitcoin',
        );
        network = 'Bitcoin';
      } else if (_selectedMethod.contains('Sham cash')) {
        // للتحقق من صحة عنوان Sham cash (نفترض أنه يجب أن يكون 32 حرفًا من الأحرف الستة عشرية)
        final RegExp shamCashRegex = RegExp(r'^[a-f0-9]{32}$');
        isValid = shamCashRegex.hasMatch(_walletAddress!);
        network = 'Sham cash';
      }

      setState(() {
        _isWalletAddressValid = isValid;
        if (!isValid) {
          _walletAddressError = 'عنوان $network غير صالح';
        } else {
          _walletAddressError = null;
        }
      });
    } catch (e) {
      setState(() {
        _isWalletAddressValid = false;
        _walletAddressError = 'خطأ في التحقق من العنوان: $e';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'فشل في اختيار الصورة: $e'
      );
    }
  }

  Future<void> _submitDeposit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (!_isWalletAddressValid) {
      ErrorHandler.showErrorSnackBar(
        context, 
        _walletAddressError ?? 'عنوان المحفظة غير صالح'
      );
      return;
    }
    
    if (_receiptImage == null) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'الرجاء إرفاق صورة إيصال الإيداع'
      );
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
      
      // Upload receipt image
      final String? imageUrl = await _storageService.uploadTransactionReceipt(
        context: context,
        file: _receiptImage!,
        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
        showLoading: false,
      );
      
      if (imageUrl == null) {
        throw Exception('فشل في رفع صورة الإيصال');
      }
      
      // Create deposit transaction
      final depositData = {
        'userId': user.uid,
        'type': 'deposit',
        'method': _selectedMethod,
        'amount': double.parse(_amountController.text),
        'status': 'pending',
        'receiptUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'notes': 'بانتظار المراجعة من قبل المشرف',
        'walletAddress': _walletAddress, // تخزين عنوان المحفظة المستخدم
      };
      
      await _firestoreService.createTransaction(
        context: context,
        transactionData: depositData,
        showLoading: false,
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب الإيداع بنجاح وهو قيد المراجعة'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        setState(() {
          _amountController.clear();
          _receiptImage = null;
        });
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'فشل في إرسال طلب الإيداع: $e'
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlingWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إيداع الأموال'),
        ),
        body: SingleChildScrollView(
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
                          'تعليمات الإيداع',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. اختر طريقة الإيداع المفضلة لديك\n'
                          '2. قم بتحويل المبلغ إلى العنوان المعروض\n'
                          '3. التقط صورة للإيصال أو لقطة شاشة تثبت التحويل\n'
                          '4. أدخل المبلغ وأرفق الصورة\n'
                          '5. انقر على زر "إرسال طلب الإيداع"\n'
                          '6. انتظر موافقة المشرف على طلبك',
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
                                  'سيتم إضافة الرصيد إلى محفظتك بعد مراجعة طلبك من قبل المشرف',
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
                
                // Deposit method selection
                const Text(
                  'اختر طريقة الإيداع',
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
                  items: _depositMethods.keys.map((String method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMethod = newValue;
                        _updateWalletAddress();
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Wallet address
                const Text(
                  'عنوان المحفظة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isWalletAddressValid ? Colors.grey.shade300 : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _isWalletAddressValid ? Colors.grey.shade50 : Colors.red.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _walletAddress ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_walletAddressError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _walletAddressError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!_isWalletAddressValid)
                            TextButton.icon(
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('تحديث'),
                              onPressed: _validateWalletAddress,
                            ),
                          TextButton.icon(
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('نسخ'),
                            onPressed: () {
                              if (_walletAddress != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ العنوان'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'أدخل مبلغ الإيداع',
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
                    } catch (e) {
                      return 'الرجاء إدخال مبلغ صحيح';
                    }
                    
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Receipt image upload
                const Text(
                  'صورة الإيصال',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: _receiptImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _receiptImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'انقر لإضافة صورة الإيصال',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitDeposit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'إرسال طلب الإيداع',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
