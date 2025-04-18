import 'package:flutter/material.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/testing/testing_framework.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

class QualityAssuranceManager {
  // Error handler
  final ErrorHandler _errorHandler = ErrorHandler();
  
  // Testing framework
  final TestingFramework _testingFramework = TestingFramework();
  
  // Code quality metrics
  final Map<String, CodeQualityMetrics> _codeQualityMetrics = {};
  
  // Performance metrics
  final Map<String, PerformanceMetrics> _performanceMetrics = {};
  
  // Crash reports
  final List<CrashReport> _crashReports = [];
  
  // User feedback
  final List<UserFeedback> _userFeedback = [];
  
  // Singleton pattern
  static final QualityAssuranceManager _instance = QualityAssuranceManager._internal();
  
  factory QualityAssuranceManager() {
    return _instance;
  }
  
  QualityAssuranceManager._internal();
  
  // Record code quality metrics
  void recordCodeQualityMetrics({
    required String filePath,
    required int linesOfCode,
    required int commentLines,
    required int complexityScore,
    required int warningCount,
    required int errorCount,
    List<String> issues = const [],
  }) {
    try {
      final fileName = path.basename(filePath);
      
      final metrics = CodeQualityMetrics(
        filePath: filePath,
        fileName: fileName,
        linesOfCode: linesOfCode,
        commentLines: commentLines,
        commentRatio: linesOfCode > 0 ? (commentLines / linesOfCode) * 100 : 0,
        complexityScore: complexityScore,
        warningCount: warningCount,
        errorCount: errorCount,
        issues: issues,
        timestamp: DateTime.now(),
      );
      
      _codeQualityMetrics[filePath] = metrics;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to record code quality metrics',
        ErrorSeverity.low,
      );
    }
  }
  
  // Record performance metrics
  void recordPerformanceMetrics({
    required String operationName,
    required Duration executionTime,
    required int memoryUsage,
    required int cpuUsage,
    required int networkCalls,
    required int databaseQueries,
    Map<String, dynamic>? additionalMetrics,
  }) {
    try {
      final metrics = PerformanceMetrics(
        operationName: operationName,
        executionTime: executionTime,
        memoryUsage: memoryUsage,
        cpuUsage: cpuUsage,
        networkCalls: networkCalls,
        databaseQueries: databaseQueries,
        additionalMetrics: additionalMetrics,
        timestamp: DateTime.now(),
      );
      
      _performanceMetrics[operationName] = metrics;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to record performance metrics',
        ErrorSeverity.low,
      );
    }
  }
  
  // Record crash report
  void recordCrashReport({
    required String errorMessage,
    required String stackTrace,
    required String deviceInfo,
    required String appVersion,
    required String userId,
    Map<String, dynamic>? additionalInfo,
  }) {
    try {
      final crashReport = CrashReport(
        errorMessage: errorMessage,
        stackTrace: stackTrace,
        deviceInfo: deviceInfo,
        appVersion: appVersion,
        userId: userId,
        additionalInfo: additionalInfo,
        timestamp: DateTime.now(),
      );
      
      _crashReports.add(crashReport);
      
      // Log crash to error handler
      _errorHandler.handleError(
        Exception(errorMessage),
        'Application crash',
        ErrorSeverity.critical,
        stackTrace: stackTrace,
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to record crash report',
        ErrorSeverity.high,
      );
    }
  }
  
  // Record user feedback
  void recordUserFeedback({
    required String userId,
    required String feedback,
    required int rating,
    String? category,
    String? screenName,
    Map<String, dynamic>? additionalInfo,
  }) {
    try {
      final userFeedback = UserFeedback(
        userId: userId,
        feedback: feedback,
        rating: rating,
        category: category,
        screenName: screenName,
        additionalInfo: additionalInfo,
        timestamp: DateTime.now(),
      );
      
      _userFeedback.add(userFeedback);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to record user feedback',
        ErrorSeverity.low,
      );
    }
  }
  
  // Get code quality metrics
  List<CodeQualityMetrics> getCodeQualityMetrics() {
    return _codeQualityMetrics.values.toList();
  }
  
  // Get performance metrics
  List<PerformanceMetrics> getPerformanceMetrics() {
    return _performanceMetrics.values.toList();
  }
  
  // Get crash reports
  List<CrashReport> getCrashReports() {
    return List.from(_crashReports);
  }
  
  // Get user feedback
  List<UserFeedback> getUserFeedback() {
    return List.from(_userFeedback);
  }
  
  // Get average user rating
  double getAverageUserRating() {
    if (_userFeedback.isEmpty) {
      return 0.0;
    }
    
    int totalRating = 0;
    for (final feedback in _userFeedback) {
      totalRating += feedback.rating;
    }
    
    return totalRating / _userFeedback.length;
  }
  
  // Get overall code quality score
  double getOverallCodeQualityScore() {
    if (_codeQualityMetrics.isEmpty) {
      return 0.0;
    }
    
    double totalScore = 0.0;
    
    for (final metrics in _codeQualityMetrics.values) {
      // Calculate individual file score (0-100)
      double fileScore = 100.0;
      
      // Deduct points for complexity
      if (metrics.complexityScore > 10) {
        fileScore -= (metrics.complexityScore - 10) * 2;
      }
      
      // Deduct points for warnings and errors
      fileScore -= metrics.warningCount * 1;
      fileScore -= metrics.errorCount * 5;
      
      // Adjust for comment ratio (ideal is 15-25%)
      if (metrics.commentRatio < 15) {
        fileScore -= (15 - metrics.commentRatio) * 0.5;
      } else if (metrics.commentRatio > 25) {
        fileScore -= (metrics.commentRatio - 25) * 0.2;
      }
      
      // Ensure score is between 0 and 100
      fileScore = fileScore.clamp(0.0, 100.0);
      
      totalScore += fileScore;
    }
    
    return totalScore / _codeQualityMetrics.length;
  }
  
  // Get average performance score
  double getAveragePerformanceScore() {
    if (_performanceMetrics.isEmpty) {
      return 0.0;
    }
    
    double totalScore = 0.0;
    
    for (final metrics in _performanceMetrics.values) {
      // Calculate individual operation score (0-100)
      double operationScore = 100.0;
      
      // Deduct points for slow execution time (> 100ms)
      if (metrics.executionTime.inMilliseconds > 100) {
        operationScore -= (metrics.executionTime.inMilliseconds - 100) / 10;
      }
      
      // Deduct points for high memory usage (> 10MB)
      if (metrics.memoryUsage > 10 * 1024 * 1024) {
        operationScore -= (metrics.memoryUsage - 10 * 1024 * 1024) / (1024 * 1024);
      }
      
      // Deduct points for high CPU usage (> 50%)
      if (metrics.cpuUsage > 50) {
        operationScore -= (metrics.cpuUsage - 50) * 0.5;
      }
      
      // Deduct points for excessive network calls (> 3)
      if (metrics.networkCalls > 3) {
        operationScore -= (metrics.networkCalls - 3) * 5;
      }
      
      // Deduct points for excessive database queries (> 5)
      if (metrics.databaseQueries > 5) {
        operationScore -= (metrics.databaseQueries - 5) * 3;
      }
      
      // Ensure score is between 0 and 100
      operationScore = operationScore.clamp(0.0, 100.0);
      
      totalScore += operationScore;
    }
    
    return totalScore / _performanceMetrics.length;
  }
  
  // Get crash frequency
  double getCrashFrequency(Duration period) {
    final now = DateTime.now();
    final periodStart = now.subtract(period);
    
    final crashesInPeriod = _crashReports.where((report) => report.timestamp.isAfter(periodStart)).length;
    
    // Calculate crashes per day
    final days = period.inDays > 0 ? period.inDays : 1;
    return crashesInPeriod / days;
  }
  
  // Generate quality assurance report
  String generateQualityAssuranceReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('# Quality Assurance Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln();
    
    buffer.writeln('## Summary');
    buffer.writeln('- Overall Code Quality Score: ${getOverallCodeQualityScore().toStringAsFixed(2)}%');
    buffer.writeln('- Average Performance Score: ${getAveragePerformanceScore().toStringAsFixed(2)}%');
    buffer.writeln('- Crash Frequency (last 30 days): ${getCrashFrequency(Duration(days: 30)).toStringAsFixed(2)} crashes/day');
    buffer.writeln('- Average User Rating: ${getAverageUserRating().toStringAsFixed(2)}/5');
    buffer.writeln();
    
    buffer.writeln('## Code Quality Metrics');
    final codeQualityMetrics = getCodeQualityMetrics();
    if (codeQualityMetrics.isEmpty) {
      buffer.writeln('No code quality metrics available.');
    } else {
      for (final metrics in codeQualityMetrics) {
        buffer.writeln('### ${metrics.fileName}');
        buffer.writeln('- Lines of Code: ${metrics.linesOfCode}');
        buffer.writeln('- Comment Lines: ${metrics.commentLines} (${metrics.commentRatio.toStringAsFixed(2)}%)');
        buffer.writeln('- Complexity Score: ${metrics.complexityScore}');
        buffer.writeln('- Warnings: ${metrics.warningCount}');
        buffer.writeln('- Errors: ${metrics.errorCount}');
        if (metrics.issues.isNotEmpty) {
          buffer.writeln('- Issues:');
          for (final issue in metrics.issues) {
            buffer.writeln('  - $issue');
          }
        }
        buffer.writeln();
      }
    }
    
    buffer.writeln('## Performance Metrics');
    final performanceMetrics = getPerformanceMetrics();
    if (performanceMetrics.isEmpty) {
      buffer.writeln('No performance metrics available.');
    } else {
      for (final metrics in performanceMetrics) {
        buffer.writeln('### ${metrics.operationName}');
        buffer.writeln('- Execution Time: ${metrics.executionTime.inMilliseconds} ms');
        buffer.writeln('- Memory Usage: ${(metrics.memoryUsage / (1024 * 1024)).toStringAsFixed(2)} MB');
        buffer.writeln('- CPU Usage: ${metrics.cpuUsage}%');
        buffer.writeln('- Network Calls: ${metrics.networkCalls}');
        buffer.writeln('- Database Queries: ${metrics.databaseQueries}');
        if (metrics.additionalMetrics != null && metrics.additionalMetrics!.isNotEmpty) {
          buffer.writeln('- Additional Metrics:');
          for (final entry in metrics.additionalMetrics!.entries) {
            buffer.writeln('  - ${entry.key}: ${entry.value}');
          }
        }
        buffer.writeln();
      }
    }
    
    buffer.writeln('## Recent Crash Reports');
    final recentCrashes = _crashReports.take(5).toList();
    if (recentCrashes.isEmpty) {
      buffer.writeln('No recent crash reports available.');
    } else {
      for (final crash in recentCrashes) {
        buffer.writeln('### Crash at ${crash.timestamp}');
        buffer.writeln('- Error: ${crash.errorMessage}');
        buffer.writeln('- Device: ${crash.deviceInfo}');
        buffer.writeln('- App Version: ${crash.appVersion}');
        buffer.writeln('- Stack Trace:');
        buffer.writeln('```');
        buffer.writeln(crash.stackTrace);
        buffer.writeln('```');
        buffer.writeln();
      }
    }
    
    buffer.writeln('## User Feedback Summary');
    final userFeedback = getUserFeedback();
    if (userFeedback.isEmpty) {
      buffer.writeln('No user feedback available.');
    } else {
      // Group feedback by rating
      final feedbackByRating = <int, List<UserFeedback>>{};
      for (int i = 1; i <= 5; i++) {
        feedbackByRating[i] = [];
      }
      
      for (final feedback in userFeedback) {
        feedbackByRating[feedback.rating]!.add(feedback);
      }
      
      for (int i = 5; i >= 1; i--) {
        final feedbackList = feedbackByRating[i]!;
        buffer.writeln('### ${i}-Star Feedback (${feedbackList.length})');
        
        if (feedbackList.isEmpty) {
          buffer.writeln('No ${i}-star feedback available.');
        } else {
          for (final feedback in feedbackList.take(3)) {
            buffer.writeln('- "${feedback.feedback}"');
            if (feedback.category != null) {
              buffer.writeln('  Category: ${feedback.category}');
            }
            if (feedback.screenName != null) {
              buffer.writeln('  Screen: ${feedback.screenName}');
            }
            buffer.writeln();
          }
        }
      }
    }
    
    return buffer.toString();
  }
  
  // Save quality assurance report to file
  Future<void> saveQualityAssuranceReport(String filePath) async {
    try {
      final report = generateQualityAssuranceReport();
      final file = File(filePath);
      await file.writeAsString(report);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to save quality assurance report',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Clear code quality metrics
  void clearCodeQualityMetrics() {
    _codeQualityMetrics.clear();
  }
  
  // Clear performance metrics
  void clearPerformanceMetrics() {
    _performanceMetrics.clear();
  }
  
  // Clear crash reports
  void clearCrashReports() {
    _crashReports.clear();
  }
  
  // Clear user feedback
  void clearUserFeedback() {
    _userFeedback.clear();
  }
  
  // Reset all data
  void reset() {
    clearCodeQualityMetrics();
    clearPerformanceMetrics();
    clearCrashReports();
    clearUserFeedback();
  }
}

// Code quality metrics class
class CodeQualityMetrics {
  final String filePath;
  final String fileName;
  final int linesOfCode;
  final int commentLines;
  final double commentRatio;
  final int complexityScore;
  final int warningCount;
  final int errorCount;
  final List<String> issues;
  final DateTime timestamp;
  
  CodeQualityMetrics({
    required this.filePath,
    required this.fileName,
    required this.linesOfCode,
    required this.commentLines,
    required this.commentRatio,
    required this.complexityScore,
    required this.warningCount,
    required this.errorCount,
    required this.issues,
    required this.timestamp,
  });
}

// Performance metrics class
class PerformanceMetrics {
  final String operationName;
  final Duration executionTime;
  final int memoryUsage;
  final int cpuUsage;
  final int networkCalls;
  final int databaseQueries;
  final Map<String, dynamic>? additionalMetrics;
  final DateTime timestamp;
  
  PerformanceMetrics({
    required this.operationName,
    required this.executionTime,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.networkCalls,
    required this.databaseQueries,
    this.additionalMetrics,
    required this.timestamp,
  });
}

// Crash report class
class CrashReport {
  final String errorMessage;
  final String stackTrace;
  final String deviceInfo;
  final String appVersion;
  final String userId;
  final Map<String, dynamic>? additionalInfo;
  final DateTime timestamp;
  
  CrashReport({
    required this.errorMessage,
    required this.stackTrace,
    required this.deviceInfo,
    required this.appVersion,
    required this.userId,
    this.additionalInfo,
    required this.timestamp,
  });
}

// User feedback class
class UserFeedback {
  final String userId;
  final String feedback;
  final int rating;
  final String? category;
  final String? screenName;
  final Map<String, dynamic>? additionalInfo;
  final DateTime timestamp;
  
  UserFeedback({
    required this.userId,
    required this.feedback,
    required this.rating,
    this.category,
    this.screenName,
    this.additionalInfo,
    required this.timestamp,
  });
}
