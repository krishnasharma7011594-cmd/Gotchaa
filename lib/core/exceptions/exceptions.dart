/// Core exception classes for the Gotchaa application.
///
/// This file defines all exceptions that can be thrown throughout the app.
/// Following the principle of "fail-fast", exceptions should be specific
/// and provide meaningful context for debugging and user-facing errors.
library;

/// Base exception class for all Gotchaa-specific exceptions.
///
/// All custom exceptions should extend this class to maintain a consistent
/// error handling pattern throughout the application.
abstract class GotchaException implements Exception {
  /// Creates a [GotchaException] with optional metadata.
  const GotchaException({
    required this.message,
    this.code,
    this.stackTrace,
    this.originalException,
  });

  /// Human-readable error message.
  final String message;

  /// Optional error code for categorizing exceptions.
  final String? code;

  /// Stack trace for debugging purposes.
  final StackTrace? stackTrace;

  /// Original exception if this is a wrapper exception.
  final Exception? originalException;

  @override
  String toString() =>
      'GotchaException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when there are authentication-related issues.
///
/// Examples:
/// - Invalid credentials
/// - Token expired
/// - Insufficient permissions
class AuthenticationException extends GotchaException {
  /// Creates an [AuthenticationException].
  const AuthenticationException({
    required super.message,
    String? code,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'AUTH_ERROR');
}

/// Exception thrown when there are authorization-related issues.
///
/// Examples:
/// - User lacks required permissions
/// - Account restrictions
/// - Feature not available in region
class AuthorizationException extends GotchaException {
  /// Creates an [AuthorizationException].
  const AuthorizationException({
    required super.message,
    String? code,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'AUTHZ_ERROR');
}

/// Exception thrown when network-related operations fail.
///
/// Examples:
/// - No internet connection
/// - Request timeout
/// - Connection refused
/// - DNS resolution failure
class NetworkException extends GotchaException {
  /// Creates a [NetworkException].
  const NetworkException({
    required super.message,
    String? code,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'NETWORK_ERROR');
}

/// Exception thrown when server operations fail.
///
/// Examples:
/// - 5xx HTTP status codes
/// - Server unavailable
/// - Internal server error
class ServerException extends GotchaException {
  /// Creates a [ServerException].
  const ServerException({
    required super.message,
    String? code,
    this.statusCode,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'SERVER_ERROR');

  /// HTTP status code if available.
  final int? statusCode;
}

/// Exception thrown when validation of data fails.
///
/// Examples:
/// - Invalid email format
/// - Password doesn't meet requirements
/// - Required field is empty
class ValidationException extends GotchaException {
  /// Creates a [ValidationException].
  const ValidationException({
    required super.message,
    String? code,
    this.field,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'VALIDATION_ERROR');

  /// Field name that failed validation.
  final String? field;
}

/// Exception thrown when resource is not found.
///
/// Examples:
/// - User profile doesn't exist
/// - Content has been deleted
/// - Invalid resource ID
class NotFoundException extends GotchaException {
  /// Creates a [NotFoundException].
  const NotFoundException({
    required super.message,
    String? code,
    this.resourceId,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'NOT_FOUND');

  /// ID of the resource that was not found.
  final String? resourceId;
}

/// Exception thrown when there's a conflict (typically 409 HTTP status).
///
/// Examples:
/// - Duplicate username
/// - Race condition in data update
/// - Incompatible state change
class ConflictException extends GotchaException {
  /// Creates a [ConflictException].
  const ConflictException({
    required super.message,
    String? code,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'CONFLICT');
}

/// Exception thrown when cache operations fail.
///
/// Examples:
/// - Corrupted cache data
/// - Insufficient storage
/// - Cache access denied
class CacheException extends GotchaException {
  /// Creates a [CacheException].
  const CacheException({
    required super.message,
    String? code,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'CACHE_ERROR');
}

/// Exception thrown when database operations fail.
///
/// Examples:
/// - Database connection failure
/// - Query error
/// - Transaction rollback
class DatabaseException extends GotchaException {
  /// Creates a [DatabaseException].
  const DatabaseException({
    required super.message,
    String? code,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'DATABASE_ERROR');
}

/// Exception thrown when platform channel communication fails.
///
/// Examples:
/// - Native method not implemented
/// - Platform channel error
/// - Missing platform capability
class PlatformException extends GotchaException {
  /// Creates a [PlatformException].
  const PlatformException({
    required super.message,
    String? code,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'PLATFORM_ERROR');
}

/// Exception thrown when an operation is not implemented.
///
/// Examples:
/// - Feature not yet implemented
/// - Platform doesn't support operation
class NotImplementedException extends GotchaException {
  /// Creates a [NotImplementedException].
  const NotImplementedException({
    required super.message,
    String? code,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'NOT_IMPLEMENTED');
}

/// Exception thrown for generic/unknown errors.
///
/// Use this only when a more specific exception doesn't apply.
class GenericException extends GotchaException {
  /// Creates a [GenericException].
  const GenericException({
    required super.message,
    String? code,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'GENERIC_ERROR');
}

/// Exception thrown when rate limiting occurs.
///
/// Examples:
/// - Too many requests
/// - API quota exceeded
class RateLimitException extends GotchaException {
  /// Creates a [RateLimitException].
  const RateLimitException({
    required super.message,
    String? code,
    this.retryAfterSeconds,
    super.stackTrace,
    super.originalException,
  }) : super(code: code ?? 'RATE_LIMIT');

  /// Number of seconds to wait before retrying.
  final int? retryAfterSeconds;
}
