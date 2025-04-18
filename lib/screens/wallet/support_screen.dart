import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _tickets = [];
  
  @override
  void initState() {
    super.initState();
    _loadTickets();
  }
  
  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get support tickets
        final ticketsQuery = await _firestore
            .collection('support_tickets')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();
        
        List<Map<String, dynamic>> tickets = [];
        
        for (var doc in ticketsQuery.docs) {
          final ticketData = doc.data();
          ticketData['id'] = doc.id;
          tickets.add(ticketData as Map<String, dynamic>);
        }
        
        setState(() {
          _tickets = tickets;
        });
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
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'مفتوحة';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'resolved':
        return 'تم الحل';
      case 'closed':
        return 'مغلقة';
      default:
        return status;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'account':
        return Icons.person;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'transaction':
        return Icons.swap_horiz;
      case 'deposit':
        return Icons.add_circle_outline;
      case 'withdraw':
        return Icons.remove_circle_outline;
      case 'security':
        return Icons.security;
      case 'bug':
        return Icons.bug_report;
      case 'feature':
        return Icons.lightbulb;
      case 'other':
        return Icons.help;
      default:
        return Icons.help;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم الفني'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: Column(
                children: [
                  // FAQ and Help Center
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
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
                              'مركز المساعدة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildHelpItem(
                                    icon: Icons.question_answer,
                                    title: 'الأسئلة الشائعة',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const FAQScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildHelpItem(
                                    icon: Icons.contact_support,
                                    title: 'تواصل معنا',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ContactUsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Tickets header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'تذاكر الدعم الفني',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateTicketScreen(),
                              ),
                            ).then((_) => _loadTickets());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('تذكرة جديدة'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tickets list
                  Expanded(
                    child: _tickets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.support,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد تذاكر دعم فني',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'انقر على "تذكرة جديدة" لإنشاء تذكرة دعم فني',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _tickets.length,
                            itemBuilder: (context, index) {
                              final ticket = _tickets[index];
                              return _buildTicketItem(ticket);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTicketItem(Map<String, dynamic> ticket) {
    final id = ticket['id'];
    final subject = ticket['subject'];
    final category = ticket['category'];
    final status = ticket['status'];
    final createdAt = ticket['createdAt'] as Timestamp;
    final lastUpdated = ticket['lastUpdated'] as Timestamp?;
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailsScreen(ticketId: id),
            ),
          ).then((_) => _loadTickets());
        },
        borderRadius: BorderRadius.circular(12),
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
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تاريخ الإنشاء: ${_formatDate(createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (lastUpdated != null)
                    Text(
                      'آخر تحديث: ${_formatDate(lastUpdated)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأسئلة الشائعة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            question: 'كيف يمكنني إنشاء محفظة؟',
            answer: 'يتم إنشاء المحفظة تلقائياً عند تسجيل حساب جديد في التطبيق. يمكنك الوصول إلى محفظتك من خلال الضغط على أيقونة المحفظة في الشاشة الرئيسية.',
          ),
          _buildFAQItem(
            question: 'كيف يمكنني إرسال الأموال؟',
            answer: 'لإرسال الأموال، انتقل إلى شاشة المحفظة واضغط على زر "إرسال". ثم أدخل رمز محفظة المستلم أو امسح رمز QR الخاص به، وحدد العملة والمبلغ، ثم اضغط على "إرسال".',
          ),
          _buildFAQItem(
            question: 'كيف يمكنني استلام الأموال؟',
            answer: 'لاستلام الأموال، انتقل إلى شاشة المحفظة واضغط على زر "استلام". سيظهر رمز QR ورمز المحفظة الخاص بك. يمكنك مشاركة هذه المعلومات مع الشخص الذي سيرسل لك الأموال.',
          ),
          _buildFAQItem(
            question: 'ما هي العملات المدعومة؟',
            answer: 'يدعم التطبيق حالياً العملات التالية: الدولار الأمريكي (USD)، اليورو (EUR)، الليرة السورية (SYP)، الريال السعودي (SAR)، الدرهم الإماراتي (AED)، والليرة التركية (TRY).',
          ),
          _buildFAQItem(
            question: 'كيف يمكنني تبديل العملات؟',
            answer: 'لتبديل العملات، انتقل إلى شاشة المحفظة واضغط على زر "مبادلة". ثم حدد العملة المصدر والعملة الهدف والمبلغ، وستظهر لك معدلات الصرف والرسوم. اضغط على "مبادلة" لإتمام العملية.',
          ),
          _buildFAQItem(
            question: 'ما هي رسوم المعاملات؟',
            answer: 'تختلف رسوم المعاملات حسب نوع العملية والعملة المستخدمة. عادةً ما تكون رسوم الإرسال 1% من قيمة المعاملة، ورسوم المبادلة 2% من قيمة المعاملة. يمكن أن تقل هذه الرسوم بناءً على مستوى المستخدم.',
          ),
          _buildFAQItem(
            question: 'كيف يمكنني إيداع الأموال في محفظتي؟',
            answer: 'لإيداع الأموال، انتقل إلى شاشة المحفظة واضغط على زر "إيداع". ثم اختر طريقة الإيداع المناسبة وأدخل المبلغ واتبع التعليمات لإتمام عملية الإيداع.',
          ),
          _buildFAQItem(
            question: 'كيف يمكنني سحب الأموال من محفظتي؟',
            answer: 'لسحب الأموال، انتقل إلى شاشة المحفظة واضغط على زر "سحب". ثم اختر طريقة السحب المناسبة وأدخل المبلغ واتبع التعليمات لإتمام عملية السحب.',
          ),
          _buildFAQItem(
            question: 'ما هو نظام المستويات؟',
            answer: 'نظام المستويات هو نظام مكافآت يتيح للمستخدمين الحصول على مزايا إضافية كلما زاد نشاطهم في التطبيق. هناك أربعة مستويات: برونزي، فضي، ذهبي، وبلاتيني. كلما ارتفع مستواك، حصلت على خصومات أكبر على الرسوم ومزايا أخرى.',
          ),
          _buildFAQItem(
            question: 'كيف يعمل نظام الإحالة؟',
            answer: 'يمكنك كسب عمولات من خلال دعوة أصدقائك للتسجيل في التطبيق باستخدام رمز الإحالة الخاص بك. ستحصل على مكافأة عند تسجيل كل صديق، بالإضافة إلى نسبة من رسوم معاملاتهم.',
          ),
          _buildFAQItem(
            question: 'ماذا أفعل إذا نسيت كلمة المرور؟',
            answer: 'إذا نسيت كلمة المرور، اضغط على "نسيت كلمة المرور" في شاشة تسجيل الدخول. سيتم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني المسجل.',
          ),
          _buildFAQItem(
            question: 'كيف يمكنني تغيير رمز PIN الخاص بي؟',
            answer: 'لتغيير رمز PIN، انتقل إلى الإعدادات > الأمان > تغيير رمز PIN. ستحتاج إلى إدخال رمز PIN الحالي ثم إدخال وتأكيد رمز PIN الجديد.',
          ),
          _buildFAQItem(
            question: 'ماذا أفعل إذا واجهت مشكلة في التطبيق؟',
            answer: 'إذا واجهت أي مشكلة، يمكنك إنشاء تذكرة دعم فني من خلال الضغط على "تذكرة جديدة" في شاشة الدعم الفني. سيقوم فريق الدعم بالرد عليك في أقرب وقت ممكن.',
          ),
        ],
      ),
    );
  }
  
  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }
}

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'other';
  bool _isLoading = false;
  
  final List<Map<String, dynamic>> _categories = [
    {'id': 'account', 'name': 'الحساب', 'icon': Icons.person},
    {'id': 'wallet', 'name': 'المحفظة', 'icon': Icons.account_balance_wallet},
    {'id': 'transaction', 'name': 'المعاملات', 'icon': Icons.swap_horiz},
    {'id': 'deposit', 'name': 'الإيداع', 'icon': Icons.add_circle_outline},
    {'id': 'withdraw', 'name': 'السحب', 'icon': Icons.remove_circle_outline},
    {'id': 'security', 'name': 'الأمان', 'icon': Icons.security},
    {'id': 'bug', 'name': 'خطأ في التطبيق', 'icon': Icons.bug_report},
    {'id': 'feature', 'name': 'اقتراح ميزة', 'icon': Icons.lightbulb},
    {'id': 'other', 'name': 'أخرى', 'icon': Icons.help},
  ];
  
  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _submitContactForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create support ticket
        await FirebaseFirestore.instance.collection('support_tickets').add({
          'userId': user.uid,
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
          'category': _selectedCategory,
          'status': 'open',
          'createdAt': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
          'messages': [
            {
              'senderId': user.uid,
              'senderType': 'user',
              'message': _messageController.text.trim(),
              'createdAt': Timestamp.now(),
            }
          ],
        });
        
        // Create notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': user.uid,
          'type': 'support',
          'title': 'تم إنشاء تذكرة دعم فني جديدة',
          'message': 'تم استلام تذكرة الدعم الفني الخاصة بك وسيتم الرد عليها قريباً',
          'isRead': false,
          'createdAt': Timestamp.now(),
          'data': {
            'category': _selectedCategory,
          },
        });
        
        // Show success message
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رسالتك بنجاح')),
        );
        
        // Navigate back
        Navigator.pop(context);
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تواصل معنا'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact info
              Card(
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
                        'معلومات الاتصال',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildContactItem(
                        icon: Icons.email,
                        title: 'البريد الإلكتروني',
                        value: 'support@mpay.com',
                      ),
                      _buildContactItem(
                        icon: Icons.phone,
                        title: 'رقم الهاتف',
                        value: '+963 11 123 4567',
                      ),
                      _buildContactItem(
                        icon: Icons.access_time,
                        title: 'ساعات العمل',
                        value: 'الأحد - الخميس: 9:00 ص - 5:00 م',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Contact form
              const Text(
                'أرسل لنا رسالة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Category
              const Text(
                'اختر فئة المشكلة:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category['id'];
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['id'];
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'],
                            size: 16,
                            color: isSelected ? Colors.blue : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.blue : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Subject
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'الموضوع',
                  hintText: 'أدخل موضوع الرسالة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الموضوع';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Message
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'الرسالة',
                  hintText: 'اكتب رسالتك هنا',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الرسالة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitContactForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'إرسال',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'other';
  bool _isLoading = false;
  
  final List<Map<String, dynamic>> _categories = [
    {'id': 'account', 'name': 'الحساب', 'icon': Icons.person},
    {'id': 'wallet', 'name': 'المحفظة', 'icon': Icons.account_balance_wallet},
    {'id': 'transaction', 'name': 'المعاملات', 'icon': Icons.swap_horiz},
    {'id': 'deposit', 'name': 'الإيداع', 'icon': Icons.add_circle_outline},
    {'id': 'withdraw', 'name': 'السحب', 'icon': Icons.remove_circle_outline},
    {'id': 'security', 'name': 'الأمان', 'icon': Icons.security},
    {'id': 'bug', 'name': 'خطأ في التطبيق', 'icon': Icons.bug_report},
    {'id': 'feature', 'name': 'اقتراح ميزة', 'icon': Icons.lightbulb},
    {'id': 'other', 'name': 'أخرى', 'icon': Icons.help},
  ];
  
  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _createTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create support ticket
        await FirebaseFirestore.instance.collection('support_tickets').add({
          'userId': user.uid,
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
          'category': _selectedCategory,
          'status': 'open',
          'createdAt': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
          'messages': [
            {
              'senderId': user.uid,
              'senderType': 'user',
              'message': _messageController.text.trim(),
              'createdAt': Timestamp.now(),
            }
          ],
        });
        
        // Create notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': user.uid,
          'type': 'support',
          'title': 'تم إنشاء تذكرة دعم فني جديدة',
          'message': 'تم استلام تذكرة الدعم الفني الخاصة بك وسيتم الرد عليها قريباً',
          'isRead': false,
          'createdAt': Timestamp.now(),
          'data': {
            'category': _selectedCategory,
          },
        });
        
        // Show success message
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء تذكرة الدعم الفني بنجاح')),
        );
        
        // Navigate back
        Navigator.pop(context);
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء تذكرة دعم فني'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              const Text(
                'اختر فئة المشكلة:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category['id'];
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['id'];
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'],
                            size: 16,
                            color: isSelected ? Colors.blue : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.blue : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Subject
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'الموضوع',
                  hintText: 'أدخل موضوع المشكلة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الموضوع';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Message
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'وصف المشكلة',
                  hintText: 'اشرح المشكلة بالتفصيل',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال وصف المشكلة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTicket,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'إنشاء تذكرة',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              // Tips
              const SizedBox(height: 24),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نصائح للحصول على مساعدة أسرع:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.check_circle,
                        text: 'اختر الفئة المناسبة للمشكلة',
                      ),
                      _buildTipItem(
                        icon: Icons.check_circle,
                        text: 'اكتب عنواناً واضحاً ومختصراً',
                      ),
                      _buildTipItem(
                        icon: Icons.check_circle,
                        text: 'اشرح المشكلة بالتفصيل',
                      ),
                      _buildTipItem(
                        icon: Icons.check_circle,
                        text: 'اذكر الخطوات التي أدت إلى المشكلة',
                      ),
                      _buildTipItem(
                        icon: Icons.check_circle,
                        text: 'اذكر أي رسائل خطأ ظهرت لك',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTipItem({
    required IconData icon,
    required String text,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}

class TicketDetailsScreen extends StatefulWidget {
  final String ticketId;
  
  const TicketDetailsScreen({
    super.key,
    required this.ticketId,
  });

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _messageController = TextEditingController();
  
  bool _isLoading = true;
  Map<String, dynamic> _ticketData = {};
  List<Map<String, dynamic>> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _loadTicketData();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTicketData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final ticketDoc = await _firestore.collection('support_tickets').doc(widget.ticketId).get();
      
      if (ticketDoc.exists) {
        final ticketData = ticketDoc.data() as Map<String, dynamic>;
        final messages = List<Map<String, dynamic>>.from(ticketData['messages'] ?? []);
        
        // Sort messages by createdAt
        messages.sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp).toDate();
          final bTime = (b['createdAt'] as Timestamp).toDate();
          return aTime.compareTo(bTime);
        });
        
        setState(() {
          _ticketData = ticketData;
          _messages = messages;
        });
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
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Add message to ticket
        final newMessage = {
          'senderId': user.uid,
          'senderType': 'user',
          'message': message,
          'createdAt': Timestamp.now(),
        };
        
        await _firestore.collection('support_tickets').doc(widget.ticketId).update({
          'messages': FieldValue.arrayUnion([newMessage]),
          'lastUpdated': Timestamp.now(),
          'status': 'open', // Reopen ticket if it was closed
        });
        
        // Clear message input
        _messageController.clear();
        
        // Reload ticket data
        _loadTicketData();
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
  
  Future<void> _closeTicket() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firestore.collection('support_tickets').doc(widget.ticketId).update({
        'status': 'closed',
        'lastUpdated': Timestamp.now(),
      });
      
      // Reload ticket data
      _loadTicketData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إغلاق التذكرة بنجاح')),
      );
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
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'مفتوحة';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'resolved':
        return 'تم الحل';
      case 'closed':
        return 'مغلقة';
      default:
        return status;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'account':
        return Icons.person;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'transaction':
        return Icons.swap_horiz;
      case 'deposit':
        return Icons.add_circle_outline;
      case 'withdraw':
        return Icons.remove_circle_outline;
      case 'security':
        return Icons.security;
      case 'bug':
        return Icons.bug_report;
      case 'feature':
        return Icons.lightbulb;
      case 'other':
        return Icons.help;
      default:
        return Icons.help;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final status = _ticketData['status'] ?? 'open';
    final isClosed = status == 'closed' || status == 'resolved';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل التذكرة'),
        actions: [
          if (!isClosed)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('إغلاق التذكرة'),
                    content: const Text('هل أنت متأكد من إغلاق هذه التذكرة؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _closeTicket();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('إغلاق'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'إغلاق التذكرة',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTicketData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Ticket info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getCategoryIcon(_ticketData['category'] ?? 'other'),
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _ticketData['subject'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(status),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تاريخ الإنشاء: ${_formatDate(_ticketData['createdAt'] as Timestamp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_ticketData['lastUpdated'] != null)
                        Text(
                          'آخر تحديث: ${_formatDate(_ticketData['lastUpdated'] as Timestamp)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Messages
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['senderType'] == 'user';
                      
                      return _buildMessageItem(
                        message: message['message'],
                        isUser: isUser,
                        timestamp: message['createdAt'] as Timestamp,
                      );
                    },
                  ),
                ),
                
                // Message input
                if (!isClosed)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'اكتب رسالتك هنا...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.newline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Text(
                        'هذه التذكرة مغلقة. لا يمكن إضافة رسائل جديدة.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
  
  Widget _buildMessageItem({
    required String message,
    required bool isUser,
    required Timestamp timestamp,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 4),
            Text(
              _formatDate(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
