import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/core/security/e2ee_service.dart';
import 'package:cryptography/cryptography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late E2EEService e2eeService;
  final Map<String, String> mockStorage = {};

  setUpAll(() {
    const channel = MethodChannel('plugins.it_soft.blitz/flutter_secure_storage');
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'read':
          return mockStorage[methodCall.arguments['key']];
        case 'write':
          mockStorage[methodCall.arguments['key']] = methodCall.arguments['value'];
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
    e2eeService = E2EEService();
    e2eeService.clearMemoryCache();
  });

  group('E2EEService Tests', () {
    test('Encryption produces output different from input', () async {
      const plaintext = 'Hello World';
      const chatId = 'chat_123';
      
      final encrypted = await e2eeService.encryptForChat(plaintext, chatId);
      
      expect(encrypted, isNot(equals(plaintext)));
      expect(encrypted, isNotEmpty);
    });

    test('Decryption recovers exact original message', () async {
      const plaintext = 'Hello World';
      const chatId = 'chat_123';
      
      final encrypted = await e2eeService.encryptForChat(plaintext, chatId);
      final decrypted = await e2eeService.decryptForChat(encrypted, chatId);
      
      expect(decrypted, equals(plaintext));
    });

    test('Same message encrypted twice produces different output (IV randomness)', () async {
      const plaintext = 'Hello World';
      const chatId = 'chat_123';
      
      final encrypted1 = await e2eeService.encryptForChat(plaintext, chatId);
      final encrypted2 = await e2eeService.encryptForChat(plaintext, chatId);
      
      expect(encrypted1, isNot(equals(encrypted2)));
    });

    test('Empty message handles gracefully', () async {
      const plaintext = '';
      const chatId = 'chat_123';
      
      final encrypted = await e2eeService.encryptForChat(plaintext, chatId);
      final decrypted = await e2eeService.decryptForChat(encrypted, chatId);
      
      expect(decrypted, equals(plaintext));
    });

    test('Very long message (10000 chars) handles correctly', () async {
      final plaintext = 'A' * 10000;
      const chatId = 'chat_123';
      
      final encrypted = await e2eeService.encryptForChat(plaintext, chatId);
      final decrypted = await e2eeService.decryptForChat(encrypted, chatId);
      
      expect(decrypted, equals(plaintext));
    });

    test('clearAllSessionData removes v2_shared_secret_ prefix keys correctly', () async {
      await e2eeService.getOrCreateChatKey('chat_1');
      await e2eeService.getOrCreateChatKey('chat_2');
      
      expect(mockStorage.keys.any((k) => k.startsWith('v2_shared_secret_')), isTrue);
      
      await e2eeService.clearAllSessionData();
      
      expect(mockStorage.keys.any((k) => k.startsWith('v2_shared_secret_')), isFalse);
    });

    test('Safety Number generation is deterministic for same inputs', () async {
      const chatId = 'chat_123';
      
      final number1 = await e2eeService.calculateSafetyNumber(chatId);
      final number2 = await e2eeService.calculateSafetyNumber(chatId);
      
      expect(number1, equals(number2));
      expect(number1.length, greaterThan(20)); // Should be grouped digits
    });
  });
}
