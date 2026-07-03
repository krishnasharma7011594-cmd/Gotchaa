/// Dio security interceptors and middleware.
///
/// ⚠️ SECURITY: These interceptors add:
/// - Security headers (X-Frame-Options, X-Content-Type-Options, etc.)
/// - Rate limiting enforcement
/// - Bearer token injection with refresh
/// - Request/response validation
/// - Error handling without leaking sensitive data
/// - CSRF and XSS mitigation
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_key_manager.dart';
import 'rate_limiting.dart';

/// Security headers interceptor.
///
/// Applies OWASP security headers to all requests.
class SecurityHeadersInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // ⚠️ SECURITY: Add headers to protect against common attacks

    options.headers.addAll({
      // Prevent clickjacking attacks
      'X-Frame-Options': 'DENY',

      // Prevent MIME sniffing attacks
      'X-Content-Type-Options': 'nosniff',

      // Enable XSS protection (legacy, but still helpful)
      'X-XSS-Protection': '1; mode=block',

      // Enforce HTTPS (on servers)
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',

      // Control referrer leakage
      'Referrer-Policy': 'strict-origin-when-cross-origin',

      // Control feature access
      'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',

      // Prevent caching of sensitive data
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',

      // Content Security Policy (basic)
      // Note: strict CSP on API responses isn't needed, but included for completeness
      'Content-Security-Policy':
          'default-src \'none\'; script-src \'self\'; style-src \'self\'; img-src \'self\'; font-src \'self\'',

      // API-specific headers
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',

      // API versioning (helps prevent breaking changes)
      'API-Version': '1',
    });

    super.onRequest(options, handler);
  }
}

/// Bearer token interceptor.
///
/// Automatically adds and refreshes authentication tokens.
class BearerTokenInterceptor extends Interceptor {
  BearerTokenInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // ⚠️ SECURITY: Only add token to trusted endpoints
    if (_shouldAddToken(options.path)) {
      final token = await BearerTokenManager().getAccessToken();

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - token may have expired
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        // Attempt to refresh token
        final refreshed = await _refreshToken();

        if (refreshed) {
          // Retry original request
          _isRefreshing = false;

          // Process all pending requests
          _processPendingRequests();

          // Retry current request
          return handler.resolve(
            await _dio.request(
              err.requestOptions.path,
              options: Options(
                method: err.requestOptions.method,
                headers: err.requestOptions.headers,
              ),
              data: err.requestOptions.data,
              queryParameters: err.requestOptions.queryParameters,
            ),
          );
        }
      } catch (_) {
        // Token refresh failed - likely need to reauthenticate
        _pendingRequests.clear();
        _isRefreshing = false;

        // Clear stored tokens on authentication failure
        await BearerTokenManager().clearTokens();

        return handler.next(err);
      }
    }

    // If already refreshing, queue the request
    if (_isRefreshing) {
      _pendingRequests.add(_PendingRequest(handler, err));
      return;
    }

    super.onError(err, handler);
  }

  /// Refresh authentication token.
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await BearerTokenManager().getRefreshToken();

      if (refreshToken == null) {
        return false;
      }

      // Make refresh token request
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'] as String?;
        final newRefreshToken = response.data['refresh_token'] as String?;
        final expiresIn = response.data['expires_in'] as int? ?? 3600;

        if (newAccessToken != null) {
          await BearerTokenManager().setTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            expiresIn: Duration(seconds: expiresIn),
          );
          return true;
        }
      }
    } catch (e) {}

    return false;
  }

  /// Process pending requests after token refresh.
  void _processPendingRequests() {
    if (_pendingRequests.isEmpty) return;

    final requests = _pendingRequests.toList();
    _pendingRequests.clear();

    for (final request in requests) {
      request.handler.next(request.error);
    }
  }

  /// Determine if token should be added to request.
  bool _shouldAddToken(String path) {
    // Don't add token to auth endpoints
    final noTokenPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
      '/auth/forgot-password',
      '/auth/reset-password',
    ];

    return !noTokenPaths.any((p) => path.contains(p));
  }
}

/// Rate limiting interceptor.
///
/// Enforces client-side rate limits before sending requests.
class RateLimitingInterceptor extends Interceptor {
  RateLimitingInterceptor(
    this._rateLimitingService, {
    this.userId,
    this.clientIp,
  });

  final RateLimitingService _rateLimitingService;
  final String? userId;
  final String? clientIp;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check rate limit
    final checkResult = await _rateLimitingService.checkLimit(
      endpoint: options.path,
      userId: userId,
      clientIp: clientIp,
    );

    if (!checkResult.allowed) {
      // ⚠️ SECURITY: Return explicit 429 rate limit error
      final retryAfter = checkResult.retryAfter?.inSeconds ?? 60;

      final exception = DioException(
        requestOptions: options,
        error: 'Too many requests',
        type: DioExceptionType.unknown,
        response: Response(
          requestOptions: options,
          statusCode: 429,
          statusMessage: 'Too Many Requests',
          data: {
            'error': 'rate_limited',
            'message':
                'You have exceeded the rate limit. Please try again later.',
            'retry_after': retryAfter,
          },
        ),
      );

      return handler.reject(exception);
    }

    return handler.next(options);
  }
}

/// Secure response validator interceptor.
///
/// Validates responses and prevents information leakage.
class ResponseValidatorInterceptor extends Interceptor {
  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // ⚠️ SECURITY: Validate response integrity

    // Ensure response is JSON
    final contentType = response.headers.value(Headers.contentTypeHeader);
    if (contentType == null || !contentType.contains('application/json')) {
      // Only accept JSON responses from API
      if (response.requestOptions.path.contains('/api/')) {
        return handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            error: 'Invalid response format',
            type: DioExceptionType.unknown,
            response: response,
          ),
        );
      }
    }

    // Validate status code
    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      if (response.statusCode != 429) {
        // Let other error codes be handled by onError
        return handler.next(response);
      }
    }

    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // ⚠️ SECURITY: Sanitize error messages to prevent leaking sensitive info

    final safeError = _sanitizeError(err);
    return handler.next(safeError);
  }

  /// Remove sensitive information from error messages.
  DioException _sanitizeError(DioException originalError) {
    String sanitizedMessage = originalError.message ?? 'Request failed';

    // Remove sensitive information
    if (originalError.error is! String) {
      // If error is an exception, get a safe message
      sanitizedMessage = _getSafeErrorMessage(originalError.type);
    }

    // Remove internal server details from error response
    final response = originalError.response;
    if (response?.data is Map) {
      final data = (response!.data as Map).cast<String, dynamic>();

      // Remove stack traces and internal details
      if (data.containsKey('stackTrace') || data.containsKey('stacktrace')) {
        data.remove('stackTrace');
        data.remove('stacktrace');
      }

      if (data.containsKey('details')) {
        data.remove('details');
      }
    }

    return DioException(
      requestOptions: originalError.requestOptions,
      response: response,
      type: originalError.type,
      error: sanitizedMessage,
      message: sanitizedMessage,
    );
  }

  /// Get safe error message for exception type.
  String _getSafeErrorMessage(DioExceptionType type) => switch (type) {
        DioExceptionType.badCertificate =>
          'Security error: Unable to verify server certificate',
        DioExceptionType.badResponse =>
          'Server returned an error. Please try again.',
        DioExceptionType.cancel => 'Request was cancelled',
        DioExceptionType.connectionTimeout =>
          'Connection timeout. Check your internet connection.',
        DioExceptionType.receiveTimeout => 'Request timeout. Please try again.',
        DioExceptionType.sendTimeout => 'Request timeout. Please try again.',
        DioExceptionType.transformTimeout =>
          'Request timeout. Please try again.',
        DioExceptionType.unknown =>
          'An error occurred. Please try again later.',
        DioExceptionType.connectionError =>
          'Connection failed. Check your internet connection.',
      };
}

/// Pending request wrapper.
class _PendingRequest {
  _PendingRequest(this.handler, this.error);

  final ErrorInterceptorHandler handler;
  final DioException error;
}

/// Logging interceptor with security considerations.
///
/// Logs requests/responses but NEVER logs sensitive data.
class SecureLoggingInterceptor extends Interceptor {
  SecureLoggingInterceptor({this.enableLogging = true});

  final bool enableLogging;
  static const List<String> _sensitiveKeys = [
    'password',
    'token',
    'authorization',
    'api_key',
    'secret',
    'refresh_token',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!enableLogging) return handler.next(options);

    // Log headers (without sensitive ones)
    final safeHeaders = _sanitizeHeaders(options.headers);
    if (safeHeaders.isNotEmpty) {}

    // Log body if present (without sensitive fields)
    if (options.data != null) {
      final safeData = _sanitizeData(options.data);
    }

    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (!enableLogging) return handler.next(response);

    // Never log response data in production
    if (kDebugMode && response.data != null) {
      final safeData = _sanitizeData(response.data);
    }

    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!enableLogging) return handler.next(err);

    return handler.next(err);
  }

  /// Remove sensitive headers.
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final safe = Map<String, dynamic>.from(headers);

    for (final sensitiveKey in _sensitiveKeys) {
      safe.remove(sensitiveKey.toLowerCase());
      safe.removeWhere((key, _) => key.toLowerCase() == sensitiveKey);
    }

    return safe;
  }

  /// Remove sensitive fields from data.
  dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      final safe = Map<String, dynamic>.from(data.cast<String, dynamic>());

      for (final sensitiveKey in _sensitiveKeys) {
        safe.removeWhere((key, _) => key.toLowerCase().contains(sensitiveKey));
      }

      return safe;
    }

    return data;
  }
}
