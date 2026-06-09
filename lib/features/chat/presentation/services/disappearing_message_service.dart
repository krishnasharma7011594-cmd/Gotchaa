import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling disappearing messages, screenshot notifications,
/// and content reporting in the chat system.
class DisappearingMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Notify the recipient that a screenshot was taken in their chat.
  Future<void> notifyScreenshot({
    required String chatId,
    required String recipientId,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).collection('events').add({
        'type': 'screenshot',
        'recipientId': recipientId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      
    }
  }

  /// Report a specific message for violating community guidelines.
  Future<void> reportMessage({
    required String chatId,
    required String messageId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'chatId': chatId,
        'messageId': messageId,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      
      rethrow;
    }
  }
}
