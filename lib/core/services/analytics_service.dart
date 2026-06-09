import 'package:firebase_analytics/firebase_analytics.dart';
import '../logging/app_logger.dart';
import 'consent_gate_service.dart';

/// Central analytics service for GOTCHAA.
///
/// All custom event tracking lives here — nowhere else.
/// This makes it trivial to switch analytics providers later (e.g. Mixpanel)
/// without hunting calls through the entire codebase.
///
/// EVENTS LOGGED:
///   1.  app_open                — every cold start (Firebase logs this auto)
///   2.  sign_up_complete        — user finishes full registration flow
///   3.  login_success           — successful sign-in (email or Google)
///   4.  onboarding_complete     — user lands on home feed for the first time
///   5.  first_post_created      — user creates their very first post
///   6.  first_message_sent      — user sends their first chat message
///   7.  vybz_created            — user uploads a Vybz short video
///   8.  match_found             — VibeTalk finds a language match
///   9.  tip_sent                — user sends a Vybz tip
///  10.  language_switched       — user changes their app language
///  11.  invite_sent             — user shares their invite code
///  12.  profile_completed       — user fills username + photo + bio
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ── Private helper ─────────────────────────────────────────────────────────

  static Future<void> _log(
    String name, {
    Map<String, Object>? params,
  }) async {
    if (!await ConsentGateService.hasAnalyticsConsent()) return;
    try {
      await _analytics.logEvent(name: name, parameters: params);
      AppLogger.i('Analytics: $name ${params ?? ''}');
    } catch (e) {
      // Never crash the app because of analytics
      AppLogger.e('Analytics: failed to log $name', e);
    }
  }

  /// Generic event logger for special cases.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) =>
      _log(name, params: parameters);

  // ── 1. App Open ────────────────────────────────────────────────────────────
  // Firebase logs app_open automatically. Call this for our custom session
  // tracking with extra context.
  static Future<void> logAppOpen({String? userId}) => _log(
        'gotchaa_session_start',
        params: userId != null ? {'user_id_present': 1} : null,
      );

  // ── 2. Sign Up Complete ────────────────────────────────────────────────────
  /// Call when user completes the full registration and lands on home.
  static Future<void> logSignUpComplete({
    required String method, // 'email' | 'google' | 'apple'
  }) =>
      _log('sign_up_complete', params: {'method': method});

  // ── 3. Login Success ───────────────────────────────────────────────────────
  /// Call on every successful sign-in.
  static Future<void> logLoginSuccess({
    required String method, // 'email' | 'google' | 'apple'
  }) =>
      _log('login_success', params: {'method': method});

  // ── 4. Onboarding Complete ─────────────────────────────────────────────────
  /// Call when new user passes all gates and lands on home feed for the
  /// first time (hasPickedLanguage + legalAccepted + ageVerified).
  static Future<void> logOnboardingComplete({
    required String language,
  }) =>
      _log('onboarding_complete', params: {'selected_language': language});

  // ── 5. First Post Created ──────────────────────────────────────────────────
  /// Call immediately after a new post is successfully uploaded.
  static Future<void> logFirstPostCreated({
    required String postType, // 'text' | 'image' | 'video'
  }) =>
      _log('first_post_created', params: {'post_type': postType});

  // ── 6. Post Created (general) ─────────────────────────────────────────────
  /// Call on every post (Firebase auto-limits to prevent spam).
  static Future<void> logPostCreated({
    required String postType,
  }) =>
      _log('post_created', params: {'post_type': postType});

  // ── 7. First Message Sent ─────────────────────────────────────────────────
  /// Call when a user sends their very first chat message ever.
  static Future<void> logFirstMessageSent() => _log('first_message_sent');

  // ── 8. Message Sent (general) ─────────────────────────────────────────────
  static Future<void> logMessageSent({
    required String type, // 'text' | 'image' | 'audio' | 'gif'
  }) =>
      _log('message_sent', params: {'message_type': type});

  // ── 9. Vybz Created ───────────────────────────────────────────────────────
  /// Call when a Vybz video is successfully uploaded.
  static Future<void> logVybzCreated({
    required int durationSeconds,
  }) =>
      _log('vybz_created', params: {'duration_seconds': durationSeconds});

  // ── 10. Match Found (VibeTalk) ─────────────────────────────────────────────
  /// Call when VibeTalk's matchmaking algorithm finds a language match.
  static Future<void> logMatchFound({
    String? matchedLanguage,
    int? waitTimeSeconds,
  }) {
    final params = <String, Object>{};
    if (matchedLanguage != null) params['matched_language'] = matchedLanguage;
    if (waitTimeSeconds != null) params['wait_time_seconds'] = waitTimeSeconds;
    return _log('match_found', params: params.isEmpty ? null : params);
  }

  // ── 11. Tip Sent ──────────────────────────────────────────────────────────
  /// Call when a user sends Vybz coins as a tip to a content creator.
  static Future<void> logTipSent({
    required int amount,
    required String recipientUid,
  }) =>
      _log('tip_sent', params: {
        'tip_amount': amount,
        'has_recipient': recipientUid.isNotEmpty ? 1 : 0,
      });

  // ── 12. Language Switched ─────────────────────────────────────────────────
  /// Call when user changes their app language from settings.
  static Future<void> logLanguageSwitched({
    required String fromLanguage,
    required String toLanguage,
  }) =>
      _log('language_switched', params: {
        'from_language': fromLanguage,
        'to_language': toLanguage,
      });

  // ── 13. Invite Sent ──────────────────────────────────────────────────────
  /// Call when user taps share on their invite code.
  static Future<void> logInviteSent() => _log('invite_sent');

  // ── 14. Profile Completed ─────────────────────────────────────────────────
  /// Call when user finishes profile setup: username + photo + bio all set.
  static Future<void> logProfileCompleted() => _log('profile_completed');

  // ── 15. Feature Viewed ────────────────────────────────────────────────────
  /// Generic screen/feature view tracker — use for notable interactions.
  static Future<void> logFeatureViewed({
    required String featureName,
  }) =>
      _log('feature_viewed', params: {'feature_name': featureName});

  // ── 16. Content Liked ─────────────────────────────────────────────────────
  /// Call when a user likes/unlikes a piece of content (posts, vybz, etc).
  static Future<void> logContentLiked({
    required String contentType,
    required bool isLiked,
  }) =>
      _log('content_liked', params: {
        'content_type': contentType,
        'action': isLiked ? 'like' : 'unlike',
      });

  // ── User Properties ───────────────────────────────────────────────────────

  /// Sets the Firebase Analytics user ID for cross-session tracking.
  /// Call after successful authentication.
  static Future<void> setUserId(String uid) async {
    if (!await ConsentGateService.hasAnalyticsConsent()) return;
    try {
      await _analytics.setUserId(id: uid);
    } catch (e) {
      AppLogger.e('Analytics: failed to set user ID', e);
    }
  }

  /// Sets the user's preferred language as a user property.
  static Future<void> setUserLanguage(String language) async {
    if (!await ConsentGateService.hasAnalyticsConsent()) return;
    try {
      await _analytics.setUserProperty(name: 'app_language', value: language);
    } catch (e) {
      AppLogger.e('Analytics: failed to set language property', e);
    }
  }

  /// Sets whether the user is verified (for segmentation).
  static Future<void> setUserVerified({required bool isVerified}) async {
    if (!await ConsentGateService.hasAnalyticsConsent()) return;
    try {
      await _analytics.setUserProperty(
        name: 'is_verified',
        value: isVerified ? 'true' : 'false',
      );
    } catch (e) {
      AppLogger.e('Analytics: failed to set verified property', e);
    }
  }
}
