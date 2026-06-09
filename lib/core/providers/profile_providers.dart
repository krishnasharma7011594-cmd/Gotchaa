import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

/// Real-time stream of the current user's profile document.
///
/// - Watches `authStateProvider` so it automatically re-evaluates on
///   sign-in / sign-out.
/// - Returns a `Stream<UserProfile?>` via Firestore's `snapshots()`.
/// - If the user has no Firestore doc yet (edge case: auth succeeded
///   but Firestore write lagged), the provider calls
///   `ensureUserDocument` to auto-create one — so the profile screen
///   never shows "not found".
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) {
    yield null;
    return;
  }

  final repo = ref.watch(firestoreRepositoryProvider);

  // Safety net: ensure the Firestore document exists before streaming.
  await repo.ensureUserDocument(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
    photoUrl: user.photoURL ?? '',
  );

  // Now stream real-time updates.
  yield* repo.getUserProfileStream(user.uid);
});

final userFollowersProvider =
    StreamProvider.family<List<UserProfile>, String>((ref, uid) {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getFollowers(uid);
});

final userFollowingProvider =
    StreamProvider.family<List<UserProfile>, String>((ref, uid) {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getFollowing(uid);
});

final blockedUsersProvider = StreamProvider<List<UserProfile>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final profileAsync = ref.watch(currentUserProfileProvider);
  final socialRepo = ref.watch(socialRepositoryProvider);

  return profileAsync.when(
    data: (profile) {
      if (profile == null || profile.blockedUids.isEmpty) {
        return Stream.value([]);
      }
      return socialRepo.getUsersByUids(profile.blockedUids);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final ghostUsersProvider = StreamProvider<List<UserProfile>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final socialRepo = ref.watch(socialRepositoryProvider);

  return profileAsync.when(
    data: (profile) {
      if (profile == null || profile.ghostUids.isEmpty) {
        return Stream.value([]);
      }
      return socialRepo.getUsersByUids(profile.ghostUids);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final friendUsersProvider = StreamProvider<List<UserProfile>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final socialRepo = ref.watch(socialRepositoryProvider);

  return profileAsync.when(
    data: (profile) {
      if (profile == null || profile.friendUids.isEmpty) {
        return Stream.value([]);
      }
      return socialRepo.getUsersByUids(profile.friendUids);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
