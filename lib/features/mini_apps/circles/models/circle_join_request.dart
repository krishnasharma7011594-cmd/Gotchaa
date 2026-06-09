import 'package:cloud_firestore/cloud_firestore.dart';

class CircleJoinRequest {

  CircleJoinRequest({
    required this.requestId,
    required this.circleId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.introMessage,
    required this.karmaScore,
    required this.trustTier,
    required this.status,
    required this.createdAt,
  });

  factory CircleJoinRequest.fromMap(Map<String, dynamic> map, String docId) => CircleJoinRequest(
      requestId: docId,
      circleId: map['circleId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'New Member',
      userAvatar: map['userAvatar'] ?? '',
      introMessage: map['introMessage'] ?? '',
      karmaScore: map['karmaScore'] ?? 0,
      trustTier: map['trustTier'] ?? 'New',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  final String requestId;
  final String circleId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String introMessage;
  final int karmaScore;
  final String trustTier;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
      'requestId': requestId,
      'circleId': circleId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'introMessage': introMessage,
      'karmaScore': karmaScore,
      'trustTier': trustTier,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
}
