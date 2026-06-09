import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vybz_model.dart';
import '../services/block_mute_service.dart';
import 'repository_providers.dart';

final vybzFeedLimitProvider = StateProvider<int>((ref) => 10);
final activeVybzIdProvider = StateProvider<String?>((ref) => null);

final vybzFeedProvider = StreamProvider<List<VybzModel>>((ref) {
  final limit = ref.watch(vybzFeedLimitProvider);
  final blockedUids = ref.watch(blockedUidsProvider).value ?? [];
  final mutedUids = ref.watch(mutedUidsProvider).value ?? [];
  
  return ref.watch(firestoreRepositoryProvider).getVybzFeed(limit: limit).map((list) {
    return list.where((v) => !blockedUids.contains(v.creatorId) && !mutedUids.contains(v.creatorId)).toList();
  });
});

final userVybzLimitProvider = StateProvider.family<int, String>((ref, userId) => 10);

final userVybzProvider = StreamProvider.family<List<VybzModel>, String>((ref, userId) {
  final limit = ref.watch(userVybzLimitProvider(userId));
  return ref.watch(firestoreRepositoryProvider).getUserVybz(userId, limit: limit);
});

final vybzCommentsProvider = StreamProvider.family<List<dynamic>, String>((ref, vybzId) => ref.watch(firestoreRepositoryProvider).getVybzComments(vybzId));
