import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../utils/distributed_counter.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new post document in the 'posts' collection.
  Future<String> createPost(PostModel post) async {
    final data = post.toMap();

    // Fetch latest privacy lists to ensure the post document has the necessary
    // metadata for visibility filtering.
    final profileDoc =
        await _firestore.collection('users_private').doc(post.uid).get();
    if (profileDoc.exists) {
      data['authorGhostUids'] =
          List<String>.from(profileDoc.data()?['ghostUids'] ?? []);
      data['authorFriendUids'] =
          List<String>.from(profileDoc.data()?['friendUids'] ?? []);

      if (post.visibility.startsWith('list:')) {
        final listId = post.visibility.split(':')[1];
        final List<dynamic> lists =
            profileDoc.data()?['customPrivacyLists'] ?? [];
        final targetListMap = lists.firstWhere(
          (l) => l['id'] == listId,
          orElse: () => null,
        );
        if (targetListMap != null) {
          data['customListUids'] =
              List<String>.from(targetListMap['uids'] ?? []);
        }
      }
    }

    data['updatedAt'] = FieldValue.serverTimestamp();
    final docRef = await _firestore.collection('posts').add(data);
    return docRef.id;
  }

  /// Stream the global posts feed ordered by createdAt descending.
  Stream<List<PostModel>> getPostsFeed(
          {required String currentUid, int limit = 10}) =>
      _firestore
          .collection('posts')
          .where('visibility', isEqualTo: 'public')
          .orderBy('createdAt', descending: true)
          .limit(limit * 2) // Fetch more to allow for filtering
          .snapshots()
          .map((snapshot) {
        final posts = snapshot.docs
            .map((doc) => PostModel.fromMap(doc.data(), doc.id))
            .toList();

        return posts
            .where((post) {
              if (post.uid == currentUid) return true;

              if (post.visibility == 'friends') {
                return post.authorFriendUids.contains(currentUid);
              } else if (post.visibility == 'ghost') {
                return !post.authorGhostUids.contains(currentUid);
              } else if (post.visibility.startsWith('list:')) {
                return post.customListUids.contains(currentUid);
              }
              return true;
            })
            .take(limit)
            .toList();
      });

  /// Stream posts for a specific user ordered by createdAt descending.
  Stream<List<PostModel>> getUserPosts(String uid,
          {required String currentUid, int limit = 50}) =>
      _firestore
          .collection('posts')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        final posts = snapshot.docs
            .map((doc) => PostModel.fromMap(doc.data(), doc.id))
            .toList();

        return posts.where((post) {
          if (post.uid == currentUid) return true;

          if (post.visibility == 'friends') {
            return post.authorFriendUids.contains(currentUid);
          } else if (post.visibility == 'ghost') {
            return !post.authorGhostUids.contains(currentUid);
          } else if (post.visibility.startsWith('list:')) {
            return post.customListUids.contains(currentUid);
          }
          return true;
        }).toList();
      });

  /// Stream posts from users that the current user follows.
  Stream<List<PostModel>> getFollowingPosts(List<String> followingUids,
      {required String currentUid, int limit = 50}) {
    if (followingUids.isEmpty) return Stream.value([]);

    final limitedUids = followingUids.take(30).toList();

    return _firestore
        .collection('posts')
        .where('uid', whereIn: limitedUids)
        .orderBy('createdAt', descending: true)
        .limit(limit * 2)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();

      return posts
          .where((post) {
            if (post.uid == currentUid) return true;

            if (post.visibility == 'friends') {
              return post.authorFriendUids.contains(currentUid);
            } else if (post.visibility == 'ghost') {
              return !post.authorGhostUids.contains(currentUid);
            } else if (post.visibility.startsWith('list:')) {
              return post.customListUids.contains(currentUid);
            }
            return true;
          })
          .take(limit)
          .toList();
    });
  }

  /// Stream posts from a specific country (Nation-based Nearby).
  Stream<List<PostModel>> getNearbyPosts(String countryCode,
          {required String currentUid, int limit = 50}) =>
      _firestore
          .collection('posts')
          .where('isPrivate', isEqualTo: false)
          .where('authorNation', isEqualTo: countryCode)
          .orderBy('createdAt', descending: true)
          .limit(limit * 2)
          .snapshots()
          .map((snapshot) {
        final posts = snapshot.docs
            .map((doc) => PostModel.fromMap(doc.data(), doc.id))
            .toList();

        return posts
            .where((post) {
              if (post.uid == currentUid) return true;

              if (post.visibility == 'friends') {
                return post.authorFriendUids.contains(currentUid);
              } else if (post.visibility == 'ghost') {
                return !post.authorGhostUids.contains(currentUid);
              } else if (post.visibility.startsWith('list:')) {
                return post.customListUids.contains(currentUid);
              }
              return true;
            })
            .take(limit)
            .toList();
      });

  /// Increment the like count for a specific post.
  Future<void> likePost(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    await DistributedCounter.increment(postRef, 'likesCount', value: 1);
    await postRef.update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Increment the view count for a specific post.
  Future<void> incrementPostViews(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    await DistributedCounter.increment(postRef, 'viewsCount', value: 1);
    await postRef.update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Increment the share count for a specific post.
  Future<void> incrementPostShares(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    await DistributedCounter.increment(postRef, 'shareCount', value: 1);
    await postRef.update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a post.
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  /// Save a post for a user
  Future<void> savePost(String uid, String postId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savedPosts')
        .doc(postId)
        .set({
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unsave a post for a user
  Future<void> unsavePost(String uid, String postId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savedPosts')
        .doc(postId)
        .delete();
  }

  /// Stream saved posts for a user
  Stream<List<PostModel>> getSavedPosts(String uid) => _firestore
          .collection('users')
          .doc(uid)
          .collection('savedPosts')
          .orderBy('savedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final postIds = snapshot.docs.map((doc) => doc.id).toList();
        if (postIds.isEmpty) return [];

        // Fetch actual post documents (check both posts and vybz collections)
        final posts = await Future.wait(postIds.map((id) async {
          // Try posts collection first
          var doc = await _firestore.collection('posts').doc(id).get();
          if (doc.exists && doc.data() != null) {
            return PostModel.fromMap(doc.data()!, doc.id);
          }

          // Try vybz collection
          doc = await _firestore.collection('vybz').doc(id).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            // Map Vybz to PostModel for the UI consistency
            return PostModel(
              postId: doc.id,
              uid: data['creatorId'] ?? '',
              caption: data['caption'] ?? '',
              mediaUrl: data['videoUrl'] ??
                  '', // Vybz uses videoUrl but we can show it
              createdAt: data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
              likesCount: data['likes'] ?? 0,
            );
          }
          return null;
        }));

        return posts.whereType<PostModel>().toList();
      });
}
