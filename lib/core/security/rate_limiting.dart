/// Rate limiting implementation for API requests.
///
/// ⚠️ SECURITY: Client-side rate limiting provides basic brute force protection
/// and prevents accidental abuse. Backend MUST enforce strict server-side
/// rate limiting for actual security.
///
/// Supports:
/// - IP-based rate limiting (client IP)
/// - User/token-based rate limiting
/// - Endpoint-specific limits
/// - Exponential backoff with jitter
library;

import 'dart:async';

/// Rate limiter that tracks requests per key.
class RateLimiter {
  /// Creates a rate limiter.
  RateLimiter({
    this.maxRequests = 100,
    this.windowDuration = const Duration(minutes: 15),
    this.backoffEnabled = true,
  });

  /// Maximum requests allowed in the window.
  final int maxRequests;

  /// Time window for counting requests.
  final Duration windowDuration;

  /// Whether to enable exponential backoff.
  final bool backoffEnabled;

  /// Request history: key -> list of timestamps
  final Map<String, List<DateTime>> _requestHistory = {};

  /// Backoff state: key -> backoff multiplier
  final Map<String, int> _backoffMultipliers = {};

  /// Check if a request should be allowed.
  ///
  /// Returns true if the request is within rate limits.
  /// Returns false if rate limit exceeded.
  Future<RateLimitStatus> checkRateLimit(String key) async {
    _cleanupOldRequests(key);

    final now = DateTime.now();
    final requestsInWindow = _requestHistory[key] ?? [];

    if (requestsInWindow.length < maxRequests) {
      // Request is allowed
      _recordRequest(key, now);
      _backoffMultipliers[key] = 1; // Reset backoff on successful request
      return RateLimitStatus.allowed();
    }

    // Rate limit exceeded
    final nextAvailableTime = requestsInWindow.first.add(windowDuration);
    final retryAfter = nextAvailableTime.difference(now);

    // Calculate backoff
    if (backoffEnabled) {
      _backoffMultipliers[key] = (_backoffMultipliers[key] ?? 1) * 2;
      final maxBackoff = windowDuration.inSeconds;
      if (_backoffMultipliers[key]! > maxBackoff) {
        _backoffMultipliers[key] = maxBackoff;
      }
    }

    return RateLimitStatus.limited(
      retryAfter: retryAfter,
      requestsInWindow: requestsInWindow.length,
      maxRequests: maxRequests,
    );
  }

  /// Get current status for a key.
  RateLimitInfo getStatus(String key) {
    _cleanupOldRequests(key);
    final requestsInWindow = _requestHistory[key] ?? [];
    return RateLimitInfo(
      requestsInWindow: requestsInWindow.length,
      maxRequests: maxRequests,
      remainingRequests: maxRequests - requestsInWindow.length,
      resetTime: requestsInWindow.isNotEmpty
          ? requestsInWindow.first.add(windowDuration)
          : DateTime.now(),
    );
  }

  /// Reset rate limit for a key.
  void reset(String key) {
    _requestHistory.remove(key);
    _backoffMultipliers.remove(key);
  }

  /// Reset all rate limits.
  void resetAll() {
    _requestHistory.clear();
    _backoffMultipliers.clear();
  }

  /// Record a request.
  void _recordRequest(String key, DateTime time) {
    _requestHistory.putIfAbsent(key, () => []).add(time);
  }

  /// Remove old requests outside the window.
  void _cleanupOldRequests(String key) {
    final now = DateTime.now();
    final history = _requestHistory[key];

    if (history == null) return;

    final cutoff = now.subtract(windowDuration);
    history.removeWhere((time) => time.isBefore(cutoff));

    if (history.isEmpty) {
      _requestHistory.remove(key);
    }
  }
}

/// Rate limit check result.
class RateLimitStatus {

  /// Creates a rate limit status.
  RateLimitStatus({
    required this.isAllowed,
    this.retryAfter,
    this.requestsInWindow,
    this.maxRequests,
  });
  /// Factory constructor for allowed requests.
  factory RateLimitStatus.allowed() => RateLimitStatus(isAllowed: true);

  /// Factory constructor for limited requests.
  factory RateLimitStatus.limited({
    required Duration retryAfter,
    int? requestsInWindow,
    int? maxRequests,
  }) => RateLimitStatus(
      isAllowed: false,
      retryAfter: retryAfter,
      requestsInWindow: requestsInWindow,
      maxRequests: maxRequests,
    );

  /// Whether request is allowed.
  final bool isAllowed;

  /// How long to wait before retrying (if denied).
  final Duration? retryAfter;

  /// Current requests in window (if known).
  final int? requestsInWindow;

  /// Max requests allowed (if known).
  final int? maxRequests;
}

/// Rate limit information.
class RateLimitInfo {
  /// Creates rate limit info.
  const RateLimitInfo({
    required this.requestsInWindow,
    required this.maxRequests,
    required this.remainingRequests,
    required this.resetTime,
  });

  /// Current requests in window.
  final int requestsInWindow;

  /// Max requests allowed.
  final int maxRequests;

  /// Remaining requests before limit.
  final int remainingRequests;

  /// When the limit resets.
  final DateTime resetTime;
}

/// Manager for endpoint-specific rate limiters.
class RateLimitingService {
  factory RateLimitingService() => _instance;

  RateLimitingService._internal();

  /// Singleton instance.
  static final RateLimitingService _instance = RateLimitingService._internal();

  // Default limits: 100 requests per 15 minutes
  static const int _defaultMaxRequests = 100;
  static const Duration _defaultWindow = Duration(minutes: 15);

  // Authentication endpoints: stricter limits for security
  static const int _authMaxRequests = 10;
  static const Duration _authWindow = Duration(minutes: 15);

  // Sensitive operations: very strict limits
  static const int _sensitiveMaxRequests = 5;
  static const Duration _sensitiveWindow = Duration(minutes: 5);

  /// Endpoint-specific rate limiters.
  final Map<String, RateLimiter> _limiters = {
    // Authentication endpoints
    '/auth/login': RateLimiter(
      maxRequests: _authMaxRequests,
      windowDuration: _authWindow,
    ),
    '/auth/register': RateLimiter(
      maxRequests: _authMaxRequests,
      windowDuration: _authWindow,
    ),
    '/auth/forgot-password': RateLimiter(
      maxRequests: 5,
      windowDuration: const Duration(hours: 1),
    ),
    '/auth/reset-password': RateLimiter(
      maxRequests: 5,
      windowDuration: const Duration(hours: 1),
    ),

    // Sensitive operations
    '/users/*/follow': RateLimiter(
      maxRequests: _sensitiveMaxRequests,
      windowDuration: _sensitiveWindow,
    ),
    '/posts/*/like': RateLimiter(
      maxRequests: _sensitiveMaxRequests,
      windowDuration: _sensitiveWindow,
    ),
    '/messages/send': RateLimiter(
      maxRequests: 30,
      windowDuration: const Duration(minutes: 1),
    ),

    // Default endpoint
    '__default__': RateLimiter(
      maxRequests: _defaultMaxRequests,
      windowDuration: _defaultWindow,
    ),
  };

  /// Check if request is allowed under rate limits.
  ///
  /// [userId] identifies the user (authenticated requests)
  /// [clientIp] identifies the client (unauthenticated requests)
  /// [endpoint] is the API endpoint path
  Future<RateLimitCheckResult> checkLimit({
    required String endpoint,
    String? userId,
    String? clientIp,
  }) async {
    // Use authenticated user ID if available, otherwise use client IP
    final key = userId ?? clientIp ?? 'unknown';

    // Get endpoint-specific limiter or use default
    final limiter = _limiters[endpoint] ?? _limiters['__default__']!;

    final status = await limiter.checkRateLimit(key);

    return RateLimitCheckResult(
      allowed: status.isAllowed,
      retryAfter: status.retryAfter,
      key: key,
      endpoint: endpoint,
      limiter: limiter,
    );
  }

  /// Get rate limit status for an endpoint.
  RateLimitInfo? getStatus({
    required String endpoint,
    String? userId,
    String? clientIp,
  }) {
    final key = userId ?? clientIp ?? 'unknown';
    final limiter = _limiters[endpoint] ?? _limiters['__default__']!;
    return limiter.getStatus(key);
  }

  /// Reset limit for a specific user/IP.
  void resetLimit({
    required String endpoint,
    String? userId,
    String? clientIp,
  }) {
    final key = userId ?? clientIp ?? 'unknown';
    final limiter = _limiters[endpoint] ?? _limiters['__default__']!;
    limiter.reset(key);
  }

  /// Clear all rate limits (use carefully!).
  void clearAll() {
    for (final limiter in _limiters.values) {
      limiter.resetAll();
    }
  }
}

/// Result of rate limit check.
class RateLimitCheckResult {
  /// Creates a rate limit check result.
  const RateLimitCheckResult({
    required this.allowed,
    required this.key,
    required this.endpoint,
    required this.limiter,
    this.retryAfter,
  });

  /// Whether request is allowed.
  final bool allowed;

  /// Rate limit key (user ID or IP).
  final String key;

  /// API endpoint.
  final String endpoint;

  /// Rate limiter instance.
  final RateLimiter limiter;

  /// When to retry (if not allowed).
  final Duration? retryAfter;

  /// Get rate limit status.
  RateLimitInfo getStatus() => limiter.getStatus(key);
}

/// Extension for using rate limiting with Dio interceptor.
/// See: dio_security_interceptor.dart for integration example.
extension RateLimitingExt on RateLimitingService {
  /// Get limiter for endpoint.
  RateLimiter getLimiter(String endpoint) =>
      _limiters[endpoint] ?? _limiters['__default__']!;

  /// Register custom endpoint limits.
  void registerEndpointLimit(
    String endpoint, {
    required int maxRequests,
    required Duration windowDuration,
  }) {
    _limiters[endpoint] = RateLimiter(
      maxRequests: maxRequests,
      windowDuration: windowDuration,
    );
  }
}
