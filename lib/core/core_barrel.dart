/// Core module providing framework and utilities for the entire application.
///
/// This module contains the foundational layers and utilities needed by all
/// features of the application:
///
/// - **architecture/**: Clean architecture base classes (repositories, use cases, view models)
/// - **constants/**: Application-wide constants and configuration
/// - **exceptions/**: Exception and error handling infrastructure
/// - **logging/**: Structured logging system
/// - **performance/**: Performance monitoring and optimization tools
/// - **security/**: 🔒 Security utilities (validation, rate limiting, token management)
/// - **theme/**: Application theme and styling
/// - **utils/**: Utility functions and extensions
///
/// ## Important Patterns
///
/// ### Error Handling
/// Always use [Result] and [Failure] types for functional error handling instead
/// of exceptions. Exceptions should only be used for truly exceptional cases.
///
/// ### Logging
/// Use [AppLogger] for logging instead of print statements.
/// This enables consistent logging with proper levels and output.
///
/// ### Performance
/// Use [performanceTracker] to measure and monitor performance-critical code sections.
/// Use [Debouncer] and [Throttler] for rate-limiting operations.
///
/// ### Security
/// CRITICAL: Always import [security_barrel.dart] and use:
/// - [InputValidator] for input validation
/// - [RateLimitingService] for rate limiting
/// - [ApiKeyManager] & [BearerTokenManager] for secure token management
/// - Security interceptors with Dio for API protection
///
/// ### State Management
/// Extend [BaseViewModel], [StateViewModel], or [ListViewModel] for consistent UI state management.
export 'architecture/architecture_barrel.dart';
export 'constants/app_constants.dart';
export 'exceptions/exceptions_barrel.dart';
export 'logging/logging_barrel.dart';
export 'performance/performance_barrel.dart';
export 'security/security_barrel.dart';
export 'theme/app_colors.dart';
export 'utils/extensions/extensions_barrel.dart';
