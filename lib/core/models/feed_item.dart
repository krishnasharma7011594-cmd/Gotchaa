import 'post_model.dart';
import 'vybz_model.dart';

enum FeedItemType { image, video, vybz, musicPost }

sealed class FeedItem {
  FeedItem({
    required this.id,
    required this.createdAt,
    required this.type,
  });
  final String id;
  final DateTime createdAt;
  final FeedItemType type;
}

class PostFeedItem extends FeedItem {
  PostFeedItem(this.post)
      : super(
          id: post.postId,
          createdAt: post.createdAt,
          type: post.spotifyTrackId != null
              ? FeedItemType.musicPost
              : post.mediaUrl.endsWith('.mp4') // Simplified check
                  ? FeedItemType.video
                  : FeedItemType.image,
        );
  final PostModel post;
}

class VybzFeedItem extends FeedItem {
  VybzFeedItem(this.vybz)
      : super(
          id: vybz.id,
          createdAt: vybz.createdAt ?? DateTime.now(),
          type: FeedItemType.vybz,
        );
  final VybzModel vybz;
}
