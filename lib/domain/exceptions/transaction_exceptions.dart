import 'package:flutter/material.dart';

/// استثناءات المعاملات
/// 
/// تعريف الاستثناءات المتعلقة بعمليات المعاملات المالية والمدفوعات

/// استثناء رصيد غير كافٍ
class InsufficientFundsException implements Exception {
  final String message;
  final double available;
  final double required;
  
  InsufficientFundsException(this.message, {this.available = 0, this.required = 0});
  
  @override
  String toString() => 'InsufficientFundsException: $message (Available: $available, Required: $required)';
}

/// استثناء فشل المعاملة
class TransactionFailedException implements Exception {
  final String message;
  final String? transactionId;
  
  TransactionFailedException(this.message, {this.transactionId});
  
  @override
  String toString() {
    if (transactionId != null) {
      return 'TransactionFailedException: $message (Transaction ID: $transactionId)';
    }
    return 'TransactionFailedException: $message';
  }
}

/// استثناء تجاوز الحد
class LimitExceededException implements Exception {
  final String message;
  final double limit;
  final double attempted;
  
  LimitExceededException(this.message, {this.limit = 0, this.attempted = 0});
  
  @override
  String toString() => 'LimitExceededException: $message (Limit: $limit, Attempted: $attempted)';
}

/// استثناء عملة غير مدعومة
class UnsupportedCurrencyException implements Exception {
  final String message;
  final String currency;
  
  UnsupportedCurrencyException(this.message, this.currency);
  
  @override
  String toString() => 'UnsupportedCurrencyException: $message (Currency: $currency)';
}

/// استثناء طريقة دفع غير مدعومة
class UnsupportedPaymentMethodException implements Exception {
  final String message;
  final String method;
  
  UnsupportedPaymentMethodException(this.message, this.method);
  
  @override
  String toString() => 'UnsupportedPaymentMethodException: $message (Method: $method)';
}

/// استثناء معاملة مكررة
class DuplicateTransactionException implements Exception {
  final String message;
  final String? originalTransactionId;
  
  DuplicateTransactionException(this.message, {this.originalTransactionId});
  
  @override
  String toString() {
    if (originalTransactionId != null) {
      return 'DuplicateTransactionException: $message (Original Transaction ID: $originalTransactionId)';
    }
    return 'DuplicateTransactionException: $message';
  }
}

/// استثناء معاملة غير موجودة
class TransactionNotFoundException implements Exception {
  final String message;
  final String? transactionId;
  
  TransactionNotFoundException(this.message, {this.transactionId});
  
  @override
  String toString() {
    if (transactionId != null) {
      return 'TransactionNotFoundException: $message (Transaction ID: $transactionId)';
    }
    return 'TransactionNotFoundException: $message';
  }
}

/// استثناء معاملة منتهية الصلاحية
class TransactionExpiredException implements Exception {
  final String message;
  final String? transactionId;
  final DateTime? expiryTime;
  
  TransactionExpiredException(this.message, {this.transactionId, this.expiryTime});
  
  @override
  String toString() {
    String result = 'TransactionExpiredException: $message';
    if (transactionId != null) {
      result += ' (Transaction ID: $transactionId';
      if (expiryTime != null) {
        result += ', Expired at: $expiryTime';
      }
      result += ')';
    }
    return result;
  }
}

/// استثناء معاملة ملغاة
class TransactionCancelledException implements Exception {
  final String message;
  final String? transactionId;
  final String? cancelReason;
  
  TransactionCancelledException(this.message, {this.transactionId, this.cancelReason});
  
  @override
  String toString() {
    String result = 'TransactionCancelledException: $message';
    if (transactionId != null) {
      result += ' (Transaction ID: $transactionId';
      if (cancelReason != null) {
        result += ', Reason: $cancelReason';
      }
      result += ')';
    }
    return result;
  }
}

/// استثناء معاملة مرفوضة
class TransactionRejectedException implements Exception {
  final String message;
  final String? transactionId;
  final String? rejectReason;
  
  TransactionRejectedException(this.message, {this.transactionId, this.rejectReason});
  
  @override
  String toString() {
    String result = 'TransactionRejectedException: $message';
    if (transactionId != null) {
      result += ' (Transaction ID: $transactionId';
      if (rejectReason != null) {
        result += ', Reason: $rejectReason';
      }
      result += ')';
    }
    return result;
  }
}

/// استثناء عنوان محفظة غير صالح
class InvalidWalletAddressException implements Exception {
  final String message;
  final String? address;
  final String? currency;
  
  InvalidWalletAddressException(this.message, {this.address, this.currency});
  
  @override
  String toString() {
    String result = 'InvalidWalletAddressException: $message';
    if (address != null) {
      result += ' (Address: ${address!.substring(0, 4)}...${address!.substring(address!.length - 4)}';
      if (currency != null) {
        result += ', Currency: $currency';
      }
      result += ')';
    }
    return result;
  }
}

/// استثناء مبلغ غير صالح
class InvalidAmountException implements Exception {
  final String message;
  final double? amount;
  
  InvalidAmountException(this.message, {this.amount});
  
  @override
  String toString() {
    if (amount != null) {
      return 'InvalidAmountException: $message (Amount: $amount)';
    }
    return 'InvalidAmountException: $message';
  }
}

/// استثناء فشل بوابة الدفع
class PaymentGatewayException implements Exception {
  final String message;
  final String? gatewayName;
  final String? errorCode;
  
  PaymentGatewayException(this.message, {this.gatewayName, this.errorCode});
  
  @override
  String toString() {
    String result = 'PaymentGatewayException: $message';
    if (gatewayName != null || errorCode != null) {
      result += ' (';
      if (gatewayName != null) {
        result += 'Gateway: $gatewayName';
        if (errorCode != null) {
          result += ', ';
        }
      }
      if (errorCode != null) {
        result += 'Error Code: $errorCode';
      }
      result += ')';
    }
    return result;
  }
}

/// استثناء فشل التحويل
class TransferFailedException implements Exception {
  final String message;
  final String? fromAccount;
  final String? toAccount;
  
  TransferFailedException(this.message, {this.fromAccount, this.toAccount});
  
  @override
  String toString() {
    String result = 'TransferFailedException: $message';
    if (fromAccount != null || toAccount != null) {
      result += ' (';
      if (fromAccount != null) {
        result += 'From: $fromAccount';
        if (toAccount != null) {
          result += ', ';
        }
      }
      if (toAccount != null) {
        result += 'To: $toAccount';
      }
      result += ')';
    }
    return result;
  }
}
