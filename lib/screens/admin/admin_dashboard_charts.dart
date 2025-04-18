import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/theme/app_theme.dart';

class AdminDashboardCharts extends StatefulWidget {
  const AdminDashboardCharts({super.key});

  @override
  State<AdminDashboardCharts> createState() => _AdminDashboardChartsState();
}

class _AdminDashboardChartsState extends State<AdminDashboardCharts> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Dashboard data
  int _totalUsers = 0;
  int _verifiedUsers = 0;
  int _pendingVerifications = 0;
  int _totalTransactions = 0;
  double _totalVolume = 0;
  
  // Transaction data by currency
  Map<String, double> _volumeByCurrency = {};
  
  // Transaction data by type
  Map<String, double> _volumeByType = {};
  
  // User data by level
  Map<String, int> _usersByLevel = {
    'bronze': 0,
    'silver': 0,
    'gold': 0,
    'platinum': 0,
  };
  
  // Transaction data by day (last 7 days)
  Map<String, double> _transactionsByDay = {};
  
  // Selected time range
  String _selectedTimeRange = 'week';
  List<String> _timeRanges = ['week', 'month', 'year', 'all'];
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Check if current user is admin
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يجب تسجيل الدخول للوصول إلى هذه الصفحة';
        });
        return;
      }
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || !(userDoc.data() as Map<String, dynamic>)['isAdmin']) {
        setState(() {
          _errorMessage = 'ليس لديك صلاحية للوصول إلى هذه الصفحة';
        });
        return;
      }
      
      // Get time range
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
      
      // Get users data
      final usersQuery = await _firestore.collection('users').get();
      
      int totalUsers = 0;
      int verifiedUsers = 0;
      Map<String, int> usersByLevel = {
        'bronze': 0,
        'silver': 0,
        'gold': 0,
        'platinum': 0,
      };
      
      for (var doc in usersQuery.docs) {
        final userData = doc.data();
        totalUsers++;
        
        if (userData['verificationStatus'] == 'verified') {
          verifiedUsers++;
        }
        
        final level = userData['level'] ?? 'bronze';
        usersByLevel[level] = (usersByLevel[level] ?? 0) + 1;
      }
      
      // Get pending verifications
      final pendingVerificationsQuery = await _firestore
          .collection('verification_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      
      int pendingVerifications = pendingVerificationsQuery.docs.length;
      
      // Get transactions data
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();
      
      int totalTransactions = transactionsQuery.docs.length;
      double totalVolume = 0;
      Map<String, double> volumeByCurrency = {};
      Map<String, double> volumeByType = {
        'deposit': 0,
        'withdrawal': 0,
        'send': 0,
        'receive': 0,
        'exchange': 0,
      };
      Map<String, double> transactionsByDay = {};
      
      // Initialize transactions by day for the last 7 days
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        transactionsByDay[dayKey] = 0;
      }
      
      for (var doc in transactionsQuery.docs) {
        final transactionData = doc.data();
        final amount = (transactionData['amount'] as num).toDouble();
        final currency = transactionData['currency'] as String;
        final type = transactionData['type'] as String;
        final timestamp = transactionData['timestamp'] as Timestamp;
        final date = timestamp.toDate();
        
        // Convert all currencies to USD for total volume (simplified conversion)
        double amountInUSD = amount;
        if (currency != 'USD') {
          // Simple conversion rates (in a real app, these would come from an API)
          final conversionRates = {
            'EUR': 1.1,  // 1 EUR = 1.1 USD
            'SYP': 0.0004,  // 1 SYP = 0.0004 USD
            'SAR': 0.27,  // 1 SAR = 0.27 USD
            'AED': 0.27,  // 1 AED = 0.27 USD
            'TRY': 0.03,  // 1 TRY = 0.03 USD
          };
          
          amountInUSD = amount * (conversionRates[currency] ?? 1);
        }
        
        totalVolume += amountInUSD;
        
        // Update volume by currency
        volumeByCurrency[currency] = (volumeByCurrency[currency] ?? 0) + amount;
        
        // Update volume by type
        volumeByType[type] = (volumeByType[type] ?? 0) + amountInUSD;
        
        // Update transactions by day (for the last 7 days)
        if (date.isAfter(now.subtract(const Duration(days: 7)))) {
          final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          transactionsByDay[dayKey] = (transactionsByDay[dayKey] ?? 0) + amountInUSD;
        }
      }
      
      setState(() {
        _totalUsers = totalUsers;
        _verifiedUsers = verifiedUsers;
        _pendingVerifications = pendingVerifications;
        _totalTransactions = totalTransactions;
        _totalVolume = totalVolume;
        _volumeByCurrency = volumeByCurrency;
        _volumeByType = volumeByType;
        _usersByLevel = usersByLevel;
        _transactionsByDay = transactionsByDay;
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
  
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 2);
    }
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
  
  String _getLevelName(String level) {
    switch (level) {
      case 'bronze':
        return 'برونزي';
      case 'silver':
        return 'فضي';
      case 'gold':
        return 'ذهبي';
      case 'platinum':
        return 'بلاتيني';
      default:
        return level;
    }
  }
  
  Color _getLevelColor(String level) {
    switch (level) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey.shade500;
      case 'gold':
        return Colors.amber;
      case 'platinum':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ErrorHandlingWrapper(
      onRetry: _loadDashboardData,
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
                        // Time range filter
                        _buildTimeRangeFilter(),
                        const SizedBox(height: 24),
                        
                        // Summary cards
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        
                        // Transaction volume chart
                        _buildTransactionVolumeChart(),
                        const SizedBox(height: 24),
                        
                        // Two charts side by side
                        AdaptiveContainer(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Transaction distribution chart
                              Expanded(
                                child: _buildTransactionDistributionChart(),
                              ),
                              const SizedBox(width: 16),
                              
                              // User levels chart
                              Expanded(
                                child: _buildUserLevelsChart(),
                              ),
                            ],
                          ),
                          mobileChild: Column(
                            children: [
                              // Transaction distribution chart
                              _buildTransactionDistributionChart(),
                              const SizedBox(height: 24),
                              
                              // User levels chart
                              _buildUserLevelsChart(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildTimeRangeFilter() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Text(
              'الفترة الزمنية:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _timeRanges.map((range) {
                    final isSelected = _selectedTimeRange == range;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(_getTimeRangeText(range)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTimeRange = range;
                            });
                            _loadDashboardData();
                          }
                        },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: Colors.purple.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.purple : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
              tooltip: 'تحديث البيانات',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCards() {
    return AdaptiveContainer(
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'إجمالي المستخدمين',
              value: _totalUsers.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'المستخدمين الموثقين',
              value: '$_verifiedUsers (${_totalUsers > 0 ? (_verifiedUsers / _totalUsers * 100).toStringAsFixed(1) : 0}%)',
              icon: Icons.verified_user,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'طلبات التوثيق المعلقة',
              value: _pendingVerifications.toString(),
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'إجمالي المعاملات',
              value: _totalTransactions.toString(),
              icon: Icons.swap_horiz,
              color: Colors.purple,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'إجمالي الحجم (USD)',
              value: '\$${_formatNumber(_totalVolume)}',
              icon: Icons.attach_money,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
      mobileChild: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'إجمالي المستخدمين',
                  value: _totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'المستخدمين الموثقين',
                  value: '$_verifiedUsers (${_totalUsers > 0 ? (_verifiedUsers / _totalUsers * 100).toStringAsFixed(1) : 0}%)',
                  icon: Icons.verified_user,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'طلبات التوثيق المعلقة',
                  value: _pendingVerifications.toString(),
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'إجمالي المعاملات',
                  value: _totalTransactions.toString(),
                  icon: Icons.swap_horiz,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'إجمالي الحجم (USD)',
            value: '\$${_formatNumber(_totalVolume)}',
            icon: Icons.attach_money,
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionVolumeChart() {
    // Sort days chronologically
    final sortedDays = _transactionsByDay.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    // Create line chart data
    final spots = sortedDays.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;
      final volume = _transactionsByDay[day] ?? 0;
      
      return FlSpot(index.toDouble(), volume);
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
              'حجم المعاملات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'حجم المعاملات اليومي (USD) - ${_getTimeRangeText(_selectedTimeRange)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: sortedDays.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد بيانات كافية لعرض الرسم البياني',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1000,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= sortedDays.length) {
                                  return const SizedBox();
                                }
                                
                                final day = sortedDays[value.toInt()];
                                final parts = day.split('-');
                                
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${parts[2]}/${parts[1]}',
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
                                    _formatNumber(value),
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
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                            left: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                        minX: 0,
                        maxX: (sortedDays.length - 1).toDouble(),
                        minY: 0,
                        maxY: _transactionsByDay.values.fold(0, (max, value) => value > max ? value : max) * 1.2,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.purple,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.purple.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionDistributionChart() {
    // Calculate total volume
    final totalVolume = _volumeByType.values.fold(0, (sum, volume) => sum + volume);
    
    // Create pie chart sections
    final pieSections = _volumeByType.entries.map((entry) {
      final type = entry.key;
      final volume = entry.value;
      final percentage = totalVolume > 0 ? volume / totalVolume * 100 : 0;
      
      return PieChartSectionData(
        value: volume,
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
              'توزيع حجم المعاملات حسب النوع (USD) - ${_getTimeRangeText(_selectedTimeRange)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: totalVolume == 0
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
                            children: _volumeByType.entries.map((entry) {
                              final type = entry.key;
                              final volume = entry.value;
                              final percentage = totalVolume > 0 ? volume / totalVolume * 100 : 0;
                              
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
  
  Widget _buildUserLevelsChart() {
    // Calculate total users
    final totalUsers = _usersByLevel.values.fold(0, (sum, count) => sum + count);
    
    // Create pie chart sections
    final pieSections = _usersByLevel.entries.map((entry) {
      final level = entry.key;
      final count = entry.value;
      final percentage = totalUsers > 0 ? count / totalUsers * 100 : 0;
      
      return PieChartSectionData(
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: _getLevelColor(level),
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
              'مستويات المستخدمين',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'توزيع المستخدمين حسب المستوى',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: totalUsers == 0
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
                            children: _usersByLevel.entries.map((entry) {
                              final level = entry.key;
                              final count = entry.value;
                              final percentage = totalUsers > 0 ? count / totalUsers * 100 : 0;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _getLevelColor(level),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getLevelName(level),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '($count - ${percentage.toStringAsFixed(1)}%)',
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
