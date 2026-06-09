import 'dart:io' show Platform;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../firebase/firestore_bootstrap.dart';
import '../logging/app_logger.dart';
import './analytics_service.dart';
import './notification_service.dart';

/// Service to manage GDPR / CCPA user consents.
/// Persists consent statuses and timestamps in SharedPreferences
/// and updates Firebase SDK collection states dynamically.
class ConsentGateService {
  ConsentGateService._();

  // Keys
  static const _keyPrompted = 'gdpr_consent_prompted';
  static const _keyAnalytics = 'gdpr_consent_analytics';
  static const _keyPerformance = 'gdpr_consent_performance';
  static const _keyPersonalization = 'gdpr_consent_personalization';
  static const _keyDoNotSell = 'ccpa_do_not_sell';

  static const _keyTimestampAnalytics = 'gdpr_consent_analytics_timestamp';
  static const _keyTimestampPerformance = 'gdpr_consent_performance_timestamp';
  static const _keyTimestampPersonalization =
      'gdpr_consent_personalization_timestamp';
  static const _keyTimestampDoNotSell = 'ccpa_do_not_sell_timestamp';

  // ── Getters ────────────────────────────────────────────────────────────────

  /// Checks if the user has been prompted for GDPR consent.
  static Future<bool> hasPromptedForConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPrompted) ?? false;
    } catch (e, stack) {
      AppLogger.e(
          'GDPR Consent: Failed to read hasPromptedForConsent from SharedPreferences',
          e);
      debugPrint('$stack');
      return false;
    }
  }

  /// Checks if the user has granted Analytics consent.
  static Future<bool> hasAnalyticsConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAnalytics) ?? false;
    } catch (e, stack) {
      AppLogger.e(
          'GDPR Consent: Failed to read hasAnalyticsConsent from SharedPreferences',
          e);
      debugPrint('$stack');
      return false;
    }
  }

  /// Grants analytics consent and enables Firebase Analytics collection.
  static Future<void> grantAnalyticsConsent() => setAnalyticsConsent(true);

  /// Revokes analytics consent and disables Firebase Analytics collection.
  static Future<void> revokeAnalyticsConsent() => setAnalyticsConsent(false);

  /// Checks if the user has granted Performance monitoring consent.
  static Future<bool> hasPerformanceConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPerformance) ?? false;
    } catch (e, stack) {
      AppLogger.e(
          'GDPR Consent: Failed to read hasPerformanceConsent from SharedPreferences',
          e);
      debugPrint('$stack');
      return false;
    }
  }

  /// Checks if the user has granted Personalization consent.
  static Future<bool> hasPersonalizationConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPersonalization) ?? false;
    } catch (e, stack) {
      AppLogger.e(
          'GDPR Consent: Failed to read hasPersonalizationConsent from SharedPreferences',
          e);
      debugPrint('$stack');
      return false;
    }
  }

  /// Checks if CCPA "Do Not Sell My Personal Information" is active.
  static Future<bool> isDoNotSellEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyDoNotSell) ?? false;
    } catch (e, stack) {
      AppLogger.e(
          'GDPR Consent: Failed to read isDoNotSellEnabled from SharedPreferences',
          e);
      debugPrint('$stack');
      return false;
    }
  }

  // ── Setters & Updates ──────────────────────────────────────────────────────

  /// Mark the user as having been prompted with the consent gate modal.
  static Future<void> setPromptedForConsent(bool prompted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPrompted, prompted);
      if (prompted) {
        await initializeFirebaseAndDependents();
      }
    } catch (e, stack) {
      AppLogger.e('GDPR Consent: Failed to write prompted consent status', e);
      debugPrint('$stack');
    }
  }

  /// Auxiliary helper to initialize Firebase SDK dynamically at runtime after consent.
  static Future<void> initializeFirebaseAndDependents() async {
    try {
      // Eager check if Firebase is already initialized
      try {
        Firebase.app();
        debugPrint('Firebase already initialized');
        return;
      } catch (_) {
        // App does not exist, so initialize it
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully after consent');

      // Configure Firestore Settings
      try {
        configureFirestore();
      } catch (e) {
        debugPrint('Firestore config error: $e');
      }

      // 1. Crashlytics (Legitimate Interest)
      try {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(true);
        debugPrint('FirebaseCrashlytics collection enabled successfully');
      } catch (e, stack) {
        debugPrint('FirebaseCrashlytics failed to enable: $e');
        debugPrint('$stack');
      }

      // 2. Analytics Consent Check & Apply
      final analyticsConsent = await hasAnalyticsConsent();
      try {
        await FirebaseAnalytics.instance
            .setAnalyticsCollectionEnabled(analyticsConsent);
        debugPrint(
            'FirebaseAnalytics collection enabled set to: $analyticsConsent');
      } catch (e, stack) {
        debugPrint('FirebaseAnalytics failed to set collection enabled: $e');
        debugPrint('$stack');
      }

      // 3. Performance Consent Check & Apply
      final performanceConsent = await hasPerformanceConsent();
      try {
        await FirebasePerformance.instance
            .setPerformanceCollectionEnabled(performanceConsent);
        debugPrint(
            'FirebasePerformance collection enabled set to: $performanceConsent');
      } catch (e, stack) {
        debugPrint('FirebasePerformance failed to set collection enabled: $e');
        debugPrint('$stack');
      }

      // 4. Firebase App Check
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kReleaseMode
              ? AndroidProvider.playIntegrity
              : AndroidProvider.debug,
          appleProvider:
              kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
        );
        debugPrint('FirebaseAppCheck activated successfully');
      } catch (e, stack) {
        debugPrint('FirebaseAppCheck activation failed (non-fatal): $e');
        debugPrint('$stack');
      }

      // 5. Notification Service
      try {
        await NotificationService().initialize();
        debugPrint('NotificationService initialized successfully');
      } catch (e, stack) {
        debugPrint('NotificationService init error: $e');
        debugPrint('$stack');
      }

      // 6. Log app_open if analytics consent is granted
      if (analyticsConsent) {
        try {
          final packageInfo = await PackageInfo.fromPlatform();
          await AnalyticsService.logEvent(
            name: 'app_open',
            parameters: {
              'platform': Platform.operatingSystem,
              'app_version': packageInfo.version,
            },
          );
          debugPrint('Log app_open event successful');
        } catch (e, stack) {
          debugPrint('Failed to log app_open event: $e');
          debugPrint('$stack');
        }
      }

      // 7. Error handlers to Crashlytics
      try {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        debugPrint('FlutterError.onError registered with Crashlytics');
      } catch (e, stack) {
        debugPrint('Failed to set Crashlytics records: $e');
        debugPrint('$stack');
      }

      try {
        PlatformDispatcher.instance.onError = (error, stack) {
          try {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          } catch (err) {
            debugPrint('PlatformDispatcher recordError failed: $err');
          }
          return true;
        };
        debugPrint(
            'PlatformDispatcher.instance.onError registered with Crashlytics');
      } catch (e, stack) {
        debugPrint('Failed to register PlatformDispatcher error handler: $e');
        debugPrint('$stack');
      }
    } catch (e) {
      AppLogger.e('GDPR Consent: Firebase initialization sequence failed', e);
    }
  }

  /// Grants all consents (e.g. "Accept All" button).
  static Future<void> grantAllConsents() async {
    await setAnalyticsConsent(true);
    await setPerformanceConsent(true);
    await setPersonalizationConsent(true);
    await setPromptedForConsent(true);
  }

  /// Revokes/Denies non-essential consents (e.g. "Essential Only" button).
  static Future<void> grantEssentialOnly() async {
    await setAnalyticsConsent(false);
    await setPerformanceConsent(false);
    await setPersonalizationConsent(false);
    await setPromptedForConsent(true);
  }

  /// Updates Analytics Consent and toggles Firebase Analytics SDK at runtime.
  static Future<void> setAnalyticsConsent(bool granted) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAnalytics, granted);
      await prefs.setString(_keyTimestampAnalytics, timestamp);
    } catch (e, stack) {
      AppLogger.e('GDPR Consent: Failed to write Analytics consent status', e);
      debugPrint('$stack');
    }

    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(granted);
      AppLogger.i(
          'GDPR Consent: Firebase Analytics collection set to $granted');
    } catch (e) {
      AppLogger.e(
          'GDPR Consent: Failed to update Firebase Analytics collection', e);
    }
  }

  /// Updates Performance Consent and toggles Firebase Performance SDK at runtime.
  static Future<void> setPerformanceConsent(bool granted) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPerformance, granted);
      await prefs.setString(_keyTimestampPerformance, timestamp);
    } catch (e, stack) {
      AppLogger.e(
          'GDPR Consent: Failed to write Performance consent status', e);
      debugPrint('$stack');
    }

    try {
      await FirebasePerformance.instance
          .setPerformanceCollectionEnabled(granted);
      AppLogger.i(
          'GDPR Consent: Firebase Performance monitoring set to $granted');
    } catch (e) {
      AppLogger.e(
          'GDPR Consent: Failed to update Firebase Performance collection', e);
    }
  }

  /// Updates Personalization Consent.
  static Future<void> setPersonalizationConsent(bool granted) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPersonalization, granted);
      await prefs.setString(_keyTimestampPersonalization, timestamp);
      AppLogger.i('GDPR Consent: Personalization set to $granted');
    } catch (e, stack) {
      AppLogger.e(
          'GDPR Consent: Failed to write Personalization consent status', e);
      debugPrint('$stack');
    }
  }

  /// Updates "Do Not Sell" status.
  static Future<void> setDoNotSell(bool enabled) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDoNotSell, enabled);
      await prefs.setString(_keyTimestampDoNotSell, timestamp);
      AppLogger.i('CCPA: Do Not Sell Personal Info set to $enabled');
    } catch (e, stack) {
      AppLogger.e('GDPR Consent: Failed to write Do Not Sell status', e);
      debugPrint('$stack');
    }
  }

  // ── Timestamp Getters ──────────────────────────────────────────────────────

  /// Get last updated ISO timestamp for Analytics consent.
  static Future<String?> getAnalyticsTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyTimestampAnalytics);
    } catch (e, stack) {
      AppLogger.e('GDPR Consent: Failed to read getAnalyticsTimestamp', e);
      debugPrint('$stack');
      return null;
    }
  }

  /// Get last updated ISO timestamp for Performance consent.
  static Future<String?> getPerformanceTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyTimestampPerformance);
    } catch (e, stack) {
      AppLogger.e('GDPR Consent: Failed to read getPerformanceTimestamp', e);
      debugPrint('$stack');
      return null;
    }
  }

  /// Get last updated ISO timestamp for Personalization consent.
  static Future<String?> getPersonalizationTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyTimestampPersonalization);
    } catch (e, stack) {
      AppLogger.e(
          'GDPR Consent: Failed to read getPersonalizationTimestamp', e);
      debugPrint('$stack');
      return null;
    }
  }

  /// Get last updated ISO timestamp for Do Not Sell consent.
  static Future<String?> getDoNotSellTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyTimestampDoNotSell);
    } catch (e, stack) {
      AppLogger.e('GDPR Consent: Failed to read getDoNotSellTimestamp', e);
      debugPrint('$stack');
      return null;
    }
  }

  /// Resets all consent storage. Useful for testing or account cleanup.
  static Future<void> resetAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPrompted);
      await prefs.remove(_keyAnalytics);
      await prefs.remove(_keyPerformance);
      await prefs.remove(_keyPersonalization);
      await prefs.remove(_keyDoNotSell);
      await prefs.remove(_keyTimestampAnalytics);
      await prefs.remove(_keyTimestampPerformance);
      await prefs.remove(_keyTimestampPersonalization);
      await prefs.remove(_keyTimestampDoNotSell);
    } catch (e, stack) {
      AppLogger.e('GDPR Consent: Failed to resetAll in SharedPreferences', e);
      debugPrint('$stack');
    }
  }
}
