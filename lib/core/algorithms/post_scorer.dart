import 'dart:math';
import '../models/post_model.dart';
import '../models/user_profile.dart';

class PostScorer {
  /// Calculate a score for a post based on user preferences and engagement.
  /// Higher score = more relevant for 'For You' feed.
  static double calculateScore(PostModel post, UserProfile? currentUser) {
    double score = 0;

    // 1. Recency (Highest Weight)
    // Posts decay over time. Fresh posts (last 24h) get a huge boost.
    final ageInHours = DateTime.now().difference(post.createdAt).inHours;
    final recencyScore =
        100 / (ageInHours + 1); // 100 for brand new, 4 for 24h old
    score += recencyScore * 5.0; // Recency multiplier

    // 2. Engagement (Social Proof)
    // Weighted likes and comments. Comments weighted more as they show higher intent.
    final engagement = (post.likesCount * 1.0) +
        (post.commentsCount * 2.0) +
        (post.shareCount * 3.0);
    score += engagement * 1.5;

    // 3. Geographic Relevance (Nation)
    // Users love seeing content from their own country.
    if (currentUser != null && currentUser.nation != null) {
      final userCountry = currentUser.nation!['currentCountry'] as String?;
      if (userCountry != null && post.authorNation == userCountry) {
        score += 50.0; // Large boost for same country
      } else if (currentUser.nation!['currentContinent'] == post.authorNation) {
        // Fallback: boost for same continent (if we had continent in post model, but we have nation code)
        // For now, exact country match is primary.
      }
    }

    // 4. Linguistic Relevance (Language)
    // Content in the user's primary language is prioritized.
    if (currentUser != null && currentUser.nation != null) {
      final userLanguage = currentUser.nation!['languageCode'] as String?;
      if (userLanguage != null && post.authorLanguage == userLanguage) {
        score += 30.0;
      }
    }

    // 5. Verification Boost
    // Verified creators get a small visibility boost.
    // (Note: we'd need to check if the author is verified, which might require a separate fetch or including it in the post)
    // For now, let's assume we might add 'isAuthorVerified' to PostModel later.

    // 6. Random Variation (Serendipity)
    // Add a tiny bit of randomness so the feed doesn't feel static.
    score += Random().nextDouble() * 5.0;

    return score;
  }
}
