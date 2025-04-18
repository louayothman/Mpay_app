import 'package:flutter/material.dart';
import 'package:mpay_app/widgets/error_handling_wrapper.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/services/firestore_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreTransactions = true;
  String? _lastDocumentId;
  Timestamp? _lastTimestamp;
  String _selectedFilter = 'all';
  
  // تحديد حجم الصفحة للتحميل المتدرج
  final int _pageSize = 10;
  
  // متغير للتحكم في عملية السحب للتحديث
  bool _isRefreshing = false;
  
  // متغير لتتبع حالة الخطأ
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    
    if (refresh) {
      setState(() {
        _isRefreshing = true;
        _transactions = [];
        _lastDocumentId = null;
        _lastTimestamp = null;
        _hasMoreTransactions = true;
        _errorMessage = null;
      });
    } else if (_isLoadingMore || !_hasMoreTransactions) {
      return;
    } else {
      setState(() {
        _isLoading = true;
        _isLoadingMore = true;
        _errorMessage = null;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('لم يتم العثور على المستخدي');
      }

      Query query = FirebaseFirestore.instance.collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      // تطبيق الفلتر إذا كان محدد
      if (_selectedFilter != 'all') {
        query = query.where('type', isEqualTo: _selectedFilter);
      }
      
      // تطبيق التصفح المتدرج باستخدام startAfter
      if (_lastDocumentId != null && _lastTimestamp != null && !refresh) {
        // الحصول على المستند الأخير للاستخدام كنقطة بداية
        DocumentSnapshot lastDoc = await FirebaseFirestore.instance
            .collection('transactions')
            .doc(_lastDocumentId)
            .get();
            
        // التأكد من أن المستند موجود
        if (lastDoc.exists) {
          query = query.startAfter([_lastTimestamp]);
        }
      }

      final snapshot = await query.get();
      final List<Map<String, dynamic>> newTransactions = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        newTransactions.add({
          'id': doc.id,
          ...data,
        });
      }
      
      // تحديث المؤشر للصفحة التالية
      if (newTransactions.isNotEmpty) {
        _lastDocumentId = newTransactions.last['id'];
        _lastTimestamp = newTransactions.last['timestamp'];
      }
      
      // التحقق مما إذا كانت هناك المزيد من البيانات
      final hasMore = newTransactions.length >= _pageSize;

      if (mounted) {
        setState(() {
          if (refresh) {
            _transactions = newTransactions;
            _isRefreshing = false;
          } else {
            _transactions.addAll(newTransactions);
          }
          _isLoading = false;
          _isLoadingMore = false;
          _hasMoreTransactions = hasMore;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isRefreshing = false;
          _errorMessage = 'فشل في تحميل المعاملات: $e';
        });
        ErrorHandler.showErrorSnackBar(
          context, 
          'فشل في تحميل المعاملات: $e'
        );
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (!_hasMoreTransactions || _isLoadingMore || _isLoading) return;
    
    await _loadTransactions();
  }

  Future<void> _refreshTransactions() async {
    if (_isRefreshing) return;
    return _loadTransactions(refresh: true);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'غير متوفر';
    
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }
    
    return 'غير متوفر';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'مكتمل':
        return Colors.green;
      case 'pending':
      case 'قيد الانتظار':
        return Colors.orange;
      case 'rejected':
      case 'مرفوض':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
      case 'إيداع':
        return Icons.arrow_downward;
      case 'withdrawal':
      case 'سحب':
        return Icons.arrow_upward;
      case 'transfer':
      case 'تحويل':
        return Icons.swap_horiz;
      case 'exchange':
      case 'تبادل':
        return Icons.currency_exchange;
      default:
        return Icons.receipt_long;
    }
  }

  String _getTransactionTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return 'إيداع';
      case 'withdrawal':
        return 'سحب';
      case 'transfer':
        return 'تحويل';
      case 'exchange':
        return 'تبادل';
      default:
        return type;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'قيد الانتظار';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorHandlingWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المعاملات'),
        ),
        body: Column(
          children: [
            // Filter options
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'تصفية حسب:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'الكل'),
                          const SizedBox(width: 8),
                          _buildFilterChip('deposit', 'إيداع'),
                          const SizedBox(width: 8),
                          _buildFilterChip('withdrawal', 'سحب'),
                          const SizedBox(width: 8),
                          _buildFilterChip('transfer', 'تحويل'),
                          const SizedBox(width: 8),
                          _buildFilterChip('exchange', 'تبادل'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Transactions list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshTransactions,
                child: _isLoading && _transactions.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _transactions.isEmpty
                        ? _buildEmptyState()
                        : _buildTransactionsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد معاملات',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFilter != 'all'
                    ? 'جرب تغيير الفلتر أو اسحب للأسفل للتحديث'
                    : 'اسحب للأسفل للتحديث',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return LazyLoadingListView(
      itemCount: _transactions.length + (_hasMoreTransactions ? 1 : 0),
      onEndReached: _hasMoreTransactions ? _loadMoreTransactions : null,
      endReachThreshold: 500.0, // تحميل المزيد عندما نصل إلى 500 بكسل من النهاية
      itemBuilder: (context, index) {
        // عرض مؤشر التحميل في نهاية القائمة
        if (index == _transactions.length) {
          return _isLoadingMore
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                )
              : const SizedBox.shrink();
        }
        
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction);
      },
      padding: const EdgeInsets.all(16),
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && _selectedFilter != value) {
          setState(() {
            _selectedFilter = value;
          });
          _loadTransactions(refresh: true);
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String? ?? 'unknown';
    final method = transaction['method'] as String? ?? '';
    final amount = transaction['amount'] as num? ?? 0;
    final status = transaction['status'] as String? ?? 'pending';
    final timestamp = transaction['timestamp'];
    final notes = transaction['notes'] as String? ?? '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTransactionIcon(type),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTransactionTypeText(type),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          method,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${type.toLowerCase() == 'withdrawal' ? '-' : '+'} ${amount.toString()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: type.toLowerCase() == 'withdrawal' ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (notes.isNotEmpty)
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String? ?? 'unknown';
    final method = transaction['method'] as String? ?? '';
    final amount = transaction['amount'] as num? ?? 0;
    final status = transaction['status'] as String? ?? 'pending';
    final timestamp = transaction['timestamp'];
    final notes = transaction['notes'] as String? ?? '';
    final walletAddress = transaction['walletAddress'] as String? ?? '';
    final receiptUrl = transaction['receiptUrl'] as String? ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تفاصيل المعاملة',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    _buildDetailRow('نوع المعاملة', _getTransactionTypeText(type)),
                    _buildDetailRow('الطريقة', method),
                    _buildDetailRow('المبلغ', amount.toString()),
                    _buildDetailRow('الحالة', _getStatusText(status), _getStatusColor(status)),
                    _buildDetailRow('التاريخ', _formatTimestamp(timestamp)),
                    _buildDetailRow('رقم المعاملة', transaction['id'] ?? ''),
                    
                    if (walletAddress.isNotEmpty)
                      _buildDetailRow('عنوان المحفظة', walletAddress),
                    
                    if (notes.isNotEmpty)
                      _buildDetailRow('ملاحظات', notes),
                    
                    if (receiptUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'صورة الإيصال',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: OptimizedImage(
                          imageUrl: receiptUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.grey[400], size: 48),
                                  const SizedBox(height: 8),
                                  const Text('فشل تحميل الصورة'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    if (status.toLowerCase() == 'pending') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showCancelTransactionDialog(transaction);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('إلغاء المعاملة'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: value.length > 30 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ':',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelTransactionDialog(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء المعاملة'),
        content: const Text(
          'هل أنت متأكد من رغبتك في إلغاء هذه المعاملة؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelTransaction(transaction['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelTransaction(String? transactionId) async {
    if (transactionId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firestoreService.cancelTransaction(transactionId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء المعاملة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        
        // تحديث القائمة بعد الإلغاء
        _loadTransactions(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ErrorHandler.showErrorSnackBar(
          context, 
          'فشل في إلغاء المعاملة: $e'
        );
      }
    }
  }
}
