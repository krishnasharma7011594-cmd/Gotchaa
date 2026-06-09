/// Secure API key and token management.
///
/// ⚠️ SECURITY CRITICAL:
/// - NEVER hardcode API keys in source code
/// - ALWAYS use environment variables or secure configuration
/// - Rotate keys regularly (recommended: every 90 days)
/// - Use different keys for development, staging, and production
/// - Store secrets in platform-specific secure storage:
///   - iOS: Keychain
///   - Android: Keystore / EncryptedSharedPreferences
///   - Web: Secure cookies only
/// - Monitor for key exposure (check GitHub, AWS, etc.)
library;

import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API configuration from environment or secure storage.
class ApiKeyManager {
  factory ApiKeyManager() => _instance;

  ApiKeyManager._internal()
    : _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          keyCipherAlgorithm:
              KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );

  /// Singleton instance
  static final ApiKeyManager _instance = ApiKeyManager._internal();

  final FlutterSecureStorage _secureStorage;

  // ⚠️ SECURITY: These should come from environment variables, NOT hardcoded!
  // In production, these should be injected at build time or runtime
  static const String _defaultApiBaseUrl = 'https://api.gotchaa.app/v1';

  // Cache for loaded keys (short-lived)
  final Map<String, _CachedSecret> _secretCache = {};
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Initialize API keys from secure storage.
  /// Call this during app startup.
  Future<void> initialize() async {
    // Load all secrets in parallel
    await Future.wait([
      _loadAndCacheSecret('api_key'),
      _loadAndCacheSecret('app_id'),
      _loadAndCacheSecret('firebase_api_key'),
    ]);
  }

  /// Get the API base URL.
  ///
  /// This should be configured per environment:
  /// - Development: http://localhost:3000 (for testing)
  /// - Staging: https://staging-api.gotchaa.app
  /// - Production: https://api.gotchaa.app
  String getApiBaseUrl() {
    // In a real app, this would load from environment configuration
    // Example:
    // final buildFlavor = const String.fromEnvironment('BUILD_FLAVOR', defaultValue: 'production');
    // return const {
    //   'development': 'http://localhost:3000',
    //   'staging': 'https://staging-api.gotchaa.app',
    //   'production': 'https://api.gotchaa.app',
    // }[buildFlavor] ?? _defaultApiBaseUrl;

    return _defaultApiBaseUrl;
  }

  /// Get API key securely.
  ///
  /// ⚠️ SECURITY:
  /// - Keys should never be logged or exposed
  /// - Only load when needed
  /// - Use short-lived tokens (JWT with expiration)
  Future<String?> getApiKey() async => _getSecret('api_key');

  /// Get Firebase API key.
  ///
  /// ⚠️ SECURITY: Firebase API key has limited permissions
  /// (compared to service account keys). Even if exposed,
  /// it can only access public APIs and your Firebase project.
  /// Store service account keys ONLY on the backend.
  Future<String?> getFirebaseApiKey() async => _getSecret('firebase_api_key');

  /// Get app ID.
  Future<String?> getAppId() async => _getSecret('app_id');

  /// Store an API key securely.
  ///
  /// Use only for initial setup or key rotation.
  /// ⚠️ SECURITY: Ensure this is only called from secure contexts.
  Future<void> setApiKey(String key) async {
    await _setSecret('api_key', key);
    _secretCache.remove('api_key');
  }

  /// Check if a secret exists.
  Future<bool> hasSecret(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      return value != null;
    } catch (_) {
      return false;
    }
  }

  /// Clear stored API keys (use on logout).
  ///
  /// This removes all cached and stored credentials.
  Future<void> clearSecrets() async {
    _secretCache.clear();
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      // Log error but don't fail
      
    }
  }

  /// Rotate API key (admin feature).
  ///
  /// ⚠️ SECURITY: This should be part of regular maintenance.
  /// Recommended rotation: Every 90 days
  Future<void> rotateApiKey(String newKey) async {
    // Verify new key format before storing
    if (newKey.isEmpty || newKey.length < 20) {
      throw ArgumentError('Invalid API key format');
    }

    await _setSecret('api_key', newKey);
    _secretCache.remove('api_key');
  }

  // ==================== Private Helpers ====================

  /// Load a secret from secure storage.
  Future<String?> _getSecret(String key) async {
    // Check cache first
    final cached = _secretCache[key];
    if (cached != null && !cached.isExpired) {
      return cached.value;
    }

    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) {
        _secretCache[key] = _CachedSecret(value);
      }
      return value;
    } on Exception {
      
      return null;
    }
  }

  /// Load and cache a secret.
  Future<void> _loadAndCacheSecret(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) {
        _secretCache[key] = _CachedSecret(value);
      }
    } catch (e) {
      
    }
  }

  /// Set a secret in secure storage.
  Future<void> _setSecret(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } on Exception {
      
      rethrow;
    }
  }
}

/// Cached secret with expiration.
class _CachedSecret {
  _CachedSecret(this.value) : timestamp = DateTime.now();

  final String value;
  final DateTime timestamp;

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(hours: 1);
}

/// Bearer token management for authenticated requests.
class BearerTokenManager {
  factory BearerTokenManager() => _instance;

  BearerTokenManager._internal();

  /// Singleton instance
  static final BearerTokenManager _instance = BearerTokenManager._internal();

  String? _currentToken;
  String? _refreshToken;
  DateTime? _tokenExpiresAt;

  static const String _bearerTokenKey = 'bearer_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiresKey = 'token_expires_at';

  /// Set authentication tokens.
  ///
  /// [accessToken]: Short-lived token (usually JWT, expires in 15-60 minutes)
  /// [refreshToken]: Long-lived token (usually expires in 7-30 days)
  /// [expiresIn]: Token validity duration from now
  Future<void> setTokens({
    required String accessToken,
    required Duration expiresIn,
    String? refreshToken,
  }) async {
    if (accessToken.isEmpty) {
      throw ArgumentError('Access token cannot be empty');
    }

    _currentToken = accessToken;
    _refreshToken = refreshToken ?? _refreshToken;
    _tokenExpiresAt = DateTime.now().add(expiresIn);

    // Store securely (don't use SharedPreferences for tokens!)
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        encryptedSharedPreferences: true,
      ),
    );

    try {
      await secureStorage.write(key: _bearerTokenKey, value: accessToken);

      if (refreshToken != null) {
        await secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }

      if (_tokenExpiresAt != null) {
        await secureStorage.write(
          key: _tokenExpiresKey,
          value: _tokenExpiresAt!.toIso8601String(),
        );
      }
    } catch (e) {
      
      rethrow;
    }
  }

  /// Get current access token if valid.
  ///
  /// Returns null if token doesn't exist or has expired.
  Future<String?> getAccessToken() async {
    if (_currentToken != null && !_isTokenExpired()) {
      return _currentToken;
    }

    // Try to load from secure storage
    try {
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          keyCipherAlgorithm:
              KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
          encryptedSharedPreferences: true,
        ),
      );

      _currentToken = await secureStorage.read(key: _bearerTokenKey);
      final expiresStr = await secureStorage.read(key: _tokenExpiresKey);

      if (expiresStr != null) {
        _tokenExpiresAt = DateTime.parse(expiresStr);
      }

      if (_currentToken != null && !_isTokenExpired()) {
        return _currentToken;
      }
    } catch (e) {
      
    }

    return null;
  }

  /// Get refresh token.
  Future<String?> getRefreshToken() async {
    if (_refreshToken != null) {
      return _refreshToken;
    }

    try {
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      _refreshToken = await secureStorage.read(key: _refreshTokenKey);
      return _refreshToken;
    } catch (e) {
      
      return null;
    }
  }

  /// Clear all tokens (on logout).
  Future<void> clearTokens() async {
    _currentToken = null;
    _refreshToken = null;
    _tokenExpiresAt = null;

    try {
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      await secureStorage.delete(key: _bearerTokenKey);
      await secureStorage.delete(key: _refreshTokenKey);
      await secureStorage.delete(key: _tokenExpiresKey);
    } catch (e) {
      
    }
  }

  /// Check if access token is expired.
  bool _isTokenExpired() {
    if (_tokenExpiresAt == null) return true;
    return DateTime.now().isAfter(_tokenExpiresAt!);
  }

  /// Check if token needs refresh (expires within 5 minutes).
  bool shouldRefreshToken() {
    if (_tokenExpiresAt == null) return true;
    final threshold = DateTime.now().add(const Duration(minutes: 5));
    return threshold.isAfter(_tokenExpiresAt!);
  }
}

/// Environment configuration.
///
/// Store build-time configuration here instead of in code.
class EnvironmentConfig {
  // ⚠️ SECURITY: These should be injected at build time or loaded from config files
  // Never hardcode environment URLs
  static bool get isDevelopment =>
      const bool.fromEnvironment('IS_DEV', defaultValue: false);
  static bool get isStaging =>
      const bool.fromEnvironment('IS_STAGING', defaultValue: false);
  static bool get isProduction =>
      const bool.fromEnvironment('IS_PROD', defaultValue: true);

  /// Get API endpoint for current environment.
  static String getApiEndpoint() {
    if (isDevelopment) {
      return 'http://localhost:3000/api';
    } else if (isStaging) {
      return 'https://staging-api.gotchaa.app/api';
    } else {
      return 'https://api.gotchaa.app/api';
    }
  }

  /// Whether to log sensitive data (disabled in production).
  static bool get enableSensitiveLogging => isDevelopment;

  /// Whether to report errors to service (enabled in production).
  static bool get enableErrorReporting => !isDevelopment;
}
