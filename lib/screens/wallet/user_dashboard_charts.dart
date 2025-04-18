import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';
import 'package:mpay_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class UserDashboardCharts extends StatefulWidget {
  final String userId;

  const UserDashboardCharts({
    super.key,
    required this.userId,
  });

  @override
  State<UserDashboardCharts> createState() => _UserDashboardChartsState();
}

class _UserDashboardChartsState extends State<UserDashboardCharts> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Transaction data
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _balanceByType = {};
  Map<String, double> _transactionsByMonth = {};
  Map<String, double> _transactionsByType = {};
  
  // Selected currency for charts
  String _selectedCurrency = 'USD';
  List<String> _supportedCurrencies = ['USD', 'SYP', 'EUR', 'SAR', 'AED', 'TRY'];
  
  // Selected time range
  String _selectedTimeRange = 'month';
  List<String> _timeRanges = ['week', 'month', 'year', 'all'];
  
  @override
  void initState() {
    super.initState();
    _loadTransactionData();
  }
  
  Future<void> _loadTransactionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get transactions
      final DateTime now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedTimeRange) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        case 'all':
        default:
          startDate = DateTime(2000);
          break;
      }
      
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: widget.userId)
          .where('currency', isEqualTo: _selectedCurrency)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('timestamp', descending: true)
          .get();
      
      List<Map<String, dynamic>> transactions = [];
      Map<String, double> balanceByType = {
        'deposit': 0,
        'withdrawal': 0,
        'send': 0,
        'receive': 0,
        'exchange': 0,
      };
      
      Map<String, double> transactionsByMonth = {};
      Map<String, double> transactionsByType = {
        'deposit': 0,
        'withdrawal': 0,
        'send': 0,
        'receive': 0,
        'exchange': 0,
      };
      
      for (var doc in transactionsQuery.docs) {
        final transactionData = doc.data();
        transactions.add(transactionData as Map<String, dynamic>);
        
        final type = transactionData['type'] as String;
        final amount = (transactionData['amount'] as num).toDouble();
        
        // Update balance by type
        balanceByType[type] = (balanceByType[type] ?? 0) + amount;
        
        // Update transactions by type
        transactionsByType[type] = (transactionsByType[type] ?? 0) + 1;
        
        // Update transactions by month
        final timestamp = transactionData['timestamp'] as Timestamp;
        final date = timestamp.toDate();
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        transactionsByMonth[monthKey] = (transactionsByMonth[monthKey] ?? 0) + amount;
      }
      
      setState(() {
        _transactions = transactions;
        _balanceByType = balanceByType;
        _transactionsByMonth = transactionsByMonth;
        _transactionsByType = transactionsByType;
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
  
  String _formatBalance(double balance) {
    return balance.toStringAsFixed(balance.truncateToDouble() == balance ? 0 : 2);
  }
  
  String _getTimeRangeText(String range) {
    switch (range) {
      case 'week':
        return 'آخر أسبوع';
      case 'month':
        return 'آخر شهر';
      case 'year':
        return 'آخر سنة';
      case 'all':
        return 'كل الوقت';
      default:
        return range;
    }
  }
  
  String _getTransactionTypeText(String type) {
    switch (type) {
      case 'deposit':
        return 'إيداع';
      case 'withdrawal':
        return 'سحب';
      case 'send':
        return 'إرسال';
      case 'receive':
        return 'استلام';
      case 'exchange':
        return 'تبديل';
      default:
        return type;
    }
  }
  
  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'deposit':
        return Colors.green;
      case 'withdrawal':
        return Colors.red;
      case 'send':
        return Colors.orange;
      case 'receive':
        return Colors.blue;
      case 'exchange':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ErrorHandlingWrapper(
      onRetry: _loadTransactionData,
      child: ConnectivityAwareWidget(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filters
                        _buildFilters(),
                        const SizedBox(height: 24),
                        
                        // Balance summary
                        _buildBalanceSummary(),
                        const SizedBox(height: 24),
                        
                        // Transaction activity chart
                        _buildTransactionActivityChart(),
                        const SizedBox(height: 24),
                        
                        // Transaction distribution chart
                        _buildTransactionDistributionChart(),
                      ],
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تصفية البيانات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('العملة'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: _supportedCurrencies.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text('${_getCurrencySymbol(currency)} $currency'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCurrency = newValue;
                            });
                            _loadTransactionData();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الفترة الزمنية'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedTimeRange,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: _timeRanges.map((String range) {
                          return DropdownMenuItem<String>(
                            value: range,
                            child: Text(_getTimeRangeText(range)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedTimeRange = newValue;
                            });
                            _loadTransactionData();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBalanceSummary() {
    // Calculate total balance
    double totalBalance = 0;
    _balanceByType.forEach((type, amount) {
      if (type == 'deposit' || type == 'receive') {
        totalBalance += amount;
      } else if (type == 'withdrawal' || type == 'send') {
        totalBalance -= amount;
      }
    });
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص الرصيد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceCard(
                    title: 'الرصيد الإجمالي',
                    amount: totalBalance,
                    currency: _selectedCurrency,
                    color: Colors.blue,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceCard(
                    title: 'الإيداعات',
                    amount: _balanceByType['deposit'] ?? 0,
                    currency: _selectedCurrency,
                    color: Colors.green,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceCard(
                    title: 'السحوبات',
                    amount: _balanceByType['withdrawal'] ?? 0,
                    currency: _selectedCurrency,
                    color: Colors.red,
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceCard(
                    title: 'المستلم',
                    amount: _balanceByType['receive'] ?? 0,
                    currency: _selectedCurrency,
                    color: Colors.blue,
                    icon: Icons.call_received,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceCard(
                    title: 'المرسل',
                    amount: _balanceByType['send'] ?? 0,
                    currency: _selectedCurrency,
                    color: Colors.orange,
                    icon: Icons.call_made,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBalanceCard({
    required String title,
    required double amount,
    required String currency,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_getCurrencySymbol(currency)} ${_formatBalance(amount)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionActivityChart() {
    // Sort months chronologically
    final sortedMonths = _transactionsByMonth.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    // Take only the last 6 months if there are more
    final displayMonths = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6)
        : sortedMonths;
    
    // Create bar chart data
    final barGroups = displayMonths.asMap().entries.map((entry) {
      final index = entry.key;
      final month = entry.value;
      final amount = _transactionsByMonth[month] ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount.abs(),
            color: amount >= 0 ? Colors.green : Colors.red,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نشاط المعاملات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'إجمالي المعاملات حسب الشهر (${_selectedCurrency})',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: displayMonths.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد بيانات كافية لعرض الرسم البياني',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _transactionsByMonth.values.fold(0, (max, value) => value.abs() > max ? value.abs() : max) * 1.2,
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= displayMonths.length) {
                                  return const SizedBox();
                                }
                                
                                final month = displayMonths[value.toInt()];
                                final parts = month.split('-');
                                final monthName = DateFormat('MMM').format(
                                  DateTime(int.parse(parts[0]), int.parse(parts[1])),
                                );
                                
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    monthName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 40,
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: barGroups,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionDistributionChart() {
    // Calculate total transactions
    final totalTransactions = _transactionsByType.values.fold(0, (sum, count) => sum + count);
    
    // Create pie chart sections
    final pieSections = _transactionsByType.entries.map((entry) {
      final type = entry.key;
      final count = entry.value;
      final percentage = totalTransactions > 0 ? count / totalTransactions * 100 : 0;
      
      return PieChartSectionData(
        value: count,
        title: '${percentage.toStringAsFixed(1)}%',
        color: _getTransactionTypeColor(type),
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزيع المعاملات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'نسبة أنواع المعاملات (${_selectedCurrency})',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: totalTransactions == 0
                  ? const Center(
                      child: Text(
                        'لا توجد بيانات كافية لعرض الرسم البياني',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: pieSections,
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _transactionsByType.entries.map((entry) {
                              final type = entry.key;
                              final count = entry.value;
                              final percentage = totalTransactions > 0 ? count / totalTransactions * 100 : 0;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _getTransactionTypeColor(type),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getTransactionTypeText(type),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${percentage.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
