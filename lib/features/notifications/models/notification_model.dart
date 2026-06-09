import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.fromUsername,
    required this.fromAvatar,
    required this.fromNationFlag,
    required this.targetId,
    required this.isRead,
    required this.createdAt,
    this.targetImageUrl,
    this.message,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) =>
      NotificationModel(
        id: id,
        type: map['type'] as String? ?? 'system',
        fromUid: map['fromUid'] as String? ?? '',
        fromUsername: map['fromUsername'] as String? ?? 'User',
        fromAvatar: map['fromAvatar'] as String? ?? '',
        fromNationFlag: map['fromNationFlag'] as String? ?? '🌍',
        targetId: map['targetId'] as String? ?? '',
        targetImageUrl: map['targetImageUrl'] as String?,
        message: map['message'] as String?,
        isRead: map['isRead'] as bool? ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  final String id;
  final String
      type; // 'like', 'comment', 'follow', 'vybzMilestone', 'commentLike'
  final String fromUid;
  final String fromUsername;
  final String fromAvatar;
  final String fromNationFlag;
  final String targetId;
  final String? targetImageUrl;
  final String? message;
  final bool isRead;
  final DateTime createdAt;
}
