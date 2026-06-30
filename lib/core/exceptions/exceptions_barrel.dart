/// Exception handling and error management utilities.
///
/// ## Exception Hierarchy
/// All exceptions inherit from [GotchaException] for consistent error handling.
/// Specific exception types should be used to categorize different error scenarios.
///
/// ## Failures and Results
/// For functional error handling, use [Failure] and [Result] types instead of
/// throwing exceptions. This provides type-safe, composable error handling.
///
/// ## Usage Examples
///
/// ### Using Exceptions (for truly exceptional cases):
/// ```dart
/// try {
///   await repository.fetchUser(id);
/// } on AuthenticationException catch (e) {
///   showSnackBar('Please log in again: ${e.message}');
/// } on NetworkException catch (e) {
///   showSnackBar('No internet connection');
/// } catch (e) {
///   showSnackBar('Something went wrong');
/// }
/// ```
///
/// ### Using Results (recommended for error paths):
/// ```dart
/// final Result<User, AuthFailure> result = await repository.fetchUser(id);
/// result.when(
///   success: (user) =>
/// ```
library;

export 'exceptions.dart';
export 'failure.dart';
export 'result.dart';
