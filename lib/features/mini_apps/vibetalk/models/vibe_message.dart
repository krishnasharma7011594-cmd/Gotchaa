import 'package:cloud_firestore/cloud_firestore.dart';

class VibeMessage {

  const VibeMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isSystemMessage = false,
  });

  factory VibeMessage.fromMap(Map<String, dynamic> map, String id) => VibeMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSystemMessage: map['isSystemMessage'] ?? false,
    );
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isSystemMessage;

  Map<String, dynamic> toMap() => {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSystemMessage': isSystemMessage,
    };
}
