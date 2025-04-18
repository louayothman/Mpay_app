import 'package:flutter/material.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'dart:async';
import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;

class BusinessAnalyticsManager {
  // Error handler
  final ErrorHandler _errorHandler = ErrorHandler();
  
  // Firebase service
  final FirebaseService _firebaseService = FirebaseService();
  
  // API service
  final ApiIntegrationService _apiService = ApiIntegrationService();
  
  // Connectivity utils
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  
  // Analytics data
  Map<String, dynamic> _transactionAnalytics = {};
  Map<String, dynamic> _userAnalytics = {};
  Map<String, dynamic> _financialAnalytics = {};
  Map<String, dynamic> _usageAnalytics = {};
  
  // Singleton pattern
  static final BusinessAnalyticsManager _instance = BusinessAnalyticsManager._internal();
  
  factory BusinessAnalyticsManager() {
    return _instance;
  }
  
  BusinessAnalyticsManager._internal();
  
  // Initialize the manager
  Future<void> initialize() async {
    try {
      // Ensure API service is initialized
      await _apiService.initialize();
      
      // Load cached analytics data
      await _loadCachedAnalyticsData();
      
      // Refresh analytics data if connected
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      if (hasConnection) {
        await refreshAllAnalytics();
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to initialize business analytics manager',
        ErrorSeverity.high,
      );
    }
  }
  
  // Load cached analytics data
  Future<void> _loadCachedAnalyticsData() async {
    try {
      final transactionData = await _firebaseService.getAppCachedData('transaction_analytics');
      if (transactionData != null) {
        _transactionAnalytics = transactionData;
      }
      
      final userData = await _firebaseService.getAppCachedData('user_analytics');
      if (userData != null) {
        _userAnalytics = userData;
      }
      
      final financialData = await _firebaseService.getAppCachedData('financial_analytics');
      if (financialData != null) {
        _financialAnalytics = financialData;
      }
      
      final usageData = await _firebaseService.getAppCachedData('usage_analytics');
      if (usageData != null) {
        _usageAnalytics = usageData;
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to load cached analytics data',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Save analytics data to cache
  Future<void> _saveAnalyticsDataToCache() async {
    try {
      await _firebaseService.setAppCachedData('transaction_analytics', _transactionAnalytics);
      await _firebaseService.setAppCachedData('user_analytics', _userAnalytics);
      await _firebaseService.setAppCachedData('financial_analytics', _financialAnalytics);
      await _firebaseService.setAppCachedData('usage_analytics', _usageAnalytics);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to save analytics data to cache',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Refresh all analytics
  Future<void> refreshAllAnalytics() async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      await Future.wait([
        refreshTransactionAnalytics(),
        refreshUserAnalytics(),
        refreshFinancialAnalytics(),
        refreshUsageAnalytics(),
      ]);
      
      // Save updated data to cache
      await _saveAnalyticsDataToCache();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh all analytics',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Refresh transaction analytics
  Future<void> refreshTransactionAnalytics() async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Get transaction analytics from API
      final response = await _apiService.get(
        '/analytics/transactions',
        useCache: true,
        cacheDuration: const Duration(hours: 1),
      );
      
      _transactionAnalytics = response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh transaction analytics',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Refresh user analytics
  Future<void> refreshUserAnalytics() async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Get user analytics from API
      final response = await _apiService.get(
        '/analytics/users',
        useCache: true,
        cacheDuration: const Duration(hours: 2),
      );
      
      _userAnalytics = response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh user analytics',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Refresh financial analytics
  Future<void> refreshFinancialAnalytics() async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Get financial analytics from API
      final response = await _apiService.get(
        '/analytics/financial',
        useCache: true,
        cacheDuration: const Duration(hours: 3),
      );
      
      _financialAnalytics = response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh financial analytics',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Refresh usage analytics
  Future<void> refreshUsageAnalytics() async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }
      
      // Get usage analytics from API
      final response = await _apiService.get(
        '/analytics/usage',
        useCache: true,
        cacheDuration: const Duration(hours: 6),
      );
      
      _usageAnalytics = response;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh usage analytics',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Get transaction analytics
  Map<String, dynamic> getTransactionAnalytics() {
    return Map.from(_transactionAnalytics);
  }
  
  // Get user analytics
  Map<String, dynamic> getUserAnalytics() {
    return Map.from(_userAnalytics);
  }
  
  // Get financial analytics
  Map<String, dynamic> getFinancialAnalytics() {
    return Map.from(_financialAnalytics);
  }
  
  // Get usage analytics
  Map<String, dynamic> getUsageAnalytics() {
    return Map.from(_usageAnalytics);
  }
  
  // Get transaction count by type
  Map<String, int> getTransactionCountByType() {
    try {
      final transactionsByType = _transactionAnalytics['transactionsByType'];
      
      if (transactionsByType == null) {
        return {};
      }
      
      return Map<String, int>.from(transactionsByType);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get transaction count by type',
        ErrorSeverity.low,
      );
      
      return {};
    }
  }
  
  // Get transaction volume by currency
  Map<String, double> getTransactionVolumeByCurrency() {
    try {
      final volumeByCurrency = _transactionAnalytics['volumeByCurrency'];
      
      if (volumeByCurrency == null) {
        return {};
      }
      
      return Map<String, double>.from(volumeByCurrency);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get transaction volume by currency',
        ErrorSeverity.low,
      );
      
      return {};
    }
  }
  
  // Get transaction trend data
  List<TransactionTrendData> getTransactionTrendData() {
    try {
      final trendData = _transactionAnalytics['trendData'];
      
      if (trendData == null || !(trendData is List)) {
        return [];
      }
      
      return (trendData as List).map((item) => TransactionTrendData.fromJson(item)).toList();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get transaction trend data',
        ErrorSeverity.low,
      );
      
      return [];
    }
  }
  
  // Get user growth data
  List<UserGrowthData> getUserGrowthData() {
    try {
      final growthData = _userAnalytics['growthData'];
      
      if (growthData == null || !(growthData is List)) {
        return [];
      }
      
      return (growthData as List).map((item) => UserGrowthData.fromJson(item)).toList();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get user growth data',
        ErrorSeverity.low,
      );
      
      return [];
    }
  }
  
  // Get user demographics
  Map<String, dynamic> getUserDemographics() {
    try {
      final demographics = _userAnalytics['demographics'];
      
      if (demographics == null) {
        return {};
      }
      
      return Map<String, dynamic>.from(demographics);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get user demographics',
        ErrorSeverity.low,
      );
      
      return {};
    }
  }
  
  // Get user retention data
  Map<String, double> getUserRetentionData() {
    try {
      final retentionData = _userAnalytics['retention'];
      
      if (retentionData == null) {
        return {};
      }
      
      return Map<String, double>.from(retentionData);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get user retention data',
        ErrorSeverity.low,
      );
      
      return {};
    }
  }
  
  // Get revenue data
  List<RevenueData> getRevenueData() {
    try {
      final revenueData = _financialAnalytics['revenueData'];
      
      if (revenueData == null || !(revenueData is List)) {
        return [];
      }
      
      return (revenueData as List).map((item) => RevenueData.fromJson(item)).toList();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get revenue data',
        ErrorSeverity.low,
      );
      
      return [];
    }
  }
  
  // Get profit and loss data
  Map<String, double> getProfitAndLossData() {
    try {
      final plData = _financialAnalytics['profitAndLoss'];
      
      if (plData == null) {
        return {};
      }
      
      return Map<String, double>.from(plData);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get profit and loss data',
        ErrorSeverity.low,
      );
      
      return {};
    }
  }
  
  // Get fee revenue by type
  Map<String, double> getFeeRevenueByType() {
    try {
      final feeRevenue = _financialAnalytics['feeRevenueByType'];
      
      if (feeRevenue == null) {
        return {};
      }
      
      return Map<String, double>.from(feeRevenue);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get fee revenue by type',
        ErrorSeverity.low,
      );
      
      return {};
    }
  }
  
  // Get app usage statistics
  Map<String, dynamic> getAppUsageStatistics() {
    try {
      final usageStats = _usageAnalytics['usageStatistics'];
      
      if (usageStats == null) {
        return {};
      }
      
      return Map<String, dynamic>.from(usageStats);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get app usage statistics',
        ErrorSeverity.low,
      );
      
      return {};
    }
  }
  
  // Get feature usage data
  Map<String, int> getFeatureUsageData() {
    try {
      final featureUsage = _usageAnalytics['featureUsage'];
      
      if (featureUsage == null) {
        return {};
      }
      
      return Map<String, int>.from(featureUsage);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get feature usage data',
        ErrorSeverity.low,
      );
      
      return {};
    }
  }
  
  // Get session data
  List<SessionData> getSessionData() {
    try {
      final sessionData = _usageAnalytics['sessionData'];
      
      if (sessionData == null || !(sessionData is List)) {
        return [];
      }
      
      return (sessionData as List).map((item) => SessionData.fromJson(item)).toList();
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get session data',
        ErrorSeverity.low,
      );
      
      return [];
    }
  }
  
  // Get transaction count chart
  charts.Series<TransactionTrendData, DateTime> getTransactionCountChart() {
    final data = getTransactionTrendData();
    
    return charts.Series<TransactionTrendData, DateTime>(
      id: 'Transactions',
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (TransactionTrendData data, _) => data.date,
      measureFn: (TransactionTrendData data, _) => data.count,
      data: data,
    );
  }
  
  // Get transaction volume chart
  charts.Series<TransactionTrendData, DateTime> getTransactionVolumeChart() {
    final data = getTransactionTrendData();
    
    return charts.Series<TransactionTrendData, DateTime>(
      id: 'Volume',
      colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      domainFn: (TransactionTrendData data, _) => data.date,
      measureFn: (TransactionTrendData data, _) => data.volume,
      data: data,
    );
  }
  
  // Get user growth chart
  charts.Series<UserGrowthData, DateTime> getUserGrowthChart() {
    final data = getUserGrowthData();
    
    return charts.Series<UserGrowthData, DateTime>(
      id: 'Users',
      colorFn: (_, __) => charts.MaterialPalette.purple.shadeDefault,
      domainFn: (UserGrowthData data, _) => data.date,
      measureFn: (UserGrowthData data, _) => data.userCount,
      data: data,
    );
  }
  
  // Get revenue chart
  charts.Series<RevenueData, DateTime> getRevenueChart() {
    final data = getRevenueData();
    
    return charts.Series<RevenueData, DateTime>(
      id: 'Revenue',
      colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      domainFn: (RevenueData data, _) => data.date,
      measureFn: (RevenueData data, _) => data.amount,
      data: data,
    );
  }
  
  // Get session duration chart
  charts.Series<SessionData, DateTime> getSessionDurationChart() {
    final data = getSessionData();
    
    return charts.Series<SessionData, DateTime>(
      id: 'Session Duration',
      colorFn: (_, __) => charts.MaterialPalette.cyan.shadeDefault,
      domainFn: (SessionData data, _) => data.date,
      measureFn: (SessionData data, _) => data.averageDuration.inMinutes,
      data: data,
    );
  }
  
  // Get transaction type pie chart
  List<charts.Series<PieChartData, String>> getTransactionTypePieChart() {
    final transactionsByType = getTransactionCountByType();
    
    final data = transactionsByType.entries
        .map((entry) => PieChartData(entry.key, entry.value))
        .toList();
    
    return [
      charts.Series<PieChartData, String>(
        id: 'Transaction Types',
        domainFn: (PieChartData data, _) => data.category,
        measureFn: (PieChartData data, _) => data.value,
        colorFn: (PieChartData data, _) {
          switch (data.category) {
            case 'deposit':
              return charts.MaterialPalette.green.shadeDefault;
            case 'withdrawal':
              return charts.MaterialPalette.red.shadeDefault;
            case 'transfer':
              return charts.MaterialPalette.blue.shadeDefault;
            case 'payment':
              return charts.MaterialPalette.purple.shadeDefault;
            default:
              return charts.MaterialPalette.gray.shadeDefault;
          }
        },
        data: data,
        labelAccessorFn: (PieChartData row, _) => '${row.category}: ${row.value}',
      )
    ];
  }
  
  // Get currency volume pie chart
  List<charts.Series<PieChartData, String>> getCurrencyVolumePieChart() {
    final volumeByCurrency = getTransactionVolumeByCurrency();
    
    final data = volumeByCurrency.entries
        .map((entry) => PieChartData(entry.key, entry.value))
        .toList();
    
    return [
      charts.Series<PieChartData, String>(
        id: 'Currency Volumes',
        domainFn: (PieChartData data, _) => data.category,
        measureFn: (PieChartData data, _) => data.value,
        colorFn: (PieChartData data, _) {
          switch (data.category) {
            case 'USD':
              return charts.MaterialPalette.green.shadeDefault;
            case 'EUR':
              return charts.MaterialPalette.blue.shadeDefault;
            case 'GBP':
              return charts.MaterialPalette.purple.shadeDefault;
            case 'BTC':
              return charts.MaterialPalette.yellow.shadeDefault;
            case 'ETH':
              return charts.MaterialPalette.cyan.shadeDefault;
            default:
              return charts.MaterialPalette.gray.shadeDefault;
          }
        },
        data: data,
        labelAccessorFn: (PieChartData row, _) => '${row.category}: ${row.value.toStringAsFixed(2)}',
      )
    ];
  }
  
  // Get feature usage pie chart
  List<charts.Series<PieChartData, String>> getFeatureUsagePieChart() {
    final featureUsage = getFeatureUsageData();
    
    final data = featureUsage.entries
        .map((entry) => PieChartData(entry.key, entry.value.toDouble()))
        .toList();
    
    return [
      charts.Series<PieChartData, String>(
        id: 'Feature Usage',
        domainFn: (PieChartData data, _) => data.category,
        measureFn: (PieChartData data, _) => data.value,
        colorFn: (PieChartData data, _) => charts.MaterialPalette.blue.shadeDefault,
        data: data,
        labelAccessorFn: (PieChartData row, _) => '${row.category}: ${row.value.toInt()}',
      )
    ];
  }
  
  // Generate business analytics report
  String generateBusinessAnalyticsReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('# Business Analytics Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln();
    
    buffer.writeln('## Transaction Analytics');
    
    // Transaction count by type
    final transactionsByType = getTransactionCountByType();
    buffer.writeln('### Transaction Count by Type');
    if (transactionsByType.isEmpty) {
      buffer.writeln('No transaction data available.');
    } else {
      for (final entry in transactionsByType.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
    }
    buffer.writeln();
    
    // Transaction volume by currency
    final volumeByCurrency = getTransactionVolumeByCurrency();
    buffer.writeln('### Transaction Volume by Currency');
    if (volumeByCurrency.isEmpty) {
      buffer.writeln('No volume data available.');
    } else {
      for (final entry in volumeByCurrency.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value.toStringAsFixed(2)}');
      }
    }
    buffer.writeln();
    
    // Transaction trend
    final trendData = getTransactionTrendData();
    buffer.writeln('### Transaction Trend (Last 7 Days)');
    if (trendData.isEmpty) {
      buffer.writeln('No trend data available.');
    } else {
      for (final data in trendData.take(7)) {
        buffer.writeln('- ${data.date.toString().substring(0, 10)}: Count: ${data.count}, Volume: ${data.volume.toStringAsFixed(2)}');
      }
    }
    buffer.writeln();
    
    buffer.writeln('## User Analytics');
    
    // User growth
    final growthData = getUserGrowthData();
    buffer.writeln('### User Growth (Last 6 Months)');
    if (growthData.isEmpty) {
      buffer.writeln('No user growth data available.');
    } else {
      for (final data in growthData.take(6)) {
        buffer.writeln('- ${data.date.toString().substring(0, 7)}: ${data.userCount} users (${data.growthRate.toStringAsFixed(2)}% growth)');
      }
    }
    buffer.writeln();
    
    // User demographics
    final demographics = getUserDemographics();
    buffer.writeln('### User Demographics');
    if (demographics.isEmpty) {
      buffer.writeln('No demographics data available.');
    } else {
      if (demographics['ageGroups'] != null) {
        buffer.writeln('#### Age Groups');
        final ageGroups = Map<String, dynamic>.from(demographics['ageGroups']);
        for (final entry in ageGroups.entries) {
          buffer.writeln('- ${entry.key}: ${entry.value}%');
        }
        buffer.writeln();
      }
      
      if (demographics['countries'] != null) {
        buffer.writeln('#### Countries');
        final countries = Map<String, dynamic>.from(demographics['countries']);
        for (final entry in countries.entries) {
          buffer.writeln('- ${entry.key}: ${entry.value}%');
        }
        buffer.writeln();
      }
    }
    
    // User retention
    final retentionData = getUserRetentionData();
    buffer.writeln('### User Retention');
    if (retentionData.isEmpty) {
      buffer.writeln('No retention data available.');
    } else {
      for (final entry in retentionData.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value.toStringAsFixed(2)}%');
      }
    }
    buffer.writeln();
    
    buffer.writeln('## Financial Analytics');
    
    // Revenue data
    final revenueData = getRevenueData();
    buffer.writeln('### Revenue (Last 6 Months)');
    if (revenueData.isEmpty) {
      buffer.writeln('No revenue data available.');
    } else {
      for (final data in revenueData.take(6)) {
        buffer.writeln('- ${data.date.toString().substring(0, 7)}: ${data.amount.toStringAsFixed(2)} ${data.currency}');
      }
    }
    buffer.writeln();
    
    // Profit and loss
    final plData = getProfitAndLossData();
    buffer.writeln('### Profit and Loss');
    if (plData.isEmpty) {
      buffer.writeln('No profit and loss data available.');
    } else {
      for (final entry in plData.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value.toStringAsFixed(2)}');
      }
    }
    buffer.writeln();
    
    // Fee revenue by type
    final feeRevenue = getFeeRevenueByType();
    buffer.writeln('### Fee Revenue by Type');
    if (feeRevenue.isEmpty) {
      buffer.writeln('No fee revenue data available.');
    } else {
      for (final entry in feeRevenue.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value.toStringAsFixed(2)}');
      }
    }
    buffer.writeln();
    
    buffer.writeln('## Usage Analytics');
    
    // App usage statistics
    final usageStats = getAppUsageStatistics();
    buffer.writeln('### App Usage Statistics');
    if (usageStats.isEmpty) {
      buffer.writeln('No usage statistics available.');
    } else {
      if (usageStats['dailyActiveUsers'] != null) {
        buffer.writeln('- Daily Active Users: ${usageStats['dailyActiveUsers']}');
      }
      if (usageStats['monthlyActiveUsers'] != null) {
        buffer.writeln('- Monthly Active Users: ${usageStats['monthlyActiveUsers']}');
      }
      if (usageStats['averageSessionDuration'] != null) {
        buffer.writeln('- Average Session Duration: ${usageStats['averageSessionDuration']} minutes');
      }
      if (usageStats['sessionsPerUser'] != null) {
        buffer.writeln('- Sessions Per User: ${usageStats['sessionsPerUser']}');
      }
    }
    buffer.writeln();
    
    // Feature usage
    final featureUsage = getFeatureUsageData();
    buffer.writeln('### Feature Usage');
    if (featureUsage.isEmpty) {
      buffer.writeln('No feature usage data available.');
    } else {
      for (final entry in featureUsage.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value} uses');
      }
    }
    buffer.writeln();
    
    // Session data
    final sessionData = getSessionData();
    buffer.writeln('### Session Data (Last 7 Days)');
    if (sessionData.isEmpty) {
      buffer.writeln('No session data available.');
    } else {
      for (final data in sessionData.take(7)) {
        buffer.writeln('- ${data.date.toString().substring(0, 10)}: ${data.sessionCount} sessions, ${data.averageDuration.inMinutes} minutes average');
      }
    }
    buffer.writeln();
    
    return buffer.toString();
  }
  
  // Save business analytics report to file
  Future<void> saveBusinessAnalyticsReport(String filePath) async {
    try {
      final report = generateBusinessAnalyticsReport();
      final file = File(filePath);
      await file.writeAsString(report);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to save business analytics report',
        ErrorSeverity.medium,
      );
    }
  }
}

// Transaction trend data class
class TransactionTrendData {
  final DateTime date;
  final int count;
  final double volume;
  
  TransactionTrendData({
    required this.date,
    required this.count,
    required this.volume,
  });
  
  factory TransactionTrendData.fromJson(Map<String, dynamic> json) {
    return TransactionTrendData(
      date: DateTime.parse(json['date']),
      count: json['count'],
      volume: json['volume'].toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'count': count,
      'volume': volume,
    };
  }
}

// User growth data class
class UserGrowthData {
  final DateTime date;
  final int userCount;
  final double growthRate;
  
  UserGrowthData({
    required this.date,
    required this.userCount,
    required this.growthRate,
  });
  
  factory UserGrowthData.fromJson(Map<String, dynamic> json) {
    return UserGrowthData(
      date: DateTime.parse(json['date']),
      userCount: json['userCount'],
      growthRate: json['growthRate'].toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'userCount': userCount,
      'growthRate': growthRate,
    };
  }
}

// Revenue data class
class RevenueData {
  final DateTime date;
  final double amount;
  final String currency;
  
  RevenueData({
    required this.date,
    required this.amount,
    required this.currency,
  });
  
  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      date: DateTime.parse(json['date']),
      amount: json['amount'].toDouble(),
      currency: json['currency'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'currency': currency,
    };
  }
}

// Session data class
class SessionData {
  final DateTime date;
  final int sessionCount;
  final Duration averageDuration;
  
  SessionData({
    required this.date,
    required this.sessionCount,
    required this.averageDuration,
  });
  
  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      date: DateTime.parse(json['date']),
      sessionCount: json['sessionCount'],
      averageDuration: Duration(minutes: json['averageDurationMinutes']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'sessionCount': sessionCount,
      'averageDurationMinutes': averageDuration.inMinutes,
    };
  }
}

// Pie chart data class
class PieChartData {
  final String category;
  final double value;
  
  PieChartData(this.category, this.value);
}
