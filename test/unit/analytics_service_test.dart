import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/core/services/analytics_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnalyticsService Tests', () {
    test('Every event method is callable and does not throw', () async {
      // We call every method to verify it exists and doesn't throw exceptions.
      // The implementation wraps calls in try-catch, so even without Firebase
      // initialized, they should not crash the app.
      
      await AnalyticsService.logAppOpen();
      await AnalyticsService.logSignUpComplete(method: 'email');
      await AnalyticsService.logLoginSuccess(method: 'email');
      await AnalyticsService.logOnboardingComplete(language: 'en');
      await AnalyticsService.logFirstPostCreated(postType: 'text');
      await AnalyticsService.logPostCreated(postType: 'text');
      await AnalyticsService.logFirstMessageSent();
      await AnalyticsService.logMessageSent(type: 'text');
      await AnalyticsService.logVybzCreated(durationSeconds: 10);
      await AnalyticsService.logMatchFound(matchedLanguage: 'en', waitTimeSeconds: 5);
      await AnalyticsService.logTipSent(amount: 10, recipientUid: 'user_123');
      await AnalyticsService.logLanguageSwitched(fromLanguage: 'en', toLanguage: 'es');
      await AnalyticsService.logInviteSent();
      await AnalyticsService.logProfileCompleted();
      await AnalyticsService.logFeatureViewed(featureName: 'vibetalk');
      await AnalyticsService.logContentLiked(contentType: 'post', isLiked: true);
      
      expect(true, isTrue); // If we reach here, it passed
    });

    test('Fire-and-forget pattern verified', () async {
      // Fire-and-forget means we don't need to await the result to continue.
      // We verify that calling the methods without await works and doesn't throw.
      
      AnalyticsService.logAppOpen();
      AnalyticsService.logMessageSent(type: 'text');
      
      expect(true, isTrue);
    });

    test('All events tested individually', () async {
      // Individual tests to ensure no specific method has issues
      expect(() => AnalyticsService.logAppOpen(), returnsNormally);
      expect(() => AnalyticsService.logSignUpComplete(method: 'email'), returnsNormally);
      expect(() => AnalyticsService.logLoginSuccess(method: 'email'), returnsNormally);
      expect(() => AnalyticsService.logOnboardingComplete(language: 'en'), returnsNormally);
      expect(() => AnalyticsService.logFirstPostCreated(postType: 'text'), returnsNormally);
      expect(() => AnalyticsService.logPostCreated(postType: 'text'), returnsNormally);
      expect(() => AnalyticsService.logFirstMessageSent(), returnsNormally);
      expect(() => AnalyticsService.logMessageSent(type: 'text'), returnsNormally);
      expect(() => AnalyticsService.logVybzCreated(durationSeconds: 10), returnsNormally);
      expect(() => AnalyticsService.logMatchFound(matchedLanguage: 'en', waitTimeSeconds: 5), returnsNormally);
      expect(() => AnalyticsService.logTipSent(amount: 10, recipientUid: 'user_123'), returnsNormally);
      expect(() => AnalyticsService.logLanguageSwitched(fromLanguage: 'en', toLanguage: 'es'), returnsNormally);
      expect(() => AnalyticsService.logInviteSent(), returnsNormally);
      expect(() => AnalyticsService.logProfileCompleted(), returnsNormally);
      expect(() => AnalyticsService.logFeatureViewed(featureName: 'vibetalk'), returnsNormally);
      expect(() => AnalyticsService.logContentLiked(contentType: 'post', isLiked: true), returnsNormally);
    });
  });
}
