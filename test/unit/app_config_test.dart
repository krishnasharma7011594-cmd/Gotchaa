import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('Test fallback values when keys missing', () {
      // By default in tests, String.fromEnvironment returns the default value (empty string)
      // unless passed via --dart-define to the test runner.
      expect(AppConfig.geminiApiKey, isEmpty);
      expect(AppConfig.uberClientId, isEmpty);
      expect(AppConfig.uberClientSecret, isEmpty);
      expect(AppConfig.spotifyClientId, isEmpty);
    });

    test('Test allKeysPresent returns false when keys missing', () {
      expect(AppConfig.allKeysPresent, isFalse);
    });

    test('Test assertKeysPresent throws when keys missing', () {
      // This will throw an AssertionError in debug mode because geminiApiKey is empty.
      expect(() => AppConfig.assertKeysPresent(), throwsA(isA<AssertionError>()));
    });
  });
}
