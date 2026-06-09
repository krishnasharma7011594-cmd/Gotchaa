import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment_model.dart';
import '../models/user_profile.dart';
import '../utils/distributed_counter.dart';

class SocialRepository {
  SocialRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  // ═══════════════════════════════════════════════════════════════════════
  // FOLLOW SYSTEM
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> followUser({
    required String myUid,
    required String targetUid,
  }) async {
    if (myUid == targetUid) return;

    final batch = _db.batch();

    batch.set(
      _db
          .collection('followers')
          .doc(targetUid)
          .collection('userFollowers')
          .doc(myUid),
      {'uid': myUid, 'followedAt': FieldValue.serverTimestamp()},
    );

    batch.set(
      _db
          .collection('following')
          .doc(myUid)
          .collection('userFollowing')
          .doc(targetUid),
      {'uid': targetUid, 'followedAt': FieldValue.serverTimestamp()},
    );

    batch.update(
      _db.collection('users').doc(targetUid),
      {'followersCount': FieldValue.increment(1)},
    );
    batch.update(
      _db.collection('users').doc(myUid),
      {'followingCount': FieldValue.increment(1)},
    );

    await batch.commit();
  }

  Future<void> unfollowUser({
    required String myUid,
    required String targetUid,
  }) async {
    if (myUid == targetUid) return;

    final batch = _db.batch();

    batch.delete(
      _db
          .collection('followers')
          .doc(targetUid)
          .collection('userFollowers')
          .doc(myUid),
    );

    batch.delete(
      _db
          .collection('following')
          .doc(myUid)
          .collection('userFollowing')
          .doc(targetUid),
    );

    batch.update(
      _db.collection('users').doc(targetUid),
      {'followersCount': FieldValue.increment(-1)},
    );
    batch.update(
      _db.collection('users').doc(myUid),
      {'followingCount': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  Future<bool> isFollowing({
    required String myUid,
    required String targetUid,
  }) async {
    final doc = await _db
        .collection('following')
        .doc(myUid)
        .collection('userFollowing')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  Stream<bool> isFollowingStream({
    required String myUid,
    required String targetUid,
  }) =>
      _db
          .collection('following')
          .doc(myUid)
          .collection('userFollowing')
          .doc(targetUid)
          .snapshots()
          .map((snap) => snap.exists);

  // ═══════════════════════════════════════════════════════════════════════
  // LIKE SYSTEM
  // ═══════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════
  // LIKE SYSTEM
  // ═══════════════════════════════════════════════════════════════════════

  /// Likes a content item (post, vybz, or comment).
  /// [contentType] can be 'posts', 'vybz', or 'comments'.
  /// [parentId] is only required for comments (the postId where the comment exists).
  Future<void> likeContent({
    required String contentId,
    required String uid,
    required String contentType, // 'posts' | 'vybz' | 'comments'
    String? parentId, // Post ID if liking a comment
    String? contentOwnerId,
    String? contentOwnerName,
    String? likerName,
    String? likerPhotoUrl,
  }) async {
    final DocumentReference contentRef;
    final DocumentReference likeRef;

    if (contentType == 'comments' && parentId != null) {
      contentRef = _db
          .collection('posts')
          .doc(parentId)
          .collection('comments')
          .doc(contentId);
    } else {
      contentRef = _db.collection(contentType).doc(contentId);
    }

    likeRef = contentRef.collection('likes').doc(uid);

    final existing = await likeRef.get();
    if (existing.exists) return;

    final batch = _db.batch();

    batch.set(likeRef, {
      'uid': uid,
      'likedAt': FieldValue.serverTimestamp(),
      'displayName': likerName ?? '',
      'photoUrl': likerPhotoUrl ?? '',
    });

    DistributedCounter.incrementInBatch(batch, contentRef, 'likesCount',
        value: 1);

    // Update global activity if needed
    if (contentOwnerId != null && contentOwnerId != uid) {
      final notifRef = _db
          .collection('notifications')
          .doc(contentOwnerId)
          .collection('userNotifications')
          .doc();

      batch.set(notifRef, {
        'type': contentType == 'comments' ? 'commentLike' : 'like',
        'fromUid': uid,
        'fromUsername': likerName ?? 'Someone',
        'fromAvatar': likerPhotoUrl ?? '',
        'targetId': contentId,
        'parentId': parentId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'message': contentType == 'comments'
            ? 'liked your comment'
            : 'liked your post',
      });
    }

    await batch.commit();
  }

  Future<void> unlikeContent({
    required String contentId,
    required String uid,
    required String contentType,
    String? parentId,
  }) async {
    final DocumentReference contentRef;
    if (contentType == 'comments' && parentId != null) {
      contentRef = _db
          .collection('posts')
          .doc(parentId)
          .collection('comments')
          .doc(contentId);
    } else {
      contentRef = _db.collection(contentType).doc(contentId);
    }

    final likeRef = contentRef.collection('likes').doc(uid);

    final existing = await likeRef.get();
    if (!existing.exists) return;

    final batch = _db.batch();

    batch.delete(likeRef);

    DistributedCounter.incrementInBatch(batch, contentRef, 'likesCount',
        value: -1);

    await batch.commit();
  }

  Stream<bool> isLikedStream({
    required String contentId,
    required String uid,
    required String contentType,
    String? parentId,
  }) {
    final DocumentReference contentRef;
    if (contentType == 'comments' && parentId != null) {
      contentRef = _db
          .collection('posts')
          .doc(parentId)
          .collection('comments')
          .doc(contentId);
    } else {
      contentRef = _db.collection(contentType).doc(contentId);
    }

    return contentRef
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists);
  }

  Future<List<Map<String, dynamic>>> getLikers(
      String contentId, String contentType,
      {String? parentId}) async {
    final DocumentReference contentRef;
    if (contentType == 'comments' && parentId != null) {
      contentRef = _db
          .collection('posts')
          .doc(parentId)
          .collection('comments')
          .doc(contentId);
    } else {
      contentRef = _db.collection(contentType).doc(contentId);
    }

    final query = await contentRef
        .collection('likes')
        .orderBy('likedAt', descending: true)
        .get();
    return query.docs.map((doc) => doc.data()).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COMMENT SYSTEM
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> addComment({
    required String postId,
    required CommentModel comment,
  }) async {
    final batch = _db.batch();

    final commentRef =
        _db.collection('posts').doc(postId).collection('comments').doc();

    batch.set(commentRef, comment.toMap());

    DistributedCounter.incrementInBatch(
        batch, _db.collection('posts').doc(postId), 'commentsCount',
        value: 1);

    await batch.commit();
  }

  Stream<List<CommentModel>> getComments(
    String postId, {
    int limit = 20,
  }) =>
      _db
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
              .toList());

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final batch = _db.batch();

    batch.delete(
      _db.collection('posts').doc(postId).collection('comments').doc(commentId),
    );

    DistributedCounter.incrementInBatch(
        batch, _db.collection('posts').doc(postId), 'commentsCount',
        value: -1);

    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOOKMARK SYSTEM
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> bookmarkPost({
    required String postId,
    required String uid,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(postId)
        .set({
      'postId': postId,
      'bookmarkedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unbookmarkPost({
    required String postId,
    required String uid,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(postId)
        .delete();
  }

  Stream<bool> isBookmarkedStream({
    required String postId,
    required String uid,
  }) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .doc(postId)
          .snapshots()
          .map((snap) => snap.exists);

  Stream<List<String>> getBookmarkedPostIds(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('bookmarks')
      .orderBy('bookmarkedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => doc.id).toList());

  // ═══════════════════════════════════════════════════════════════════════
  // FOLLOW RETRIEVAL
  // ═══════════════════════════════════════════════════════════════════════

  Stream<List<UserProfile>> getFollowers(String uid, {int limit = 20}) => _db
          .collection('followers')
          .doc(uid)
          .collection('userFollowers')
          .orderBy('followedAt', descending: true)
          .limit(limit)
          .snapshots()
          .asyncMap((snap) async {
        final uids = snap.docs.map((doc) => doc.id).toList();
        if (uids.isEmpty) return [];

        final profiles = await Future.wait(uids.map((uid) => _db
            .collection('users')
            .doc(uid)
            .get()
            .then((d) => UserProfile.fromMap(d.data() ?? {}, d.id))));
        return profiles;
      });

  Stream<List<UserProfile>> getFollowing(String uid, {int limit = 20}) => _db
          .collection('following')
          .doc(uid)
          .collection('userFollowing')
          .orderBy('followedAt', descending: true)
          .limit(limit)
          .snapshots()
          .asyncMap((snap) async {
        final uids = snap.docs.map((doc) => doc.id).toList();
        if (uids.isEmpty) return [];

        final profiles = await Future.wait(uids.map((uid) => _db
            .collection('users')
            .doc(uid)
            .get()
            .then((d) => UserProfile.fromMap(d.data() ?? {}, d.id))));
        return profiles;
      });

  Stream<List<UserProfile>> getUsersByUids(List<String> uids) {
    if (uids.isEmpty) return Stream.value([]);

    // Firestore whereIn limit is 30. If more, we'd need to batch.
    // For blocked users, 30 is usually enough for a simple demo/impl.
    return _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: uids.take(30).toList())
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
            .toList());
  }
}
