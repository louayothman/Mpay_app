import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

/// Performance optimizer for monitoring and improving app performance
class PerformanceOptimizer {
  // Singleton pattern
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  
  factory PerformanceOptimizer() {
    return _instance;
  }
  
  PerformanceOptimizer._internal();
  
  // Performance metrics tracking
  final Map<String, List<PerformanceMetric>> _performanceMetrics = {};
  final Queue<ApiCallMetric> _apiCallMetrics = Queue();
  final int _maxApiCallMetrics = 100;
  
  // Frame metrics
  int _slowFrameCount = 0;
  int _totalFrameCount = 0;
  DateTime? _lastFrameTime;
  
  // Memory usage tracking
  double _lastReportedMemoryUsage = 0.0;
  Timer? _memoryMonitorTimer;
  
  // Battery usage tracking
  DateTime? _lastBatteryCheck;
  double? _lastBatteryLevel;
  
  // Flag to track if monitoring is active
  bool _isMonitoringActive = false;
  
  // Isolate for background processing
  Isolate? _backgroundIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  
  /// Initialize performance optimization
  static Future<void> initialize() async {
    // Optimize first frame rendering
    WidgetsBinding.instance.deferFirstFrame();
    
    // Use a shorter delay to improve startup time
    Future.delayed(const Duration(milliseconds: 50), () {
      if (WidgetsBinding.instance.mounted) {
        WidgetsBinding.instance.allowFirstFrame();
      }
    });
    
    // Register frame callback for monitoring
    await _instance._startMonitoring();
    
    // Initialize background isolate for performance analysis
    await _instance._initializeBackgroundIsolate();
    
    // Start memory monitoring
    _instance._startMemoryMonitoring();
  }
  
  /// Initialize background isolate for performance analysis
  Future<void> _initializeBackgroundIsolate() async {
    try {
      _receivePort = ReceivePort();
      
      _backgroundIsolate = await Isolate.spawn(
        _performanceAnalysisIsolate,
        _receivePort!.sendPort,
      );
      
      _sendPort = await _receivePort!.first as SendPort;
      
      // Listen for messages from the isolate
      _receivePort!.listen((message) {
        if (message is Map<String, dynamic>) {
          // Process performance analysis results
          if (message.containsKey('performance_report')) {
            final report = message['performance_report'];
            _processPerformanceReport(report);
          }
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize background isolate: $e');
      // Continue without background processing if isolate creation fails
    }
  }
  
  /// Process performance report from background isolate
  void _processPerformanceReport(Map<String, dynamic> report) {
    // Update metrics based on report
    if (report.containsKey('memory_optimization')) {
      final recommendations = report['memory_optimization'];
      debugPrint('Memory optimization recommendations: $recommendations');
    }
  }
  
  /// Background isolate entry point
  static void _performanceAnalysisIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    
    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        // Process performance data
        if (message.containsKey('metrics')) {
          final metrics = message['metrics'];
          final report = _analyzePerformanceData(metrics);
          sendPort.send({'performance_report': report});
        }
      }
    });
  }
  
  /// Analyze performance data in background isolate
  static Map<String, dynamic> _analyzePerformanceData(Map<String, dynamic> metrics) {
    // Analyze metrics and generate recommendations
    final report = <String, dynamic>{};
    
    // Example analysis
    if (metrics.containsKey('memory_usage')) {
      final memoryUsage = metrics['memory_usage'] as double;
      if (memoryUsage > 100) {
        report['memory_optimization'] = 'Consider reducing cached data';
      }
    }
    
    return report;
  }
  
  /// Start memory monitoring
  void _startMemoryMonitoring() {
    // Cancel existing timer if any
    _memoryMonitorTimer?.cancel();
    
    // Monitor memory usage every 30 seconds
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkMemoryUsage();
    });
  }
  
  /// Check memory usage
  Future<void> _checkMemoryUsage() async {
    try {
      // This is a placeholder. In a real app, you would use platform-specific
      // methods to get actual memory usage.
      final currentMemoryUsage = 0.0;
      
      if (_lastReportedMemoryUsage > 0 && 
          currentMemoryUsage > _lastReportedMemoryUsage * 1.5) {
        // Memory usage increased by 50%
        _logPerformanceMetric(
          'memory_usage',
          currentMemoryUsage,
          'Memory usage increased significantly',
        );
        
        // Send to background isolate for analysis
        _sendToBackgroundIsolate({
          'metrics': {'memory_usage': currentMemoryUsage}
        });
      }
      
      _lastReportedMemoryUsage = currentMemoryUsage;
    } catch (e) {
      debugPrint('Error checking memory usage: $e');
    }
  }
  
  /// Send data to background isolate
  void _sendToBackgroundIsolate(Map<String, dynamic> data) {
    if (_sendPort != null) {
      _sendPort!.send(data);
    }
  }
  
  /// Start monitoring frames
  Future<void> _startMonitoring() async {
    if (!_isMonitoringActive) {
      _isMonitoringActive = true;
      SchedulerBinding.instance.addPostFrameCallback(_monitorFrameCallback);
    }
  }
  
  /// Stop monitoring frames
  void _stopMonitoring() {
    _isMonitoringActive = false;
  }
  
  /// Monitor frame callback
  void _monitorFrameCallback(Duration timeStamp) {
    if (!_isMonitoringActive) return;
    
    final now = DateTime.now();
    
    if (_lastFrameTime != null) {
      final frameDuration = now.difference(_lastFrameTime!);
      
      // Track slow frames (> 16ms for 60fps)
      if (frameDuration.inMilliseconds > 16) {
        _slowFrameCount++;
        
        // Log severe jank (frames taking > 100ms)
        if (frameDuration.inMilliseconds > 100) {
          _logPerformanceMetric(
            'severe_jank',
            frameDuration.inMilliseconds.toDouble(),
            'Severe frame jank detected',
          );
        }
      }
      
      _totalFrameCount++;
      
      // Log frame metrics periodically
      if (_totalFrameCount % 100 == 0) {
        final slowFramePercentage = (_slowFrameCount / _totalFrameCount) * 100;
        _logPerformanceMetric(
          'frame_rendering',
          slowFramePercentage,
          'Slow frames percentage',
        );
        
        // Send to background isolate for analysis
        _sendToBackgroundIsolate({
          'metrics': {
            'slow_frame_percentage': slowFramePercentage,
            'total_frames': _totalFrameCount,
          }
        });
        
        // Reset counters periodically to focus on recent performance
        if (_totalFrameCount > 1000) {
          _slowFrameCount = (_slowFrameCount * 100) ~/ _totalFrameCount;
          _totalFrameCount = 100;
        }
      }
    }
    
    _lastFrameTime = now;
    
    // Only register for next frame if monitoring is still active
    if (_isMonitoringActive) {
      SchedulerBinding.instance.addPostFrameCallback(_monitorFrameCallback);
    }
  }
  
  /// Log performance metric
  void _logPerformanceMetric(String category, double value, String description) {
    if (!_performanceMetrics.containsKey(category)) {
      _performanceMetrics[category] = [];
    }
    
    _performanceMetrics[category]!.add(
      PerformanceMetric(
        value: value,
        timestamp: DateTime.now(),
        description: description,
      ),
    );
    
    // Limit the number of stored metrics to prevent memory leaks
    if (_performanceMetrics[category]!.length > 100) {
      _performanceMetrics[category]!.removeAt(0);
    }
  }
  
  /// Log API call for performance monitoring
  void logApiCall(
    String endpoint,
    int statusCode,
    int responseSize,
    DateTime timestamp,
  ) {
    final metric = ApiCallMetric(
      endpoint: endpoint,
      statusCode: statusCode,
      responseSize: responseSize,
      timestamp: timestamp,
      duration: DateTime.now().difference(timestamp),
    );
    
    _apiCallMetrics.add(metric);
    
    // Limit the number of stored metrics to prevent memory leaks
    if (_apiCallMetrics.length > _maxApiCallMetrics) {
      _apiCallMetrics.removeFirst();
    }
    
    // Log slow API calls (> 1 second)
    if (metric.duration.inMilliseconds > 1000) {
      debugPrint('Slow API call: ${metric.endpoint} - ${metric.duration.inMilliseconds}ms');
      
      // Send to background isolate for analysis
      _sendToBackgroundIsolate({
        'metrics': {
          'slow_api_call': {
            'endpoint': metric.endpoint,
            'duration_ms': metric.duration.inMilliseconds,
          }
        }
      });
    }
  }
  
  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    // Frame metrics
    report['frame_metrics'] = {
      'total_frames': _totalFrameCount,
      'slow_frames': _slowFrameCount,
      'slow_frame_percentage': _totalFrameCount > 0
          ? (_slowFrameCount / _totalFrameCount) * 100
          : 0,
    };
    
    // API call metrics
    final apiCallStats = <String, dynamic>{};
    final endpointDurations = <String, List<int>>{};
    
    for (final metric in _apiCallMetrics) {
      if (!endpointDurations.containsKey(metric.endpoint)) {
        endpointDurations[metric.endpoint] = [];
      }
      
      endpointDurations[metric.endpoint]!.add(metric.duration.inMilliseconds);
    }
    
    for (final entry in endpointDurations.entries) {
      final durations = entry.value;
      
      if (durations.isNotEmpty) {
        durations.sort();
        
        final avgDuration = durations.reduce((a, b) => a + b) / durations.length;
        final medianDuration = durations[durations.length ~/ 2];
        final p95Duration = durations[(durations.length * 0.95).floor()];
        
        apiCallStats[entry.key] = {
          'count': durations.length,
          'avg_duration_ms': avgDuration,
          'median_duration_ms': medianDuration,
          'p95_duration_ms': p95Duration,
        };
      }
    }
    
    report['api_call_metrics'] = apiCallStats;
    
    // Other performance metrics
    final otherMetrics = <String, dynamic>{};
    
    for (final entry in _performanceMetrics.entries) {
      if (entry.value.isNotEmpty) {
        final latestMetric = entry.value.last;
        otherMetrics[entry.key] = {
          'value': latestMetric.value,
          'timestamp': latestMetric.timestamp.toIso8601String(),
          'description': latestMetric.description,
        };
      }
    }
    
    report['other_metrics'] = otherMetrics;
    
    return report;
  }
  
  /// Reset performance metrics
  void resetPerformanceMetrics() {
    _performanceMetrics.clear();
    _apiCallMetrics.clear();
    _slowFrameCount = 0;
    _totalFrameCount = 0;
  }
  
  /// Optimized ListView with improved performance
  static Widget optimizedListView({
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    Axis scrollDirection = Axis.vertical,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    ScrollController? controller,
    Widget? separatorBuilder,
    String? semanticLabel,
  }) {
    // Avoid using shrinkWrap: true when possible as it's expensive
    if (shrinkWrap && physics == null) {
      // If shrinkWrap is needed, use a more efficient physics
      physics = const ClampingScrollPhysics();
    }
    
    // Use cacheExtent to improve scrolling performance
    final effectiveCacheExtent = cacheExtent ?? (itemCount > 100 ? 500.0 : 250.0);
    
    // For large lists, use a more efficient approach
    if (itemCount > 100 && !shrinkWrap) {
      return separatorBuilder != null
          ? ListView.separated(
              itemBuilder: (context, index) => RepaintBoundary(
                child: itemBuilder(context, index),
              ),
              separatorBuilder: (context, index) => separatorBuilder,
              itemCount: itemCount,
              physics: physics,
              padding: padding,
              scrollDirection: scrollDirection,
              addAutomaticKeepAlives: false, // Disable for better performance
              addRepaintBoundaries: false, // We're adding them manually
              addSemanticIndexes: addSemanticIndexes,
              cacheExtent: effectiveCacheExtent,
              semanticChildCount: semanticChildCount,
              controller: controller,
            )
          : ListView.builder(
              itemBuilder: (context, index) => RepaintBoundary(
                child: itemBuilder(context, index),
              ),
              itemCount: itemCount,
              physics: physics,
              padding: padding,
              scrollDirection: scrollDirection,
              addAutomaticKeepAlives: false, // Disable for better performance
              addRepaintBoundaries: false, // We're adding them manually
              addSemanticIndexes: addSemanticIndexes,
              cacheExtent: effectiveCacheExtent,
              semanticChildCount: semanticChildCount,
              controller: controller,
            );
    }
    
    // Add semantic label for accessibility
    final Widget listView = separatorBuilder != null
        ? ListView.separated(
            itemBuilder: itemBuilder,
            separatorBuilder: (context, index) => separatorBuilder,
            itemCount: itemCount,
            shrinkWrap: shrinkWrap,
            physics: physics,
            padding: padding,
            scrollDirection: scrollDirection,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
            cacheExtent: effectiveCacheExtent,
            semanticChildCount: semanticChildCount,
            controller: controller,
          )
        : ListView.builder(
            itemBuilder: itemBuilder,
            itemCount: itemCount,
            shrinkWrap: shrinkWrap,
            physics: physics,
            padding: padding,
            scrollDirection: scrollDirection,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
            cacheExtent: effectiveCacheExtent,
            semanticChildCount: semanticChildCount,
            controller: controller,
          );
    
    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        child: listView,
      );
    }
    
    return listView;
  }
  
  /// Optimized image widget with memory efficiency
  static Widget optimizedImage({
    required ImageProvider image,
    double? width,
    double? height,
    BoxFit? fit,
    Color? color,
    BlendMode? colorBlendMode,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    FilterQuality filterQuality = FilterQuality.low,
    bool isAntiAlias = false,
    String? semanticLabel,
    Widget? loadingBuilder,
    Widget? errorBuilder,
  }) {
    // Use RepaintBoundary to optimize rendering
    final Widget imageWidget = RepaintBoundary(
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality, // Use low quality for better performance
        isAntiAlias: isAntiAlias,
        semanticLabel: semanticLabel,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
        loadingBuilder: loadingBuilder != null
            ? (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return loadingBuilder;
              }
            : null,
        errorBuilder: errorBuilder != null
            ? (context, error, stackTrace) => errorBuilder
            : null,
      ),
    );
    
    return imageWidget;
  }
  
  /// Optimized animation builder with reduced repaints
  static Widget optimizedAnimationBuilder<T>({
    required Animation<T> animation,
    required Widget Function(BuildContext context, T value, Widget? child) builder,
    Widget? child,
    bool useRepaintBoundary = true,
  }) {
    final Widget animatedWidget = AnimatedBuilder(
      animation: animation,
      builder: (context, childWidget) => builder(context, animation.value, childWidget),
      child: child,
    );
    
    return useRepaintBoundary
        ? RepaintBoundary(child: animatedWidget)
        : animatedWidget;
  }
  
  /// Optimized container with efficient widget selection
  static Widget optimizedContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    Decoration? decoration,
    double? width,
    double? height,
    Alignment? alignment,
    BoxConstraints? constraints,
  }) {
    // Use more efficient widgets when possible
    
    // Use SizedBox for simple sizing
    if (padding == null && margin == null && color == null && decoration == null && alignment == null && constraints == null) {
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );
    }
    
    // Use Padding for simple padding
    if (margin == null && color == null && decoration == null && width == null && height == null && alignment == null && constraints == null && padding != null) {
      return Padding(
        padding: padding,
        child: child,
      );
    }
    
    // Use Align for simple alignment
    if (padding == null && margin == null && color == null && decoration == null && width == null && height == null && constraints == null && alignment != null) {
      return Align(
        alignment: alignment,
        child: child,
      );
    }
    
    // Use ColoredBox for simple background color
    if (padding == null && margin == null && decoration == null && width == null && height == null && alignment == null && constraints == null && color != null) {
      return ColoredBox(
        color: color,
        child: child,
      );
    }
    
    // Use Container for more complex cases
    return Container(
      padding: padding,
      margin: margin,
      color: color,
      decoration: decoration,
      width: width,
      height: height,
      alignment: alignment,
      constraints: constraints,
      child: child,
    );
  }
  
  /// Optimized text widget with efficient rendering
  static Widget optimizedText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    TextDirection? textDirection,
    int? maxLines,
    TextOverflow? overflow,
    double? textScaleFactor,
    bool selectable = false,
    String? semanticLabel,
  }) {
    final Widget textWidget = selectable
        ? SelectableText(
            text,
            style: style,
            textAlign: textAlign,
            textDirection: textDirection,
            maxLines: maxLines,
            textScaler: textScaleFactor != null ? TextScaler.linear(textScaleFactor) : null,
            semanticsLabel: semanticLabel,
          )
        : Text(
            text,
            style: style,
            textAlign: textAlign,
            textDirection: textDirection,
            maxLines: maxLines,
            overflow: overflow,
            textScaler: textScaleFactor != null ? TextScaler.linear(textScaleFactor) : null,
            semanticsLabel: semanticLabel,
          );
    
    return textWidget;
  }
  
  /// Optimized screen widget with efficient structure
  static Widget optimizedScreen({
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
    Color? backgroundColor,
    bool extendBody = false,
    bool extendBodyBehindAppBar = false,
    bool resizeToAvoidBottomInset = true,
    bool addSafeArea = true,
    String? semanticLabel,
  }) {
    final Widget screenBody = addSafeArea ? SafeArea(child: body) : body;
    
    final Widget scaffold = Scaffold(
      appBar: appBar,
      body: screenBody,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
    
    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        child: scaffold,
      );
    }
    
    return scaffold;
  }
  
  /// Optimized future builder to prevent memory leaks
  static Widget optimizedFutureBuilder<T>({
    required Future<T> future,
    required Widget Function(BuildContext context, T data) builder,
    Widget? loadingWidget,
    Widget Function(BuildContext context, dynamic error)? errorBuilder,
    bool useRepaintBoundary = true,
  }) {
    return _OptimizedFutureBuilder<T>(
      future: future,
      builder: builder,
      loadingWidget: loadingWidget,
      errorBuilder: errorBuilder,
      useRepaintBoundary: useRepaintBoundary,
    );
  }
  
  /// Optimized stream builder to prevent memory leaks
  static Widget optimizedStreamBuilder<T>({
    required Stream<T> stream,
    required Widget Function(BuildContext context, T data) builder,
    T? initialData,
    Widget? loadingWidget,
    Widget Function(BuildContext context, dynamic error)? errorBuilder,
    bool useRepaintBoundary = true,
  }) {
    return _OptimizedStreamBuilder<T>(
      stream: stream,
      builder: builder,
      initialData: initialData,
      loadingWidget: loadingWidget,
      errorBuilder: errorBuilder,
      useRepaintBoundary: useRepaintBoundary,
    );
  }
  
  /// Get image dimensions efficiently
  static Future<Size> getImageDimensions(ImageProvider provider) async {
    final Completer<Size> completer = Completer<Size>();
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final Size size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        completer.complete(size);
        stream.removeListener(listener);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        completer.completeError(exception, stackTrace);
        stream.removeListener(listener);
      },
    );
    
    stream.addListener(listener);
    return completer.future;
  }
  
  /// Calculate optimal image dimensions for efficient rendering
  static Size calculateOptimalImageDimensions(
    Size originalSize,
    Size targetSize,
    BoxFit fit,
  ) {
    if (fit == BoxFit.cover || fit == BoxFit.contain) {
      final double aspectRatio = originalSize.width / originalSize.height;
      final double targetAspectRatio = targetSize.width / targetSize.height;
      
      if ((fit == BoxFit.cover && aspectRatio < targetAspectRatio) ||
          (fit == BoxFit.contain && aspectRatio > targetAspectRatio)) {
        return Size(targetSize.width, targetSize.width / aspectRatio);
      } else {
        return Size(targetSize.height * aspectRatio, targetSize.height);
      }
    }
    
    return targetSize;
  }
  
  /// Dispose resources
  void dispose() {
    // Stop frame monitoring
    _stopMonitoring();
    
    // Stop memory monitoring
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    
    // Terminate background isolate
    _backgroundIsolate?.kill(priority: Isolate.immediate);
    _backgroundIsolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
    
    // Clear all metrics
    resetPerformanceMetrics();
    
    // Reset other state
    _lastFrameTime = null;
    _lastReportedMemoryUsage = 0.0;
    _lastBatteryCheck = null;
    _lastBatteryLevel = null;
  }
  
  /// Static method to dispose the singleton instance
  static void disposeInstance() {
    _instance.dispose();
  }
}

/// Performance metric class
class PerformanceMetric {
  final double value;
  final DateTime timestamp;
  final String description;
  
  PerformanceMetric({
    required this.value,
    required this.timestamp,
    required this.description,
  });
}

/// API call metric class
class ApiCallMetric {
  final String endpoint;
  final int statusCode;
  final int responseSize;
  final DateTime timestamp;
  final Duration duration;
  
  ApiCallMetric({
    required this.endpoint,
    required this.statusCode,
    required this.responseSize,
    required this.timestamp,
    required this.duration,
  });
}

/// Optimized FutureBuilder implementation with memory leak prevention
class _OptimizedFutureBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final bool useRepaintBoundary;
  
  const _OptimizedFutureBuilder({
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.useRepaintBoundary = true,
    Key? key,
  }) : super(key: key);
  
  @override
  _OptimizedFutureBuilderState<T> createState() => _OptimizedFutureBuilderState<T>();
}

class _OptimizedFutureBuilderState<T> extends State<_OptimizedFutureBuilder<T>> {
  Future<T>? _future;
  T? _data;
  dynamic _error;
  bool _hasData = false;
  bool _hasError = false;
  bool _isLoading = true;
  bool _isMounted = false;
  
  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _future = widget.future;
    _loadData();
  }
  
  @override
  void didUpdateWidget(_OptimizedFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      _future = widget.future;
      _isLoading = true;
      _hasData = false;
      _hasError = false;
      _loadData();
    }
  }
  
  Future<void> _loadData() async {
    if (_future == null) return;
    
    try {
      final data = await _future!;
      if (_isMounted) {
        setState(() {
          _data = data;
          _hasData = true;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (error) {
      if (_isMounted) {
        setState(() {
          _error = error;
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    Widget child;
    
    if (_hasData) {
      child = widget.builder(context, _data as T);
    } else if (_hasError) {
      child = widget.errorBuilder != null
          ? widget.errorBuilder!(context, _error)
          : Center(
              child: Text(
                'Error: ${_error.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
            );
    } else {
      child = widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }
    
    return widget.useRepaintBoundary ? RepaintBoundary(child: child) : child;
  }
  
  @override
  void dispose() {
    // Mark as unmounted to prevent setState after dispose
    _isMounted = false;
    
    // Clear references to prevent memory leaks
    _future = null;
    _data = null;
    _error = null;
    super.dispose();
  }
}

/// Optimized StreamBuilder implementation with memory leak prevention
class _OptimizedStreamBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final T? initialData;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final bool useRepaintBoundary;
  
  const _OptimizedStreamBuilder({
    required this.stream,
    required this.builder,
    this.initialData,
    this.loadingWidget,
    this.errorBuilder,
    this.useRepaintBoundary = true,
    Key? key,
  }) : super(key: key);
  
  @override
  _OptimizedStreamBuilderState<T> createState() => _OptimizedStreamBuilderState<T>();
}

class _OptimizedStreamBuilderState<T> extends State<_OptimizedStreamBuilder<T>> {
  StreamSubscription<T>? _subscription;
  T? _data;
  dynamic _error;
  bool _hasData = false;
  bool _hasError = false;
  bool _isMounted = false;
  
  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _data = widget.initialData;
    _hasData = _data != null;
    _subscribe();
  }
  
  @override
  void didUpdateWidget(_OptimizedStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _unsubscribe();
      _subscribe();
    }
  }
  
  void _subscribe() {
    _subscription = widget.stream.listen(
      (data) {
        if (_isMounted) {
          setState(() {
            _data = data;
            _hasData = true;
            _hasError = false;
          });
        }
      },
      onError: (error) {
        if (_isMounted) {
          setState(() {
            _error = error;
            _hasError = true;
          });
        }
      },
    );
  }
  
  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
  
  @override
  Widget build(BuildContext context) {
    Widget child;
    
    if (_hasData) {
      child = widget.builder(context, _data as T);
    } else if (_hasError) {
      child = widget.errorBuilder != null
          ? widget.errorBuilder!(context, _error)
          : Center(
              child: Text(
                'Error: ${_error.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
            );
    } else {
      child = widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }
    
    return widget.useRepaintBoundary ? RepaintBoundary(child: child) : child;
  }
  
  @override
  void dispose() {
    // Mark as unmounted to prevent setState after dispose
    _isMounted = false;
    
    // Unsubscribe from stream
    _unsubscribe();
    
    // Clear references to prevent memory leaks
    _data = null;
    _error = null;
    super.dispose();
  }
}
