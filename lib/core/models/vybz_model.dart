import 'package:cloud_firestore/cloud_firestore.dart';

class VybzModel {
  VybzModel({
    required this.id,
    required this.creatorId,
    required this.videoUrl,
    required this.caption,
    this.thumbnailUrl = '',
    this.hashtags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.tips = 0.0,
    this.creatorUsername = '',
    this.creatorPhoto = '',
    this.createdAt,
  });

  factory VybzModel.fromMap(Map<String, dynamic> data, String id) => VybzModel(
        id: id,
        creatorId: data['creatorId'] ?? '',
        videoUrl: data['videoUrl'] ?? '',
        caption: data['caption'] ?? '',
        thumbnailUrl: data['thumbnailUrl'] ?? '',
        hashtags: List<String>.from(data['hashtags'] ?? []),
        likesCount: data['likesCount'] ?? (data['likes'] ?? 0),
        commentsCount: data['commentsCount'] ?? 0,
        viewsCount: data['viewsCount'] ?? 0,
        tips: (data['tips'] ?? 0.0).toDouble(),
        creatorUsername: data['creatorUsername'] ?? '',
        creatorPhoto: data['creatorPhoto'] ?? '',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : null,
      );
  final String id;
  final String creatorId;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final List<String> hashtags;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final double tips;
  final String creatorUsername;
  final String creatorPhoto;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'creatorId': creatorId,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'hashtags': hashtags,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'viewsCount': viewsCount,
        'tips': tips,
        'creatorUsername': creatorUsername,
        'creatorPhoto': creatorPhoto,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
