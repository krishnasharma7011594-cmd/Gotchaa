import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/core/security/e2ee_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EEService e2eeService;
  final Map<String, String> mockStorage = {};
  const chatId = 'chat_123';
  const otherUserId = 'other_user_123';

  // Pre-computed 32-byte test AES key (all zeros – valid for AES-256)
  final testKeyBase64 = base64Encode(Uint8List(32));

  setUpAll(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'read':
          return mockStorage[methodCall.arguments['key']];
        case 'write':
          mockStorage[methodCall.arguments['key']] =
              methodCall.arguments['value'];
          return null;
        case 'delete':
          mockStorage.remove(methodCall.arguments['key']);
          return null;
        case 'readAll':
          return mockStorage;
        case 'deleteAll':
          mockStorage.clear();
          return null;
      }
      return null;
    });
  });

  setUp(() {
    mockStorage.clear();
    // Pre-populate shared secret keys so getOrCreateChatKey doesn't need Firebase
    mockStorage['v2_shared_secret_$chatId'] = testKeyBase64;
    mockStorage['v2_shared_secret_chat_1'] = testKeyBase64;
    mockStorage['v2_shared_secret_chat_2'] = testKeyBase64;
    e2eeService = E2EEService();
    e2eeService.clearMemoryCache();
  });

  group('E2EEService Tests', () {
    test('Encryption produces output different from input', () async {
      const plaintext = 'Hello World';

      final encrypted =
          await e2eeService.encryptForChat(plaintext, chatId, otherUserId);

      expect(encrypted, isNot(equals(plaintext)));
      expect(encrypted, isNotEmpty);
    });

    test('Decryption recovers exact original message', () async {
      const plaintext = 'Hello World';

      final encrypted =
          await e2eeService.encryptForChat(plaintext, chatId, otherUserId);
      final decrypted =
          await e2eeService.decryptForChat(encrypted, chatId, otherUserId);

      expect(decrypted, equals(plaintext));
    });

    test(
        'Same message encrypted twice produces different output (IV randomness)',
        () async {
      const plaintext = 'Hello World';

      final encrypted1 =
          await e2eeService.encryptForChat(plaintext, chatId, otherUserId);
      final encrypted2 =
          await e2eeService.encryptForChat(plaintext, chatId, otherUserId);

      expect(encrypted1, isNot(equals(encrypted2)));
    });

    test('Empty message handles gracefully', () async {
      const plaintext = '';

      final encrypted =
          await e2eeService.encryptForChat(plaintext, chatId, otherUserId);
      final decrypted =
          await e2eeService.decryptForChat(encrypted, chatId, otherUserId);

      expect(decrypted, equals(plaintext));
    });

    test('Very long message (10000 chars) handles correctly', () async {
      final plaintext = 'A' * 10000;

      final encrypted =
          await e2eeService.encryptForChat(plaintext, chatId, otherUserId);
      final decrypted =
          await e2eeService.decryptForChat(encrypted, chatId, otherUserId);

      expect(decrypted, equals(plaintext));
    });

    test('clearAllSessionData removes v2_shared_secret_ prefix keys correctly',
        () async {
      // Keys already pre-populated in setUp; verify they exist
      expect(
        mockStorage.keys.any((k) => k.startsWith('v2_shared_secret_')),
        isTrue,
      );

      await e2eeService.clearAllSessionData();

      expect(
        mockStorage.keys.any((k) => k.startsWith('v2_shared_secret_')),
        isFalse,
      );
    });

    test('Safety Number generation is deterministic for same inputs', () async {
      // Skip: requires FirebaseAuth.currentUser which is unavailable in unit tests.
      // Covered by integration tests that run with an initialized Firebase instance.
    }, skip: 'Requires Firebase Auth – run in integration test environment');
  });
}
