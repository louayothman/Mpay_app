import 'package:flutter/material.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/providers/state_management.dart';
import 'package:provider/provider.dart';

/// شاشة المحفظة الرئيسية
///
/// تعرض هذه الشاشة أرصدة المستخدم بالعملات المختلفة وتوفر إمكانية الإيداع والسحب
/// وعرض المعاملات السابقة
class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // استخدام مزود الحالة بدلاً من إدارة الحالة محلياً
  late WalletStateProvider _walletProvider;
  
  @override
  void initState() {
    super.initState();
    // الحصول على مرجع لمزود الحالة
    _walletProvider = Provider.of<WalletStateProvider>(context, listen: false);
  }

  /// الانتقال إلى شاشة الإيداع
  void _navigateToDeposit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DepositScreen(),
      ),
    ).then((_) => _walletProvider.refreshWalletData());
  }

  /// الانتقال إلى شاشة السحب
  void _navigateToWithdraw() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WithdrawScreen(),
      ),
    ).then((_) => _walletProvider.refreshWalletData());
  }

  /// الانتقال إلى شاشة المعاملات
  void _navigateToTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionsScreen(),
      ),
    ).then((_) => _walletProvider.refreshWalletData());
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlingWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحفظة', semanticsLabel: 'شاشة المحفظة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _walletProvider.refreshWalletData(),
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
        body: Consumer<WalletStateProvider>(
          builder: (context, walletProvider, child) {
            if (walletProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'جاري تحميل بيانات المحفظة',
                ),
              );
            }
            
            if (walletProvider.errorMessage.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      walletProvider.errorMessage,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => walletProvider.refreshWalletData(),
                      child: Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () => walletProvider.refreshWalletData(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ملخص إجمالي الرصيد
                        _buildTotalBalanceSummary(walletProvider),
                        
                        const SizedBox(height: 24),
                        
                        // بطاقات الأرصدة
                        _buildCurrencyBalances(walletProvider, constraints),
                        
                        const SizedBox(height: 32),
                        
                        // أزرار الإجراءات
                        _buildActionButtons(),
                        
                        const SizedBox(height: 32),
                        
                        // المعاملات الأخيرة
                        _buildTransactionsHeader(),
                        const SizedBox(height: 16),
                        _buildRecentTransactions(walletProvider),
                        
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
            );
          },
        ),
      ),
    );
  }

  /// بناء ملخص إجمالي الرصيد
  Widget _buildTotalBalanceSummary(WalletStateProvider walletProvider) {
    return FutureBuilder<double>(
      future: walletProvider.calculateTotalBalanceInUSD(),
      builder: (context, snapshot) {
        double totalBalance = snapshot.data ?? 0.0;
        
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
                snapshot.connectionState == ConnectionState.waiting
                    ? Container(
                        height: 28,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
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
      },
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
  Widget _buildCurrencyBalances(WalletStateProvider walletProvider, BoxConstraints constraints) {
    // ترتيب العملات لعرض الأرصدة غير الصفرية أولاً
    final nonZeroCurrencies = walletProvider.supportedCurrencies
        .where((currency) => walletProvider.getBalance(currency) > 0)
        .toList();
    
    final zeroCurrencies = walletProvider.supportedCurrencies
        .where((currency) => walletProvider.getBalance(currency) == 0)
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
          return _buildBalanceCard(walletProvider, orderedCurrencies[index]);
        },
      );
    } else {
      return Column(
        children: orderedCurrencies.map((currency) => _buildBalanceCard(walletProvider, currency)).toList(),
      );
    }
  }

  /// بناء بطاقة رصيد
  Widget _buildBalanceCard(WalletStateProvider walletProvider, String currency) {
    final balance = walletProvider.getBalance(currency);
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
          ],
        ),
      ),
    );
  }

  /// بناء أزرار الإجراءات
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.arrow_downward,
          label: 'إيداع',
          onTap: _navigateToDeposit,
          color: Colors.green,
        ),
        _buildActionButton(
          icon: Icons.arrow_upward,
          label: 'سحب',
          onTap: _navigateToWithdraw,
          color: Colors.red,
        ),
        _buildActionButton(
          icon: Icons.swap_horiz,
          label: 'تحويل',
          onTap: () {
            // تنفيذ عملية التحويل
          },
          color: Colors.blue,
        ),
        _buildActionButton(
          icon: Icons.qr_code,
          label: 'مسح QR',
          onTap: () {
            // تنفيذ عملية مسح رمز QR
          },
          color: Colors.purple,
        ),
      ],
    );
  }

  /// بناء زر إجراء
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء عنوان المعاملات
  Widget _buildTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'المعاملات الأخيرة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
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
  Widget _buildRecentTransactions(WalletStateProvider walletProvider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: walletProvider.getRecentTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'فشل في تحميل المعاملات: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        
        final transactions = snapshot.data ?? [];
        
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد معاملات حتى الآن',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionItem(transaction);
          },
        );
      },
    );
  }

  /// بناء عنصر معاملة
  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final String title = transaction['title'] ?? 'معاملة';
    final double amount = transaction['amount'] ?? 0.0;
    final DateTime date = transaction['date'] != null
        ? (transaction['date'] as DateTime)
        : DateTime.now();
    final String type = transaction['type'] ?? 'transfer';
    
    final bool isIncoming = amount > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getTransactionColor(type).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getTransactionIcon(type),
            color: _getTransactionColor(type),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _formatDate(date),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Text(
          '${isIncoming ? '+' : ''}$amount',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isIncoming ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  /// الحصول على لون العملة
  Color _getCurrencyColor(String currency) {
    switch (currency) {
      case 'SYP':
        return Colors.red;
      case 'USD':
        return Colors.green;
      case 'EUR':
        return Colors.blue;
      case 'TRY':
        return Colors.red[700]!;
      case 'SAR':
        return Colors.green[700]!;
      case 'AED':
        return Colors.green[900]!;
      case 'USDT':
        return Colors.teal;
      case 'BTC':
        return Colors.orange;
      case 'ETH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// الحصول على أيقونة العملة
  Widget _getCurrencyIcon(String currency) {
    IconData iconData;
    
    switch (currency) {
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
      case 'USDT':
        iconData = Icons.monetization_on;
        break;
      case 'BTC':
        iconData = Icons.currency_bitcoin;
        break;
      case 'ETH':
        iconData = Icons.currency_exchange;
        break;
      default:
        iconData = Icons.money;
    }
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _getCurrencyColor(currency).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: _getCurrencyColor(currency),
        size: 20,
      ),
    );
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

  /// الحصول على لون المعاملة
  Color _getTransactionColor(String type) {
    switch (type) {
      case 'transfer':
        return Colors.blue;
      case 'receive':
        return Colors.green;
      case 'purchase':
        return Colors.red;
      case 'deposit':
        return Colors.teal;
      case 'withdrawal':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// الحصول على أيقونة المعاملة
  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'transfer':
        return Icons.swap_horiz;
      case 'receive':
        return Icons.arrow_downward;
      case 'purchase':
        return Icons.shopping_cart;
      case 'deposit':
        return Icons.add;
      case 'withdrawal':
        return Icons.remove;
      default:
        return Icons.receipt_long;
    }
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'الأمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }
}

// استيراد الشاشات المطلوبة
class DepositScreen extends StatelessWidget {
  const DepositScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إيداع'),
      ),
      body: const Center(
        child: Text('شاشة الإيداع'),
      ),
    );
  }
}

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سحب'),
      ),
      body: const Center(
        child: Text('شاشة السحب'),
      ),
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعاملات'),
      ),
      body: const Center(
        child: Text('شاشة المعاملات'),
      ),
    );
  }
}
