import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../providers/auth_providers.dart';

final blockedUidsProvider = StreamProvider<List<String>>((ref) {
  final currentUserId = ref.watch(currentUserProvider)?.uid;
  if (currentUserId == null) {
    return Stream.value([]);
  }

  final firestore = FirebaseFirestore.instance;

  // Stream of accounts blocked by current user
  final blockerStream = firestore
      .collection('blocked_accounts')
      .where('blockerId', isEqualTo: currentUserId)
      .snapshots();

  // Stream of accounts that blocked the current user
  final blockedStream = firestore
      .collection('blocked_accounts')
      .where('blockedId', isEqualTo: currentUserId)
      .snapshots();

  return Rx.combineLatest2(
    blockerStream,
    blockedStream,
    (blockerSnap, blockedSnap) {
      final Set<String> uids = {};
      for (final doc in blockerSnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['blockedId'] != null) {
          uids.add(data['blockedId'] as String);
        }
      }
      for (final doc in blockedSnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['blockerId'] != null) {
          uids.add(data['blockerId'] as String);
        }
      }
      return uids.toList();
    },
  );
});

final mutedUidsProvider = StreamProvider<List<String>>((ref) {
  final currentUserId = ref.watch(currentUserProvider)?.uid;
  if (currentUserId == null) {
    return Stream.value([]);
  }

  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('muted_accounts')
      .where('muterId', isEqualTo: currentUserId)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => doc.data()['mutedId'] as String?)
        .whereType<String>()
        .toList());
});
