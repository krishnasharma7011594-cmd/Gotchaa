import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import 'repository_providers.dart';

/// Whether current user is following a target user (real-time stream).
final isFollowingProvider =
    StreamProvider.family<bool, ({String myUid, String targetUid})>(
        (ref, args) => ref
            .watch(socialRepositoryProvider)
            .isFollowingStream(myUid: args.myUid, targetUid: args.targetUid));

final isContentLikedProvider = StreamProvider.family<bool,
        ({String contentId, String uid, String contentType, String? parentId})>(
    (ref, args) => ref.watch(socialRepositoryProvider).isLikedStream(
          contentId: args.contentId,
          uid: args.uid,
          contentType: args.contentType,
          parentId: args.parentId,
        ));

/// Whether current user has bookmarked a post.
final isPostBookmarkedProvider =
    StreamProvider.family<bool, ({String postId, String uid})>((ref, args) =>
        ref
            .watch(socialRepositoryProvider)
            .isBookmarkedStream(postId: args.postId, uid: args.uid));

final postCommentsLimitProvider =
    StateProvider.family<int, String>((ref, postId) => 20);

/// Stream comments for a post.
final postCommentsProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  final limit = ref.watch(postCommentsLimitProvider(postId));
  return ref.watch(socialRepositoryProvider).getComments(postId, limit: limit);
});
