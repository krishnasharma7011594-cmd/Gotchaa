import 'package:cloud_firestore/cloud_firestore.dart';

class VibeRoom { // The current gamified prompt data

  const VibeRoom({
    required this.id,
    required this.users,
    required this.createdAt, this.status = 'active',
    this.callerId,
    this.offer,
    this.answer,
    this.activeGame,
  });

  factory VibeRoom.fromMap(Map<String, dynamic> map, String id) => VibeRoom(
      id: id,
      users: List<String>.from(map['users'] ?? []),
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      callerId: map['callerId'],
      offer: map['offer'],
      answer: map['answer'],
      activeGame: map['activeGame'],
    );
  final String id;
  final List<String> users;
  final String status; // 'active', 'ended'
  final DateTime createdAt;
  final String? callerId; // who initiates the WebRTC call
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;
  final Map<String, dynamic>? activeGame;

  Map<String, dynamic> toMap() => {
      'id': id,
      'users': users,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'callerId': callerId,
      'offer': offer,
      'answer': answer,
      'activeGame': activeGame,
    };
}
