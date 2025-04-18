import 'package:flutter/material.dart';
import 'package:mpay_app/services/api_integration_service.dart';
import 'package:mpay_app/services/payment_gateway_service.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  final ApiIntegrationService _apiService = ApiIntegrationService();
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  final ErrorHandler _errorHandler = ErrorHandler();
  final SecurityUtils _securityUtils = SecurityUtils();
  
  // Stream controllers
  final StreamController<Notification> _notificationStreamController = StreamController<Notification>.broadcast();
  
  // Notification settings
  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _transactionNotificationsEnabled = true;
  bool _securityNotificationsEnabled = true;
  bool _marketingNotificationsEnabled = false;
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  // Initialize the service
  Future<void> initialize(String userId) async {
    if (_isInitialized) {
      return;
    }
    
    try {
      // Ensure API service is initialized
      await _apiService.initialize();
      
      // Initialize Firebase messaging
      await _firebaseService.initializeMessaging();
      
      // Register device token
      final deviceToken = await _firebaseService.getMessagingToken();
      if (deviceToken != null) {
        await registerDeviceToken(userId, deviceToken);
      }
      
      // Load notification settings
      await loadNotificationSettings(userId);
      
      // Set up notification listeners
      _setupNotificationListeners(userId);
      
      _isInitialized = true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to initialize notification service',
        ErrorSeverity.high,
      );
    }
  }
  
  // Register device token
  Future<void> registerDeviceToken(String userId, String deviceToken) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Save token locally for later registration
        await _firebaseService.saveUserDeviceToken(userId, deviceToken);
        return;
      }
      
      // Register token with API
      await _apiService.post(
        '/notifications/register-device',
        body: {
          'userId': userId,
          'deviceToken': deviceToken,
          'platform': _getPlatform(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      // Save token locally
      await _firebaseService.saveUserDeviceToken(userId, deviceToken);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to register device token',
        ErrorSeverity.medium,
      );
      
      // Save token locally for later registration
      await _firebaseService.saveUserDeviceToken(userId, deviceToken);
    }
  }
  
  // Unregister device token
  Future<void> unregisterDeviceToken(String userId) async {
    try {
      final deviceToken = await _firebaseService.getMessagingToken();
      
      if (deviceToken == null) {
        return;
      }
      
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Mark token for removal when connection is available
        await _firebaseService.markDeviceTokenForRemoval(userId, deviceToken);
        return;
      }
      
      // Unregister token with API
      await _apiService.post(
        '/notifications/unregister-device',
        body: {
          'userId': userId,
          'deviceToken': deviceToken,
        },
      );
      
      // Remove token locally
      await _firebaseService.removeUserDeviceToken(userId, deviceToken);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to unregister device token',
        ErrorSeverity.low,
      );
    }
  }
  
  // Load notification settings
  Future<void> loadNotificationSettings(String userId) async {
    try {
      final settings = await _firebaseService.getUserNotificationSettings(userId);
      
      if (settings != null) {
        _notificationsEnabled = settings['enabled'] ?? true;
        _soundEnabled = settings['sound'] ?? true;
        _vibrationEnabled = settings['vibration'] ?? true;
        _transactionNotificationsEnabled = settings['transactionNotifications'] ?? true;
        _securityNotificationsEnabled = settings['securityNotifications'] ?? true;
        _marketingNotificationsEnabled = settings['marketingNotifications'] ?? false;
      }
      
      // Sync settings with server if connected
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (hasConnection) {
        await _apiService.post(
          '/notifications/settings',
          body: {
            'userId': userId,
            'settings': {
              'enabled': _notificationsEnabled,
              'sound': _soundEnabled,
              'vibration': _vibrationEnabled,
              'transactionNotifications': _transactionNotificationsEnabled,
              'securityNotifications': _securityNotificationsEnabled,
              'marketingNotifications': _marketingNotificationsEnabled,
            },
          },
        );
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to load notification settings',
        ErrorSeverity.low,
      );
    }
  }
  
  // Save notification settings
  Future<void> saveNotificationSettings(
    String userId, {
    bool? enabled,
    bool? sound,
    bool? vibration,
    bool? transactionNotifications,
    bool? securityNotifications,
    bool? marketingNotifications,
  }) async {
    try {
      // Update local settings
      if (enabled != null) {
        _notificationsEnabled = enabled;
      }
      
      if (sound != null) {
        _soundEnabled = sound;
      }
      
      if (vibration != null) {
        _vibrationEnabled = vibration;
      }
      
      if (transactionNotifications != null) {
        _transactionNotificationsEnabled = transactionNotifications;
      }
      
      if (securityNotifications != null) {
        _securityNotificationsEnabled = securityNotifications;
      }
      
      if (marketingNotifications != null) {
        _marketingNotificationsEnabled = marketingNotifications;
      }
      
      // Save settings locally
      await _firebaseService.saveUserNotificationSettings(
        userId,
        {
          'enabled': _notificationsEnabled,
          'sound': _soundEnabled,
          'vibration': _vibrationEnabled,
          'transactionNotifications': _transactionNotificationsEnabled,
          'securityNotifications': _securityNotificationsEnabled,
          'marketingNotifications': _marketingNotificationsEnabled,
        },
      );
      
      // Sync settings with server if connected
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (hasConnection) {
        await _apiService.post(
          '/notifications/settings',
          body: {
            'userId': userId,
            'settings': {
              'enabled': _notificationsEnabled,
              'sound': _soundEnabled,
              'vibration': _vibrationEnabled,
              'transactionNotifications': _transactionNotificationsEnabled,
              'securityNotifications': _securityNotificationsEnabled,
              'marketingNotifications': _marketingNotificationsEnabled,
            },
          },
        );
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to save notification settings',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Set up notification listeners
  void _setupNotificationListeners(String userId) {
    // Listen for Firebase messages
    _firebaseService.onMessageReceived.listen((message) {
      _handleIncomingNotification(userId, message);
    });
    
    // Listen for local notifications
    _firebaseService.onLocalNotificationReceived.listen((notification) {
      _notificationStreamController.add(notification);
    });
  }
  
  // Handle incoming notification
  void _handleIncomingNotification(String userId, Map<String, dynamic> message) {
    try {
      // Parse notification data
      final notification = Notification.fromFirebaseMessage(message);
      
      // Check if notification is enabled
      if (!_notificationsEnabled) {
        return;
      }
      
      // Check notification type
      if (notification.type == NotificationType.transaction && !_transactionNotificationsEnabled) {
        return;
      }
      
      if (notification.type == NotificationType.security && !_securityNotificationsEnabled) {
        return;
      }
      
      if (notification.type == NotificationType.marketing && !_marketingNotificationsEnabled) {
        return;
      }
      
      // Show notification
      _firebaseService.showLocalNotification(
        notification.id,
        notification.title,
        notification.body,
        notification.data,
        sound: _soundEnabled,
        vibration: _vibrationEnabled,
      );
      
      // Add to stream
      _notificationStreamController.add(notification);
      
      // Save notification to history
      _saveNotificationToHistory(userId, notification);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to handle incoming notification',
        ErrorSeverity.low,
      );
    }
  }
  
  // Save notification to history
  Future<void> _saveNotificationToHistory(String userId, Notification notification) async {
    try {
      await _firebaseService.saveUserNotification(
        userId,
        notification.toJson(),
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to save notification to history',
        ErrorSeverity.low,
      );
    }
  }
  
  // Get notification history
  Future<List<Notification>> getNotificationHistory(
    String userId, {
    NotificationType? type,
    bool? read,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Return cached notifications if available
        final cachedNotifications = await _getCachedNotifications(userId);
        return _filterNotifications(
          cachedNotifications,
          type,
          read,
          startDate,
          endDate,
          limit,
          offset,
        );
      }
      
      // Prepare query parameters
      final queryParams = <String, dynamic>{
        'userId': userId,
        'limit': limit,
        'offset': offset,
      };
      
      if (type != null) {
        queryParams['type'] = type.toString().split('.').last;
      }
      
      if (read != null) {
        queryParams['read'] = read;
      }
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      // Get notifications from API
      final response = await _apiService.get(
        '/notifications/history',
        queryParams: queryParams,
        useCache: true,
        cacheDuration: const Duration(minutes: 15),
      );
      
      final List<Notification> notifications = [];
      
      if (response['notifications'] != null && response['notifications'] is List) {
        for (final notification in response['notifications']) {
          notifications.add(Notification.fromJson(notification));
        }
      }
      
      // Cache notifications
      await _cacheNotifications(userId, notifications);
      
      return notifications;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get notification history',
        ErrorSeverity.medium,
      );
      
      // Try to get cached notifications as fallback
      final cachedNotifications = await _getCachedNotifications(userId);
      return _filterNotifications(
        cachedNotifications,
        type,
        read,
        startDate,
        endDate,
        limit,
        offset,
      );
    }
  }
  
  // Get cached notifications
  Future<List<Notification>> _getCachedNotifications(String userId) async {
    try {
      final cachedData = await _firebaseService.getUserNotifications(userId);
      
      if (cachedData != null && cachedData.isNotEmpty) {
        final List<Notification> notifications = [];
        
        for (final notification in cachedData) {
          notifications.add(Notification.fromJson(notification));
        }
        
        return notifications;
      }
    } catch (e) {
      // Ignore cache errors
    }
    
    return [];
  }
  
  // Cache notifications
  Future<void> _cacheNotifications(String userId, List<Notification> notifications) async {
    try {
      final notificationsJson = notifications.map((notification) => notification.toJson()).toList();
      
      await _firebaseService.setUserCachedData(
        userId,
        'notifications',
        {'notifications': notificationsJson},
      );
    } catch (e) {
      // Ignore cache errors
    }
  }
  
  // Filter notifications
  List<Notification> _filterNotifications(
    List<Notification> notifications,
    NotificationType? type,
    bool? read,
    DateTime? startDate,
    DateTime? endDate,
    int limit,
    int offset,
  ) {
    List<Notification> filteredNotifications = List.from(notifications);
    
    if (type != null) {
      filteredNotifications = filteredNotifications.where((n) => n.type == type).toList();
    }
    
    if (read != null) {
      filteredNotifications = filteredNotifications.where((n) => n.read == read).toList();
    }
    
    if (startDate != null) {
      filteredNotifications = filteredNotifications.where((n) => n.timestamp.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      filteredNotifications = filteredNotifications.where((n) => n.timestamp.isBefore(endDate)).toList();
    }
    
    // Sort by timestamp (newest first)
    filteredNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Apply pagination
    if (offset < filteredNotifications.length) {
      final endIndex = offset + limit < filteredNotifications.length
          ? offset + limit
          : filteredNotifications.length;
      
      return filteredNotifications.sublist(offset, endIndex);
    }
    
    return [];
  }
  
  // Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      // Update locally
      await _firebaseService.updateUserNotification(
        userId,
        notificationId,
        {'read': true},
      );
      
      // Update on server if connected
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (hasConnection) {
        await _apiService.post(
          '/notifications/mark-read',
          body: {
            'userId': userId,
            'notificationId': notificationId,
          },
        );
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to mark notification as read',
        ErrorSeverity.low,
      );
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      // Update locally
      await _firebaseService.markAllUserNotificationsAsRead(userId);
      
      // Update on server if connected
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (hasConnection) {
        await _apiService.post(
          '/notifications/mark-all-read',
          body: {
            'userId': userId,
          },
        );
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to mark all notifications as read',
        ErrorSeverity.low,
      );
    }
  }
  
  // Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      // Delete locally
      await _firebaseService.deleteUserNotification(
        userId,
        notificationId,
      );
      
      // Delete on server if connected
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (hasConnection) {
        await _apiService.delete(
          '/notifications/$notificationId',
          body: {
            'userId': userId,
          },
        );
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to delete notification',
        ErrorSeverity.low,
      );
    }
  }
  
  // Delete all notifications
  Future<void> deleteAllNotifications(String userId) async {
    try {
      // Delete locally
      await _firebaseService.deleteAllUserNotifications(userId);
      
      // Delete on server if connected
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (hasConnection) {
        await _apiService.delete(
          '/notifications',
          body: {
            'userId': userId,
          },
        );
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to delete all notifications',
        ErrorSeverity.low,
      );
    }
  }
  
  // Send notification
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Create local notification
        final notification = Notification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          body: body,
          type: type,
          timestamp: DateTime.now(),
          read: false,
          data: data,
        );
        
        // Show notification
        _firebaseService.showLocalNotification(
          notification.id,
          notification.title,
          notification.body,
          notification.data,
          sound: _soundEnabled,
          vibration: _vibrationEnabled,
        );
        
        // Add to stream
        _notificationStreamController.add(notification);
        
        // Save notification to history
        _saveNotificationToHistory(userId, notification);
        
        return;
      }
      
      // Send notification via API
      await _apiService.post(
        '/notifications/send',
        body: {
          'userId': userId,
          'title': title,
          'body': body,
          'type': type.toString().split('.').last,
          'data': data,
        },
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to send notification',
        ErrorSeverity.medium,
      );
      
      // Create local notification as fallback
      final notification = Notification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        read: false,
        data: data,
      );
      
      // Show notification
      _firebaseService.showLocalNotification(
        notification.id,
        notification.title,
        notification.body,
        notification.data,
        sound: _soundEnabled,
        vibration: _vibrationEnabled,
      );
      
      // Add to stream
      _notificationStreamController.add(notification);
      
      // Save notification to history
      _saveNotificationToHistory(userId, notification);
    }
  }
  
  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final hasConnection = await _connectivityUtils.checkInternetConnection();
      
      if (!hasConnection) {
        // Get count from local cache
        final notifications = await _getCachedNotifications(userId);
        return notifications.where((n) => !n.read).length;
      }
      
      // Get count from API
      final response = await _apiService.get(
        '/notifications/unread-count',
        queryParams: {'userId': userId},
        useCache: true,
        cacheDuration: const Duration(minutes: 5),
      );
      
      return response['count'] ?? 0;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get unread notification count',
        ErrorSeverity.low,
      );
      
      // Get count from local cache as fallback
      final notifications = await _getCachedNotifications(userId);
      return notifications.where((n) => !n.read).length;
    }
  }
  
  // Get notification stream
  Stream<Notification> get notificationStream => _notificationStreamController.stream;
  
  // Get platform
  String _getPlatform() {
    return 'android'; // For simplicity, assuming Android platform
  }
  
  // Dispose
  void dispose() {
    _notificationStreamController.close();
  }
  
  // Getters for notification settings
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get transactionNotificationsEnabled => _transactionNotificationsEnabled;
  bool get securityNotificationsEnabled => _securityNotificationsEnabled;
  bool get marketingNotificationsEnabled => _marketingNotificationsEnabled;
}

// Notification class
class Notification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool read;
  final Map<String, dynamic>? data;
  
  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.read,
    this.data,
  });
  
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: _getNotificationTypeFromString(json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      read: json['read'] ?? false,
      data: json['data'],
    );
  }
  
  factory Notification.fromFirebaseMessage(Map<String, dynamic> message) {
    final notification = message['notification'] ?? {};
    final data = message['data'] ?? {};
    
    return Notification(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification['title'] ?? data['title'] ?? 'New Notification',
      body: notification['body'] ?? data['body'] ?? '',
      type: _getNotificationTypeFromString(data['type']),
      timestamp: DateTime.now(),
      read: false,
      data: data,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
      'data': data,
    };
  }
  
  static NotificationType _getNotificationTypeFromString(String? typeString) {
    switch (typeString) {
      case 'transaction':
        return NotificationType.transaction;
      case 'security':
        return NotificationType.security;
      case 'system':
        return NotificationType.system;
      case 'marketing':
        return NotificationType.marketing;
      default:
        return NotificationType.system;
    }
  }
}

// Notification type enum
enum NotificationType {
  transaction,
  security,
  system,
  marketing,
}
