import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {

  CommentModel({
    required this.id,
    required this.uid,
    required this.text,
    required this.createdAt,
    this.username = '',
    this.userPhoto = '',
    this.likesCount = 0,
  });

  factory CommentModel.fromMap(Map<String, dynamic> data, String id) => CommentModel(
        id: id,
        uid: data['uid'] ?? '',
        username: data['username'] ?? '',
        userPhoto: data['userPhoto'] ?? '',
        text: data['text'] ?? '',
        likesCount: data['likesCount'] ?? 0,
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
  final String id;
  final String uid;
  final String username;
  final String userPhoto;
  final String text;
  final int likesCount;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'userPhoto': userPhoto,
        'text': text,
        'likesCount': likesCount,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
