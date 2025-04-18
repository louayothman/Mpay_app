import 'package:flutter/material.dart';
import 'package:mpay_app/utils/error_handler.dart';

/// غلاف معالجة الأخطاء
///
/// يوفر غلافًا للويدجت مع معالجة الأخطاء والتعامل مع الحالات المختلفة
class ErrorHandlingWrapper extends StatelessWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final VoidCallback? onRetry;
  
  const ErrorHandlingWrapper({
    Key? key,
    required this.child,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
  
  /// إنشاء غلاف معالجة الأخطاء مع حالة التحميل
  static Widget withLoadingState({
    required Widget child,
    required bool isLoading,
    Widget? loadingWidget,
    String loadingMessage = 'جاري التحميل...',
  }) {
    if (isLoading) {
      return loadingWidget ?? _DefaultLoadingWidget(message: loadingMessage);
    }
    
    return child;
  }
  
  /// إنشاء غلاف معالجة الأخطاء مع حالة البيانات الفارغة
  static Widget withEmptyState({
    required Widget child,
    required bool isEmpty,
    Widget? emptyWidget,
    String emptyMessage = 'لا توجد بيانات',
    IconData emptyIcon = Icons.inbox,
  }) {
    if (isEmpty) {
      return emptyWidget ?? _DefaultEmptyWidget(
        message: emptyMessage,
        icon: emptyIcon,
      );
    }
    
    return child;
  }
  
  /// إنشاء غلاف معالجة الأخطاء مع حالة الخطأ
  static Widget withErrorState({
    required Widget child,
    required bool hasError,
    required String errorMessage,
    Widget? errorWidget,
    VoidCallback? onRetry,
  }) {
    if (hasError) {
      return errorWidget ?? _DefaultErrorWidget(
        message: errorMessage,
        onRetry: onRetry,
      );
    }
    
    return child;
  }
  
  /// إنشاء غلاف معالجة الأخطاء مع جميع الحالات
  static Widget withAllStates({
    required Widget child,
    required bool isLoading,
    required bool isEmpty,
    required bool hasError,
    required String errorMessage,
    Widget? loadingWidget,
    Widget? emptyWidget,
    Widget? errorWidget,
    VoidCallback? onRetry,
    String loadingMessage = 'جاري التحميل...',
    String emptyMessage = 'لا توجد بيانات',
    IconData emptyIcon = Icons.inbox,
  }) {
    if (isLoading) {
      return loadingWidget ?? _DefaultLoadingWidget(message: loadingMessage);
    }
    
    if (hasError) {
      return errorWidget ?? _DefaultErrorWidget(
        message: errorMessage,
        onRetry: onRetry,
      );
    }
    
    if (isEmpty) {
      return emptyWidget ?? _DefaultEmptyWidget(
        message: emptyMessage,
        icon: emptyIcon,
      );
    }
    
    return child;
  }
}

/// ويدجت التحميل الافتراضي
class _DefaultLoadingWidget extends StatelessWidget {
  final String message;
  
  const _DefaultLoadingWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// ويدجت البيانات الفارغة الافتراضي
class _DefaultEmptyWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  
  const _DefaultEmptyWidget({
    Key? key,
    required this.message,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// ويدجت الخطأ الافتراضي
class _DefaultErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const _DefaultErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// غلاف معالجة الأخطاء للحالة
///
/// يوفر غلافًا للحالة مع معالجة الأخطاء والتعامل مع الحالات المختلفة
class ErrorHandlingState<T extends StatefulWidget> extends State<T> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  /// تعيين حالة التحميل
  void setLoading(bool isLoading) {
    if (mounted) {
      setState(() {
        _isLoading = isLoading;
        if (isLoading) {
          _hasError = false;
          _errorMessage = '';
        }
      });
    }
  }
  
  /// تعيين حالة الخطأ
  void setError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }
  
  /// إعادة تعيين الحالة
  void resetState() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = false;
        _errorMessage = '';
      });
    }
  }
  
  /// معالجة الاستثناء
  void handleException(Exception exception, {BuildContext? context}) {
    final errorMessage = ErrorHandler.getCustomErrorMessage(exception);
    setError(errorMessage);
    
    if (context != null) {
      ErrorHandler.showErrorSnackBar(context, errorMessage);
    }
  }
  
  /// التحقق مما إذا كانت الحالة في وضع التحميل
  bool get isLoading => _isLoading;
  
  /// التحقق مما إذا كانت الحالة في وضع الخطأ
  bool get hasError => _hasError;
  
  /// الحصول على رسالة الخطأ
  String get errorMessage => _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    // يجب تجاوز هذه الدالة في الفئات الفرعية
    throw UnimplementedError('يجب تجاوز دالة build في الفئات الفرعية');
  }
}

/// غلاف معالجة الأخطاء للمستقبل
///
/// يوفر غلافًا للمستقبل مع معالجة الأخطاء والتعامل مع الحالات المختلفة
class FutureErrorHandler<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final bool Function(T data)? isEmpty;
  
  const FutureErrorHandler({
    Key? key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.isEmpty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ?? const _DefaultLoadingWidget(
            message: 'جاري التحميل...',
          );
        }
        
        if (snapshot.hasError) {
          final errorMessage = ErrorHandler.getCustomErrorMessage(
            snapshot.error is Exception 
                ? snapshot.error as Exception 
                : Exception(snapshot.error.toString())
          );
          
          return errorBuilder?.call(context, errorMessage) ?? _DefaultErrorWidget(
            message: errorMessage,
          );
        }
        
        if (!snapshot.hasData) {
          return emptyBuilder?.call(context) ?? const _DefaultEmptyWidget(
            message: 'لا توجد بيانات',
            icon: Icons.inbox,
          );
        }
        
        final data = snapshot.data as T;
        
        if (isEmpty != null && isEmpty!(data)) {
          return emptyBuilder?.call(context) ?? const _DefaultEmptyWidget(
            message: 'لا توجد بيانات',
            icon: Icons.inbox,
          );
        }
        
        return builder(context, data);
      },
    );
  }
}

/// غلاف معالجة الأخطاء للتدفق
///
/// يوفر غلافًا للتدفق مع معالجة الأخطاء والتعامل مع الحالات المختلفة
class StreamErrorHandler<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final bool Function(T data)? isEmpty;
  
  const StreamErrorHandler({
    Key? key,
    required this.stream,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.isEmpty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ?? const _DefaultLoadingWidget(
            message: 'جاري التحميل...',
          );
        }
        
        if (snapshot.hasError) {
          final errorMessage = ErrorHandler.getCustomErrorMessage(
            snapshot.error is Exception 
                ? snapshot.error as Exception 
                : Exception(snapshot.error.toString())
          );
          
          return errorBuilder?.call(context, errorMessage) ?? _DefaultErrorWidget(
            message: errorMessage,
          );
        }
        
        if (!snapshot.hasData) {
          return emptyBuilder?.call(context) ?? const _DefaultEmptyWidget(
            message: 'لا توجد بيانات',
            icon: Icons.inbox,
          );
        }
        
        final data = snapshot.data as T;
        
        if (isEmpty != null && isEmpty!(data)) {
          return emptyBuilder?.call(context) ?? const _DefaultEmptyWidget(
            message: 'لا توجد بيانات',
            icon: Icons.inbox,
          );
        }
        
        return builder(context, data);
      },
    );
  }
}
