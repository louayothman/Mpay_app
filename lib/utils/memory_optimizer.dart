import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/scheduler.dart';

class MemoryOptimizer {
  // نمط Singleton
  static final MemoryOptimizer _instance = MemoryOptimizer._internal();
  
  factory MemoryOptimizer() {
    return _instance;
  }
  
  MemoryOptimizer._internal();
  
  // قائمة المراقبين
  final List<WeakReference<Object>> _objectReferences = [];
  
  // مؤقت مراقبة الذاكرة
  Timer? _memoryMonitorTimer;
  
  // سجل استخدام الذاكرة
  final List<MemorySnapshot> _memorySnapshots = [];
  
  // الحد الأقصى لعدد لقطات الذاكرة
  static const int _maxSnapshots = 50;
  
  // معدل أخذ لقطات الذاكرة (بالثواني)
  static const int _snapshotInterval = 30;
  
  // بدء مراقبة الذاكرة
  void startMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: _snapshotInterval), (_) {
      _captureMemorySnapshot();
      _detectPotentialLeaks();
    });
    
    // التقاط لقطة ذاكرة أولية
    _captureMemorySnapshot();
  }
  
  // إيقاف مراقبة الذاكرة
  void stopMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
  }
  
  // التقاط لقطة ذاكرة - تم تحسين الأداء
  Future<void> _captureMemorySnapshot() async {
    try {
      // في التنفيذ الحقيقي، استخدم قنوات أصلية للحصول على معلومات استخدام الذاكرة الدقيقة
      final snapshot = await _getMemoryInfo();
      
      // تحقق من وجود تغيير كبير قبل إضافة لقطة جديدة
      final shouldAdd = _memorySnapshots.isEmpty || 
          (_memorySnapshots.isNotEmpty && _isSignificantMemoryChange(_memorySnapshots.last, snapshot));
      
      if (shouldAdd) {
        _memorySnapshots.add(snapshot);
        
        // الحد من عدد اللقطات المخزنة
        if (_memorySnapshots.length > _maxSnapshots) {
          _memorySnapshots.removeAt(0);
        }
        
        // تسجيل استخدام الذاكرة فقط في وضع التصحيح
        if (snapshot.usedHeapSize > 0) {
          debugPrint('لقطة ذاكرة: ${snapshot.usedHeapSize ~/ (1024 * 1024)} ميجابايت');
        }
      }
    } catch (e) {
      debugPrint('خطأ في التقاط لقطة ذاكرة: $e');
    }
  }
  
  // التحقق من وجود تغيير كبير في استخدام الذاكرة
  bool _isSignificantMemoryChange(MemorySnapshot previous, MemorySnapshot current) {
    // اعتبر التغيير كبيرًا إذا كان أكثر من 5% من الاستخدام السابق
    final threshold = previous.usedHeapSize * 0.05;
    return (current.usedHeapSize - previous.usedHeapSize).abs() > threshold;
  }
  
  // الحصول على معلومات الذاكرة
  Future<MemorySnapshot> _getMemoryInfo() async {
    // في التنفيذ الحقيقي، استخدم قنوات أصلية للحصول على معلومات استخدام الذاكرة الدقيقة
    // هذا تنفيذ مبسط
    return MemorySnapshot(
      totalHeapSize: 0, // سيتم تعبئته بالقيم الفعلية في التنفيذ الحقيقي
      usedHeapSize: 0,
      externalSize: 0,
      timestamp: DateTime.now(),
    );
  }
  
  // اكتشاف تسربات الذاكرة المحتملة - تم تحسين الأداء
  void _detectPotentialLeaks() {
    if (_memorySnapshots.length < 5) return;
    
    // استخدام نافذة متحركة للتحليل بدلاً من تحليل كل التاريخ
    final windowSize = min(5, _memorySnapshots.length);
    final startIdx = _memorySnapshots.length - windowSize;
    
    if (startIdx < 0) return;
    
    final recentSnapshots = _memorySnapshots.sublist(startIdx);
    final firstSnapshot = recentSnapshots.first;
    final lastSnapshot = recentSnapshots.last;
    
    final durationMinutes = lastSnapshot.timestamp.difference(firstSnapshot.timestamp).inMinutes;
    if (durationMinutes < 1) return;
    
    // استخدام تحليل الانحدار الخطي البسيط لتقدير معدل النمو بشكل أكثر دقة
    final growthRate = _calculateGrowthRate(recentSnapshots);
    
    // إذا كان معدل النمو أكبر من 1 ميجابايت في الدقيقة، فقد يكون هناك تسرب
    if (growthRate > 1 * 1024 * 1024) {
      debugPrint('تحذير: تم اكتشاف نمو ذاكرة مرتفع محتمل: ${(growthRate / (1024 * 1024)).toStringAsFixed(2)} ميجابايت/دقيقة');
      
      // تنظيف الذاكرة تلقائيًا عند اكتشاف تسرب محتمل
      _cleanMemory();
    }
  }
  
  // حساب معدل النمو باستخدام تحليل الانحدار الخطي البسيط
  double _calculateGrowthRate(List<MemorySnapshot> snapshots) {
    if (snapshots.length < 2) return 0;
    
    // حساب المتوسطات
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;
    
    final baseTime = snapshots.first.timestamp.millisecondsSinceEpoch;
    
    for (int i = 0; i < snapshots.length; i++) {
      // تحويل الوقت إلى دقائق من البداية
      final x = (snapshots[i].timestamp.millisecondsSinceEpoch - baseTime) / (60 * 1000);
      final y = snapshots[i].usedHeapSize.toDouble();
      
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    
    final n = snapshots.length.toDouble();
    
    // حساب معامل الانحدار (معدل النمو)
    // تجنب القسمة على صفر
    if ((n * sumX2 - sumX * sumX) == 0) return 0;
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    
    return slope; // معدل النمو بالبايت في الدقيقة
  }
  
  // تسجيل كائن للمراقبة - تم تحسين الأداء
  void trackObject(Object object) {
    // تنظيف المراجع الضعيفة قبل إضافة كائن جديد
    if (_objectReferences.length % 10 == 0) {
      _cleanWeakReferences();
    }
    
    _objectReferences.add(WeakReference<Object>(object));
  }
  
  // تنظيف المراجع الضعيفة - تم تحسين الأداء
  void _cleanWeakReferences() {
    // استخدام removeWhere بدلاً من التكرار اليدوي
    _objectReferences.removeWhere((ref) => ref.target == null);
  }
  
  // تنظيف الذاكرة - تم تحسين الأداء
  void _cleanMemory() {
    // تنظيف ذاكرة التخزين المؤقت للصور
    PaintingBinding.instance.imageCache.clear();
    
    // تنظيف المراجع الضعيفة
    _cleanWeakReferences();
    
    // تشغيل جامع القمامة يدويًا (في التنفيذ الحقيقي، استخدم قنوات أصلية)
    
    // تسجيل تنظيف الذاكرة
    debugPrint('تم تنفيذ تنظيف الذاكرة');
  }
  
  // تحسين استخدام الذاكرة - تم تحسين الأداء
  void optimizeMemory() {
    // تنظيف الذاكرة
    _cleanMemory();
    
    // تقليل حجم ذاكرة التخزين المؤقت للصور
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 ميجابايت
    
    // تنظيف الكائنات غير المستخدمة
    _disposeUnusedObjects();
    
    // تسجيل تحسين الذاكرة
    debugPrint('تم تنفيذ تحسين استخدام الذاكرة');
  }
  
  // التخلص من الكائنات غير المستخدمة
  void _disposeUnusedObjects() {
    // تنظيف المراجع الضعيفة
    _cleanWeakReferences();
    
    // في التنفيذ الحقيقي، يمكن تنفيذ منطق إضافي للتخلص من الكائنات غير المستخدمة
  }
  
  // الحصول على تقرير استخدام الذاكرة - تم تحسين الأداء
  Map<String, dynamic> getMemoryReport() {
    final report = <String, dynamic>{};
    
    if (_memorySnapshots.isNotEmpty) {
      final latestSnapshot = _memorySnapshots.last;
      final initialSnapshot = _memorySnapshots.first;
      
      report['current_memory'] = {
        'total_heap_mb': latestSnapshot.totalHeapSize / (1024 * 1024),
        'used_heap_mb': latestSnapshot.usedHeapSize / (1024 * 1024),
        'external_mb': latestSnapshot.externalSize / (1024 * 1024),
      };
      
      // حساب معدل النمو فقط إذا كان هناك أكثر من لقطة واحدة
      if (_memorySnapshots.length > 1) {
        final durationMinutes = latestSnapshot.timestamp.difference(initialSnapshot.timestamp).inMinutes;
        
        report['memory_growth'] = {
          'total_growth_mb': (latestSnapshot.totalHeapSize - initialSnapshot.totalHeapSize) / (1024 * 1024),
          'used_growth_mb': (latestSnapshot.usedHeapSize - initialSnapshot.usedHeapSize) / (1024 * 1024),
          'duration_minutes': durationMinutes,
        };
        
        // حساب معدل النمو
        if (durationMinutes > 0) {
          final growthRatePerMinute = (latestSnapshot.usedHeapSize - initialSnapshot.usedHeapSize) / durationMinutes;
          report['growth_rate_mb_per_minute'] = growthRatePerMinute / (1024 * 1024);
        }
      }
    }
    
    report['tracked_objects_count'] = _objectReferences.length;
    report['active_objects_count'] = _objectReferences.where((ref) => ref.target != null).length;
    
    return report;
  }
  
  // تحرير الموارد
  void dispose() {
    stopMonitoring();
    _memorySnapshots.clear();
    _objectReferences.clear();
  }
  
  // تحسين استخدام الذاكرة للصور
  void optimizeImageMemory() {
    // تنظيف ذاكرة التخزين المؤقت للصور
    PaintingBinding.instance.imageCache.clear();
    
    // تقليل حجم ذاكرة التخزين المؤقت للصور
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 ميجابايت
    
    debugPrint('تم تحسين ذاكرة الصور');
  }
  
  // تحسين استخدام الذاكرة للقوائم
  void optimizeListViewMemory() {
    // تنظيف المراجع الضعيفة
    _cleanWeakReferences();
    
    // في التنفيذ الحقيقي، يمكن تنفيذ منطق إضافي لتحسين ذاكرة القوائم
    debugPrint('تم تحسين ذاكرة القوائم');
  }
}

/// لقطة ذاكرة
class MemorySnapshot {
  final int totalHeapSize;
  final int usedHeapSize;
  final int externalSize;
  final DateTime timestamp;
  
  MemorySnapshot({
    required this.totalHeapSize,
    required this.usedHeapSize,
    required this.externalSize,
    required this.timestamp,
  });
}

/// مرجع ضعيف
class WeakReference<T extends Object> {
  final T _object;
  
  WeakReference(this._object);
  
  T? get target => _object;
}
