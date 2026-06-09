import 'package:cloud_firestore/cloud_firestore.dart';

class CircleMessage {
  // { 'lat': double, 'lng': double, 'title': String, 'style': String }

  CircleMessage({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    required this.timestamp,
    required this.ttl,
    required this.isPinned,
    this.pinLocation,
  });

  factory CircleMessage.fromMap(Map<String, dynamic> map, String docId) =>
      CircleMessage(
        messageId: docId,
        chatId: map['chatId'] ?? '',
        senderId: map['senderId'] ?? '',
        senderName: map['senderName'] ?? 'Anonymous',
        senderAvatar: map['senderAvatar'] ?? '',
        text: map['text'] ?? '',
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ttl: (map['ttl'] as Timestamp?)?.toDate() ??
            DateTime.now().add(const Duration(hours: 24)),
        isPinned: map['isPinned'] ?? false,
        pinLocation: map['pinLocation'] != null
            ? Map<String, dynamic>.from(map['pinLocation'])
            : null,
      );
  final String messageId;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final DateTime timestamp;
  final DateTime ttl; // auto-delete expiration timestamp
  final bool isPinned;
  final Map<String, dynamic>? pinLocation;

  Map<String, dynamic> toMap() => {
        'messageId': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'ttl': Timestamp.fromDate(ttl),
        'isPinned': isPinned,
        if (pinLocation != null) 'pinLocation': pinLocation,
      };
}
