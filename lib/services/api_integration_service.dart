import 'package:flutter/material.dart';
import 'package:mpay_app/theme/app_theme.dart';
import 'package:mpay_app/widgets/optimized_widgets.dart';
import 'package:mpay_app/widgets/responsive_widgets.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'package:mpay_app/firebase/firebase_service.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/performance_optimizer.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:mpay_app/utils/device_compatibility_manager.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:path/path.dart' as path;

/// Service for API integration with secure communication and error handling
class ApiIntegrationService {
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  final ErrorHandler _errorHandler = ErrorHandler();
  final PerformanceOptimizer _performanceOptimizer = PerformanceOptimizer();
  final SecurityUtils _securityUtils = SecurityUtils();
  final DeviceCompatibilityManager _deviceCompatibilityManager = DeviceCompatibilityManager();
  
  // Base URLs for different environments
  static const String _productionBaseUrl = 'https://api.mpay.com/v1';
  static const String _stagingBaseUrl = 'https://staging-api.mpay.com/v1';
  static const String _developmentBaseUrl = 'https://dev-api.mpay.com/v1';
  
  // Current environment
  String _currentEnvironment = 'production';
  
  // API timeout duration
  Duration _timeoutDuration = const Duration(seconds: 30);
  
  // Retry configuration
  int _maxRetries = 3;
  Duration _retryDelay = const Duration(seconds: 2);
  
  // Cache configuration
  final Map<String, CachedResponse> _responseCache = {};
  final Duration _defaultCacheDuration = const Duration(minutes: 5);
  
  // Rate limiting
  final Map<String, DateTime> _lastRequestTimes = {};
  final Duration _minRequestInterval = const Duration(milliseconds: 500);
  
  // Authentication token
  String? _authToken;
  DateTime? _tokenExpiryTime;
  
  // HTTP client with SSL pinning
  http.Client? _secureClient;
  
  // Singleton pattern
  static final ApiIntegrationService _instance = ApiIntegrationService._internal();
  
  factory ApiIntegrationService() {
    return _instance;
  }
  
  ApiIntegrationService._internal();
  
  /// Initialize the service
  Future<void> initialize({
    String environment = 'production',
    Duration? timeout,
    int? maxRetries,
    Duration? retryDelay,
    Duration? cacheDuration,
    Duration? minRequestInterval,
  }) async {
    _currentEnvironment = environment;
    
    if (timeout != null) {
      _timeoutDuration = timeout;
    }
    
    if (maxRetries != null && maxRetries > 0) {
      _maxRetries = maxRetries;
    }
    
    if (retryDelay != null) {
      _retryDelay = retryDelay;
    }
    
    if (minRequestInterval != null) {
      _minRequestInterval = minRequestInterval;
    }
    
    // Initialize secure HTTP client with certificate validation
    await _initializeSecureClient();
    
    // Check device compatibility
    await _deviceCompatibilityManager.checkApiCompatibility();
    
    // Initialize security features
    await _securityUtils.initializeApiSecurity();
    
    // Clear cache
    clearCache();
  }
  
  /// Initialize secure HTTP client with certificate validation
  Future<void> _initializeSecureClient() async {
    try {
      // Create a secure HTTP client with certificate validation
      final HttpClient httpClient = HttpClient()
        ..badCertificateCallback = _validateCertificate;
      
      // Set connection timeout
      httpClient.connectionTimeout = _timeoutDuration;
      
      // Create IOClient with the secure HttpClient
      _secureClient = http_io.IOClient(httpClient);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to initialize secure HTTP client',
        ErrorSeverity.critical,
      );
      
      // Fallback to standard client if secure client initialization fails
      _secureClient = http.Client();
      
      // Log security event
      _securityUtils.logSecurityEvent(
        'system',
        'secure_client_initialization_failure',
        'Failed to initialize secure HTTP client: ${e.toString()}',
      );
    }
  }
  
  /// Validate SSL/TLS certificate
  bool _validateCertificate(X509Certificate cert, String host, int port) {
    try {
      // Get the list of trusted certificates
      final trustedCerts = _getTrustedCertificates();
      
      // Check if the certificate is in the trusted list
      for (final trustedCert in trustedCerts) {
        if (_compareCertificates(cert, trustedCert)) {
          return true;
        }
      }
      
      // Certificate pinning - validate against known certificate fingerprints
      final fingerprints = _getCertificateFingerprints();
      final certFingerprint = _calculateFingerprint(cert);
      
      if (fingerprints.contains(certFingerprint)) {
        return true;
      }
      
      // Log security event for certificate validation failure
      _securityUtils.logSecurityEvent(
        'system',
        'certificate_validation_failure',
        'Invalid certificate for host: $host:$port',
      );
      
      // In production, return false to reject untrusted certificates
      return _currentEnvironment == 'development';
    } catch (e) {
      // Log error
      _errorHandler.handleError(
        e,
        'Certificate validation error',
        ErrorSeverity.high,
      );
      
      // In production, return false on validation error
      return _currentEnvironment == 'development';
    }
  }
  
  /// Get list of trusted certificates
  List<X509Certificate> _getTrustedCertificates() {
    try {
      // In a real implementation, you would load trusted certificates from a secure storage
      // For now, return an empty list
      return [];
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get trusted certificates',
        ErrorSeverity.high,
      );
      return [];
    }
  }
  
  /// Compare two certificates
  bool _compareCertificates(X509Certificate cert1, X509Certificate cert2) {
    try {
      // Compare certificate properties
      return cert1.sha1 == cert2.sha1;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to compare certificates',
        ErrorSeverity.high,
      );
      return false;
    }
  }
  
  /// Get list of trusted certificate fingerprints
  List<String> _getCertificateFingerprints() {
    try {
      // In a real implementation, these would be stored securely and possibly fetched from a server
      // These are example fingerprints and should be replaced with actual values
      return [
        // Example SHA-256 fingerprints for api.mpay.com
        'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99',
        'BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA',
      ];
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get certificate fingerprints',
        ErrorSeverity.high,
      );
      return [];
    }
  }
  
  /// Calculate certificate fingerprint
  String _calculateFingerprint(X509Certificate cert) {
    try {
      // In a real implementation, you would calculate the SHA-256 fingerprint of the certificate
      // For now, return a placeholder
      return cert.sha1.toUpperCase().replaceAllMapped(
        RegExp(r'..'),
        (match) => '${match.group(0)}:',
      ).substring(0, 95); // Remove the trailing colon
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to calculate certificate fingerprint',
        ErrorSeverity.high,
      );
      return '';
    }
  }
  
  /// Get base URL based on current environment
  String get baseUrl {
    switch (_currentEnvironment) {
      case 'production':
        return _productionBaseUrl;
      case 'staging':
        return _stagingBaseUrl;
      case 'development':
        return _developmentBaseUrl;
      default:
        return _productionBaseUrl;
    }
  }
  
  /// Set authentication token
  Future<void> setAuthToken(String token, {Duration? expiresIn}) async {
    if (token.isEmpty) {
      throw ArgumentError('Token cannot be empty');
    }
    
    _authToken = token;
    
    if (expiresIn != null) {
      _tokenExpiryTime = DateTime.now().add(expiresIn);
    } else {
      // Default token expiry time (1 hour)
      _tokenExpiryTime = DateTime.now().add(const Duration(hours: 1));
    }
    
    // Securely store the token
    await _securityUtils.securelyStoreApiToken(token, _tokenExpiryTime!);
  }
  
  /// Clear authentication token
  Future<void> clearAuthToken() async {
    _authToken = null;
    _tokenExpiryTime = null;
    await _securityUtils.clearSecurelyStoredApiToken();
  }
  
  /// Check if token is valid
  bool get isTokenValid {
    if (_authToken == null || _tokenExpiryTime == null) {
      return false;
    }
    
    // Add a buffer of 5 minutes before actual expiry
    final expiryWithBuffer = _tokenExpiryTime!.subtract(const Duration(minutes: 5));
    return DateTime.now().isBefore(expiryWithBuffer);
  }
  
  /// Refresh token if needed
  Future<bool> refreshTokenIfNeeded() async {
    if (isTokenValid) {
      return true;
    }
    
    try {
      // Try to get token from secure storage
      final storedToken = await _securityUtils.getSecurelyStoredApiToken();
      final storedExpiryTime = await _securityUtils.getSecurelyStoredApiTokenExpiry();
      
      if (storedToken != null && storedExpiryTime != null) {
        final expiryWithBuffer = storedExpiryTime.subtract(const Duration(minutes: 5));
        if (DateTime.now().isBefore(expiryWithBuffer)) {
          _authToken = storedToken;
          _tokenExpiryTime = storedExpiryTime;
          return true;
        }
      }
      
      // If no valid token in storage, refresh from server
      final refreshResult = await _refreshToken();
      return refreshResult;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh API token',
        ErrorSeverity.high,
      );
      return false;
    }
  }
  
  /// Refresh token from server
  Future<bool> _refreshToken() async {
    try {
      // Get refresh token from secure storage
      final refreshToken = await _securityUtils.getSecurelyStoredRefreshToken();
      
      if (refreshToken == null) {
        return false;
      }
      
      // Ensure secure client is initialized
      if (_secureClient == null) {
        await _initializeSecureClient();
      }
      
      final response = await _secureClient!.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'X-Refresh-Token': refreshToken,
        },
      ).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newToken = responseData['token'];
        
        if (newToken == null || newToken.toString().isEmpty) {
          throw ApiException('Invalid token received from server', response.statusCode);
        }
        
        final expiresIn = Duration(seconds: responseData['expiresIn'] ?? 3600);
        
        await setAuthToken(newToken.toString(), expiresIn: expiresIn);
        
        // Store new refresh token if provided
        if (responseData['refreshToken'] != null) {
          await _securityUtils.securelyStoreRefreshToken(responseData['refreshToken'].toString());
        }
        
        return true;
      } else {
        // Clear tokens on refresh failure
        await clearAuthToken();
        await _securityUtils.clearSecurelyStoredRefreshToken();
        return false;
      }
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to refresh token from server',
        ErrorSeverity.high,
      );
      
      // Clear tokens on refresh failure
      await clearAuthToken();
      await _securityUtils.clearSecurelyStoredRefreshToken();
      
      return false;
    }
  }
  
  /// Clear cache
  void clearCache() {
    _responseCache.clear();
  }
  
  /// Clear specific cache entry
  void clearCacheEntry(String cacheKey) {
    _responseCache.remove(cacheKey);
  }
  
  /// Generate cache key
  String _generateCacheKey(String url, Map<String, dynamic>? queryParams, Map<String, dynamic>? body) {
    final buffer = StringBuffer(url);
    
    if (queryParams != null && queryParams.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        queryParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      buffer.write('?');
      buffer.write(sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&'));
    }
    
    if (body != null && body.isNotEmpty) {
      buffer.write('#');
      buffer.write(json.encode(body));
    }
    
    return buffer.toString();
  }
  
  /// Check rate limiting
  bool _checkRateLimit(String endpoint) {
    final now = DateTime.now();
    
    if (_lastRequestTimes.containsKey(endpoint)) {
      final lastRequestTime = _lastRequestTimes[endpoint]!;
      final timeSinceLastRequest = now.difference(lastRequestTime);
      
      if (timeSinceLastRequest < _minRequestInterval) {
        return false;
      }
    }
    
    _lastRequestTimes[endpoint] = now;
    return true;
  }
  
  /// Add authentication headers
  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': await _deviceCompatibilityManager.getAppVersion(),
      'X-Device-Info': await _deviceCompatibilityManager.getDeviceInfo(),
    };
    
    if (await refreshTokenIfNeeded() && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    // Add security headers
    final securityHeaders = await _securityUtils.generateApiSecurityHeaders();
    headers.addAll(securityHeaders);
    
    return headers;
  }
  
  /// Execute HTTP request with retry logic
  Future<dynamic> _executeRequest(
    Future<dynamic> Function() requestFunction,
    String endpoint,
  ) async {
    if (!_checkRateLimit(endpoint)) {
      throw ApiException(
        'Rate limit exceeded for endpoint: $endpoint',
        429,
      );
    }
    
    // Ensure secure client is initialized
    if (_secureClient == null) {
      await _initializeSecureClient();
    }
    
    int retryCount = 0;
    
    while (true) {
      try {
        return await requestFunction().timeout(_timeoutDuration);
      } catch (e) {
        retryCount++;
        
        if (retryCount >= _maxRetries) {
          if (e is TimeoutException) {
            throw ApiException(
              'Request timed out after $_maxRetries attempts for endpoint: $endpoint',
              408,
            );
          } else if (e is SocketException) {
            throw ApiException(
              'Network error after $_maxRetries attempts for endpoint: $endpoint',
              0,
              errorCode: 'network_error',
            );
          } else {
            rethrow;
          }
        }
        
        // Check if we should retry based on the error
        final shouldRetry = _shouldRetryRequest(e);
        if (!shouldRetry) {
          rethrow;
        }
        
        // Exponential backoff
        final delay = _retryDelay * retryCount;
        await Future.delayed(delay);
      }
    }
  }
  
  /// Determine if request should be retried
  bool _shouldRetryRequest(dynamic error) {
    if (error is SocketException || error is TimeoutException) {
      return true;
    }
    
    if (error is http.ClientException) {
      return true;
    }
    
    if (error is ApiException) {
      // Retry on server errors (5xx) but not on client errors (4xx)
      return error.statusCode >= 500 && error.statusCode < 600;
    }
    
    return false;
  }
  
  /// Process API response
  Future<dynamic> _processResponse(http.Response response, String endpoint) async {
    final statusCode = response.statusCode;
    
    // Log API call for performance monitoring
    _performanceOptimizer.logApiCall(
      endpoint,
      statusCode,
      response.contentLength ?? 0,
      DateTime.now(),
    );
    
    if (statusCode >= 200 && statusCode < 300) {
      // Success response
      if (response.body.isEmpty) {
        return null;
      }
      
      try {
        return json.decode(response.body);
      } catch (e) {
        _errorHandler.handleError(
          e,
          'Failed to parse API response for endpoint: $endpoint',
          ErrorSeverity.medium,
        );
        return response.body;
      }
    } else if (statusCode == 401) {
      // Unauthorized - clear token and throw exception
      await clearAuthToken();
      throw ApiException(
        'Unauthorized access. Please log in again.',
        statusCode,
      );
    } else {
      // Error response
      String errorMessage = 'API request failed with status code: $statusCode';
      String errorCode = 'unknown_error';
      
      try {
        final errorBody = json.decode(response.body);
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'].toString();
        } else if (errorBody['error'] != null) {
          errorMessage = errorBody['error'].toString();
        }
        
        if (errorBody['code'] != null) {
          errorCode = errorBody['code'].toString();
        }
        
        // Log security events for certain error codes
        if (statusCode == 403 || statusCode == 429) {
          _securityUtils.logSecurityEvent(
            'system',
            'api_security_event',
            'Security-related API error: $statusCode - $errorCode',
          );
        }
      } catch (e) {
        // Ignore parsing errors for error responses
      }
      
      throw ApiException(errorMessage, statusCode, errorCode: errorCode);
    }
  }
  
  /// Validate internet connectivity
  Future<void> _validateConnectivity() async {
    final hasConnection = await _connectivityUtils.checkInternetConnection();
    
    if (!hasConnection) {
      throw ApiException(
        'No internet connection available',
        0,
        errorCode: 'no_connectivity',
      );
    }
  }
  
  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool useCache = false,
    Duration? cacheDuration,
    bool requiresAuth = true,
  }) async {
    // Validate endpoint
    if (endpoint.isEmpty) {
      throw ArgumentError('Endpoint cannot be empty');
    }
    
    // Validate connectivity
    await _validateConnectivity();
    
    // Build URL with query parameters
    var uri = Uri.parse('$baseUrl$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      // Convert all values to strings
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value?.toString() ?? '')
      );
      
      uri = uri.replace(queryParameters: stringParams);
    }
    
    // Check cache first if enabled
    if (useCache) {
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', queryParams, null);
      final cachedResponse = _responseCache[cacheKey];
      
      if (cachedResponse != null && !cachedResponse.isExpired()) {
        return cachedResponse.data;
      }
    }
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
    
    try {
      final response = await _executeRequest(
        () => _secureClient!.get(uri, headers: headers),
        endpoint,
      );
      
      final processedResponse = await _processResponse(response, endpoint);
      
      // Cache response if enabled
      if (useCache) {
        final cacheKey = _generateCacheKey('$baseUrl$endpoint', queryParams, null);
        _responseCache[cacheKey] = CachedResponse(
          processedResponse,
          DateTime.now().add(cacheDuration ?? _defaultCacheDuration),
        );
      }
      
      return processedResponse;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'GET request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    // Validate endpoint
    if (endpoint.isEmpty) {
      throw ArgumentError('Endpoint cannot be empty');
    }
    
    // Validate connectivity
    await _validateConnectivity();
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
    
    try {
      final response = await _executeRequest(
        () => _secureClient!.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        ),
        endpoint,
      );
      
      // Clear cache for this endpoint if it exists
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', null, body);
      clearCacheEntry(cacheKey);
      
      return await _processResponse(response, endpoint);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'POST request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    // Validate endpoint
    if (endpoint.isEmpty) {
      throw ArgumentError('Endpoint cannot be empty');
    }
    
    // Validate connectivity
    await _validateConnectivity();
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
    
    try {
      final response = await _executeRequest(
        () => _secureClient!.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        ),
        endpoint,
      );
      
      // Clear cache for this endpoint if it exists
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', null, body);
      clearCacheEntry(cacheKey);
      
      return await _processResponse(response, endpoint);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'PUT request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    // Validate endpoint
    if (endpoint.isEmpty) {
      throw ArgumentError('Endpoint cannot be empty');
    }
    
    // Validate connectivity
    await _validateConnectivity();
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
    
    try {
      final response = await _executeRequest(
        () => _secureClient!.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        ),
        endpoint,
      );
      
      // Clear cache for this endpoint if it exists
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', null, body);
      clearCacheEntry(cacheKey);
      
      return await _processResponse(response, endpoint);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'DELETE request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  /// PATCH request
  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    // Validate endpoint
    if (endpoint.isEmpty) {
      throw ArgumentError('Endpoint cannot be empty');
    }
    
    // Validate connectivity
    await _validateConnectivity();
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
    
    try {
      final response = await _executeRequest(
        () => _secureClient!.patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? json.encode(body) : null,
        ),
        endpoint,
      );
      
      // Clear cache for this endpoint if it exists
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', null, body);
      clearCacheEntry(cacheKey);
      
      return await _processResponse(response, endpoint);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'PATCH request failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  /// Upload file
  Future<dynamic> uploadFile(
    String endpoint,
    String filePath, {
    String fileField = 'file',
    Map<String, String>? fields,
    bool requiresAuth = true,
  }) async {
    // Validate endpoint and file path
    if (endpoint.isEmpty) {
      throw ArgumentError('Endpoint cannot be empty');
    }
    
    if (filePath.isEmpty) {
      throw ArgumentError('File path cannot be empty');
    }
    
    // Check if file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', filePath);
    }
    
    // Validate connectivity
    await _validateConnectivity();
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Accept': 'application/json',
          };
    
    // Remove Content-Type header as it will be set by the multipart request
    headers.remove('Content-Type');
    
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add file
      final multipartFile = await http.MultipartFile.fromPath(fileField, filePath);
      request.files.add(multipartFile);
      
      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // Execute request
      final streamedResponse = await _executeRequest(
        () => _secureClient!.send(request),
        endpoint,
      ) as http.StreamedResponse;
      
      // Convert to Response
      final response = await http.Response.fromStream(streamedResponse);
      
      // Clear cache for this endpoint if it exists
      final cacheKey = _generateCacheKey('$baseUrl$endpoint', null, null);
      clearCacheEntry(cacheKey);
      
      return await _processResponse(response, endpoint);
    } catch (e) {
      _errorHandler.handleError(
        e,
        'File upload failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  /// Download file
  Future<String> downloadFile(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    Function(int, int)? onProgress,
  }) async {
    // Validate endpoint and save path
    if (endpoint.isEmpty) {
      throw ArgumentError('Endpoint cannot be empty');
    }
    
    if (savePath.isEmpty) {
      throw ArgumentError('Save path cannot be empty');
    }
    
    // Validate connectivity
    await _validateConnectivity();
    
    // Ensure directory exists
    final directory = Directory(path.dirname(savePath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    // Check if we have write permission
    try {
      final testFile = File('${savePath}_test');
      await testFile.writeAsString('test');
      await testFile.delete();
    } catch (e) {
      throw FileSystemException('Cannot write to directory', path.dirname(savePath));
    }
    
    // Build URL with query parameters
    var uri = Uri.parse('$baseUrl$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      // Convert all values to strings
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value?.toString() ?? '')
      );
      
      uri = uri.replace(queryParameters: stringParams);
    }
    
    // Get headers
    final headers = requiresAuth
        ? await _getAuthenticatedHeaders()
        : {
            'Accept': '*/*',
          };
    
    // Create temporary file path
    final tempFilePath = '${savePath}_temp';
    
    try {
      // Create file
      final file = File(tempFilePath);
      final sink = file.openWrite();
      
      try {
        // Execute request
        final response = await _executeRequest(
          () => _secureClient!.send(http.Request('GET', uri)..headers.addAll(headers)),
          endpoint,
        ) as http.StreamedResponse;
        
        // Check response status
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Get total size
          final totalBytes = response.contentLength ?? -1;
          int receivedBytes = 0;
          
          // Download file
          await response.stream.forEach((chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            
            // Report progress
            if (onProgress != null && totalBytes != -1) {
              onProgress(receivedBytes, totalBytes);
            }
          });
          
          // Close file
          await sink.close();
          
          // Move temp file to final location
          final finalFile = File(savePath);
          if (await finalFile.exists()) {
            await finalFile.delete();
          }
          await file.rename(savePath);
          
          // Return file path
          return savePath;
        } else {
          // Handle error
          final errorResponse = await http.Response.fromStream(response);
          await _processResponse(errorResponse, endpoint);
          
          // This line should not be reached if _processResponse throws an exception
          throw ApiException(
            'Failed to download file with status code: ${response.statusCode}',
            response.statusCode,
          );
        }
      } catch (e) {
        // Close file
        await sink.close();
        rethrow;
      }
    } catch (e) {
      // Delete temp file if it exists
      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      _errorHandler.handleError(
        e,
        'File download failed for endpoint: $endpoint',
        ErrorSeverity.medium,
      );
      rethrow;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _secureClient?.close();
    _secureClient = null;
    clearCache();
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String errorCode;
  
  ApiException(this.message, this.statusCode, {this.errorCode = 'unknown_error'});
  
  @override
  String toString() {
    return 'ApiException: $message (Status Code: $statusCode, Error Code: $errorCode)';
  }
}

/// Cached Response
class CachedResponse {
  final dynamic data;
  final DateTime expiryTime;
  
  CachedResponse(this.data, this.expiryTime);
  
  bool isExpired() {
    return DateTime.now().isAfter(expiryTime);
  }
}
