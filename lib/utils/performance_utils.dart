import 'package:flutter/foundation.dart';

/// مساعد لتنفيذ العمليات الثقيلة في خيوط منفصلة
class ComputeHelper {
  /// تنفيذ عملية ثقيلة في خيط منفصل باستخدام compute
  ///
  /// [function]: الدالة التي سيتم تنفيذها في خيط منفصل
  /// [message]: البيانات التي سيتم تمريرها إلى الدالة
  static Future<R> runInBackground<M, R>(
    ComputeCallback<M, R> function,
    M message,
  ) async {
    return compute(function, message);
  }

  /// تنفيذ عملية معالجة قائمة في خيط منفصل
  ///
  /// [function]: الدالة التي سيتم تنفيذها على كل عنصر
  /// [items]: قائمة العناصر التي سيتم معالجتها
  static Future<List<R>> processListInBackground<T, R>(
    R Function(T) function,
    List<T> items,
  ) async {
    return compute(_processListHelper<T, R>, _ProcessListParams(function, items));
  }

  /// دالة مساعدة لمعالجة القوائم
  static List<R> _processListHelper<T, R>(_ProcessListParams<T, R> params) {
    return params.items.map(params.function).toList();
  }

  /// تنفيذ عملية فلترة قائمة في خيط منفصل
  ///
  /// [predicate]: دالة الفلترة
  /// [items]: قائمة العناصر التي سيتم فلترتها
  static Future<List<T>> filterListInBackground<T>(
    bool Function(T) predicate,
    List<T> items,
  ) async {
    return compute(_filterListHelper<T>, _FilterListParams(predicate, items));
  }

  /// دالة مساعدة لفلترة القوائم
  static List<T> _filterListHelper<T>(_FilterListParams<T> params) {
    return params.items.where(params.predicate).toList();
  }

  /// تنفيذ عملية فرز قائمة في خيط منفصل
  ///
  /// [compare]: دالة المقارنة للفرز
  /// [items]: قائمة العناصر التي سيتم فرزها
  static Future<List<T>> sortListInBackground<T>(
    int Function(T, T) compare,
    List<T> items,
  ) async {
    return compute(_sortListHelper<T>, _SortListParams(compare, items));
  }

  /// دالة مساعدة لفرز القوائم
  static List<T> _sortListHelper<T>(_SortListParams<T> params) {
    final List<T> result = List.from(params.items);
    result.sort(params.compare);
    return result;
  }

  /// تنفيذ عملية تحويل بيانات JSON في خيط منفصل
  ///
  /// [converter]: دالة التحويل
  /// [jsonData]: بيانات JSON التي سيتم تحويلها
  static Future<R> parseJsonInBackground<R>(
    R Function(Map<String, dynamic>) converter,
    Map<String, dynamic> jsonData,
  ) async {
    return compute(_parseJsonHelper<R>, _JsonParseParams(converter, jsonData));
  }

  /// دالة مساعدة لتحويل بيانات JSON
  static R _parseJsonHelper<R>(_JsonParseParams<R> params) {
    return params.converter(params.jsonData);
  }

  /// تنفيذ عملية تحويل قائمة من بيانات JSON في خيط منفصل
  ///
  /// [converter]: دالة التحويل
  /// [jsonList]: قائمة بيانات JSON التي سيتم تحويلها
  static Future<List<R>> parseJsonListInBackground<R>(
    R Function(Map<String, dynamic>) converter,
    List<dynamic> jsonList,
  ) async {
    return compute(
      _parseJsonListHelper<R>,
      _JsonListParseParams(converter, jsonList),
    );
  }

  /// دالة مساعدة لتحويل قائمة من بيانات JSON
  static List<R> _parseJsonListHelper<R>(_JsonListParseParams<R> params) {
    return params.jsonList
        .map((item) => params.converter(item as Map<String, dynamic>))
        .toList();
  }
}

/// فئة مساعدة لتمرير معلمات معالجة القوائم
class _ProcessListParams<T, R> {
  final R Function(T) function;
  final List<T> items;

  _ProcessListParams(this.function, this.items);
}

/// فئة مساعدة لتمرير معلمات فلترة القوائم
class _FilterListParams<T> {
  final bool Function(T) predicate;
  final List<T> items;

  _FilterListParams(this.predicate, this.items);
}

/// فئة مساعدة لتمرير معلمات فرز القوائم
class _SortListParams<T> {
  final int Function(T, T) compare;
  final List<T> items;

  _SortListParams(this.compare, this.items);
}

/// فئة مساعدة لتمرير معلمات تحويل بيانات JSON
class _JsonParseParams<R> {
  final R Function(Map<String, dynamic>) converter;
  final Map<String, dynamic> jsonData;

  _JsonParseParams(this.converter, this.jsonData);
}

/// فئة مساعدة لتمرير معلمات تحويل قائمة من بيانات JSON
class _JsonListParseParams<R> {
  final R Function(Map<String, dynamic>) converter;
  final List<dynamic> jsonList;

  _JsonListParseParams(this.converter, this.jsonList);
}
