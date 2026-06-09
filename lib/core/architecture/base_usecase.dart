/// Base use case classes following the Clean Architecture pattern.
///
/// Use cases represent the business rules and are independent of frameworks
/// and UI. They orchestrate data flow from repositories and domain models.
library;

import '../exceptions/failure.dart';
import '../exceptions/result.dart';

/// Base use case that takes no parameters.
///
/// Example:
/// ```dart
/// class GetCurrentUserUseCase extends NoParamUseCase<User, UserFailure> {
///   GetCurrentUserUseCase(this._userRepository);
///
///   final UserRepository _userRepository;
///
///   @override
///   Future<Result<User, UserFailure>> call() async {
///     return _userRepository.getCurrentUser();
///   }
/// }
/// ```
abstract class NoParamUseCase<Success, FailureType extends Failure> {
  /// Execute the use case.
  Future<Result<Success, FailureType>> call();
}

/// Base use case that takes a single parameter.
///
/// Example:
/// ```dart
/// class GetUserByIdUseCase extends UseCase<User, String, UserFailure> {
///   GetUserByIdUseCase(this._userRepository);
///
///   final UserRepository _userRepository;
///
///   @override
///   Future<Result<User, UserFailure>> call(String userId) async {
///     return _userRepository.getUserById(userId);
///   }
/// }
/// ```
abstract class UseCase<Success, Params, FailureType extends Failure> {
  /// Execute the use case with the given parameters.
  Future<Result<Success, FailureType>> call(Params params);
}

/// Base use case that takes multiple parameters.
///
/// Example:
/// ```dart
/// class TransferMoneyParams {
///   final String fromAccountId;
///   final String toAccountId;
///   final double amount;
///
///   TransferMoneyParams({
///     required this.fromAccountId,
///     required this.toAccountId,
///     required this.amount,
///   });
/// }
///
/// class TransferMoneyUseCase extends MultiParamUseCase<void, TransferMoneyParams, TransactionFailure> {
///   @override
///   Future<Result<void, TransactionFailure>> call(TransferMoneyParams params) async {
///     // Implementation
///   }
/// }
/// ```
typedef MultiParamUseCase<S, P, F extends Failure> = UseCase<S, P, F>;

/// Base use case with stream of results.
///
/// Use for operations that produce multiple results over time.
abstract class StreamUseCase<Success, Params, FailureType extends Failure> {
  /// Execute the use case and return a stream of results.
  Stream<Result<Success, FailureType>> call(Params params);
}

/// Base use case that produces no results (fire-and-forget).
///
/// Use for side-effect operations like logging or tracking.
abstract class SideEffectUseCase<Params, FailureType extends Failure> {
  /// Execute the use case.
  Future<Result<void, FailureType>> call(Params params);
}

/// Extension methods for use cases.
extension UseCaseExt<S, F extends Failure> on Future<Result<S, F>> {
  /// Convert the result to a stream (for use with StreamBuilder).
  Stream<Result<S, F>> toStream() async* {
    yield await this;
  }

  /// Execute a callback if successful.
  Future<Result<S, F>> onSuccess(
    Future<void> Function(S value) callback,
  ) async => then((result) async {
    await result.when(success: callback, failure: (_) async {});
    return result;
  });

  /// Execute a callback if failed.
  Future<Result<S, F>> onFailure(
    Future<void> Function(F failure) callback,
  ) async => then((result) async {
    await result.when(success: (_) async {}, failure: callback);
    return result;
  });
}
