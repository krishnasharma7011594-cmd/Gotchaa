/// Application-wide constants and configuration values.
///
/// Centralize all magic strings, numbers, and configuration values here
/// to make changes easier and avoid duplication.
library;

/// API configuration constants.
class ApiConfig {
  /// Base URL for API endpoints.
  static const String baseUrl = 'https://api.gotchaa.app/v1';

  /// API timeout duration.
  static const Duration timeout = Duration(seconds: 30);

  /// Maximum retry attempts for failed requests.
  static const int maxRetries = 3;

  /// Delay between retries (exponential backoff will multiply this).
  static const Duration retryDelay = Duration(seconds: 1);
}

/// Legal and compliance configuration.
class LegalConfig {
  /// Current version of the Terms of Service.
  static const String termsVersion = 'v3.0';

  /// Current version of the Privacy Policy.
  static const String privacyVersion = 'v3.0';

  /// Policy effective label shown in Legal Hub.
  static const String effectiveLabel = 'May 2026';

  /// Public URL base for sharing legal document links.
  static const String legalUrlBase = 'https://gotchaa.app/legal';
}

/// Default values for various features.
class Defaults {
  /// Default page size for paginated lists.
  static const int defaultPageSize = 20;

  /// Maximum page size to prevent excessive data loading.
  static const int maxPageSize = 100;

  /// Cache duration before data is considered stale.
  static const Duration cacheDuration = Duration(hours: 1);

  /// Debounce duration for search queries.
  static const Duration searchDebounce = Duration(milliseconds: 500);

  /// Animation duration for standard transitions.
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Long animation duration for complex transitions.
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
}

/// Size constants for UI dimensions.
class UISize {
  // Padding and margin
  static const double paddingXSmall = 4;
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;
  static const double paddingXLarge = 32;

  // Border radius
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;

  // Icon sizes
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
  static const double iconXLarge = 48;

  // Button heights
  static const double buttonHeightSmall = 36;
  static const double buttonHeightMedium = 44;
  static const double buttonHeightLarge = 52;

  // Avatar sizes
  static const double avatarSmall = 32;
  static const double avatarMedium = 48;
  static const double avatarLarge = 64;
}

/// Feature flags for conditional feature enablement.
class FeatureFlags {
  /// Whether to enable remote config.
  static const bool enableRemoteConfig = true;

  /// Whether to enable analytics.
  static const bool enableAnalytics = true;

  /// Whether to enable crash reporting.
  static const bool enableCrashReporting = true;

  /// Whether to enable offline mode.
  static const bool enableOfflineMode = true;

  /// Whether to enable push notifications.
  static const bool enablePushNotifications = true;

  /// Whether to enable dark mode.
  static const bool enableDarkMode = true;

  /// Whether to enable experimental features.
  static const bool enableExperimental = false;
}

/// Route/screen names used for navigation.
class RouteNames {
  static const String splash = '/splash';
  static const String languageSelection = '/language-selection';
  static const String login = '/login';
  static const String profileSetup = '/profile-setup';
  static const String interestSelection = '/interest-selection';
  static const String mainShell = '/main-shell';
  static const String home = 'home';
  static const String explore = 'explore';
  static const String create = 'create';
  static const String chat = 'chat';
  static const String wallet = 'wallet';
  static const String notifications = 'notifications';
  static const String profile = 'profile';
  static const String karma = 'karma';
  static const String settings = 'settings';

  static const String vybz = 'vybz';
}

/// Storage keys for local persistence.
class StorageKeys {
  // User data
  static const String currentUser = 'current_user';
  static const String userToken = 'user_token';
  static const String userPreferences = 'user_preferences';

  // App data
  static const String appLanguage = 'app_language';
  static const String appTheme = 'app_theme';
  static const String lastKnownLocation = 'last_known_location';

  // Cache keys
  static const String cachedUsers = 'cached_users';
  static const String cachedPosts = 'cached_posts';
  static const String cachedNotifications = 'cached_notifications';

  // Settings
  static const String notificationsEnabled = 'notifications_enabled';
  static const String darkModeEnabled = 'dark_mode_enabled';
  static const String autoPlayVideos = 'auto_play_videos';

  // Legal
  static const String termsAcceptedVersion = 'terms_accepted_version';
  static const String privacyAcceptedVersion = 'privacy_accepted_version';
  static const String legalAcceptedTimestamp = 'legal_accepted_timestamp';
}

/// Error message templates.
class ErrorMessages {
  static const String networkError =
      'Unable to connect. Check your internet connection.';
  static const String serverError =
      'Something went wrong. Please try again later.';
  static const String authError = 'Please log in to continue.';
  static const String permissionError =
      'You don\'t have permission to do this.';
  static const String notFoundError = 'The requested item was not found.';
  static const String validationError =
      'Please check your input and try again.';
  static const String unknownError = 'An unexpected error occurred.';
  static const String timeout = 'Request timed out. Please try again.';
  static const String offline = 'You appear to be offline.';
}

/// Success message templates.
class SuccessMessages {
  static const String saved = 'Saved successfully!';
  static const String deleted = 'Deleted successfully!';
  static const String updated = 'Updated successfully!';
  static const String created = 'Created successfully!';
  static const String loggedOut = 'Logged out successfully!';
}

/// Environment configuration.
enum Environment { development, staging, production }

/// Get current environment.
Environment get currentEnvironment {
  const environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  switch (environment) {
    case 'prod':
      return Environment.production;
    case 'stage':
      return Environment.staging;
    default:
      return Environment.development;
  }
}

/// Check if we're in debug mode.
bool get isDebugMode {
  const bool inDebugMode = bool.fromEnvironment('dart.vm.product') == false;
  return inDebugMode;
}

/// App version and build info.
class AppVersion {
  /// Current app version (e.g. "1.0.0").
  static const String version = '1.0.0';

  /// Current build number.
  static const int buildNumber = 1;

  /// Full version string with build info.
  static const String fullVersion = '$version+$buildNumber';
}
