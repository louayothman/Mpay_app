import 'package:flutter/material.dart';

/// استثناءات البيانات
/// 
/// تعريف الاستثناءات المتعلقة بعمليات البيانات والتخزين والمزامنة

/// استثناء عدم العثور على البيانات
class DataNotFoundException implements Exception {
  final String message;
  final String? dataId;
  
  DataNotFoundException(this.message, {this.dataId});
  
  @override
  String toString() {
    if (dataId != null) {
      return 'DataNotFoundException: $message (Data ID: $dataId)';
    }
    return 'DataNotFoundException: $message';
  }
}

/// استثناء البيانات تالفة
class DataCorruptedException implements Exception {
  final String message;
  final String? dataSource;
  
  DataCorruptedException(this.message, {this.dataSource});
  
  @override
  String toString() {
    if (dataSource != null) {
      return 'DataCorruptedException: $message (Source: $dataSource)';
    }
    return 'DataCorruptedException: $message';
  }
}

/// استثناء تنسيق بيانات غير صالح
class InvalidDataFormatException implements Exception {
  final String message;
  final String? expectedFormat;
  
  InvalidDataFormatException(this.message, {this.expectedFormat});
  
  @override
  String toString() {
    if (expectedFormat != null) {
      return 'InvalidDataFormatException: $message (Expected format: $expectedFormat)';
    }
    return 'InvalidDataFormatException: $message';
  }
}

/// استثناء فشل المزامنة
class SynchronizationFailedException implements Exception {
  final String message;
  final String? syncTarget;
  
  SynchronizationFailedException(this.message, {this.syncTarget});
  
  @override
  String toString() {
    if (syncTarget != null) {
      return 'SynchronizationFailedException: $message (Target: $syncTarget)';
    }
    return 'SynchronizationFailedException: $message';
  }
}

/// استثناء تضارب في البيانات
class DataConflictException implements Exception {
  final String message;
  final String? conflictDetails;
  
  DataConflictException(this.message, {this.conflictDetails});
  
  @override
  String toString() {
    if (conflictDetails != null) {
      return 'DataConflictException: $message (Conflict details: $conflictDetails)';
    }
    return 'DataConflictException: $message';
  }
}

/// استثناء البيانات منتهية الصلاحية
class DataExpiredException implements Exception {
  final String message;
  final DateTime? expiryTime;
  
  DataExpiredException(this.message, {this.expiryTime});
  
  @override
  String toString() {
    if (expiryTime != null) {
      return 'DataExpiredException: $message (Expired at: $expiryTime)';
    }
    return 'DataExpiredException: $message';
  }
}

/// استثناء فشل الحفظ
class SaveFailedException implements Exception {
  final String message;
  final String? dataType;
  
  SaveFailedException(this.message, {this.dataType});
  
  @override
  String toString() {
    if (dataType != null) {
      return 'SaveFailedException: $message (Data type: $dataType)';
    }
    return 'SaveFailedException: $message';
  }
}

/// استثناء فشل التحميل
class LoadFailedException implements Exception {
  final String message;
  final String? dataType;
  
  LoadFailedException(this.message, {this.dataType});
  
  @override
  String toString() {
    if (dataType != null) {
      return 'LoadFailedException: $message (Data type: $dataType)';
    }
    return 'LoadFailedException: $message';
  }
}

/// استثناء فشل الحذف
class DeleteFailedException implements Exception {
  final String message;
  final String? dataId;
  
  DeleteFailedException(this.message, {this.dataId});
  
  @override
  String toString() {
    if (dataId != null) {
      return 'DeleteFailedException: $message (Data ID: $dataId)';
    }
    return 'DeleteFailedException: $message';
  }
}

/// استثناء فشل التحديث
class UpdateFailedException implements Exception {
  final String message;
  final String? dataId;
  
  UpdateFailedException(this.message, {this.dataId});
  
  @override
  String toString() {
    if (dataId != null) {
      return 'UpdateFailedException: $message (Data ID: $dataId)';
    }
    return 'UpdateFailedException: $message';
  }
}

/// استثناء فشل الاستعلام
class QueryFailedException implements Exception {
  final String message;
  final String? queryDetails;
  
  QueryFailedException(this.message, {this.queryDetails});
  
  @override
  String toString() {
    if (queryDetails != null) {
      return 'QueryFailedException: $message (Query details: $queryDetails)';
    }
    return 'QueryFailedException: $message';
  }
}

/// استثناء فشل التحقق من صحة البيانات
class ValidationFailedException implements Exception {
  final String message;
  final Map<String, String>? validationErrors;
  
  ValidationFailedException(this.message, {this.validationErrors});
  
  @override
  String toString() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return 'ValidationFailedException: $message (Errors: ${validationErrors.toString()})';
    }
    return 'ValidationFailedException: $message';
  }
}

/// استثناء فشل التشفير
class EncryptionFailedException implements Exception {
  final String message;
  
  EncryptionFailedException(this.message);
  
  @override
  String toString() => 'EncryptionFailedException: $message';
}

/// استثناء فشل فك التشفير
class DecryptionFailedException implements Exception {
  final String message;
  
  DecryptionFailedException(this.message);
  
  @override
  String toString() => 'DecryptionFailedException: $message';
}

/// استثناء فشل التخزين المؤقت
class CacheFailedException implements Exception {
  final String message;
  final String? cacheKey;
  
  CacheFailedException(this.message, {this.cacheKey});
  
  @override
  String toString() {
    if (cacheKey != null) {
      return 'CacheFailedException: $message (Cache key: $cacheKey)';
    }
    return 'CacheFailedException: $message';
  }
}

/// استثناء فشل التخزين المحلي
class LocalStorageFailedException implements Exception {
  final String message;
  final String? operation;
  
  LocalStorageFailedException(this.message, {this.operation});
  
  @override
  String toString() {
    if (operation != null) {
      return 'LocalStorageFailedException: $message (Operation: $operation)';
    }
    return 'LocalStorageFailedException: $message';
  }
}
