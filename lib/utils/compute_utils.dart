import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpay_app/utils/performance_optimizer.dart';
import 'dart:async';
import 'dart:isolate';

class ComputeUtils {
  // Singleton pattern
  static final ComputeUtils _instance = ComputeUtils._internal();
  
  factory ComputeUtils() {
    return _instance;
  }
  
  ComputeUtils._internal();
  
  // Track active isolates
  final Map<String, Isolate> _activeIsolates = {};
  
  // Run heavy computation in a separate isolate
  Future<T> runCompute<T, U>(
    FutureOr<T> Function(U message) callback,
    U message, {
    String? taskName,
    Duration? timeout,
  }) async {
    final String taskId = taskName ?? 'task_${DateTime.now().millisecondsSinceEpoch}';
    final ReceivePort receivePort = ReceivePort();
    final Completer<T> completer = Completer<T>();
    
    // Create timeout if specified
    Timer? timeoutTimer;
    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          // Kill the isolate if it times out
          _activeIsolates[taskId]?.kill(priority: Isolate.immediate);
          _activeIsolates.remove(taskId);
          receivePort.close();
          completer.completeError(TimeoutException('Compute task timed out', timeout));
        }
      });
    }
    
    try {
      // Start performance tracking
      final startTime = DateTime.now();
      
      // Spawn isolate
      final isolate = await Isolate.spawn<_IsolateData<U>>(
        _isolateEntryPoint,
        _IsolateData<U>(
          callback,
          message,
          receivePort.sendPort,
        ),
      );
      
      // Store isolate reference
      _activeIsolates[taskId] = isolate;
      
      // Listen for result or error
      receivePort.listen((dynamic message) {
        // Clean up
        _activeIsolates.remove(taskId);
        timeoutTimer?.cancel();
        receivePort.close();
        
        // Track performance
        final duration = DateTime.now().difference(startTime);
        PerformanceOptimizer().logComputeTask(taskId, duration.inMilliseconds);
        
        // Handle result or error
        if (message is _IsolateError) {
          if (!completer.isCompleted) {
            completer.completeError(message.error, message.stackTrace);
          }
        } else {
          if (!completer.isCompleted) {
            completer.complete(message as T);
          }
        }
      });
      
      return completer.future;
    } catch (e, stackTrace) {
      // Clean up
      _activeIsolates.remove(taskId);
      timeoutTimer?.cancel();
      receivePort.close();
      
      // Rethrow with original stack trace
      return Future.error(e, stackTrace);
    }
  }
  
  // Cancel all running isolates
  void cancelAll() {
    for (final isolate in _activeIsolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    _activeIsolates.clear();
  }
  
  // Get number of active isolates
  int get activeIsolateCount => _activeIsolates.length;
}

// Data structure to pass to isolate
class _IsolateData<T> {
  final Function callback;
  final T message;
  final SendPort sendPort;
  
  _IsolateData(this.callback, this.message, this.sendPort);
}

// Error structure for isolate errors
class _IsolateError {
  final dynamic error;
  final StackTrace stackTrace;
  
  _IsolateError(this.error, this.stackTrace);
}

// Entry point for isolate
void _isolateEntryPoint<T>(_IsolateData<T> data) async {
  try {
    // Execute callback with message
    final result = await data.callback(data.message);
    // Send result back
    data.sendPort.send(result);
  } catch (e, stackTrace) {
    // Send error back
    data.sendPort.send(_IsolateError(e, stackTrace));
  }
}

// Extension methods for PerformanceOptimizer
extension ComputePerformanceExtension on PerformanceOptimizer {
  // Log compute task performance
  void logComputeTask(String taskId, int durationMs) {
    _logPerformanceMetric(
      'compute_task',
      durationMs.toDouble(),
      'Compute task: $taskId',
    );
  }
}
