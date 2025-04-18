// Core data models and services for Mpay application
import 'package:cloud_firestore/cloud_firestore.dart';

// User model
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isVerified;
  final String level;
  final double totalTransactions;
  final String referralCode;
  final String referredBy;
  final int referralCount;
  final String fcmToken;
  final bool isAdmin;
  final List<String> adminPermissions;
  final String profilePicture;
  final Map<String, double> dailyLimits;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    required this.lastLogin,
    required this.isVerified,
    required this.level,
    required this.totalTransactions,
    required this.referralCode,
    this.referredBy = '',
    this.referralCount = 0,
    this.fcmToken = '',
    this.isAdmin = false,
    this.adminPermissions = const [],
    this.profilePicture = '',
    required this.dailyLimits,
  });

  // Convert from Firestore
  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    DateTime lastLoginDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
      
      lastLoginDate = data['lastLogin'] is Timestamp 
          ? (data['lastLogin'] as Timestamp).toDate() 
          : DateTime.now();
    } catch (e) {
      createdAtDate = DateTime.now();
      lastLoginDate = DateTime.now();
    }

    return User(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      createdAt: createdAtDate,
      lastLogin: lastLoginDate,
      isVerified: data['isVerified'] ?? false,
      level: data['level'] ?? 'bronze',
      totalTransactions: data['totalTransactions']?.toDouble() ?? 0.0,
      referralCode: data['referralCode'] ?? '',
      referredBy: data['referredBy'] ?? '',
      referralCount: data['referralCount'] ?? 0,
      fcmToken: data['fcmToken'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      adminPermissions: List<String>.from(data['adminPermissions'] ?? []),
      profilePicture: data['profilePicture'] ?? '',
      dailyLimits: Map<String, double>.from(data['dailyLimits'] ?? {}),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isVerified': isVerified,
      'level': level,
      'totalTransactions': totalTransactions,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralCount': referralCount,
      'fcmToken': fcmToken,
      'isAdmin': isAdmin,
      'adminPermissions': adminPermissions,
      'profilePicture': profilePicture,
      'dailyLimits': dailyLimits,
    };
  }
}

// Wallet model
class Wallet {
  final String walletId;
  final Map<String, double> balances;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.walletId,
    required this.balances,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Firestore
  factory Wallet.fromFirestore(Map<String, dynamic> data, String id) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    DateTime updatedAtDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
      
      updatedAtDate = data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now();
    } catch (e) {
      createdAtDate = DateTime.now();
      updatedAtDate = DateTime.now();
    }

    // Safely convert balances
    Map<String, double> balancesMap = {};
    if (data['balances'] != null && data['balances'] is Map) {
      try {
        balancesMap = Map<String, double>.from(
          (data['balances'] as Map).map((key, value) => 
            MapEntry(key.toString(), (value is num) ? value.toDouble() : 0.0))
        );
      } catch (e) {
        balancesMap = {};
      }
    }

    return Wallet(
      walletId: id,
      balances: balancesMap,
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'walletId': walletId,
      'balances': balances,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// Transaction model
class Transaction {
  final String id;
  final String type;
  final String senderId;
  final String receiverId;
  final double amount;
  final String currency;
  final double fee;
  final double discount;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String notes;
  final String referenceId;

  Transaction({
    required this.id,
    required this.type,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.currency,
    required this.fee,
    required this.discount,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.notes = '',
    this.referenceId = '',
  });

  // Validate transaction data
  static bool validateTransactionData(double amount, double fee, double discount) {
    if (amount <= 0) return false;
    if (fee < 0) return false;
    if (discount < 0) return false;
    if (discount > amount) return false;
    return true;
  }

  // Convert from Firestore
  factory Transaction.fromFirestore(Map<String, dynamic> data, String id) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert numeric values
    double amount = data['amount']?.toDouble() ?? 0.0;
    double fee = data['fee']?.toDouble() ?? 0.0;
    double discount = data['discount']?.toDouble() ?? 0.0;
    
    // Validate financial data
    if (!validateTransactionData(amount, fee, discount)) {
      throw ArgumentError('Invalid transaction data');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    DateTime? completedAtDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
      
      completedAtDate = data['completedAt'] is Timestamp 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null;
    } catch (e) {
      createdAtDate = DateTime.now();
      completedAtDate = null;
    }

    return Transaction(
      id: id,
      type: data['type'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      amount: amount,
      currency: data['currency'] ?? '',
      fee: fee,
      discount: discount,
      status: data['status'] ?? '',
      createdAt: createdAtDate,
      completedAt: completedAtDate,
      notes: data['notes'] ?? '',
      referenceId: data['referenceId'] ?? '',
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'currency': currency,
      'fee': fee,
      'discount': discount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
      'referenceId': referenceId,
    };
  }
}

// Exchange model
class Exchange {
  final String id;
  final String userId;
  final String fromCurrency;
  final String toCurrency;
  final double fromAmount;
  final double toAmount;
  final double exchangeRate;
  final double fee;
  final double discount;
  final DateTime createdAt;
  final String status;

  Exchange({
    required this.id,
    required this.userId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAmount,
    required this.toAmount,
    required this.exchangeRate,
    required this.fee,
    required this.discount,
    required this.createdAt,
    required this.status,
  });

  // Validate exchange data
  static bool validateExchangeData(double fromAmount, double toAmount, 
                                  double exchangeRate, double fee, double discount) {
    if (fromAmount <= 0) return false;
    if (toAmount <= 0) return false;
    if (exchangeRate <= 0) return false;
    if (fee < 0) return false;
    if (discount < 0) return false;
    if (discount > fromAmount) return false;
    return true;
  }

  // Convert from Firestore
  factory Exchange.fromFirestore(Map<String, dynamic> data, String id) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert numeric values
    double fromAmount = data['fromAmount']?.toDouble() ?? 0.0;
    double toAmount = data['toAmount']?.toDouble() ?? 0.0;
    double exchangeRate = data['exchangeRate']?.toDouble() ?? 0.0;
    double fee = data['fee']?.toDouble() ?? 0.0;
    double discount = data['discount']?.toDouble() ?? 0.0;
    
    // Validate financial data
    if (!validateExchangeData(fromAmount, toAmount, exchangeRate, fee, discount)) {
      throw ArgumentError('Invalid exchange data');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
    } catch (e) {
      createdAtDate = DateTime.now();
    }

    return Exchange(
      id: id,
      userId: data['userId'] ?? '',
      fromCurrency: data['fromCurrency'] ?? '',
      toCurrency: data['toCurrency'] ?? '',
      fromAmount: fromAmount,
      toAmount: toAmount,
      exchangeRate: exchangeRate,
      fee: fee,
      discount: discount,
      createdAt: createdAtDate,
      status: data['status'] ?? '',
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'fromAmount': fromAmount,
      'toAmount': toAmount,
      'exchangeRate': exchangeRate,
      'fee': fee,
      'discount': discount,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}

// Offer model - Define before Deal to fix reference issue
class Offer {
  final String userId;
  final double amount;
  final String status;
  final DateTime createdAt;

  Offer({
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  // Validate offer data
  static bool validateOfferData(double amount) {
    return amount > 0;
  }

  // Convert from Map
  factory Offer.fromMap(Map<String, dynamic> data) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert numeric values
    double amount = data['amount']?.toDouble() ?? 0.0;
    
    // Validate financial data
    if (!validateOfferData(amount)) {
      throw ArgumentError('Invalid offer amount');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
    } catch (e) {
      createdAtDate = DateTime.now();
    }

    return Offer(
      userId: data['userId'] ?? '',
      amount: amount,
      status: data['status'] ?? '',
      createdAt: createdAtDate,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// Deal model
class Deal {
  final String id;
  final String creatorId;
  final String type;
  final String currency;
  final double amount;
  final double exchangeRate;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Offer> offers;

  Deal({
    required this.id,
    required this.creatorId,
    required this.type,
    required this.currency,
    required this.amount,
    required this.exchangeRate,
    this.notes = '',
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.offers = const [],
  });

  // Validate deal data
  static bool validateDealData(double amount, double exchangeRate) {
    if (amount <= 0) return false;
    if (exchangeRate <= 0) return false;
    return true;
  }

  // Convert from Firestore
  factory Deal.fromFirestore(Map<String, dynamic> data, String id) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert numeric values
    double amount = data['amount']?.toDouble() ?? 0.0;
    double exchangeRate = data['exchangeRate']?.toDouble() ?? 0.0;
    
    // Validate financial data
    if (!validateDealData(amount, exchangeRate)) {
      throw ArgumentError('Invalid deal data');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    DateTime updatedAtDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
      
      updatedAtDate = data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now();
    } catch (e) {
      createdAtDate = DateTime.now();
      updatedAtDate = DateTime.now();
    }

    // Safely convert offers list
    List<Offer> offersList = [];
    if (data['offers'] != null && data['offers'] is List) {
      try {
        for (var offer in data['offers']) {
          if (offer is Map<String, dynamic>) {
            offersList.add(Offer.fromMap(offer));
          }
        }
      } catch (e) {
        offersList = [];
      }
    }

    return Deal(
      id: id,
      creatorId: data['creatorId'] ?? '',
      type: data['type'] ?? '',
      currency: data['currency'] ?? '',
      amount: amount,
      exchangeRate: exchangeRate,
      notes: data['notes'] ?? '',
      status: data['status'] ?? '',
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
      offers: offersList,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    List<Map<String, dynamic>> offersList = [];
    for (var offer in offers) {
      offersList.add(offer.toMap());
    }

    return {
      'creatorId': creatorId,
      'type': type,
      'currency': currency,
      'amount': amount,
      'exchangeRate': exchangeRate,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'offers': offersList,
    };
  }
}

// Rating model
class Rating {
  final String id;
  final String dealId;
  final String fromUserId;
  final String toUserId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.dealId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  // Validate rating data
  static bool validateRatingData(int rating) {
    return rating >= 1 && rating <= 5;
  }

  // Convert from Firestore
  factory Rating.fromFirestore(Map<String, dynamic> data, String id) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert rating value
    int ratingValue = data['rating'] ?? 0;
    
    // Validate rating value
    if (!validateRatingData(ratingValue)) {
      throw ArgumentError('Invalid rating value');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
    } catch (e) {
      createdAtDate = DateTime.now();
    }

    return Rating(
      id: id,
      dealId: data['dealId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      rating: ratingValue,
      comment: data['comment'] ?? '',
      createdAt: createdAtDate,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'dealId': dealId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// DepositWithdrawal model
class DepositWithdrawal {
  final String id;
  final String userId;
  final String type;
  final String method;
  final double amount;
  final String currency;
  final double fee;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String adminId;
  final String notes;
  final String screenshotUrl;
  final String destinationAddress;

  DepositWithdrawal({
    required this.id,
    required this.userId,
    required this.type,
    required this.method,
    required this.amount,
    required this.currency,
    this.fee = 0.0,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.adminId = '',
    this.notes = '',
    this.screenshotUrl = '',
    this.destinationAddress = '',
  });

  // Validate deposit/withdrawal data
  static bool validateDepositWithdrawalData(double amount, double fee) {
    if (amount <= 0) return false;
    if (fee < 0) return false;
    if (fee > amount) return false;
    return true;
  }

  // Convert from Firestore
  factory DepositWithdrawal.fromFirestore(Map<String, dynamic> data, String id) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert numeric values
    double amount = data['amount']?.toDouble() ?? 0.0;
    double fee = data['fee']?.toDouble() ?? 0.0;
    
    // Validate financial data
    if (!validateDepositWithdrawalData(amount, fee)) {
      throw ArgumentError('Invalid deposit/withdrawal data');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    DateTime? completedAtDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
      
      completedAtDate = data['completedAt'] is Timestamp 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null;
    } catch (e) {
      createdAtDate = DateTime.now();
      completedAtDate = null;
    }

    return DepositWithdrawal(
      id: id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      method: data['method'] ?? '',
      amount: amount,
      currency: data['currency'] ?? '',
      fee: fee,
      status: data['status'] ?? '',
      createdAt: createdAtDate,
      completedAt: completedAtDate,
      adminId: data['adminId'] ?? '',
      notes: data['notes'] ?? '',
      screenshotUrl: data['screenshotUrl'] ?? '',
      destinationAddress: data['destinationAddress'] ?? '',
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'method': method,
      'amount': amount,
      'currency': currency,
      'fee': fee,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'adminId': adminId,
      'notes': notes,
      'screenshotUrl': screenshotUrl,
      'destinationAddress': destinationAddress,
    };
  }
}

// Notification model
class Notification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.data = const {},
  });

  // Convert from Firestore
  factory Notification.fromFirestore(Map<String, dynamic> data, String id) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
    } catch (e) {
      createdAtDate = DateTime.now();
    }

    return Notification(
      id: id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: createdAtDate,
      data: data['data'] ?? {},
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }
}

// TicketMessage model - Define before SupportTicket to fix reference issue
class TicketMessage {
  final String senderId;
  final String message;
  final String attachmentUrl;
  final DateTime createdAt;

  TicketMessage({
    required this.senderId,
    required this.message,
    this.attachmentUrl = '',
    required this.createdAt,
  });

  // Convert from Map
  factory TicketMessage.fromMap(Map<String, dynamic> data) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
    } catch (e) {
      createdAtDate = DateTime.now();
    }

    return TicketMessage(
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      attachmentUrl: data['attachmentUrl'] ?? '',
      createdAt: createdAtDate,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'message': message,
      'attachmentUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// SupportTicket model
class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketMessage> messages;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  // Convert from Firestore
  factory SupportTicket.fromFirestore(Map<String, dynamic> data, String id) {
    // Validate data exists
    if (data == null) {
      throw ArgumentError('Data cannot be null');
    }
    
    // Safely convert Timestamp objects
    DateTime createdAtDate;
    DateTime updatedAtDate;
    
    try {
      createdAtDate = data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now();
      
      updatedAtDate = data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now();
    } catch (e) {
      createdAtDate = DateTime.now();
      updatedAtDate = DateTime.now();
    }

    // Safely convert messages list
    List<TicketMessage> messagesList = [];
    if (data['messages'] != null && data['messages'] is List) {
      try {
        for (var message in data['messages']) {
          if (message is Map<String, dynamic>) {
            messagesList.add(TicketMessage.fromMap(message));
          }
        }
      } catch (e) {
        messagesList = [];
      }
    }

    return SupportTicket(
      id: id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      status: data['status'] ?? '',
      priority: data['priority'] ?? '',
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
      messages: messagesList,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    List<Map<String, dynamic>> messagesList = [];
    for (var message in messages) {
      messagesList.add(message.toMap());
    }

    return {
      'userId': userId,
      'subject': subject,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'messages': messagesList,
    };
  }
}
