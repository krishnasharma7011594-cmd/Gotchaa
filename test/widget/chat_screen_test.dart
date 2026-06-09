import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/features/chat/presentation/screens/chat_conversation_screen.dart';
import 'package:gotchaa/features/chat/providers/chat_providers.dart';
import 'package:gotchaa/core/models/chat_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/pump_app.dart';

void main() {
  const testChatId = 'test_chat_id';
  const testUserName = 'Test User';

  group('ChatConversationScreen Tests', () {
    testWidgets('Empty state shown when no messages',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const ChatConversationScreen(
            chatId: testChatId, userName: testUserName),
        overrides: [
          messageStreamProvider(testChatId)
              .overrideWith((ref) => Stream.value([])),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('No messages yet. Start the conversation.'),
          findsOneWidget);
    });

    testWidgets('Message list renders messages', (WidgetTester tester) async {
      final messages = [
        MessageModel(
          id: '1',
          senderId: 'user1',
          receiverId: 'user2',
          text: 'Hello Test',
          timestamp: DateTime.now(),
          type: 'text',
        ),
      ];

      await tester.pumpApp(
        const ChatConversationScreen(
            chatId: testChatId, userName: testUserName),
        overrides: [
          messageStreamProvider(testChatId)
              .overrideWith((ref) => Stream.value(messages)),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Hello Test'), findsOneWidget);
    });

    testWidgets('Encryption indicator present', (WidgetTester tester) async {
      final messages = [
        MessageModel(
          id: '1',
          senderId: 'user1',
          receiverId: 'user2',
          text: 'Hello',
          timestamp: DateTime.now(),
          type: 'text',
        ),
      ];

      await tester.pumpApp(
        const ChatConversationScreen(
            chatId: testChatId, userName: testUserName),
        overrides: [
          messageStreamProvider(testChatId)
              .overrideWith((ref) => Stream.value(messages)),
        ],
      );

      await tester.pumpAndSettle();

      expect(
          find.text(
              'Messages are end-to-end encrypted. No one outside of this chat can read them.'),
          findsOneWidget);
    });

    testWidgets('Input field and send button are present',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const ChatConversationScreen(
            chatId: testChatId, userName: testUserName),
        overrides: [
          messageStreamProvider(testChatId)
              .overrideWith((ref) => Stream.value([])),
        ],
      );

      await tester.pumpAndSettle();

      // Input field should be present (implied by EnhancedChatInput or TextField)
      expect(find.byType(TextField), findsOneWidget);
      // Send button or similar icon should be present
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });
}
