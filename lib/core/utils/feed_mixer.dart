import '../models/feed_item.dart';
import '../models/post_model.dart';
import '../models/vybz_model.dart';

class FeedMixer {
  /// Mixes standard posts and Vybz videos into a unified feed.
  /// Logic: Inject a Vybz video every [mixInterval] items.
  static List<FeedItem> mix({
    required List<PostModel> posts,
    required List<VybzModel> vybz,
    int mixInterval = 5,
  }) {
    final List<FeedItem> mixedFeed = [];
    int vybzIndex = 0;

    for (int i = 0; i < posts.length; i++) {
      // Add the standard post
      mixedFeed.add(PostFeedItem(posts[i]));

      // Check if we should inject a Vybz video
      // (i + 1) % mixInterval == 0 means after the 4th, 9th, 14th... post
      if ((i + 1) % mixInterval == 0 && vybzIndex < vybz.length) {
        mixedFeed.add(VybzFeedItem(vybz[vybzIndex]));
        vybzIndex++;
      }
    }

    // If we have remaining Vybz videos, add them at the end (optional)
    // while (vybzIndex < vybz.length) {
    //   mixedFeed.add(VybzFeedItem(vybz[vybzIndex]));
    //   vybzIndex++;
    // }

    return mixedFeed;
  }
}
