import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String _walletId = '';
  String _selectedCurrency = 'USD';
  List<String> _supportedCurrencies = ['USD', 'SYP', 'EUR', 'SAR', 'AED', 'TRY'];
  Map<String, double> _dailyLimits = {};
  
  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }
  
  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get wallet data
        final walletDoc = await _firestore.collection('wallets').doc(user.uid).get();
        
        if (walletDoc.exists) {
          final walletData = walletDoc.data() as Map<String, dynamic>;
          setState(() {
            _walletId = walletData['walletId'] ?? user.uid;
          });
        }
        
        // Get user data for daily limits
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _dailyLimits = Map<String, double>.from(userData['dailyLimits'] ?? {});
            
            // Ensure all supported currencies have a limit entry
            for (var currency in _supportedCurrencies) {
              _dailyLimits[currency] ??= 0.0;
            }
          });
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
  
  String _formatLimit(double limit) {
    return limit.toStringAsFixed(limit.truncateToDouble() == limit ? 0 : 2);
  }
  
  void _copyWalletId() {
    Clipboard.setData(ClipboardData(text: _walletId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رمز المحفظة')),
    );
  }
  
  void _shareWalletInfo() {
    final text = 'رمز محفظتي في تطبيق Mpay: $_walletId\n'
        'يمكنك استخدام هذا الرمز لإرسال الأموال إلي.';
    Share.share(text);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استلام الأموال'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Currency Selector
                  const Text(
                    'اختر العملة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Currency Chips
                  Wrap(
                    spacing: 8,
                    children: _supportedCurrencies.map((currency) {
                      final isSelected = currency == _selectedCurrency;
                      return ChoiceChip(
                        label: Text(
                          currency,
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Theme.of(context).primaryColor,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCurrency = currency;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Daily Limit
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الحد اليومي للاستلام',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_getCurrencySymbol(_selectedCurrency)} ${_formatLimit(_dailyLimits[_selectedCurrency] ?? 0.0)} $_selectedCurrency',
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // QR Code
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text(
                            'مسح رمز QR للاستلام',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          QrImageView(
                            data: '$_walletId:$_selectedCurrency',
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'أو استخدم رمز المحفظة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _walletId,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: _copyWalletId,
                                  tooltip: 'نسخ',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Share Button
                  ElevatedButton.icon(
                    onPressed: _shareWalletInfo,
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة معلومات المحفظة'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Instructions
                  const Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تعليمات الاستلام',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. اختر العملة التي ترغب في استلامها\n'
                            '2. اطلب من المرسل مسح رمز QR أو إدخال رمز محفظتك\n'
                            '3. سيتم إشعارك فور استلام الأموال\n'
                            '4. تحقق من رصيدك في صفحة المحفظة',
                            style: TextStyle(fontSize: 14),
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
}
