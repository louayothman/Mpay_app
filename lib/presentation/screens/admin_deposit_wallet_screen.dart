import 'package:flutter/material.dart';
import 'package:mpay_app/business/admin_dashboard_manager.dart';
import 'package:mpay_app/utils/currency_converter.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/presentation/widgets/custom_app_bar.dart';
import 'package:mpay_app/presentation/widgets/custom_button.dart';
import 'package:mpay_app/presentation/widgets/loading_indicator.dart';
import 'package:mpay_app/presentation/widgets/error_dialog.dart';
import 'package:mpay_app/presentation/widgets/success_dialog.dart';

/// شاشة إدارة محافظ الإيداع للمشرف
///
/// تتيح هذه الشاشة للمشرف إدارة عناوين محافظ الإيداع لطرق الإيداع المختلفة
class AdminDepositWalletScreen extends StatefulWidget {
  final String adminId;
  
  const AdminDepositWalletScreen({
    Key? key,
    required this.adminId,
  }) : super(key: key);
  
  @override
  _AdminDepositWalletScreenState createState() => _AdminDepositWalletScreenState();
}

class _AdminDepositWalletScreenState extends State<AdminDepositWalletScreen> {
  final AdminDashboardManager _adminManager = AdminDashboardManager(
    apiService: ApiIntegrationService(),
    firebaseService: FirebaseService(),
    errorHandler: ErrorHandler(),
    currencyConverter: CurrencyConverter(
      apiService: ApiIntegrationService(),
      firebaseService: FirebaseService(),
      errorHandler: ErrorHandler(),
    ),
  );
  
  // عناوين محافظ الإيداع الحالية
  Map<String, String> _currentDepositWalletAddresses = {};
  
  // حالة التحميل
  bool _isLoading = true;
  
  // حالة التحديث
  bool _isUpdating = false;
  
  // طريقة الإيداع المحددة للإضافة
  String _newDepositMethod = '';
  String _newDepositWalletAddress = '';
  
  // وحدات التحكم في النص لعناوين المحافظ
  final Map<String, TextEditingController> _addressControllers = {};
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    // التخلص من وحدات التحكم في النص
    for (final controller in _addressControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  /// تحميل البيانات
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // تحميل عناوين محافظ الإيداع
      final depositWalletAddresses = await _adminManager.getAllDepositWalletAddresses();
      
      // إنشاء وحدات تحكم في النص لكل عنوان
      for (final entry in depositWalletAddresses.entries) {
        _addressControllers[entry.key] = TextEditingController(text: entry.value);
      }
      
      setState(() {
        _currentDepositWalletAddresses = depositWalletAddresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            message: 'فشل في تحميل البيانات: ${e.toString()}',
          ),
        );
      }
    }
  }
  
  /// تحديث عنوان محفظة الإيداع
  Future<void> _updateDepositWalletAddress(String currency, String newAddress) async {
    if (newAddress.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'عنوان المحفظة لا يمكن أن يكون فارغًا',
        ),
      );
      return;
    }
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final success = await _adminManager.updateDepositWalletAddress(
        currency,
        newAddress,
        widget.adminId,
      );
      
      setState(() {
        _isUpdating = false;
      });
      
      if (success) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => SuccessDialog(
              message: 'تم تحديث عنوان محفظة الإيداع بنجاح',
            ),
          );
          
          // تحديث البيانات
          _loadData();
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(
              message: 'فشل في تحديث عنوان محفظة الإيداع',
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            message: 'فشل في تحديث عنوان محفظة الإيداع: ${e.toString()}',
          ),
        );
      }
    }
  }
  
  /// إضافة طريقة إيداع جديدة
  Future<void> _addNewDepositMethod() async {
    if (_newDepositMethod.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'اسم طريقة الإيداع لا يمكن أن يكون فارغًا',
        ),
      );
      return;
    }
    
    if (_newDepositWalletAddress.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'عنوان المحفظة لا يمكن أن يكون فارغًا',
        ),
      );
      return;
    }
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final success = await _adminManager.addNewDepositMethod(
        _newDepositMethod,
        _newDepositWalletAddress,
        widget.adminId,
      );
      
      setState(() {
        _isUpdating = false;
        _newDepositMethod = '';
        _newDepositWalletAddress = '';
      });
      
      if (success) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => SuccessDialog(
              message: 'تم إضافة طريقة الإيداع الجديدة بنجاح',
            ),
          );
          
          // تحديث البيانات
          _loadData();
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(
              message: 'فشل في إضافة طريقة الإيداع الجديدة',
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            message: 'فشل في إضافة طريقة الإيداع الجديدة: ${e.toString()}',
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'إدارة محافظ الإيداع',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'عناوين محافظ الإيداع الحالية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._currentDepositWalletAddresses.entries.map((entry) {
                        final currency = entry.key;
                        final controller = _addressControllers[currency]!;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getDepositMethodName(currency),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'عنوان المحفظة',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CustomButton(
                                      text: 'تحديث',
                                      onPressed: () => _updateDepositWalletAddress(
                                        currency,
                                        controller.text,
                                      ),
                                      width: 120,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'إضافة طريقة إيداع جديدة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                onChanged: (value) => _newDepositMethod = value,
                                decoration: const InputDecoration(
                                  labelText: 'اسم طريقة الإيداع',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                onChanged: (value) => _newDepositWalletAddress = value,
                                decoration: const InputDecoration(
                                  labelText: 'عنوان المحفظة',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  CustomButton(
                                    text: 'إضافة',
                                    onPressed: _addNewDepositMethod,
                                    width: 120,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'ملاحظات هامة:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• تأكد من صحة عناوين المحافظ قبل التحديث.\n'
                        '• يجب أن تكون عناوين المحافظ متوافقة مع معايير كل عملة رقمية.\n'
                        '• يتم استخدام هذه العناوين في عمليات الإيداع من قبل المستخدمين.\n'
                        '• تغيير عنوان المحفظة يؤثر فقط على المعاملات الجديدة.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (_isUpdating)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: LoadingIndicator()),
                  ),
              ],
            ),
    );
  }
  
  /// الحصول على اسم طريقة الإيداع
  String _getDepositMethodName(String methodCode) {
    switch (methodCode) {
      case 'USDT':
        return 'تيثر (USDT)';
      case 'BTC':
        return 'بيتكوين (BTC)';
      case 'ETH':
        return 'إيثريوم (ETH)';
      case 'ShamCash':
        return 'شام كاش';
      default:
        return methodCode;
    }
  }
}
