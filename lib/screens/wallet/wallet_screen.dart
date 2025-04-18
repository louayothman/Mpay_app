import 'package:flutter/material.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/services/firestore_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mpay_app/screens/wallet/deposit_screen.dart';
import 'package:mpay_app/screens/wallet/withdraw_screen.dart';
import 'package:mpay_app/screens/wallet/transactions_screen.dart';
import 'package:mpay_app/utils/cache_manager.dart';
import 'package:mpay_app/utils/currency_converter.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// شاشة المحفظة الرئيسية
///
/// تعرض هذه الشاشة أرصدة المستخدم بالعملات المختلفة وتوفر إمكانية الإيداع والسحب
/// وعرض المعاملات السابقة
class WalletScreen extends StatefulWidget {
  final WalletBloc? walletBloc;
  
  const WalletScreen({Key? key, this.walletBloc}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final CacheManager _cacheManager = CacheManager();
  final CurrencyConverter _currencyConverter = CurrencyConverter(
    apiService: ApiIntegrationService(),
    firebaseService: FirebaseService(),
    errorHandler: ErrorHandler(),
  );
  
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  StreamSubscription? _subscription;
  
  // قائمة العملات المدعومة
  List<String> _supportedCurrencies = [];
  
  // قائمة المعاملات الأخيرة
  List<Map<String, dynamic>> _recentTransactions = [];
  
  // عدد المعاملات التي سيتم تحميلها في كل مرة
  static const int _transactionsPageSize = 3;
  
  // مؤشر الصفحة الحالية للمعاملات
  int _currentTransactionsPage = 1;

  @override
  bool get wantKeepAlive => true; // للحفاظ على حالة الشاشة عند التنقل

  @override
  void initState() {
    super.initState();
    _initializeCurrencies();
    _loadWalletData();
    _loadRecentTransactions();
    
    // إضافة الاشتراك في تدفق المحفظة إذا كان متوفراً
    if (widget.walletBloc != null) {
      _subscription = widget.walletBloc!.walletStream.listen((wallet) {
        if (mounted) {
          setState(() {
            _walletData = wallet;
            _isLoading = false;
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    // إلغاء الاشتراك عند التخلص من الشاشة لمنع تسرب الذاكرة
    _subscription?.cancel();
    super.dispose();
  }
  
  /// تهيئة قائمة العملات المدعومة
  Future<void> _initializeCurrencies() async {
    try {
      // محاولة الحصول على العملات المدعومة من ذاكرة التخزين المؤقت أولاً
      final cachedCurrencies = _cacheManager.getCachedData<List<String>>('supported_currencies');
      
      if (cachedCurrencies != null && mounted) {
        setState(() {
          _supportedCurrencies = cachedCurrencies;
        });
        return;
      }
      
      // إذا لم تكن موجودة في ذاكرة التخزين المؤقت، قم بتحميلها
      // استخدام compute لنقل العملية إلى خيط منفصل
      final currencies = await compute(_fetchSupportedCurrencies, _currencyConverter);
      
      if (mounted) {
        setState(() {
          _supportedCurrencies = currencies;
        });
        
        // تخزين العملات المدعومة في ذاكرة التخزين المؤقت
        _cacheManager.cacheData<List<String>>('supported_currencies', currencies, 
          expiry: const Duration(days: 1));
      }
    } catch (e) {
      // استخدام قائمة افتراضية في حالة فشل الحصول على العملات المدعومة
      if (mounted) {
        setState(() {
          _supportedCurrencies = [
            'SYP',  // ليرة سورية
            'USD',  // دولار أمريكي
            'EUR',  // يورو
            'TRY',  // ليرة تركية
            'SAR',  // ريال سعودي
            'AED',  // درهم إماراتي
            'USDT', // تيثر
            'BTC',  // بيتكوين
            'ETH',  // إيثريوم
          ];
        });
        
        // تخزين القائمة الافتراضية في ذاكرة التخزين المؤقت
        _cacheManager.cacheData<List<String>>('supported_currencies', _supportedCurrencies, 
          expiry: const Duration(hours: 1));
      }
    }
  }
  
  /// تحميل بيانات المحفظة
  Future<void> _loadWalletData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // محاولة الحصول على بيانات المحفظة من ذاكرة التخزين المؤقت أولاً
      final walletData = await _cacheManager.getWalletData(forceRefresh: false);
      
      if (mounted) {
        setState(() {
          _walletData = walletData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showErrorSnackBar(
          context, 
          'فشل في تحميل بيانات المحفظة: $e'
        );
      }
    }
  }
  
  /// تحميل المعاملات الأخيرة
  Future<void> _loadRecentTransactions() async {
    try {
      // محاولة الحصول على المعاملات من ذاكرة التخزين المؤقت أولاً
      final cachedTransactions = _cacheManager.getCachedData<List<Map<String, dynamic>>>('recent_transactions');
      
      if (cachedTransactions != null && mounted) {
        setState(() {
          _recentTransactions = cachedTransactions;
        });
        return;
      }
      
      // إذا لم تكن موجودة في ذاكرة التخزين المؤقت، قم بتحميلها
      // استخدام compute لنقل العملية إلى خيط منفصل
      final transactions = await compute(_fetchRecentTransactions, _transactionsPageSize);
      
      if (mounted) {
        setState(() {
          _recentTransactions = transactions;
        });
        
        // تخزين المعاملات في ذاكرة التخزين المؤقت
        _cacheManager.cacheData<List<Map<String, dynamic>>>('recent_transactions', transactions, 
          expiry: const Duration(minutes: 5));
      }
    } catch (e) {
      // استخدام بيانات وهمية في حالة فشل الحصول على المعاملات
      if (mounted) {
        setState(() {
          _recentTransactions = [
            {
              'type': 'إيداع',
              'amount': 100.0,
              'currency': 'USDT',
              'date': DateTime.now().subtract(const Duration(days: 1)),
              'status': 'مكتمل',
            },
            {
              'type': 'سحب',
              'amount': 0.005,
              'currency': 'BTC',
              'date': DateTime.now().subtract(const Duration(days: 3)),
              'status': 'مكتمل',
            },
            {
              'type': 'إيداع',
              'amount': 500.0,
              'currency': 'SYP',
              'date': DateTime.now().subtract(const Duration(days: 5)),
              'status': 'مكتمل',
            },
          ];
        });
      }
    }
  }
  
  /// تحميل المزيد من المعاملات
  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      // زيادة رقم الصفحة
      _currentTransactionsPage++;
      
      // استخدام compute لنقل العملية إلى خيط منفصل
      final moreTransactions = await compute(
        _fetchMoreTransactions, 
        _FetchTransactionsParams(
          pageSize: _transactionsPageSize,
          page: _currentTransactionsPage
        )
      );
      
      if (mounted) {
        setState(() {
          _recentTransactions.addAll(moreTransactions);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ErrorHandler.showErrorSnackBar(
          context, 
          'فشل في تحميل المزيد من المعاملات: $e'
        );
      }
    }
  }

  /// الحصول على رصيد عملة معينة
  double _getBalance(String currency) {
    if (_walletData == null || !_walletData!.containsKey('balances')) {
      return 0.0;
    }
    
    final balances = _walletData!['balances'] as Map<String, dynamic>?;
    if (balances == null) {
      return 0.0;
    }
    
    return balances[currency] as double? ?? 0.0;
  }

  /// الانتقال إلى شاشة الإيداع
  void _navigateToDeposit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DepositScreen(),
      ),
    ).then((_) => _loadWalletData());
  }

  /// الانتقال إلى شاشة السحب
  void _navigateToWithdraw() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WithdrawScreen(),
      ),
    ).then((_) => _loadWalletData());
  }

  /// الانتقال إلى شاشة المعاملات
  void _navigateToTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionsScreen(),
      ),
    ).then((_) => _loadWalletData());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب بسبب AutomaticKeepAliveClientMixin
    
    return ErrorHandlingWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحفظة', semanticsLabel: 'شاشة المحفظة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWalletData,
              tooltip: 'تحديث',
              semanticLabel: 'تحديث بيانات المحفظة',
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long),
              onPressed: _navigateToTransactions,
              tooltip: 'المعاملات',
              semanticLabel: 'عرض جميع المعاملات',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'جاري تحميل بيانات المحفظة',
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadWalletData,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ملخص إجمالي الرصيد
                          _buildTotalBalanceSummary(),
                          
                          const SizedBox(height: 24),
                          
                          // بطاقات الأرصدة
                          _buildCurrencyBalances(constraints),
                          
                          const SizedBox(height: 32),
                          
                          // أزرار الإجراءات
                          _buildActionButtons(),
                          
                          const SizedBox(height: 32),
                          
                          // المعاملات الأخيرة
                          _buildTransactionsHeader(),
                          const SizedBox(height: 16),
                          _buildRecentTransactions(),
                          
                          // زر تحميل المزيد
                          if (_recentTransactions.isNotEmpty)
                            Center(
                              child: _isLoadingMore
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  )
                                : TextButton.icon(
                                    onPressed: _loadMoreTransactions,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('تحميل المزيد'),
                                  ),
                            ),
                          
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              onPressed: _navigateToTransactions,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('عرض جميع المعاملات'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          // إضافة مساحة إضافية في الأسفل لتحسين تجربة التمرير
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  /// بناء ملخص إجمالي الرصيد
  Widget _buildTotalBalanceSummary() {
    // حساب إجمالي الرصيد بالدولار الأمريكي
    double totalBalance = 0;
    for (var currency in _supportedCurrencies) {
      double balance = _getBalance(currency);
      
      // تحويل الرصيد إلى الدولار الأمريكي باستخدام أسعار الصرف
      try {
        double exchangeRate = _currencyConverter.getExchangeRate('USD', currency);
        totalBalance += balance / exchangeRate;
      } catch (e) {
        // استخدام أسعار صرف مبسطة في حالة فشل الحصول على أسعار الصرف
        if (currency == 'USD' || currency == 'USDT') {
          totalBalance += balance;
        } else if (currency == 'EUR') {
          totalBalance += balance * 1.1; // سعر صرف مبسط
        } else if (currency == 'BTC') {
          totalBalance += balance * 60000; // سعر صرف مبسط
        } else if (currency == 'ETH') {
          totalBalance += balance * 3000; // سعر صرف مبسط
        } else if (currency == 'SYP') {
          totalBalance += balance * 0.0004; // سعر صرف مبسط
        } else if (currency == 'TRY') {
          totalBalance += balance * 0.03; // سعر صرف مبسط
        } else if (currency == 'SAR') {
          totalBalance += balance * 0.27; // سعر صرف مبسط
        } else if (currency == 'AED') {
          totalBalance += balance * 0.27; // سعر صرف مبسط
        } else {
          totalBalance += balance * 1; // افتراضي
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إجمالي الرصيد',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              semanticsLabel: 'إجمالي الرصيد بالدولار الأمريكي',
            ),
            const SizedBox(height: 8),
            Text(
              '\$${totalBalance.toStringAsFixed(2)} USD',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionButton(
                  icon: Icons.arrow_downward,
                  label: 'إيداع',
                  onTap: _navigateToDeposit,
                ),
                _buildQuickActionButton(
                  icon: Icons.arrow_upward,
                  label: 'سحب',
                  onTap: _navigateToWithdraw,
                ),
                _buildQuickActionButton(
                  icon: Icons.receipt_long,
                  label: 'المعاملات',
                  onTap: _navigateToTransactions,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء زر إجراء سريع
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء أرصدة العملات
  Widget _buildCurrencyBalances(BoxConstraints constraints) {
    // ترتيب العملات لعرض الأرصدة غير الصفرية أولاً
    final nonZeroCurrencies = _supportedCurrencies
        .where((currency) => _getBalance(currency) > 0)
        .toList();
    
    final zeroCurrencies = _supportedCurrencies
        .where((currency) => _getBalance(currency) == 0)
        .toList();
    
    // إعادة ترتيب العملات لعرض الأرصدة غير الصفرية أولاً
    final orderedCurrencies = [...nonZeroCurrencies, ...zeroCurrencies];
    
    // تحديد ما إذا كان يجب استخدام الشبكة أو القائمة بناءً على عرض الشاشة
    final isWideScreen = constraints.maxWidth > 600;
    
    if (isWideScreen) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: orderedCurrencies.length,
        itemBuilder: (context, index) {
          return _buildBalanceCard(orderedCurrencies[index]);
        },
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orderedCurrencies.length,
        itemBuilder: (context, index) {
          return _buildBalanceCard(orderedCurrencies[index]);
        },
      );
    }
  }

  /// بناء بطاقة رصيد
  Widget _buildBalanceCard(String currency) {
    final balance = _getBalance(currency);
    final hasBalance = balance > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: hasBalance ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasBalance 
              ? _getCurrencyColor(currency).withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: hasBalance ? 1 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _getCurrencyIcon(currency),
                    const SizedBox(width: 12),
                    Text(
                      _getCurrencyName(currency),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasBalance 
                            ? _getCurrencyColor(currency)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (hasBalance)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCurrencyColor(currency).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'نشط',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCurrencyColor(currency),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              balance.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: hasBalance ? Colors.black87 : Colors.grey,
              ),
              semanticsLabel: '$balance $currency',
            ),
            const SizedBox(height: 8),
            Text(
              'الرصيد المتاح',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (hasBalance) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCurrencyActionButton(
                      icon: Icons.arrow_downward,
                      label: 'إيداع',
                      onPressed: _navigateToDeposit,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCurrencyActionButton(
                      icon: Icons.arrow_upward,
                      label: 'سحب',
                      onPressed: _navigateToWithdraw,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// بناء زر إجراء للعملة
  Widget _buildCurrencyActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
      ),
    );
  }

  /// الحصول على أيقونة العملة
  Widget _getCurrencyIcon(String currency) {
    IconData iconData;
    Color iconColor = _getCurrencyColor(currency);
    
    switch (currency) {
      case 'USDT':
        iconData = Icons.monetization_on;
        break;
      case 'BTC':
        iconData = Icons.currency_bitcoin;
        break;
      case 'ETH':
        iconData = Icons.diamond;
        break;
      case 'SYP':
        iconData = Icons.money;
        break;
      case 'USD':
        iconData = Icons.attach_money;
        break;
      case 'EUR':
        iconData = Icons.euro;
        break;
      case 'TRY':
        iconData = Icons.money;
        break;
      case 'SAR':
        iconData = Icons.money;
        break;
      case 'AED':
        iconData = Icons.money;
        break;
      default:
        iconData = Icons.account_balance_wallet;
    }
    
    // استخدام صورة من الإنترنت إذا كانت متوفرة
    final currencyImageUrl = _getCurrencyImageUrl(currency);
    
    if (currencyImageUrl != null) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CachedNetworkImage(
          imageUrl: currencyImageUrl,
          width: 28,
          height: 28,
          placeholder: (context, url) => Icon(
            iconData,
            color: iconColor,
            size: 20,
          ),
          errorWidget: (context, url, error) => Icon(
            iconData,
            color: iconColor,
            size: 20,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }
  
  /// الحصول على عنوان URL لصورة العملة
  String? _getCurrencyImageUrl(String currency) {
    switch (currency) {
      case 'BTC':
        return 'https://cryptologos.cc/logos/bitcoin-btc-logo.png';
      case 'ETH':
        return 'https://cryptologos.cc/logos/ethereum-eth-logo.png';
      case 'USDT':
        return 'https://cryptologos.cc/logos/tether-usdt-logo.png';
      default:
        return null;
    }
  }

  /// الحصول على لون العملة
  Color _getCurrencyColor(String currency) {
    switch (currency) {
      case 'USDT':
        return Colors.green;
      case 'BTC':
        return Colors.orange;
      case 'ETH':
        return Colors.purple;
      case 'SYP':
        return Colors.blue;
      case 'USD':
        return Colors.green.shade800;
      case 'EUR':
        return Colors.blue.shade800;
      case 'TRY':
        return Colors.red.shade800;
      case 'SAR':
        return Colors.green.shade700;
      case 'AED':
        return Colors.teal.shade700;
      default:
        return Colors.grey;
    }
  }
  
  /// الحصول على اسم العملة
  String _getCurrencyName(String currency) {
    switch (currency) {
      case 'SYP':
        return 'ليرة سورية';
      case 'USD':
        return 'دولار أمريكي';
      case 'EUR':
        return 'يورو';
      case 'TRY':
        return 'ليرة تركية';
      case 'SAR':
        return 'ريال سعودي';
      case 'AED':
        return 'درهم إماراتي';
      case 'USDT':
        return 'تيثر';
      case 'BTC':
        return 'بيتكوين';
      case 'ETH':
        return 'إيثريوم';
      default:
        return currency;
    }
  }

  /// بناء أزرار الإجراءات
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.arrow_downward,
          label: 'إيداع',
          onPressed: _navigateToDeposit,
          color: Colors.green,
        ),
        _buildActionButton(
          icon: Icons.arrow_upward,
          label: 'سحب',
          onPressed: _navigateToWithdraw,
          color: Colors.red,
        ),
        _buildActionButton(
          icon: Icons.swap_horiz,
          label: 'تحويل',
          onPressed: () {
            // سيتم تنفيذه لاحقاً
          },
          color: Colors.blue,
        ),
      ],
    );
  }

  /// بناء زر إجراء
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: color,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// بناء رأس المعاملات
  Widget _buildTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'المعاملات الأخيرة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: _navigateToTransactions,
          child: const Text('عرض الكل'),
        ),
      ],
    );
  }

  /// بناء المعاملات الأخيرة
  Widget _buildRecentTransactions() {
    if (_recentTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'لا توجد معاملات حديثة',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _recentTransactions[index];
        return _buildTransactionItem(
          type: transaction['type'] as String,
          amount: transaction['amount'] as double,
          currency: transaction['currency'] as String,
          date: transaction['date'] as DateTime,
          status: transaction['status'] as String,
        );
      },
    );
  }

  /// بناء عنصر معاملة
  Widget _buildTransactionItem({
    required String type,
    required double amount,
    required String currency,
    required DateTime date,
    required String status,
  }) {
    final isDeposit = type == 'إيداع';
    final color = isDeposit ? Colors.green : Colors.red;
    final icon = isDeposit ? Icons.arrow_downward : Icons.arrow_upward;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          type,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${date.day}/${date.month}/${date.year}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isDeposit ? '+' : '-'}$amount $currency',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: status == 'مكتمل' ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// واجهة برمجية لتدفق بيانات المحفظة
class WalletBloc {
  final Stream<Map<String, dynamic>> walletStream;
  
  WalletBloc({required this.walletStream});
}

/// دالة لجلب العملات المدعومة في خيط منفصل
List<String> _fetchSupportedCurrencies(CurrencyConverter converter) {
  return converter.getSupportedCurrencies();
}

/// دالة لجلب المعاملات الأخيرة في خيط منفصل
List<Map<String, dynamic>> _fetchRecentTransactions(int pageSize) {
  // في التطبيق الحقيقي، يجب الحصول على المعاملات الأخيرة من قاعدة البيانات
  // هنا نستخدم بيانات وهمية للعرض
  return [
    {
      'type': 'إيداع',
      'amount': 100.0,
      'currency': 'USDT',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'مكتمل',
    },
    {
      'type': 'سحب',
      'amount': 0.005,
      'currency': 'BTC',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'مكتمل',
    },
    {
      'type': 'إيداع',
      'amount': 500.0,
      'currency': 'SYP',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'مكتمل',
    },
  ];
}

/// معلمات لجلب المزيد من المعاملات
class _FetchTransactionsParams {
  final int pageSize;
  final int page;
  
  _FetchTransactionsParams({
    required this.pageSize,
    required this.page,
  });
}

/// دالة لجلب المزيد من المعاملات في خيط منفصل
List<Map<String, dynamic>> _fetchMoreTransactions(_FetchTransactionsParams params) {
  // في التطبيق الحقيقي، يجب الحصول على المعاملات من قاعدة البيانات
  // هنا نستخدم بيانات وهمية للعرض
  final baseDate = DateTime.now().subtract(Duration(days: params.page * 7));
  
  return [
    {
      'type': 'إيداع',
      'amount': 200.0 * params.page,
      'currency': 'USDT',
      'date': baseDate.subtract(const Duration(days: 1)),
      'status': 'مكتمل',
    },
    {
      'type': 'سحب',
      'amount': 0.01 * params.page,
      'currency': 'BTC',
      'date': baseDate.subtract(const Duration(days: 3)),
      'status': 'مكتمل',
    },
    {
      'type': 'إيداع',
      'amount': 1000.0 * params.page,
      'currency': 'SYP',
      'date': baseDate.subtract(const Duration(days: 5)),
      'status': 'مكتمل',
    },
  ];
}
