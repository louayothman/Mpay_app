import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get notifications
        final notificationsQuery = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();
        
        List<Map<String, dynamic>> notifications = [];
        
        for (var doc in notificationsQuery.docs) {
          final notificationData = doc.data();
          notificationData['id'] = doc.id;
          notifications.add(notificationData as Map<String, dynamic>);
        }
        
        setState(() {
          _notifications = notifications;
        });
        
        // Mark all as read
        for (var notification in notifications) {
          if (notification['isRead'] == false) {
            await _firestore.collection('notifications').doc(notification['id']).update({
              'isRead': true,
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteNotification(String id) async {
    try {
      await _firestore.collection('notifications').doc(id).delete();
      
      setState(() {
        _notifications.removeWhere((notification) => notification['id'] == id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الإشعار')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  Future<void> _deleteAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final batch = _firestore.batch();
        
        for (var notification in _notifications) {
          final docRef = _firestore.collection('notifications').doc(notification['id']);
          batch.delete(docRef);
        }
        
        await batch.commit();
        
        setState(() {
          _notifications = [];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف جميع الإشعارات')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'الآن';
        } else {
          return 'منذ ${difference.inMinutes} دقيقة';
        }
      } else {
        return 'منذ ${difference.inHours} ساعة';
      }
    } else if (difference.inDays == 1) {
      return 'الأمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return DateFormat('yyyy/MM/dd').format(date);
    }
  }
  
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'transaction':
        return Icons.swap_horiz;
      case 'deposit':
        return Icons.add_circle_outline;
      case 'withdraw':
        return Icons.remove_circle_outline;
      case 'deal':
        return Icons.handshake;
      case 'exchange':
        return Icons.currency_exchange;
      case 'referral':
        return Icons.person_add;
      case 'commission':
        return Icons.attach_money;
      case 'commission_withdrawal':
        return Icons.money_off;
      case 'level_up':
        return Icons.star;
      case 'system':
        return Icons.info;
      case 'support':
        return Icons.support_agent;
      default:
        return Icons.notifications;
    }
  }
  
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'transaction':
        return Colors.blue;
      case 'deposit':
        return Colors.green;
      case 'withdraw':
        return Colors.red;
      case 'deal':
        return Colors.purple;
      case 'exchange':
        return Colors.orange;
      case 'referral':
        return Colors.teal;
      case 'commission':
        return Colors.amber;
      case 'commission_withdrawal':
        return Colors.brown;
      case 'level_up':
        return Colors.indigo;
      case 'system':
        return Colors.grey;
      case 'support':
        return Colors.cyan;
      default:
        return Colors.blue;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('حذف جميع الإشعارات'),
                    content: const Text('هل أنت متأكد من حذف جميع الإشعارات؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAllNotifications();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'حذف الكل',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد إشعارات',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final id = notification['id'];
    final type = notification['type'];
    final title = notification['title'];
    final message = notification['message'];
    final isRead = notification['isRead'] ?? false;
    final createdAt = notification['createdAt'] as Timestamp;
    final data = notification['data'] as Map<String, dynamic>?;
    
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(id);
      },
      child: Card(
        elevation: isRead ? 1 : 3,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isRead
              ? BorderSide.none
              : BorderSide(color: _getNotificationColor(type), width: 1),
        ),
        child: InkWell(
          onTap: () {
            // Handle notification tap based on type and data
            if (data != null) {
              // Navigate to relevant screen based on notification type
              // For example, if it's a transaction notification, navigate to transaction details
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (data != null && data.containsKey('amount') && data.containsKey('currency'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'المبلغ: ${data['amount']} ${data['currency']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
