import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';
import 'package:mpay_app/utils/performance_optimizer.dart';

class ConnectivityUtils {
  static final Connectivity _connectivity = Connectivity();
  static final InternetConnectionChecker _connectionChecker = InternetConnectionChecker();
  
  // Cache for connectivity status to reduce redundant checks
  static bool? _lastKnownConnectivity;
  static DateTime? _lastConnectivityCheck;
  static const Duration _connectivityCacheDuration = Duration(seconds: 5);
  
  // Stream controller for connectivity changes - using lazy initialization
  static StreamController<bool>? _connectivityStreamController;
  
  // Getter that lazily initializes the stream controller
  static Stream<bool> get connectivityStream {
    _connectivityStreamController ??= StreamController<bool>.broadcast();
    return _connectivityStreamController!.stream;
  }
  
  // StreamSubscription for connectivity changes
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Initialize connectivity monitoring
  static Future<void> initialize() async {
    // Check initial connectivity
    _lastKnownConnectivity = await _checkConnectivityUncached();
    _lastConnectivityCheck = DateTime.now();
    
    // Create stream controller if needed
    _connectivityStreamController ??= StreamController<bool>.broadcast();
    
    // Add initial value to stream
    if (!_connectivityStreamController!.isClosed) {
      _connectivityStreamController!.add(_lastKnownConnectivity ?? false);
    }
    
    // Cancel existing subscription if any
    await _connectivitySubscription?.cancel();
    
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
      final isConnected = result != ConnectivityResult.none 
          ? await _connectionChecker.hasConnection 
          : false;
      
      // Only update if status changed
      if (_lastKnownConnectivity != isConnected) {
        _lastKnownConnectivity = isConnected;
        _lastConnectivityCheck = DateTime.now();
        
        // Check if controller exists and is not closed before adding event
        if (_connectivityStreamController != null && !_connectivityStreamController!.isClosed) {
          _connectivityStreamController!.add(isConnected);
        }
      }
    });
  }
  
  // Check if device is connected to internet with caching
  static Future<bool> isConnected() async {
    // Use cached value if available and recent
    if (_lastKnownConnectivity != null && _lastConnectivityCheck != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastConnectivityCheck!);
      if (timeSinceLastCheck < _connectivityCacheDuration) {
        return _lastKnownConnectivity!;
      }
    }
    
    // Check connectivity and update cache
    final isConnected = await _checkConnectivityUncached();
    _lastKnownConnectivity = isConnected;
    _lastConnectivityCheck = DateTime.now();
    return isConnected;
  }
  
  // Check connectivity without using cache
  static Future<bool> _checkConnectivityUncached() async {
    try {
      // First check connectivity status (fast)
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Then verify actual internet connection (slower but more accurate)
      return await _connectionChecker.hasConnection;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }
  
  // Check internet connection with timeout
  static Future<bool> checkInternetConnection({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      return await _connectionChecker.hasConnection.timeout(timeout);
    } on TimeoutException {
      return false;
    } catch (e) {
      debugPrint('Error checking internet connection: $e');
      return false;
    }
  }
  
  // Show connectivity status banner
  static Widget connectivityBanner(bool isConnected) {
    if (isConnected) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade800, semanticLabel: 'لا يوجد اتصال'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'لا يوجد اتصال بالإنترنت. بعض الميزات قد لا تعمل بشكل صحيح.',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
  
  // Retry mechanism for network operations with exponential backoff
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool exponentialBackoff = true,
    bool throwOnConnectivityError = false,
    Function(int, Exception)? onRetry,
  }) async {
    int attempts = 0;
    Exception? lastException;
    
    while (true) {
      try {
        // Check connectivity before attempting operation
        if (throwOnConnectivityError && attempts > 0) {
          final isConnected = await isConnected();
          if (!isConnected) {
            throw ConnectivityException('No internet connection available');
          }
        }
        
        // Track network operation performance
        final startTime = DateTime.now();
        final result = await operation();
        final duration = DateTime.now().difference(startTime);
        
        // Log performance metrics for network operations
        PerformanceOptimizer().logApiCall(
          'retry_operation',
          200, // Success status code
          0,  // Unknown response size
          startTime,
        );
        
        return result;
      } catch (e) {
        attempts++;
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Notify about retry if callback provided
        if (onRetry != null) {
          onRetry(attempts, lastException);
        }
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        // Calculate delay with optional exponential backoff
        final delay = exponentialBackoff
            ? initialDelay * (1 << (attempts - 1)) // 1s, 2s, 4s, 8s, etc.
            : initialDelay * attempts;
            
        await Future.delayed(delay);
      }
    }
  }
  
  // Optimize network request batching
  static Future<List<T>> batchRequests<T>(
    List<Future<T> Function()> operations, {
    int maxConcurrent = 2,
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    final results = <T>[];
    
    // Process in batches to avoid overloading the network
    for (int i = 0; i < operations.length; i += maxConcurrent) {
      final batch = operations.skip(i).take(maxConcurrent);
      final batchResults = await Future.wait(batch.map((op) => op()));
      results.addAll(batchResults);
      
      // Add delay between batches if not the last batch
      if (i + maxConcurrent < operations.length) {
        await Future.delayed(delay);
      }
    }
    
    return results;
  }
  
  // Dispose resources
  static Future<void> dispose() async {
    // Cancel connectivity subscription
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    
    // Close stream controller if it exists and is not already closed
    if (_connectivityStreamController != null && !_connectivityStreamController!.isClosed) {
      await _connectivityStreamController!.close();
      _connectivityStreamController = null;
    }
  }
}

// Custom exception for connectivity issues
class ConnectivityException implements Exception {
  final String message;
  
  ConnectivityException(this.message);
  
  @override
  String toString() => 'ConnectivityException: $message';
}
