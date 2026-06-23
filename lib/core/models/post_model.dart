import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  PostModel({
    required this.postId,
    required this.uid,
    required this.createdAt,
    this.username = '',
    this.userPhoto = '',
    this.caption = '',
    this.mediaUrl = '',
    this.mediaThumbnailUrl = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.shareCount = 0,
    this.viewsCount = 0,
    this.isVideo = false,
    this.spotifyTrackId,
    this.spotifyTrackName,
    this.spotifyArtistName,
    this.spotifyAlbumArtUrl,
    this.spotifyPreviewUrl,
    this.overlays,
    this.authorNation,
    this.authorLanguage,
    this.hashtags = const [],
    this.searchKeywords = const [],
    this.blurHash,
    this.isPrivate = false,
    this.visibility = 'public',
    this.authorGhostUids = const [],
    this.authorFriendUids = const [],
    this.customListUids = const [],
  });

  factory PostModel.fromMap(Map<String, dynamic> data, String id) {
    try {
      return PostModel(
        postId: id,
        uid: data['uid'] ?? '',
        username: data['username'] ?? '',
        userPhoto: data['userPhoto'] ?? '',
        caption: data['caption'] ?? '',
        mediaUrl: data['mediaUrl'] ?? '',
        mediaThumbnailUrl: data['mediaThumbnailUrl'] ?? '',
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        likesCount: (data['likesCount'] ?? 0) as int,
        commentsCount: (data['commentsCount'] ?? 0) as int,
        shareCount: (data['shareCount'] ?? 0) as int,
        viewsCount: (data['viewsCount'] ?? 0) as int,
        isVideo: data['isVideo'] ?? false,
        spotifyTrackId: data['spotifyTrackId'] as String?,
        spotifyTrackName: data['spotifyTrackName'] as String?,
        spotifyArtistName: data['spotifyArtistName'] as String?,
        spotifyAlbumArtUrl: data['spotifyAlbumArtUrl'] as String?,
        spotifyPreviewUrl: data['spotifyPreviewUrl'] as String?,
        overlays: data['overlays'] != null
            ? List<Map<String, dynamic>>.from(data['overlays'])
            : null,
        authorNation: data['authorNation'] as String?,
        authorLanguage: data['authorLanguage'] as String?,
        hashtags: List<String>.from(data['hashtags'] ?? []),
        searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
        blurHash: data['blurHash'] as String?,
        isPrivate: data['isPrivate'] ?? false,
        visibility: data['visibility'] ?? 'public',
        authorGhostUids: List<String>.from(data['authorGhostUids'] ?? []),
        authorFriendUids: List<String>.from(data['authorFriendUids'] ?? []),
        customListUids: List<String>.from(data['customListUids'] ?? []),
      );
    } catch (e) {
      return PostModel(
        postId: id,
        uid: 'error',
        createdAt: DateTime.now(),
        caption: 'Error loading post',
        mediaThumbnailUrl: '',
      );
    }
  }
  final String postId;
  final String uid;
  final String username;
  final String userPhoto;
  final String caption;
  final String mediaUrl;
  final String mediaThumbnailUrl;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final String? spotifyTrackId;
  final String? spotifyTrackName;
  final String? spotifyArtistName;
  final String? spotifyAlbumArtUrl;
  final String? spotifyPreviewUrl;
  final List<Map<String, dynamic>>? overlays;
  final String? authorNation;
  final String? authorLanguage;
  final int shareCount;
  final int viewsCount;
  final bool isVideo;
  final List<String> hashtags;
  final List<String> searchKeywords;
  final String? blurHash;
  final bool isPrivate;
  final String visibility; // 'public', 'friends', 'ghost'
  final List<String> authorGhostUids;
  final List<String> authorFriendUids;
  final List<String> customListUids;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'userPhoto': userPhoto,
        'caption': caption,
        'mediaUrl': mediaUrl,
        if (mediaThumbnailUrl.isNotEmpty)
          'mediaThumbnailUrl': mediaThumbnailUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'shareCount': shareCount,
        'viewsCount': viewsCount,
        'isVideo': isVideo,
        if (spotifyTrackId != null) 'spotifyTrackId': spotifyTrackId,
        if (spotifyTrackName != null) 'spotifyTrackName': spotifyTrackName,
        if (spotifyArtistName != null) 'spotifyArtistName': spotifyArtistName,
        if (spotifyAlbumArtUrl != null)
          'spotifyAlbumArtUrl': spotifyAlbumArtUrl,
        if (spotifyPreviewUrl != null) 'spotifyPreviewUrl': spotifyPreviewUrl,
        if (overlays != null) 'overlays': overlays,
        if (authorNation != null) 'authorNation': authorNation,
        if (authorLanguage != null) 'authorLanguage': authorLanguage,
        'hashtags': hashtags,
        'searchKeywords': searchKeywords,
        if (blurHash != null) 'blurHash': blurHash,
        'isPrivate': isPrivate,
        'visibility': visibility,
        'authorGhostUids': authorGhostUids,
        'authorFriendUids': authorFriendUids,
        'customListUids': customListUids,
      };
}
