import 'package:cloud_firestore/cloud_firestore.dart';

/// Returns cached [QuerySnapshot] when the same query runs within [ttl].
class FirestoreQueryCache {
  FirestoreQueryCache._();
  static final FirestoreQueryCache instance = FirestoreQueryCache._();

  static const Duration defaultTtl = Duration(seconds: 60);

  final Map<String, _CacheEntry> _cache = {};

  String _key(Query query) => query.hashCode.toString();

  Future<QuerySnapshot<Map<String, dynamic>>> get(
    Query<Map<String, dynamic>> query, {
    Duration ttl = defaultTtl,
  }) async {
    final key = _key(query);
    final now = DateTime.now();
    final hit = _cache[key];
    if (hit != null && now.difference(hit.fetchedAt) < ttl) {
      return hit.snapshot;
    }
    final snapshot = await query.get();
    _cache[key] = _CacheEntry(snapshot, now);
    return snapshot;
  }

  void invalidate([Query? query]) {
    if (query == null) {
      _cache.clear();
      return;
    }
    _cache.remove(_key(query));
  }
}

class _CacheEntry {
  _CacheEntry(this.snapshot, this.fetchedAt);
  final QuerySnapshot<Map<String, dynamic>> snapshot;
  final DateTime fetchedAt;
}
