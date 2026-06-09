/// Failure class for representing errors in a functional way.
///
/// This is used in repositories and use cases to represent error states
/// in a type-safe manner without throwing exceptions.
library;

import 'exceptions.dart';

/// Base class for all failures in the application.
///
/// Failures represent errors that can be handled and should be displayed
/// to the user or logged appropriately. This is part of a functional approach
/// to error handling where errors are values, not exceptions.
abstract class Failure {
  /// Creates a [Failure].
  const Failure({required this.message, this.exception});

  /// Human-readable error message.
  final String message;

  /// The underlying exception if one exists.
  final GotchaException? exception;

  @override
  String toString() => message;

  /// Check if this failure represents a specific type.
  bool isType<T extends Failure>() => this is T;

  /// Get the error code if available.
  String? get errorCode => exception?.code;
}

/// Failure representing authentication errors.
class AuthFailure extends Failure {
  /// Creates an [AuthFailure].
  const AuthFailure({required super.message, super.exception});
}

/// Failure representing authorization errors.
class AuthzFailure extends Failure {
  /// Creates an [AuthzFailure].
  const AuthzFailure({required super.message, super.exception});
}

/// Failure representing network errors.
class NetworkFailure extends Failure {
  /// Creates a [NetworkFailure].
  const NetworkFailure({required super.message, super.exception});
}

/// Failure representing server errors.
class ServerFailure extends Failure {
  /// Creates a [ServerFailure].
  const ServerFailure({
    required super.message,
    super.exception,
    this.statusCode,
  });

  /// HTTP status code if available.
  final int? statusCode;
}

/// Failure representing validation errors.
class ValidationFailure extends Failure {
  /// Creates a [ValidationFailure].
  const ValidationFailure({
    required super.message,
    super.exception,
    this.field,
  });

  /// Field that failed validation.
  final String? field;
}

/// Failure representing not found errors.
class NotFoundFailure extends Failure {
  /// Creates a [NotFoundFailure].
  const NotFoundFailure({
    required super.message,
    super.exception,
    this.resourceId,
  });

  /// ID of the resource that was not found.
  final String? resourceId;
}

/// Failure representing cache errors.
class CacheFailure extends Failure {
  /// Creates a [CacheFailure].
  const CacheFailure({required super.message, super.exception});
}

/// Failure representing database errors.
class DatabaseFailure extends Failure {
  /// Creates a [DatabaseFailure].
  const DatabaseFailure({required super.message, super.exception});
}

/// Failure representing conflict errors.
class ConflictFailure extends Failure {
  /// Creates a [ConflictFailure].
  const ConflictFailure({required super.message, super.exception});
}

/// Failure representing platform errors.
class PlatformFailure extends Failure {
  /// Creates a [PlatformFailure].
  const PlatformFailure({required super.message, super.exception});
}

/// Failure representing not implemented errors.
class NotImplementedFailure extends Failure {
  /// Creates a [NotImplementedFailure].
  const NotImplementedFailure({required super.message, super.exception});
}

/// Failure representing rate limit errors.
class RateLimitFailure extends Failure {
  /// Creates a [RateLimitFailure].
  const RateLimitFailure({
    required super.message,
    super.exception,
    this.retryAfterSeconds,
  });

  /// Number of seconds to wait before retrying.
  final int? retryAfterSeconds;
}

/// Generic failure for unknown errors.
class GenericFailure extends Failure {
  /// Creates a [GenericFailure].
  const GenericFailure({required super.message, super.exception});
}
