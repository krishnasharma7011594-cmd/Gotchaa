import 'package:flutter/foundation.dart';

enum BroRole { user, assistant }

enum BroMessageType { voice, text }

class BroMessage {
  final String id;
  final BroRole role;
  final String content;
  final DateTime timestamp;
  final BroMessageType type;
  final String? audioUrl; // For voice messages

  BroMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    required this.type,
    this.audioUrl,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'audioUrl': audioUrl,
      };

  factory BroMessage.fromMap(Map<String, dynamic> map) => BroMessage(
        id: map['id'],
        role: BroRole.values.byName(map['role']),
        content: map['content'],
        timestamp: DateTime.parse(map['timestamp']),
        type: BroMessageType.values.byName(map['type']),
        audioUrl: map['audioUrl'],
      );
}
