import 'package:async/async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../algorithms/post_scorer.dart';
import '../geo/content_policy.dart';
import '../geo/geo_compliance_service.dart';
import '../geo/geo_content_filter.dart';
import '../models/feed_item.dart';
import '../models/post_model.dart';
import '../models/vybz_model.dart';
import '../services/block_mute_service.dart';
import '../utils/feed_mixer.dart';
import 'auth_providers.dart';
import 'profile_providers.dart';
import 'repository_providers.dart';

final postsFeedLimitProvider = StateProvider<int>((ref) => 10);

/// Mixed Feed for the 'For You' tab.
/// Uses the algorithmic PostScorer and interleaves Vybz videos.
final forYouFeedProvider = StreamProvider<List<FeedItem>>((ref) {
  final limit = ref.watch(postsFeedLimitProvider);
  final userProfile = ref.watch(currentUserProfileProvider).asData?.value;
  final postRepo = ref.watch(postRepositoryProvider);
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);

  final currentUser = ref.watch(currentUserProvider);

  final blockedUids = ref.watch(blockedUidsProvider).value ?? [];
  final mutedUids = ref.watch(mutedUidsProvider).value ?? [];

  // Combine posts and vybz streams
  final postsStream =
      postRepo.getPostsFeed(currentUid: currentUser?.uid ?? '', limit: limit);
  final vybzStream = firestoreRepo.getVybzFeed(limit: limit ~/ 5 + 1);

  return RxMixer.combine(postsStream, vybzStream).map((data) {
    // Filter out posts and vybz from blocked/muted users
    final posts = data.posts
        .where(
            (p) => !blockedUids.contains(p.uid) && !mutedUids.contains(p.uid))
        .toList();
    final vybz = data.vybz
        .where((v) =>
            !blockedUids.contains(v.creatorId) &&
            !mutedUids.contains(v.creatorId))
        .toList();

    // Apply Geo Content Filtering
    final countryCode =
        userProfile?.nation?['currentCountry'] as String? ?? 'US';
    final region = GeoComplianceService().getRegionForCountry(countryCode);
    final policy = ContentPolicy.forRegion(region);
    final filteredPosts = GeoContentFilter().filterFeed(posts, policy);

    // 1. Score and Sort Posts
    final sortedPosts = List<PostModel>.from(filteredPosts);
    sortedPosts.sort((a, b) {
      final scoreA = PostScorer.calculateScore(a, userProfile);
      final scoreB = PostScorer.calculateScore(b, userProfile);
      return scoreB.compareTo(scoreA); // Descending
    });

    // 2. Mix in Vybz
    return FeedMixer.mix(posts: sortedPosts, vybz: vybz);
  });
});

/// Mixed Feed for the 'Following' tab.
final followingFeedProvider = StreamProvider<List<FeedItem>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value([]);

  final userProfile = ref.watch(currentUserProfileProvider).asData?.value;
  final countryCode = userProfile?.nation?['currentCountry'] as String? ?? 'US';
  final region = GeoComplianceService().getRegionForCountry(countryCode);
  final policy = ContentPolicy.forRegion(region);

  final followingList =
      ref.watch(userFollowingProvider(currentUser.uid)).asData?.value ?? [];
  final followingUids = followingList.map((u) => u.uid).toList();

  if (followingUids.isEmpty) return Stream.value([]);

  final limit = ref.watch(postsFeedLimitProvider);
  final postRepo = ref.watch(postRepositoryProvider);
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);

  final blockedUids = ref.watch(blockedUidsProvider).value ?? [];
  final mutedUids = ref.watch(mutedUidsProvider).value ?? [];

  final postsStream = postRepo.getFollowingPosts(followingUids,
      currentUid: currentUser.uid, limit: limit);
  final vybzStream = firestoreRepo.getVybzFeed(
      limit: 5); // Global vybz fallback or following-only vybz if we had it

  return RxMixer.combine(postsStream, vybzStream).map((data) {
    // Filter out blocked/muted users
    final posts = data.posts
        .where(
            (p) => !blockedUids.contains(p.uid) && !mutedUids.contains(p.uid))
        .toList();
    final vybz = data.vybz
        .where((v) =>
            !blockedUids.contains(v.creatorId) &&
            !mutedUids.contains(v.creatorId))
        .toList();

    final filteredPosts = GeoContentFilter().filterFeed(posts, policy);
    return FeedMixer.mix(posts: filteredPosts, vybz: vybz);
  });
});

/// Mixed Feed for the 'Nearby' tab.
final nearbyFeedProvider = StreamProvider<List<FeedItem>>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider).asData?.value;
  if (userProfile == null || userProfile.nation == null)
    return Stream.value([]);

  final countryCode = userProfile.nation!['currentCountry'] as String?;
  if (countryCode == null) return Stream.value([]);

  final limit = ref.watch(postsFeedLimitProvider);
  final postRepo = ref.watch(postRepositoryProvider);
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);

  final currentUser = ref.watch(currentUserProvider);
  final region = GeoComplianceService().getRegionForCountry(countryCode);
  final policy = ContentPolicy.forRegion(region);

  final blockedUids = ref.watch(blockedUidsProvider).value ?? [];
  final mutedUids = ref.watch(mutedUidsProvider).value ?? [];

  final postsStream = postRepo.getNearbyPosts(countryCode,
      currentUid: currentUser?.uid ?? '', limit: limit);
  final vybzStream = firestoreRepo.getVybzFeed(limit: 5);

  return RxMixer.combine(postsStream, vybzStream).map((data) {
    // Filter out blocked/muted users
    final posts = data.posts
        .where(
            (p) => !blockedUids.contains(p.uid) && !mutedUids.contains(p.uid))
        .toList();
    final vybz = data.vybz
        .where((v) =>
            !blockedUids.contains(v.creatorId) &&
            !mutedUids.contains(v.creatorId))
        .toList();

    final filteredPosts = GeoContentFilter().filterFeed(posts, policy);
    return FeedMixer.mix(posts: filteredPosts, vybz: vybz);
  });
});

/// Helper class to combine streams for the Mixer.
class RxMixer {
  static Stream<({List<PostModel> posts, List<VybzModel> vybz})> combine(
    Stream<List<PostModel>> posts,
    Stream<List<VybzModel>> vybz,
  ) async* {
    List<PostModel> latestPosts = [];
    List<VybzModel> latestVybz = [];

    await for (final event in _merge(posts, vybz)) {
      if (event is List<PostModel>) latestPosts = event;
      if (event is List<VybzModel>) latestVybz = event;
      yield (posts: latestPosts, vybz: latestVybz);
    }
  }

  static Stream<dynamic> _merge(
      Stream<List<PostModel>> s1, Stream<List<VybzModel>> s2) async* {
    final stream1 = s1.handleError((_) => null);
    final stream2 = s2.handleError((_) => null);
    await for (final val in StreamGroup.merge([stream1, stream2])) {
      yield val;
    }
  }
}

// Keep other providers
final userPostsLimitProvider =
    StateProvider.family<int, String>((ref, uid) => 10);

final userPostsProvider =
    StreamProvider.family<List<PostModel>, String>((ref, uid) {
  final limit = ref.watch(userPostsLimitProvider(uid));
  final currentUid = ref.watch(currentUserProvider)?.uid ?? '';
  return ref
      .watch(postRepositoryProvider)
      .getUserPosts(uid, currentUid: currentUid, limit: limit);
});

final currentUserPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  final limit = ref.watch(userPostsLimitProvider(uid));
  return ref
      .watch(postRepositoryProvider)
      .getUserPosts(uid, currentUid: uid, limit: limit);
});

final savedPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(postRepositoryProvider).getSavedPosts(uid);
});
