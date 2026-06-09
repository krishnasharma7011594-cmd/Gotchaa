import '../models/post_model.dart';
import 'content_policy.dart';

class GeoContentFilter {
  /// Checks if a post should be shown based on the region's policy
  bool shouldShowContent(PostModel post, ContentPolicy policy) {
    final textToCheck = (post.caption + ' ' + post.hashtags.join(' ')).toLowerCase();

    // Check LGBTQ+ content
    if (!policy.allowLGBTQContent) {
      final lgbtqKeywords = ['lgbt', 'pride', 'gay', 'lesbian', 'transgender', 'queer'];
      for (final keyword in lgbtqKeywords) {
        if (textToCheck.contains(keyword)) {
          return false;
        }
      }
    }

    // Check Alcohol References
    if (!policy.allowAlcoholReferences) {
      final alcoholKeywords = ['alcohol', 'beer', 'wine', 'vodka', 'whiskey', 'rum', 'cocktail', 'drink', 'bar', 'pub'];
      for (final keyword in alcoholKeywords) {
        // Use word boundary to avoid matching "barrier" or "puddle"
        final regex = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
        if (regex.hasMatch(textToCheck)) {
          return false;
        }
      }
    }

    // Check Dating Features/Content
    if (!policy.allowDatingFeatures) {
      final datingKeywords = ['date', 'dating', 'couple', 'love', 'romance', 'meetup', 'hookup'];
      for (final keyword in datingKeywords) {
        final regex = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
        if (regex.hasMatch(textToCheck)) {
          return false;
        }
      }
    }

    // Check Gambling Content
    if (!policy.allowGamblingContent) {
      final gamblingKeywords = ['gamble', 'gambling', 'bet', 'betting', 'casino', 'slots', 'poker', 'lottery'];
      for (final keyword in gamblingKeywords) {
        final regex = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
        if (regex.hasMatch(textToCheck)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Filters a list of posts based on the policy
  List<PostModel> filterFeed(List<PostModel> posts, ContentPolicy policy) {
    return posts.where((post) => shouldShowContent(post, policy)).toList();
  }
}
