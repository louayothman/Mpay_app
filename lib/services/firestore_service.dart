import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/utils/cache_manager.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheManager _cacheManager = CacheManager();
  
  // تهيئة Firestore مع تحسينات الأداء
  FirestoreService() {
    // تفعيل التخزين المؤقت للبيانات غير المتصلة
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  
  // تنفيذ عمليات متعددة في دفعة واحدة
  Future<void> batchOperation({
    required List<BatchOperation> operations,
    required BuildContext context,
    bool showLoading = true,
    bool showSuccess = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        final batch = _firestore.batch();
        
        for (final operation in operations) {
          final docRef = _firestore.collection(operation.collection).doc(operation.documentId);
          
          switch (operation.type) {
            case BatchOperationType.set:
              batch.set(docRef, operation.data!, SetOptions(merge: operation.merge ?? true));
              break;
            case BatchOperationType.update:
              batch.update(docRef, operation.data!);
              break;
            case BatchOperationType.delete:
              batch.delete(docRef);
              break;
          }
        }
        
        return batch.commit();
      },
      loadingMessage: 'جاري تنفيذ العمليات...',
      successMessage: 'تم تنفيذ العمليات بنجاح',
      errorMessage: 'فشل في تنفيذ العمليات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // تحسين استدعاء الوثائق مع التخزين المؤقت
  Future<DocumentSnapshot?> getDocument({
    required BuildContext context,
    required String collection,
    required String documentId,
    bool showLoading = true,
    bool showSuccess = false,
    Duration cacheDuration = const Duration(minutes: 5),
    bool forceRefresh = false,
    Source source = Source.serverAndCache,
    List<String>? selectFields,
  }) async {
    // التحقق من التخزين المؤقت أولاً إذا لم يكن هناك طلب تحديث إجباري
    if (!forceRefresh) {
      final cachedData = await _cacheManager.getDocument('$collection/$documentId');
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        DocumentReference docRef = _firestore.collection(collection).doc(documentId);
        
        // تطبيق اختيار الحقول إذا تم تحديدها
        if (selectFields != null && selectFields.isNotEmpty) {
          docRef = docRef.withConverter(
            fromFirestore: (snapshot, _) {
              final data = <String, dynamic>{};
              final snapshotData = snapshot.data() ?? {};
              
              for (final field in selectFields) {
                if (snapshotData.containsKey(field)) {
                  data[field] = snapshotData[field];
                }
              }
              
              return DocumentSnapshot.fromFirestore(
                snapshot.reference,
                data,
                snapshot.metadata,
              );
            },
            toFirestore: (value, _) => {},
          );
        }
        
        final snapshot = await docRef.get(GetOptions(source: source));
        
        // تخزين البيانات في التخزين المؤقت
        if (snapshot.exists) {
          await _cacheManager.setDocument('$collection/$documentId', snapshot, cacheDuration);
        }
        
        return snapshot;
      },
      loadingMessage: 'جاري تحميل البيانات...',
      successMessage: 'تم تحميل البيانات بنجاح',
      errorMessage: 'فشل في تحميل البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // تحسين استدعاء المجموعات مع التخزين المؤقت
  Future<QuerySnapshot?> getCollection({
    required BuildContext context,
    required String collection,
    Query Function(CollectionReference)? queryBuilder,
    bool showLoading = true,
    bool showSuccess = false,
    Duration cacheDuration = const Duration(minutes: 5),
    bool forceRefresh = false,
    Source source = Source.serverAndCache,
    List<String>? selectFields,
    String? cacheKey,
  }) async {
    // إنشاء مفتاح التخزين المؤقت
    final effectiveCacheKey = cacheKey ?? collection;
    
    // التحقق من التخزين المؤقت أولاً إذا لم يكن هناك طلب تحديث إجباري
    if (!forceRefresh) {
      final cachedData = await _cacheManager.getCollection(effectiveCacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        CollectionReference collectionRef = _firestore.collection(collection);
        
        // تطبيق اختيار الحقول إذا تم تحديدها
        if (selectFields != null && selectFields.isNotEmpty) {
          collectionRef = collectionRef.withConverter(
            fromFirestore: (snapshot, _) {
              final data = <String, dynamic>{};
              final snapshotData = snapshot.data() ?? {};
              
              for (final field in selectFields) {
                if (snapshotData.containsKey(field)) {
                  data[field] = snapshotData[field];
                }
              }
              
              return DocumentSnapshot.fromFirestore(
                snapshot.reference,
                data,
                snapshot.metadata,
              );
            },
            toFirestore: (value, _) => {},
          );
        }
        
        Query query = queryBuilder != null ? queryBuilder(collectionRef) : collectionRef;
        final snapshot = await query.get(GetOptions(source: source));
        
        // تخزين البيانات في التخزين المؤقت
        if (snapshot.docs.isNotEmpty) {
          await _cacheManager.setCollection(effectiveCacheKey, snapshot, cacheDuration);
        }
        
        return snapshot;
      },
      loadingMessage: 'جاري تحميل البيانات...',
      successMessage: 'تم تحميل البيانات بنجاح',
      errorMessage: 'فشل في تحميل البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // تحسين إضافة وثيقة
  Future<DocumentReference?> addDocument({
    required BuildContext context,
    required String collection,
    required Map<String, dynamic> data,
    bool showLoading = true,
    bool showSuccess = true,
    bool invalidateCollectionCache = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        // التحقق من الاتصال بالإنترنت قبل إجراء العملية
        final isConnected = await ConnectivityUtils.isConnected();
        if (!isConnected) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
        
        final docRef = await _firestore.collection(collection).add(data);
        
        // إلغاء صلاحية التخزين المؤقت للمجموعة
        if (invalidateCollectionCache) {
          await _cacheManager.invalidateCollection(collection);
        }
        
        return docRef;
      },
      loadingMessage: 'جاري إضافة البيانات...',
      successMessage: 'تمت إضافة البيانات بنجاح',
      errorMessage: 'فشل في إضافة البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // تحسين تعيين وثيقة
  Future<void> setDocument({
    required BuildContext context,
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
    bool showLoading = true,
    bool showSuccess = true,
    bool invalidateCache = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        // التحقق من الاتصال بالإنترنت قبل إجراء العملية
        final isConnected = await ConnectivityUtils.isConnected();
        if (!isConnected) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
        
        await _firestore.collection(collection).doc(documentId).set(data, SetOptions(merge: merge));
        
        // إلغاء صلاحية التخزين المؤقت
        if (invalidateCache) {
          await _cacheManager.invalidateDocument('$collection/$documentId');
          await _cacheManager.invalidateCollection(collection);
        }
      },
      loadingMessage: 'جاري حفظ البيانات...',
      successMessage: 'تم حفظ البيانات بنجاح',
      errorMessage: 'فشل في حفظ البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // تحسين تحديث وثيقة
  Future<void> updateDocument({
    required BuildContext context,
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool showLoading = true,
    bool showSuccess = true,
    bool invalidateCache = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        // التحقق من الاتصال بالإنترنت قبل إجراء العملية
        final isConnected = await ConnectivityUtils.isConnected();
        if (!isConnected) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
        
        await _firestore.collection(collection).doc(documentId).update(data);
        
        // إلغاء صلاحية التخزين المؤقت
        if (invalidateCache) {
          await _cacheManager.invalidateDocument('$collection/$documentId');
          await _cacheManager.invalidateCollection(collection);
        }
      },
      loadingMessage: 'جاري تحديث البيانات...',
      successMessage: 'تم تحديث البيانات بنجاح',
      errorMessage: 'فشل في تحديث البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // تحسين حذف وثيقة
  Future<void> deleteDocument({
    required BuildContext context,
    required String collection,
    required String documentId,
    bool showLoading = true,
    bool showSuccess = true,
    bool invalidateCache = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        // التحقق من الاتصال بالإنترنت قبل إجراء العملية
        final isConnected = await ConnectivityUtils.isConnected();
        if (!isConnected) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
        
        await _firestore.collection(collection).doc(documentId).delete();
        
        // إلغاء صلاحية التخزين المؤقت
        if (invalidateCache) {
          await _cacheManager.invalidateDocument('$collection/$documentId');
          await _cacheManager.invalidateCollection(collection);
        }
      },
      loadingMessage: 'جاري حذف البيانات...',
      successMessage: 'تم حذف البيانات بنجاح',
      errorMessage: 'فشل في حذف البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: showSuccess,
    );
  }
  
  // تحسين الحصول على بيانات المستخدم
  Future<DocumentSnapshot?> getUserData({
    required BuildContext context,
    String? userId,
    bool showLoading = true,
    bool forceRefresh = false,
    List<String>? selectFields,
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return null;
    }
    
    // تحديد الحقول المطلوبة إذا لم يتم تحديدها
    final fields = selectFields ?? [
      'name', 'email', 'phoneNumber', 'profileImageUrl', 'createdAt', 'lastLoginAt', 'isVerified'
    ];
    
    return await getDocument(
      context: context,
      collection: 'users',
      documentId: uid,
      showLoading: showLoading,
      forceRefresh: forceRefresh,
      selectFields: fields,
      cacheDuration: const Duration(minutes: 15), // تخزين مؤقت لمدة أطول لبيانات المستخدم
    );
  }
  
  // تحسين الحصول على بيانات المحفظة
  Future<DocumentSnapshot?> getWalletData({
    required BuildContext context,
    String? userId,
    bool showLoading = true,
    bool forceRefresh = false,
    List<String>? selectFields,
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return null;
    }
    
    // تحديد الحقول المطلوبة إذا لم يتم تحديدها
    final fields = selectFields ?? [
      'balances', 'updatedAt', 'walletAddresses', 'totalTransactions'
    ];
    
    return await getDocument(
      context: context,
      collection: 'wallets',
      documentId: uid,
      showLoading: showLoading,
      forceRefresh: forceRefresh,
      selectFields: fields,
      cacheDuration: const Duration(minutes: 5), // تخزين مؤقت لمدة قصيرة لبيانات المحفظة
    );
  }
  
  // تحسين الحصول على معاملات المستخدم
  Future<QuerySnapshot?> getUserTransactions({
    required BuildContext context,
    String? userId,
    bool showLoading = true,
    int limit = 20,
    DocumentSnapshot? startAfterDocument,
    String? transactionType,
    bool forceRefresh = false,
    List<String>? selectFields,
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ErrorHandler.showErrorSnackBar(context, 'لم يتم العثور على المستخدم');
      return null;
    }
    
    // تحديد الحقول المطلوبة إذا لم يتم تحديدها
    final fields = selectFields ?? [
      'type', 'amount', 'status', 'timestamp', 'method', 'notes', 'walletAddress', 'receiptUrl'
    ];
    
    // إنشاء مفتاح تخزين مؤقت فريد
    final cacheKey = 'transactions_${uid}_${limit}_${transactionType ?? 'all'}';
    
    return await getCollection(
      context: context,
      collection: 'transactions',
      queryBuilder: (CollectionReference ref) {
        Query query = ref.where('userId', isEqualTo: uid);
        
        if (transactionType != null && transactionType != 'all') {
          query = query.where('type', isEqualTo: transactionType);
        }
        
        query = query.orderBy('timestamp', descending: true).limit(limit);
        
        if (startAfterDocument != null) {
          query = query.startAfterDocument(startAfterDocument);
        }
        
        return query;
      },
      showLoading: showLoading,
      forceRefresh: forceRefresh,
      selectFields: fields,
      cacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 3), // تخزين مؤقت لمدة قصيرة للمعاملات
    );
  }
  
  // تحسين إنشاء معاملة
  Future<DocumentReference?> createTransaction({
    required BuildContext context,
    required Map<String, dynamic> transactionData,
    bool showLoading = true,
    bool updateWallet = true,
  }) async {
    // التحقق من وجود بيانات المستخدم والمبلغ والعملة
    if (!transactionData.containsKey('userId') || 
        !transactionData.containsKey('amount') || 
        !transactionData.containsKey('currency')) {
      ErrorHandler.showErrorSnackBar(context, 'بيانات المعاملة غير مكتملة');
      return null;
    }
    
    final userId = transactionData['userId'] as String;
    final amount = transactionData['amount'] as double;
    final currency = transactionData['currency'] as String;
    final type = transactionData['type'] as String;
    
    // استخدام عمليات الدفعة لتحديث المحفظة وإنشاء المعاملة في نفس الوقت
    if (updateWallet) {
      // تحديد قيمة التغيير في الرصيد بناءً على نوع المعاملة
      final balanceChange = type.toLowerCase() == 'withdrawal' ? -amount : amount;
      
      final operations = [
        BatchOperation(
          type: BatchOperationType.set,
          collection: 'transactions',
          documentId: _firestore.collection('transactions').doc().id,
          data: {
            ...transactionData,
            'timestamp': FieldValue.serverTimestamp(),
          },
        ),
        BatchOperation(
          type: BatchOperationType.update,
          collection: 'wallets',
          documentId: userId,
          data: {
            'balances.$currency': FieldValue.increment(balanceChange),
            'updatedAt': FieldValue.serverTimestamp(),
            'totalTransactions': FieldValue.increment(1),
          },
        ),
      ];
      
      await batchOperation(
        operations: operations,
        context: context,
        showLoading: showLoading,
      );
      
      // إلغاء صلاحية التخزين المؤقت للمعاملات والمحفظة
      await _cacheManager.invalidateCollection('transactions');
      await _cacheManager.invalidateDocument('wallets/$userId');
      
      // إرجاع مرجع المستند الأول (المعاملة)
      return _firestore.collection('transactions').doc(operations[0].documentId);
    } else {
      // إذا لم يكن هناك حاجة لتحديث المحفظة، استخدم الطريقة العادية
      return await addDocument(
        context: context,
        collection: 'transactions',
        data: {
          ...transactionData,
          'timestamp': FieldValue.serverTimestamp(),
        },
        showLoading: showLoading,
      );
    }
  }
  
  // تحسين تحديث رصيد المحفظة
  Future<void> updateWalletBalance({
    required BuildContext context,
    required String userId,
    required String currency,
    required double amount,
    bool showLoading = true,
    String? transactionType,
  }) async {
    // تحديد قيمة التغيير في الرصيد بناءً على نوع المعاملة
    final balanceChange = transactionType?.toLowerCase() == 'withdrawal' ? -amount : amount;
    
    return await updateDocument(
      context: context,
      collection: 'wallets',
      documentId: userId,
      data: {
        'balances.$currency': FieldValue.increment(balanceChange),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      showLoading: showLoading,
      invalidateCache: true,
    );
  }
  
  // إلغاء معاملة
  Future<void> cancelTransaction(String transactionId) async {
    // الحصول على بيانات المعاملة
    final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
    
    if (!transactionDoc.exists) {
      throw Exception('المعاملة غير موجودة');
    }
    
    final transactionData = transactionDoc.data() as Map<String, dynamic>;
    final userId = transactionData['userId'] as String;
    final amount = transactionData['amount'] as num;
    final currency = transactionData['currency'] as String;
    final type = transactionData['type'] as String;
    
    // تحديد قيمة التغيير في الرصيد بناءً على نوع المعاملة
    // عند الإلغاء، نقوم بعكس التأثير الأصلي
    final balanceChange = type.toLowerCase() == 'withdrawal' ? amount.toDouble() : -amount.toDouble();
    
    // استخدام عمليات الدفعة لتحديث المعاملة والمحفظة في نفس الوقت
    final batch = _firestore.batch();
    
    // تحديث حالة المعاملة
    batch.update(_firestore.collection('transactions').doc(transactionId), {
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // تحديث رصيد المحفظة
    batch.update(_firestore.collection('wallets').doc(userId), {
      'balances.$currency': FieldValue.increment(balanceChange),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
    
    // إلغاء صلاحية التخزين المؤقت
    await _cacheManager.invalidateDocument('transactions/$transactionId');
    await _cacheManager.invalidateCollection('transactions');
    await _cacheManager.invalidateDocument('wallets/$userId');
  }
  
  // تنظيف التخزين المؤقت
  Future<void> clearCache() async {
    await _cacheManager.clearAll();
  }
}

// فئة لتمثيل عملية في الدفعة
class BatchOperation {
  final BatchOperationType type;
  final String collection;
  final String documentId;
  final Map<String, dynamic>? data;
  final bool? merge;
  
  BatchOperation({
    required this.type,
    required this.collection,
    required this.documentId,
    this.data,
    this.merge,
  }) : assert(
         (type == BatchOperationType.delete) || 
         (data != null && (type == BatchOperationType.set || type == BatchOperationType.update))
       );
}

// تعداد لأنواع عمليات الدفعة
enum BatchOperationType {
  set,
  update,
  delete,
}
