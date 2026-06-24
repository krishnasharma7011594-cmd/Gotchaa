import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/core/services/audio_focus_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock audio_session platform channel to prevent test crashes
  const MethodChannel channel = MethodChannel('com.ryanheise.audio_session');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getConfiguration' ||
          methodCall.method == 'setConfiguration') {
        return null;
      }
      if (methodCall.method == 'setActive') {
        return null;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AudioFocusManager Map Refactor Tests', () {
    late AudioFocusManager manager;

    setUp(() {
      manager = AudioFocusManager();
      // Clear or reset focus owner state if needed
    });

    test('Video swiping race condition test (Multiple vybz requesters)',
        () async {
      // 1. Video A requests focus
      await manager.requestAudioFocus('vybz_video_A', AudioRequester.vybz);
      expect(manager.currentFocusOwner, AudioRequester.vybz);

      // 2. Video B (incoming) requests focus before Video A releases it
      await manager.requestAudioFocus('vybz_video_B', AudioRequester.vybz);
      expect(manager.currentFocusOwner, AudioRequester.vybz);

      // 3. Video A releases focus
      await manager.releaseAudioFocus('vybz_video_A');

      // Focus should STILL be vybz because Video B is still active!
      // This is the core fix of the race condition.
      expect(manager.currentFocusOwner, AudioRequester.vybz);

      // 4. Video B releases focus -> Focus becomes null
      await manager.releaseAudioFocus('vybz_video_B');
      expect(manager.currentFocusOwner, isNull);
    });

    test('Priority resolution (broInput > broOutput > vybz)', () async {
      // Start with vybz active
      await manager.requestAudioFocus('vybz_video_A', AudioRequester.vybz);
      expect(manager.currentFocusOwner, AudioRequester.vybz);

      // Bro Output requests focus
      await manager.requestAudioFocus('bro_output', AudioRequester.broOutput);
      expect(manager.currentFocusOwner, AudioRequester.broOutput);

      // Bro Input (highest priority) requests focus
      await manager.requestAudioFocus('bro_input', AudioRequester.broInput);
      expect(manager.currentFocusOwner, AudioRequester.broInput);

      // Release Input -> falls back to output
      await manager.releaseAudioFocus('bro_input');
      expect(manager.currentFocusOwner, AudioRequester.broOutput);

      // Release Output -> falls back to vybz
      await manager.releaseAudioFocus('bro_output');
      expect(manager.currentFocusOwner, AudioRequester.vybz);

      // Clean up
      await manager.releaseAudioFocus('vybz_video_A');
      expect(manager.currentFocusOwner, isNull);
    });
  });
}
