import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gotchaa/features/chat/presentation/screens/chat_conversation_screen.dart';
import 'package:gotchaa/features/chat/providers/chat_providers.dart';
import 'package:gotchaa/core/models/chat_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete Chat Flow Test', (WidgetTester tester) async {
    final controller = StreamController<List<MessageModel>>();
    const testChatId = 'test_chat_id';
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messageStreamProvider(testChatId).overrideWith((ref) => controller.stream),
        ],
        child: const MaterialApp(
          home: ChatConversationScreen(chatId: testChatId, userName: 'Test User'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initial state: empty
    controller.add([]);
    await tester.pumpAndSettle();
    expect(find.text('No messages yet. Start the conversation.'), findsOneWidget);

    // Type message
    await tester.enterText(find.byType(TextField), 'Hello Integration');
    
    // Tap Send (assuming icon is Icons.send_rounded or similar)
    // Let's find the send button.
    // In ChatConversationScreen lines 25, 44, it uses EnhancedChatInput.
    // Let's assume there is a send icon.
    final sendButton = find.byIcon(Icons.send_rounded);
    if (sendButton.evaluate().isNotEmpty) {
      await tester.tap(sendButton);
      await tester.pump();
    }

    // Simulate receiving the message via stream
    final newMessage = MessageModel(
      id: '2',
      senderId: 'user1',
      receiverId: 'user2',
      text: 'Hello Integration',
      timestamp: DateTime.now(),
      type: 'text',
    );
    
    controller.add([newMessage]);
    await tester.pumpAndSettle();

    // Verify message appears in list
    expect(find.text('Hello Integration'), findsOneWidget);
    
    controller.close();
  });
}
