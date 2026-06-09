/// Result type for functional error handling.
///
/// A Result is either a Success with an associated value, or a Failure.
/// This allows for composable, type-safe error handling without exceptions.
///
/// Example:
/// ```dart
/// Result<User, AuthFailure> result = await authRepository.login(email, password);
/// result.when(
///   success: (user) =>
/// ```
library;

import 'failure.dart';

/// A Result is either a [Success] or a [Error].
///
/// Use [when] or [map] to pattern match on the result.
/// Use [getOrNull] to extract the value if it exists.
abstract class Result<S, F extends Failure> {
  /// Create a success result.
  factory Result.success(S value) = Success<S, F>;

  /// Create a failure result.
  factory Result.failure(F failure) = Error<S, F>;

  /// Pattern match on this result.
  ///
  /// One of the callbacks will be invoked depending on whether this
  /// is a success or failure.
  T when<T>({
    required T Function(S success) success,
    required T Function(F failure) failure,
  });

  /// Transform the success value if present.
  Result<T, F> map<T>(T Function(S value) transform);

  /// Transform the failure if present.
  Result<S, T> mapFailure<T extends Failure>(T Function(F failure) transform);

  /// Flat map (chain) results together.
  ///
  /// If this result is a success, applies the function to get a new result.
  /// If this result is a failure, returns this failure unchanged.
  Result<T, F> flatMap<T>(Result<T, F> Function(S success) transform);

  /// Get the success value, or null if this is a failure.
  S? getOrNull();

  /// Get the failure, or null if this is a success.
  F? getFailureOrNull();

  /// Get the success value, or a default value if this is a failure.
  S getOrElse(S defaultValue);

  /// Execute a side effect function if this is a success.
  Result<S, F> doOnSuccess(void Function(S value) action);

  /// Execute a side effect function if this is a failure.
  Result<S, F> doOnFailure(void Function(F failure) action);

  /// Recover from a failure with a success value.
  Result<S, F> recover(S Function(F failure) transform);

  /// Check if this is a success without extracting the value.
  bool isSuccess();

  /// Check if this is a failure without extracting the value.
  bool isFailure();
}

/// A successful result containing a value of type [S].
class Success<S, F extends Failure> implements Result<S, F> {
  /// Creates a [Success] with the given value.
  const Success(this.value);

  /// The successful value.
  final S value;

  @override
  T when<T>({
    required T Function(S p1) success,
    required T Function(F p1) failure,
  }) =>
      success(value);

  @override
  Result<T, F> map<T>(T Function(S value) transform) =>
      Success<T, F>(transform(value));

  @override
  Result<S, T> mapFailure<T extends Failure>(T Function(F failure) transform) =>
      Success<S, T>(value);

  @override
  Result<T, F> flatMap<T>(Result<T, F> Function(S value) transform) =>
      transform(value);

  @override
  S? getOrNull() => value;

  @override
  F? getFailureOrNull() => null;

  @override
  S getOrElse(S defaultValue) => value;

  @override
  Result<S, F> doOnSuccess(void Function(S value) action) {
    action(value);
    return this;
  }

  @override
  Result<S, F> doOnFailure(void Function(F failure) action) => this;

  @override
  Result<S, F> recover(S Function(F failure) transform) => this;

  @override
  bool isSuccess() => true;

  @override
  bool isFailure() => false;

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<S, F> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// A failed result containing a failure of type [F].
class Error<S, F extends Failure> implements Result<S, F> {
  /// Creates a [Error] with the given failure.
  const Error(this.failure);

  /// The failure value.
  final F failure;

  @override
  T when<T>({
    required T Function(S p1) success,
    required T Function(F p1) failure,
  }) =>
      failure(this.failure);

  @override
  Result<T, F> map<T>(T Function(S value) transform) => Error<T, F>(failure);

  @override
  Result<S, T> mapFailure<T extends Failure>(
    T Function(F failure) transform,
  ) =>
      Error<S, T>(transform(failure));

  @override
  Result<T, F> flatMap<T>(Result<T, F> Function(S value) transform) =>
      Error<T, F>(failure);

  @override
  S? getOrNull() => null;

  @override
  F? getFailureOrNull() => failure;

  @override
  S getOrElse(S defaultValue) => defaultValue;

  @override
  Result<S, F> doOnSuccess(void Function(S value) action) => this;

  @override
  Result<S, F> doOnFailure(void Function(F failure) action) {
    action(failure);
    return this;
  }

  @override
  Result<S, F> recover(S Function(F failure) transform) =>
      Success<S, F>(transform(failure));

  @override
  bool isSuccess() => false;

  @override
  bool isFailure() => true;

  @override
  String toString() => 'Error(${failure.message})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Error<S, F> && other.failure == failure;
  }

  @override
  int get hashCode => failure.hashCode;
}

/// Extension methods for building Result types more ergonomically.
extension ResultExt<S, F extends Failure> on Result<S, F> {
  /// Fold the result into a single value.
  ///
  /// Applies different transformations depending on success or failure.
  T fold<T>(T Function(F failure) onFailure, T Function(S success) onSuccess) =>
      when(success: onSuccess, failure: onFailure);

  /// Convert this result to an Either-like structure if needed.
  /// Returns the first element as left (failure) or second as right (success).
  (F?, S?) toTuple() => when(
        success: (value) => (null, value),
        failure: (failure) => (failure, null),
      );
}

/// Extension for wrapping async functions that may throw.
extension FutureResultExt<S, F extends Failure> on Future<Result<S, F>> {
  /// Handle errors that might occur during the future.
  Future<Result<S, F>> handleError(
    F Function(Object error, StackTrace stackTrace) handleError,
  ) async {
    try {
      return await this;
    } on Exception catch (e, stackTrace) {
      return Error<S, F>(handleError(e, stackTrace));
    }
  }
}
