import 'package:flutter/material.dart';
import 'package:mpay_app/utils/performance_optimizer_enhanced.dart';

/// مدير ذاكرة التخزين المؤقت للتطبيق
/// 
/// يوفر هذا الصف آليات لإدارة ذاكرة التخزين المؤقت في التطبيق
/// ويتضمن وظائف لتخزين البيانات مؤقتًا واسترجاعها وتنظيفها
class CacheManager {
  // نمط Singleton
  static final CacheManager _instance = CacheManager._internal();
  
  factory CacheManager() {
    return _instance;
  }
  
  CacheManager._internal();
  
  // ذاكرة التخزين المؤقت للبيانات
  final Map<String, CacheEntry<dynamic>> _dataCache = {};
  
  // ذاكرة التخزين المؤقت للصور
  final Map<String, CacheEntry<ImageProvider>> _imageCache = {};
  
  // ذاكرة التخزين المؤقت للاستجابات
  final Map<String, CacheEntry<dynamic>> _responseCache = {};
  
  // الحد الأقصى لحجم ذاكرة التخزين المؤقت
  static const int _maxCacheSize = 100;
  
  // مدة انتهاء صلاحية ذاكرة التخزين المؤقت الافتراضية
  static const Duration _defaultExpiry = Duration(minutes: 30);
  
  // تخزين بيانات مؤقتًا
  void cacheData<T>(String key, T data, {Duration? expiry}) {
    _cleanExpiredCache();
    
    final entry = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      expiry: expiry ?? _defaultExpiry,
    );
    
    _dataCache[key] = entry;
    
    // تنظيف ذاكرة التخزين المؤقت إذا تجاوزت الحد الأقصى
    if (_dataCache.length > _maxCacheSize) {
      _cleanOldestEntries(_dataCache);
    }
  }
  
  // الحصول على بيانات مخزنة مؤقتًا
  T? getCachedData<T>(String key) {
    final entry = _dataCache[key];
    
    if (entry == null) {
      return null;
    }
    
    // التحقق من انتهاء الصلاحية
    if (_isExpired(entry)) {
      _dataCache.remove(key);
      return null;
    }
    
    // تحديث وقت الوصول
    entry.lastAccessed = DateTime.now();
    
    return entry.data as T;
  }
  
  // تخزين صورة مؤقتًا - تم تحسين الأداء
  void cacheImage(String key, ImageProvider image, {Duration? expiry}) {
    _cleanExpiredCache();
    
    // التحقق من وجود الصورة بالفعل لتجنب التكرار
    if (_imageCache.containsKey(key) && !_isExpired(_imageCache[key]!)) {
      // تحديث وقت الوصول فقط إذا كانت الصورة موجودة بالفعل
      _imageCache[key]!.lastAccessed = DateTime.now();
      return;
    }
    
    final entry = CacheEntry<ImageProvider>(
      data: image,
      timestamp: DateTime.now(),
      expiry: expiry ?? _defaultExpiry,
    );
    
    _imageCache[key] = entry;
    
    // تنظيف ذاكرة التخزين المؤقت إذا تجاوزت الحد الأقصى
    if (_imageCache.length > _maxCacheSize) {
      _cleanOldestEntries(_imageCache);
    }
  }
  
  // تخزين مجموعة من الصور مؤقتًا بكفاءة
  void cacheImages(Map<String, ImageProvider> images, {Duration? expiry}) {
    // تنظيف الذاكرة المؤقتة المنتهية الصلاحية مرة واحدة فقط
    _cleanExpiredCache();
    
    // تحديد الصور الجديدة فقط لتجنب العمليات غير الضرورية
    final newImages = <String, ImageProvider>{};
    
    for (final entry in images.entries) {
      final key = entry.key;
      // إضافة الصورة فقط إذا لم تكن موجودة أو كانت منتهية الصلاحية
      if (!_imageCache.containsKey(key) || _isExpired(_imageCache[key]!)) {
        newImages[key] = entry.value;
      } else {
        // تحديث وقت الوصول للصور الموجودة
        _imageCache[key]!.lastAccessed = DateTime.now();
      }
    }
    
    // إضافة الصور الجديدة فقط
    for (final entry in newImages.entries) {
      final cacheEntry = CacheEntry<ImageProvider>(
        data: entry.value,
        timestamp: DateTime.now(),
        expiry: expiry ?? _defaultExpiry,
      );
      
      _imageCache[entry.key] = cacheEntry;
    }
    
    // تنظيف ذاكرة التخزين المؤقت إذا تجاوزت الحد الأقصى
    if (_imageCache.length > _maxCacheSize) {
      _cleanOldestEntries(_imageCache);
    }
  }
  
  // الحصول على صورة مخزنة مؤقتًا
  ImageProvider? getCachedImage(String key) {
    final entry = _imageCache[key];
    
    if (entry == null) {
      return null;
    }
    
    // التحقق من انتهاء الصلاحية
    if (_isExpired(entry)) {
      _imageCache.remove(key);
      return null;
    }
    
    // تحديث وقت الوصول
    entry.lastAccessed = DateTime.now();
    
    return entry.data;
  }
  
  // تخزين استجابة مؤقتًا
  void cacheResponse<T>(String key, T response, {Duration? expiry}) {
    _cleanExpiredCache();
    
    final entry = CacheEntry<T>(
      data: response,
      timestamp: DateTime.now(),
      expiry: expiry ?? _defaultExpiry,
    );
    
    _responseCache[key] = entry;
    
    // تنظيف ذاكرة التخزين المؤقت إذا تجاوزت الحد الأقصى
    if (_responseCache.length > _maxCacheSize) {
      _cleanOldestEntries(_responseCache);
    }
  }
  
  // الحصول على استجابة مخزنة مؤقتًا
  T? getCachedResponse<T>(String key) {
    final entry = _responseCache[key];
    
    if (entry == null) {
      return null;
    }
    
    // التحقق من انتهاء الصلاحية
    if (_isExpired(entry)) {
      _responseCache.remove(key);
      return null;
    }
    
    // تحديث وقت الوصول
    entry.lastAccessed = DateTime.now();
    
    return entry.data as T;
  }
  
  // التحقق مما إذا كان العنصر منتهي الصلاحية
  bool _isExpired<T>(CacheEntry<T> entry) {
    final now = DateTime.now();
    return now.difference(entry.timestamp) > entry.expiry;
  }
  
  // تنظيف العناصر منتهية الصلاحية - تم تحسين الأداء
  void _cleanExpiredCache() {
    final now = DateTime.now();
    
    // استخدام removeWhere بدلاً من التكرار اليدوي لتحسين الأداء
    _dataCache.removeWhere((key, entry) => now.difference(entry.timestamp) > entry.expiry);
    _imageCache.removeWhere((key, entry) => now.difference(entry.timestamp) > entry.expiry);
    _responseCache.removeWhere((key, entry) => now.difference(entry.timestamp) > entry.expiry);
  }
  
  // تنظيف أقدم العناصر - تم تحسين الأداء
  void _cleanOldestEntries<T>(Map<String, CacheEntry<T>> cache) {
    if (cache.isEmpty) return;
    
    // ترتيب العناصر حسب وقت الوصول الأخير
    final entries = cache.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
    
    // إزالة أقدم 20% من العناصر
    final entriesToRemove = (cache.length * 0.2).ceil();
    
    // استخدام مجموعة من المفاتيح للإزالة بكفاءة
    final keysToRemove = entries
        .take(entriesToRemove)
        .map((e) => e.key)
        .toSet();
    
    // إزالة المفاتيح دفعة واحدة
    keysToRemove.forEach(cache.remove);
  }
  
  // مسح ذاكرة التخزين المؤقت
  void clearCache() {
    _dataCache.clear();
    _imageCache.clear();
    _responseCache.clear();
    
    // تنظيف ذاكرة التخزين المؤقت للصور في Flutter
    PaintingBinding.instance.imageCache.clear();
    
    // تنظيف ذاكرة التخزين المؤقت لتخطيط النص
    _TextLayoutCacheWidget.clearCache();
  }
  
  // مسح ذاكرة التخزين المؤقت لنوع معين
  void clearCacheByType(CacheType type) {
    switch (type) {
      case CacheType.data:
        _dataCache.clear();
        break;
      case CacheType.image:
        _imageCache.clear();
        PaintingBinding.instance.imageCache.clear();
        break;
      case CacheType.response:
        _responseCache.clear();
        break;
    }
  }
  
  // مسح ذاكرة التخزين المؤقت بمفتاح معين
  void clearCacheByKey(String key) {
    _dataCache.remove(key);
    _imageCache.remove(key);
    _responseCache.remove(key);
  }
  
  // الحصول على إحصائيات ذاكرة التخزين المؤقت
  Map<String, dynamic> getCacheStats() {
    return {
      'data_cache_size': _dataCache.length,
      'image_cache_size': _imageCache.length,
      'response_cache_size': _responseCache.length,
      'total_cache_size': _dataCache.length + _imageCache.length + _responseCache.length,
      'flutter_image_cache_size': PaintingBinding.instance.imageCache.currentSize,
      'flutter_image_cache_bytes': PaintingBinding.instance.imageCache.currentSizeBytes,
    };
  }
  
  // تحديد ما إذا كان المفتاح موجودًا في ذاكرة التخزين المؤقت وغير منتهي الصلاحية
  bool hasValidCache(String key, CacheType type) {
    switch (type) {
      case CacheType.data:
        return _dataCache.containsKey(key) && !_isExpired(_dataCache[key]!);
      case CacheType.image:
        return _imageCache.containsKey(key) && !_isExpired(_imageCache[key]!);
      case CacheType.response:
        return _responseCache.containsKey(key) && !_isExpired(_responseCache[key]!);
    }
  }
}

// صف عنصر ذاكرة التخزين المؤقت
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration expiry;
  DateTime lastAccessed;
  
  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiry,
  }) : lastAccessed = timestamp;
}

// أنواع ذاكرة التخزين المؤقت
enum CacheType {
  data,
  image,
  response,
}

// ودجت لتنظيف ذاكرة التخزين المؤقت لتخطيط النص
class _TextLayoutCacheWidget {
  static void clearCache() {
    // في التنفيذ الحقيقي، يمكن استخدام قنوات أصلية لتنظيف ذاكرة التخزين المؤقت لتخطيط النص
    // هذا تنفيذ مبسط
    debugPrint('تم تنظيف ذاكرة التخزين المؤقت لتخطيط النص');
  }
}
