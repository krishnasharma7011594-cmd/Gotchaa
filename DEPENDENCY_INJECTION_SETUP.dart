/// Dependency Injection Setup Guide
///
/// This file provides a template for setting up the dependency injection
/// container using the get_it package. This ensures all dependencies are
/// properly instantiated and injected throughout the application.
///
/// To use this:
/// 1. Create lib/core/di/service_locator.dart
/// 2. Copy the pattern shown below
/// 3. Add getIt initialization to main() before runApp()
/// 4. Implement instance creation for each feature's repositories and use cases

library;

/*

// ============================================================================
// FILE: lib/core/di/service_locator.dart
// ============================================================================

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import all repositories, use cases, and data sources
// import '../repositories/...';
// import '../data_sources/...';

/// Global service locator instance
final getIt = GetIt.instance;

/// Setup function to initialize all dependencies
Future<void> setupServiceLocator() async {
  // =========================================================================
  // EXTERNAL DEPENDENCIES
  // =========================================================================

  /// HTTP Client
  getIt.registerSingleton<Dio>(
    Dio(
      BaseOptions(
        baseUrl: 'https://api.gotchaa.app/v1',
        connectTimeout: Duration(seconds: 30),
        receiveTimeout: Duration(seconds: 30),
      ),
    )..interceptors.addAll([
      // Add logging interceptor
      LoggerInterceptor(),
      // Add retry interceptor
      RetryInterceptor(retries: 3),
      // Add error handling interceptor
      ErrorHandlerInterceptor(),
    ]),
  );

  /// Local Storage
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // =========================================================================
  // DATA SOURCES
  // =========================================================================

  /// User Profile Data Sources
  getIt.registerSingleton<UserProfileRemoteDataSource>(
    UserProfileRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerSingleton<UserProfileLocalDataSource>(
    UserProfileLocalDataSourceImpl(getIt<SharedPreferences>()),
  );

  // =========================================================================
  // REPOSITORIES
  // =========================================================================

  /// User Profile Repository
  getIt.registerSingleton<UserProfileRepository>(
    UserProfileRepositoryImpl(
      remoteDataSource: getIt<UserProfileRemoteDataSource>(),
      localDataSource: getIt<UserProfileLocalDataSource>(),
    ),
  );

  // =========================================================================
  // USE CASES
  // =========================================================================

  /// User Profile Use Cases
  getIt.registerSingleton<GetUserProfileUseCase>(
    GetUserProfileUseCase(getIt<UserProfileRepository>()),
  );

  getIt.registerSingleton<UpdateUserProfileUseCase>(
    UpdateUserProfileUseCase(getIt<UserProfileRepository>()),
  );

  getIt.registerSingleton<FollowUserUseCase>(
    FollowUserUseCase(getIt<UserProfileRepository>()),
  );

  // =========================================================================
  // VIEW MODELS
  // =========================================================================

  /// Register view models as singletons or factories
  /// Use registerSingleton for app-level state (e.g., auth)
  /// Use registerFactory for screen-level state

  getIt.registerFactory<UserProfileViewModel>(
    () => UserProfileViewModel(
      getUserProfileUseCase: getIt<GetUserProfileUseCase>(),
      updateUserProfileUseCase: getIt<UpdateUserProfileUseCase>(),
      followUserUseCase: getIt<FollowUserUseCase>(),
    ),
  );

  /// Print setup completed
  logInfo('Service Locator initialized successfully');
}

/// Cleanup function to dispose resources
Future<void> cleanupServiceLocator() async {
  await getIt.reset();
}

// ============================================================================
// USAGE IN MAIN
// ============================================================================

// import 'core/di/service_locator.dart';
// import 'main.dart';

/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator
  await setupServiceLocator();

  // Run app
  runApp(const GotchaApp());
}
*/

// ============================================================================
// USAGE IN SCREENS
// ============================================================================

/*
class UserProfileScreen extends StatefulWidget {
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late UserProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Get view model from service locator (factory creates new instance)
    _viewModel = getIt<UserProfileViewModel>();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // ... build method
}
*/

// ============================================================================
// BEST PRACTICES
// ============================================================================

/*
1. SINGLETON vs FACTORY
   - registerSingleton: Use for stateless services or app-level state
     Examples: API client, Database, Repository, Authentication service
   
   - registerFactory: Use for screen/widget-level state
     Examples: ViewModels, form state, temporary data
   
   - registerLazySingleton: Use for expensive initialization
     Initialized only on first access

2. INITIALIZATION ORDER
   By default, dependencies are initialized in registration order.
   External dependencies should be registered first:
   1. External clients (Dio, SharedPreferences, etc.)
   2. Data sources
   3. Repositories
   4. Use cases
   5. ViewModels

3. ASYNC INITIALIZATION
   If any setup is async (like reading from SharedPreferences),
   wrap it in an async function and call it in main():
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await setupServiceLocator();
     runApp(const MyApp());
   }

4. CLEARING RESOURCES
   Always call cleanupServiceLocator() on app shutdown:
   
   void dispose() {
     cleanupServiceLocator();
     super.dispose();
   }

5. AVOIDING CIRCULAR DEPENDENCIES
   Keep dependency flow unidirectional:
   ViewModels → Use Cases → Repositories → Data Sources
   Never have a data source depend on a view model!

6. TESTING WITH SERVICE LOCATOR
   Reset the service locator before each test:
   
   setUp(() {
     getIt.reset();
     setupMockServiceLocator(); // Setup mocks instead
   });

7. ACCESSING DEPENDENCIES
   Always use getIt to retrieve dependencies:
   
   final userRepo = getIt<UserProfileRepository>();
   final getUserUC = getIt<GetUserProfileUseCase>();

*/

// ============================================================================
// INTERCEPTOR EXAMPLES
// ============================================================================

/*
class LoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logDebug('HTTP Request: \${options.method} \${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logError('HTTP Error: \${err.message}');
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logDebug('HTTP Response: \${response.statusCode}');
    super.onResponse(response, handler);
  }
}

class ErrorHandlerInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle unauthorized - refresh token or logout
      logError('Unauthorized access');
    } else if (err.response?.statusCode == 429) {
      // Handle rate limiting
      logWarning('Rate limited');
    }
    super.onError(err, handler);
  }
}

class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.retries = 3});
  final int retries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (isRetryable(err) && retries > 0) {
      await Future.delayed(Duration(seconds: 1));
      // Retry the request
    } else {
      super.onError(err, handler);
    }
  }

  bool isRetryable(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.unknown ||
        (err.response?.statusCode ?? 0) >= 500;
  }
}
*/

// ============================================================================
// FILE STRUCTURE
// ============================================================================

/*
lib/core/
├── di/
│   ├── service_locator.dart     ← Main DI setup
│   └── interceptors.dart         ← Dio interceptors (optional)
├── ...rest of core
*/

*/
