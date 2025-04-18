import 'package:flutter/material.dart';
import 'dart:io';

/// مدير السجلات
///
/// يوفر واجهة موحدة لتسجيل الرسائل والأخطاء والتحذيرات
/// مع دعم لمستويات مختلفة من التسجيل وتصدير السجلات
class Logger {
  // مستويات التسجيل
  static const int _levelVerbose = 0;
  static const int _levelDebug = 1;
  static const int _levelInfo = 2;
  static const int _levelWarning = 3;
  static const int _levelError = 4;
  static const int _levelNone = 5;
  
  // المستوى الحالي للتسجيل
  static int _currentLevel = _levelInfo;
  
  // قائمة السجلات
  static final List<LogEntry> _logs = [];
  
  // الحد الأقصى لعدد السجلات المحفوظة
  static const int _maxLogEntries = 1000;
  
  // ملف السجل
  static File? _logFile;
  
  /// تهيئة المسجل
  static Future<void> initialize({
    int level = _levelInfo,
    String? logFilePath,
  }) async {
    _currentLevel = level;
    
    if (logFilePath != null) {
      _logFile = File(logFilePath);
      
      // إنشاء الملف إذا لم يكن موجودًا
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }
      
      // كتابة رأس السجل
      await _logFile!.writeAsString(
        '=== بدء السجل: ${DateTime.now()} ===\n',
        mode: FileMode.append,
      );
    }
  }
  
  /// تسجيل رسالة تفصيلية
  static void verbose(String message) {
    _log(_levelVerbose, message);
  }
  
  /// تسجيل رسالة تصحيح
  static void debug(String message) {
    _log(_levelDebug, message);
  }
  
  /// تسجيل رسالة معلومات
  static void info(String message) {
    _log(_levelInfo, message);
  }
  
  /// تسجيل تحذير
  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(_levelWarning, message, error: error, stackTrace: stackTrace);
  }
  
  /// تسجيل خطأ
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(_levelError, message, error: error, stackTrace: stackTrace);
  }
  
  /// تسجيل رسالة
  static void _log(
    int level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // التحقق من مستوى التسجيل
    if (level < _currentLevel) {
      return;
    }
    
    // إنشاء سجل
    final timestamp = DateTime.now();
    final logEntry = LogEntry(
      level: level,
      message: message,
      timestamp: timestamp,
      error: error,
      stackTrace: stackTrace,
    );
    
    // إضافة السجل إلى القائمة
    _logs.add(logEntry);
    
    // التأكد من عدم تجاوز الحد الأقصى لعدد السجلات
    if (_logs.length > _maxLogEntries) {
      _logs.removeAt(0);
    }
    
    // طباعة السجل في وحدة التحكم
    _printLog(logEntry);
    
    // كتابة السجل في الملف
    _writeLogToFile(logEntry);
  }
  
  /// طباعة السجل في وحدة التحكم
  static void _printLog(LogEntry logEntry) {
    final levelString = _getLevelString(logEntry.level);
    final timestamp = _formatTimestamp(logEntry.timestamp);
    
    // طباعة الرسالة
    print('$timestamp [$levelString] ${logEntry.message}');
    
    // طباعة الخطأ إذا كان موجودًا
    if (logEntry.error != null) {
      print('  Error: ${logEntry.error}');
    }
    
    // طباعة تتبع المكدس إذا كان موجودًا
    if (logEntry.stackTrace != null) {
      print('  StackTrace: ${logEntry.stackTrace}');
    }
  }
  
  /// كتابة السجل في الملف
  static void _writeLogToFile(LogEntry logEntry) async {
    if (_logFile == null) {
      return;
    }
    
    try {
      final levelString = _getLevelString(logEntry.level);
      final timestamp = _formatTimestamp(logEntry.timestamp);
      
      // بناء سلسلة السجل
      final buffer = StringBuffer();
      buffer.writeln('$timestamp [$levelString] ${logEntry.message}');
      
      // إضافة الخطأ إذا كان موجودًا
      if (logEntry.error != null) {
        buffer.writeln('  Error: ${logEntry.error}');
      }
      
      // إضافة تتبع المكدس إذا كان موجودًا
      if (logEntry.stackTrace != null) {
        buffer.writeln('  StackTrace: ${logEntry.stackTrace}');
      }
      
      // كتابة السجل في الملف
      await _logFile!.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
      );
    } catch (e) {
      // طباعة الخطأ في وحدة التحكم فقط
      print('فشل في كتابة السجل في الملف: $e');
    }
  }
  
  /// الحصول على سلسلة المستوى
  static String _getLevelString(int level) {
    switch (level) {
      case _levelVerbose:
        return 'VERBOSE';
      case _levelDebug:
        return 'DEBUG';
      case _levelInfo:
        return 'INFO';
      case _levelWarning:
        return 'WARNING';
      case _levelError:
        return 'ERROR';
      default:
        return 'UNKNOWN';
    }
  }
  
  /// تنسيق الطابع الزمني
  static String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
           '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';
  }
  
  /// الحصول على سجلات المستوى المحدد
  static List<LogEntry> getLogs({int? level}) {
    if (level == null) {
      return List.unmodifiable(_logs);
    }
    
    return List.unmodifiable(
      _logs.where((log) => log.level == level),
    );
  }
  
  /// الحصول على سجلات الأخطاء
  static List<LogEntry> getErrorLogs() {
    return getLogs(level: _levelError);
  }
  
  /// الحصول على سجلات التحذيرات
  static List<LogEntry> getWarningLogs() {
    return getLogs(level: _levelWarning);
  }
  
  /// مسح السجلات
  static void clearLogs() {
    _logs.clear();
  }
  
  /// تصدير السجلات إلى ملف
  static Future<bool> exportLogs(String filePath) async {
    try {
      final file = File(filePath);
      
      // إنشاء الملف إذا لم يكن موجودًا
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      
      // بناء محتوى الملف
      final buffer = StringBuffer();
      buffer.writeln('=== تصدير السجلات: ${DateTime.now()} ===');
      buffer.writeln();
      
      for (final log in _logs) {
        final levelString = _getLevelString(log.level);
        final timestamp = _formatTimestamp(log.timestamp);
        
        buffer.writeln('$timestamp [$levelString] ${log.message}');
        
        if (log.error != null) {
          buffer.writeln('  Error: ${log.error}');
        }
        
        if (log.stackTrace != null) {
          buffer.writeln('  StackTrace: ${log.stackTrace}');
        }
        
        buffer.writeln();
      }
      
      // كتابة السجلات في الملف
      await file.writeAsString(buffer.toString());
      
      return true;
    } catch (e) {
      print('فشل في تصدير السجلات: $e');
      return false;
    }
  }
  
  /// تعيين مستوى التسجيل
  static void setLogLevel(int level) {
    _currentLevel = level;
  }
}

/// سجل
class LogEntry {
  final int level;
  final String message;
  final DateTime timestamp;
  final dynamic error;
  final StackTrace? stackTrace;
  
  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });
}
