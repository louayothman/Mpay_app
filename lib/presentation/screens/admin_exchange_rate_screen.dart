import 'package:flutter/material.dart';
import 'package:mpay_app/business/admin_dashboard_manager.dart';
import 'package:mpay_app/utils/currency_converter.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/presentation/widgets/custom_app_bar.dart';
import 'package:mpay_app/presentation/widgets/custom_button.dart';
import 'package:mpay_app/presentation/widgets/custom_text_field.dart';
import 'package:mpay_app/presentation/widgets/loading_indicator.dart';
import 'package:mpay_app/presentation/widgets/error_dialog.dart';
import 'package:mpay_app/presentation/widgets/success_dialog.dart';

/// شاشة إدارة أسعار الصرف للمشرف
///
/// تتيح هذه الشاشة للمشرف تحديث أسعار الصرف ورسوم المعاملات للعملات المختلفة
class AdminExchangeRateScreen extends StatefulWidget {
  final String adminId;
  
  const AdminExchangeRateScreen({
    Key? key,
    required this.adminId,
  }) : super(key: key);
  
  @override
  _AdminExchangeRateScreenState createState() => _AdminExchangeRateScreenState();
}

class _AdminExchangeRateScreenState extends State<AdminExchangeRateScreen> with SingleTickerProviderStateMixin {
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
  
  final CurrencyConverter _currencyConverter = CurrencyConverter(
    apiService: ApiIntegrationService(),
    firebaseService: FirebaseService(),
    errorHandler: ErrorHandler(),
  );
  
  late TabController _tabController;
  
  // أسعار الصرف الحالية
  Map<String, double> _currentExchangeRates = {};
  
  // رسوم المعاملات الحالية
  Map<String, double> _currentTransactionFees = {};
  
  // عناوين محافظ الإيداع الحالية
  Map<String, String> _currentDepositWalletAddresses = {};
  
  // حالة التحميل
  bool _isLoading = true;
  
  // حالة التحديث
  bool _isUpdating = false;
  
  // العملة المحددة للإضافة
  String _newCurrencyCode = '';
  double _newCurrencyRate = 0.0;
  double _newCurrencyFee = 1.0;
  
  // طريقة الإيداع المحددة للإضافة
  String _newDepositMethod = '';
  String _newDepositWalletAddress = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// تحميل البيانات
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // تحميل أسعار الصرف
      final exchangeRates = await _adminManager.getAllExchangeRates();
      
      // تحميل رسوم المعاملات
      final transactionFees = await _adminManager.getAllTransactionFees();
      
      // تحميل عناوين محافظ الإيداع
      final depositWalletAddresses = await _adminManager.getAllDepositWalletAddresses();
      
      setState(() {
        _currentExchangeRates = exchangeRates;
        _currentTransactionFees = transactionFees;
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
  
  /// تحديث سعر الصرف
  Future<void> _updateExchangeRate(String currency, double newRate) async {
    if (newRate <= 0) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'سعر الصرف يجب أن يكون أكبر من صفر',
        ),
      );
      return;
    }
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final success = await _adminManager.updateExchangeRate(
        currency,
        newRate,
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
              message: 'تم تحديث سعر الصرف بنجاح',
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
              message: 'فشل في تحديث سعر الصرف',
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
            message: 'فشل في تحديث سعر الصرف: ${e.toString()}',
          ),
        );
      }
    }
  }
  
  /// تحديث رسوم المعاملات
  Future<void> _updateTransactionFee(String currency, double newFee) async {
    if (newFee < 0 || newFee > 10) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'رسوم المعاملات يجب أن تكون بين 0% و 10%',
        ),
      );
      return;
    }
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final success = await _adminManager.updateTransactionFee(
        currency,
        newFee,
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
              message: 'تم تحديث رسوم المعاملات بنجاح',
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
              message: 'فشل في تحديث رسوم المعاملات',
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
            message: 'فشل في تحديث رسوم المعاملات: ${e.toString()}',
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
  
  /// إضافة عملة جديدة
  Future<void> _addNewCurrency() async {
    if (_newCurrencyCode.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'رمز العملة لا يمكن أن يكون فارغًا',
        ),
      );
      return;
    }
    
    if (_newCurrencyRate <= 0) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'سعر الصرف يجب أن يكون أكبر من صفر',
        ),
      );
      return;
    }
    
    if (_newCurrencyFee < 0 || _newCurrencyFee > 10) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'رسوم المعاملات يجب أن تكون بين 0% و 10%',
        ),
      );
      return;
    }
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final success = await _adminManager.addNewCurrency(
        _newCurrencyCode,
        _newCurrencyRate,
        _newCurrencyFee,
        widget.adminId,
      );
      
      setState(() {
        _isUpdating = false;
        _newCurrencyCode = '';
        _newCurrencyRate = 0.0;
        _newCurrencyFee = 1.0;
      });
      
      if (success) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => SuccessDialog(
              message: 'تم إضافة العملة الجديدة بنجاح',
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
              message: 'فشل في إضافة العملة الجديدة',
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
            message: 'فشل في إضافة العملة الجديدة: ${e.toString()}',
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
        title: 'إدارة العملات وطرق الإيداع',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'أسعار الصرف'),
                    Tab(text: 'رسوم المعاملات'),
                    Tab(text: 'محافظ الإيداع'),
                  ],
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExchangeRatesTab(),
                      _buildTransactionFeesTab(),
                      _buildDepositWalletsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  /// بناء علامة تبويب أسعار الصرف
  Widget _buildExchangeRatesTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أسعار الصرف الحالية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._currentExchangeRates.entries.map((entry) {
                final currency = entry.key;
                final rate = entry.value;
                final controller = TextEditingController(text: rate.toString());
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _getCurrencyName(currency),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          hintText: 'سعر الصرف',
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        text: 'تحديث',
                        onPressed: () => _updateExchangeRate(
                          currency,
                          double.tryParse(controller.text) ?? rate,
                        ),
                        width: 100,
                      ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'إضافة عملة جديدة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      onChanged: (value) => _newCurrencyCode = value,
                      hintText: 'رمز العملة (مثل USD)',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      onChanged: (value) => _newCurrencyRate = double.tryParse(value) ?? 0.0,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hintText: 'سعر الصرف',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      onChanged: (value) => _newCurrencyFee = double.tryParse(value) ?? 1.0,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hintText: 'رسوم المعاملات (%)',
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: 'إضافة',
                    onPressed: _addNewCurrency,
                    width: 100,
                  ),
                ],
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
    );
  }
  
  /// بناء علامة تبويب رسوم المعاملات
  Widget _buildTransactionFeesTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'رسوم المعاملات الحالية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._currentTransactionFees.entries.map((entry) {
                final currency = entry.key;
                final fee = entry.value;
                final controller = TextEditingController(text: fee.toString());
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _getCurrencyName(currency),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          hintText: 'رسوم المعاملات (%)',
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        text: 'تحديث',
                        onPressed: () => _updateTransactionFee(
                          currency,
                          double.tryParse(controller.text) ?? fee,
                        ),
                        width: 100,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        if (_isUpdating)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: LoadingIndicator()),
          ),
      ],
    );
  }
  
  /// بناء علامة تبويب محافظ الإيداع
  Widget _buildDepositWalletsTab() {
    return Stack(
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
                final address = entry.value;
                final controller = TextEditingController(text: address);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _getDepositMethodName(currency),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: CustomTextField(
                          controller: controller,
                          hintText: 'عنوان المحفظة',
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        text: 'تحديث',
                        onPressed: () => _updateDepositWalletAddress(
                          currency,
                          controller.text,
                        ),
                        width: 100,
                      ),
                    ],
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
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      onChanged: (value) => _newDepositMethod = value,
                      hintText: 'اسم طريقة الإيداع',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: CustomTextField(
                      onChanged: (value) => _newDepositWalletAddress = value,
                      hintText: 'عنوان المحفظة',
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: 'إضافة',
                    onPressed: _addNewDepositMethod,
                    width: 100,
                  ),
                ],
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
    );
  }
  
  /// الحصول على اسم العملة
  String _getCurrencyName(String currencyCode) {
    switch (currencyCode) {
      case 'SYP':
        return 'ليرة سورية (SYP)';
      case 'USD':
        return 'دولار أمريكي (USD)';
      case 'EUR':
        return 'يورو (EUR)';
      case 'TRY':
        return 'ليرة تركية (TRY)';
      case 'SAR':
        return 'ريال سعودي (SAR)';
      case 'AED':
        return 'درهم إماراتي (AED)';
      case 'USDT':
        return 'تيثر (USDT)';
      case 'BTC':
        return 'بيتكوين (BTC)';
      case 'ETH':
        return 'إيثريوم (ETH)';
      default:
        return currencyCode;
    }
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
