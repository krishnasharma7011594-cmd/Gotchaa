/// Code quality and architecture guidelines for the Gotchaa project.
///
/// This document outlines the coding standards, architecture patterns, and best practices
/// that should be followed throughout the Gotchaa application.
///
/// ## Table of Contents
/// 1. Coding Standards
/// 2. Architecture Pattern (Clean Architecture)
/// 3. Error Handling
/// 4. State Management
/// 5. Testing
/// 6. Performance
/// 7. Documentation
/// 8. Common Patterns
///
/// ---
///
/// ## 1. Coding Standards
///
/// ### Naming Conventions
/// - **Classes**: PascalCase (e.g., `UserRepository`, `LoginViewModel`)
/// - **Functions/Methods**: camelCase (e.g., `getUserById()`, `fetchData()`)
/// - **Constants**: lowerCamelCase or UPPER_SNAKE_CASE (e.g., `maxRetries` or `MAX_RETRIES`)
/// - **Variables**: camelCase (e.g., `userName`, `isLoading`)
/// - **Private members**: Leading underscore (e.g., `_internalData`)
///
/// ### Code Organization
/// ```
/// 1. Imports (sorted: dart, flutter, packages, local)
/// 2. Constants
/// 3. Main class/function definition
/// 4. Public methods
/// 5. Private methods
/// 6. Nested classes
/// 7. Extensions
/// ```
///
/// ### Formatting
/// - Use `dart format` for automatic formatting
/// - Line length: 80 characters (enforced by linter)
/// - Use meaningful variable names
/// - Avoid abbreviated names except for well-known patterns
///
/// ---
///
/// ## 2. Architecture Pattern (Clean Architecture)
///
/// The project uses Clean Architecture with the following layers:
///
/// ```
/// UI/Presentation Layer
///  ├── Screens
///  ├── Widgets
///  └── ViewModels
///         ↓
/// Domain Layer
///  ├── Use Cases
///  └── Entities
///         ↓
/// Data Layer
///  ├── Repositories
///  ├── Data Sources
///  └── Models
/// ```
///
/// ### Layer Responsibilities
///
/// **Presentation Layer**: UI components and state management
/// - Screens and widgets for UI
/// - ViewModels for state management
/// - Only knows about domain layer (use cases)
///
/// **Domain Layer**: Business logic and rules
/// - Use cases coordinating data and business logic
/// - Domain entities representing core concepts
/// - No dependencies on external frameworks (except Flutter exceptions)
///
/// **Data Layer**: Data access and management
/// - Repositories providing data abstraction
/// - Remote and local data sources
/// - Data models and DTOs
/// - Data persistence (cache, database)
///
/// ### Example: Implementing a Feature
///
/// ```dart
/// // 1. Create entity/model
/// class User {
///   final String id;
///   final String name;
///   // ...
/// }
///
/// // 2. Create repository interface
/// abstract class UserRepository extends BaseRepository {
///   Future<Result<User, UserFailure>> getUserById(String id);
/// }
///
/// // 3. Create use case
/// class GetUserByIdUseCase extends UseCase<User, String, UserFailure> {
///   GetUserByIdUseCase(this._userRepository);
///   final UserRepository _userRepository;
///
///   @override
///   Future<Result<User, UserFailure>> call(String id) async {
///     return _userRepository.getUserById(id);
///   }
/// }
///
/// // 4. Create view model
/// class UserViewModel extends StateViewModel<User> {
///   UserViewModel(this._getUserByIdUseCase);
///   final GetUserByIdUseCase _getUserByIdUseCase;
///
///   Future<void> loadUser(String id) async {
///     setLoading(true);
///     final result = await _getUserByIdUseCase(id);
///     result.when(
///       success: setState,
///       failure: setError,
///     );
///     setLoading(false);
///   }
/// }
/// ```
///
/// ---
///
/// ## 3. Error Handling
///
/// Use functional error handling with [Result] and [Failure] types:
///
/// ```dart
/// // DON'T: Use exceptions
/// try {
///   final user = await repository.getUser(id); // throws
/// } catch (e) {
///   print('Error: $e'); // loses type information
/// }
///
/// // DO: Use Result types
/// final result = await repository.getUser(id);
/// result.when(
///   success: (user) => print('Got user: \${user.name}'),
///   failure: (failure) => print('Error: \${failure.message}'),
/// );
/// ```
///
/// ### Exception Hierarchy
///
/// All exceptions inherit from [GotchaException]:
/// - `AuthenticationException`: Auth failures
/// - `NetworkException`: Network issues
/// - `ValidationException`: Invalid data
/// - `ServerException`: Server errors
/// - `NotFoundException`: Resource not found
/// - ... and more specific types
///
/// ### Best Practices
/// - Create specific [Failure] types for each repository/use case
/// - Use [Failure] for expected error conditions
/// - Only throw exceptions for truly exceptional cases
/// - Always catch exceptions and convert to [Failure] at boundary
///
/// ---
///
/// ## 4. State Management
///
/// Use [ChangeNotifier] and [Provider] for state management:
///
/// ```dart
/// // Simple state VM
/// class CounterViewModel extends StateViewModel<int> {
///   void increment() => setState((state ?? 0) + 1);
/// }
///
/// // List VM
/// class ItemsViewModel extends ListViewModel<Item> {
///   Future<void> loadItems() async {
///     setLoading(true);
///     final result = await useCase.call();
///     result.when(
///       success: setItems,
///       failure: setError,
///     );
///     setLoading(false);
///   }
/// }
///
/// // Binary VM (success/failure)
/// class LoginViewModel extends BinaryViewModel<AuthToken> {
///   Future<void> login(String email, String password) async {
///     // ...
///     result.when(
///       success: setSuccess,
///       failure: setFailure,
///     );
///   }
/// }
/// ```
///
/// ### ViewModel Lifecycle
/// ```dart
/// class MyScreen extends StatefulWidget {
///   @override
///   State createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen> {
///   late MyViewModel _viewModel;
///
///   @override
///   void initState() {
///     super.initState();
///     _viewModel = MyViewModel()..initialize();
///   }
///
///   @override
///   void dispose() {
///     _viewModel.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ListenableBuilder(
///       listenable: _viewModel,
///       builder: (context, _) => _buildUI(),
///     );
///   }
/// }
/// ```
///
/// ---
///
/// ## 5. Testing
///
/// Write tests for all business logic:
///
/// ```dart
/// void main() {
///   group('GetUserUseCase', () {
///     late MockUserRepository mockRepository;
///     late GetUserUseCase useCase;
///
///     setUp(() {
///       mockRepository = MockUserRepository();
///       useCase = GetUserUseCase(mockRepository);
///     });
///
///     test('returns success with user when repository succeeds', () async {
///       mockRepository.mockGetByIdSuccess('1', testUser);
///
///       final result = await useCase('1');
///
///       expect(result.isSuccess(), true);
///       expect(result.getOrNull(), testUser);
///     });
///
///     test('returns failure when repository fails', () async {
///       mockRepository.mockGetByIdFailure('1', UserFailure(...));
///
///       final result = await useCase('1');
///
///       expect(result.isFailure(), true);
///     });
///   });
/// }
/// ```
///
/// ### Testing Checklist
/// - ✓ Unit test use cases with mocked repositories
/// - ✓ Unit test repositories with mocked data sources
/// - ✓ Widget test screens with relevant ViewModels
/// - ✓ Integration test critical user flows
/// - ✓ Aim for >80% code coverage
///
/// ---
///
/// ## 6. Performance
///
/// Use performance monitoring and optimization tools:
///
/// ```dart
/// // Measure operation timing
/// performanceTracker.measure('fetch_users', () async {
///   return await repository.getUsers();
/// });
///
/// // Debounce search input (wait for user to stop typing)
/// final searchDebouncer = Debouncer(duration: Duration(milliseconds: 500));
/// onSearchChanged(String query) {
///   searchDebouncer(() {
///     search(query);
///   });
/// }
///
/// // Throttle rapid clicks (prevent double-tap)
/// final clickThrottler = Throttler(minInterval: Duration(milliseconds: 500));
/// onPressed() {
///   clickThrottler(() {
///     doAction();
///   });
/// }
///
/// // Cache results to reduce redundant API calls
/// final cache = ExpiringCache<String, User>(ttl: Duration(hours: 1));
/// ```
///
/// ---
///
/// ## 7. Documentation
///
/// Always document public APIs:
///
/// ```dart
/// /// Fetch a user by their ID.
/// ///
/// /// This method queries the remote API and caches the result locally.
/// ///
/// /// Returns a [Result] containing either:
/// /// - [Success] with the [User] object
/// /// - [Failure] with details about why the operation failed
/// ///
/// /// Throws [NetworkException] if there's no internet connection.
/// ///
/// /// Example:
/// /// ```dart
/// /// final result = await repository.getUserById('123');
/// /// result.when(
/// ///   success: (user) => print('Got:\${user.name}'),
/// ///   failure: (err) => print('Error:\${err.message}'),
/// /// );
/// /// ```
/// Future<Result<User, UserFailure>> getUserById(String id);
/// ```
///
/// ---
///
/// ## 8. Common Patterns
///
/// ### Extension Methods
/// Add functionality to existing types:
/// ```dart
/// extension StringHelpers on String {
///   bool get isValidEmail => contains('@') && contains('.');
///   String get trimmed => trim();
/// }
///
/// usage: 'test@example.com'.isValidEmail // -> true
/// ```
///
/// ### Factory Constructors
/// Validate and construct objects:
/// ```dart
/// class Email {
///   Email._(this.value);
///   final String value;
///
///   factory Email(String value) {
///     if (!value.isValidEmail) throw ValidationException('Invalid email');
///     return Email._(value);
///   }
/// }
/// ```
///
/// ### Sealed Classes (Enum-like)
/// Model all states explicitly:
/// ```dart
/// abstract sealed class UiState {}
/// class LoadingState extends UiState {}
/// class SuccessState extends UiState { final Data data; }
/// class ErrorState extends UiState { final String message; }
/// ```
///
/// ---
///
/// ## Code Review Checklist
///
/// Before submitting a PR:
/// - ✓ Code follows naming conventions
/// - ✓ No hardcoded strings (use constants)
/// - ✓ Error handling implemented with [Result]
/// - ✓ Logging added for important events
/// - ✓ Tests written for business logic
/// - ✓ Documentation added for public APIs
/// - ✓ No unused imports or variables
/// - ✓ Code formatted with `dart format`
/// - ✓ Analysis passes (`flutter analyze`)
/// - ✓ Performance considerations addressed
/// - ✓ No print statements (use loggers)
/// - ✓ Magic numbers/strings extracted to constants
///
/// ---
///
/// ## Resources
///
/// - [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
/// - [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
/// - [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
/// - [Provider Pattern](https://pub.dev/packages/provider)
/// - [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)
library;

import 'package:flutter/cupertino.dart' show ChangeNotifier;
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/material.dart' show ChangeNotifier;
import 'package:flutter/widgets.dart' show ChangeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:gotchaa/core/core_barrel.dart'
    show Result, Failure, GotchaException;
import 'package:gotchaa/core/exceptions/exceptions_barrel.dart'
    show Result, Failure, GotchaException;
import 'package:riverpod_annotation/riverpod_annotation.dart' show Provider;
