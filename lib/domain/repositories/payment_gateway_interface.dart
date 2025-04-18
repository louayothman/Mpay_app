/// واجهة لخدمات البوابة المالية
/// 
/// تحدد هذه الواجهة العمليات المتعلقة ببوابة الدفع
/// بدون تحديد كيفية تنفيذ هذه العمليات
abstract class PaymentGatewayInterface {
  /// تهيئة خدمة بوابة الدفع
  Future<void> initialize();
  
  /// الحصول على طرق الدفع المتاحة للمستخدم
  Future<List<dynamic>> getAvailablePaymentMethods(String userId);
  
  /// الحصول على عناوين محافظ العملات الرقمية
  Future<Map<String, String>> getCryptoWalletAddresses();
  
  /// إرسال طلب إيداع
  Future<dynamic> submitDepositRequest({
    required String userId,
    required String paymentMethodId,
    required double amount,
    required String currency,
    required String? reference,
    required String? proofImagePath,
    String? cryptoCurrency,
    String? walletAddress,
    Map<String, dynamic>? additionalData,
  });
  
  /// التحقق من حالة المعاملة
  Future<dynamic> checkTransactionStatus(String transactionId);
}
