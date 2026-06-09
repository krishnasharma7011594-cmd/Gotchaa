import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class DistributedCounter {
  static const int numShards = 10;

  /// Increments a distributed counter shard.
  static Future<void> increment(DocumentReference docRef, String counterName,
      {int value = 1}) async {
    final shardId = Random().nextInt(numShards).toString();
    final shardRef = docRef.collection('${counterName}_shards').doc(shardId);
    await shardRef.set({
      'count': FieldValue.increment(value),
    }, SetOptions(merge: true));
  }

  /// Increments using a WriteBatch.
  static void incrementInBatch(
      WriteBatch batch, DocumentReference docRef, String counterName,
      {int value = 1}) {
    final shardId = Random().nextInt(numShards).toString();
    final shardRef = docRef.collection('${counterName}_shards').doc(shardId);
    batch.set(
        shardRef,
        {
          'count': FieldValue.increment(value),
        },
        SetOptions(merge: true));
  }

  /// Streams the sum of all shards for a counter.
  static Stream<int> streamCount(
          DocumentReference docRef, String counterName) =>
      docRef.collection('${counterName}_shards').snapshots().map((snapshot) {
        int total = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          total += (data['count'] ?? 0) as int;
        }
        return total;
      });

  /// Fetches the sum of all shards (one-shot).
  static Future<int> getCount(
      DocumentReference docRef, String counterName) async {
    final snapshot = await docRef.collection('${counterName}_shards').get();
    int total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      total += (data['count'] ?? 0) as int;
    }
    return total;
  }
}
