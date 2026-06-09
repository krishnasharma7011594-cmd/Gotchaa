import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/firebase/performance_traces.dart';

class VibeMatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? 'unauthenticated';
  StreamSubscription? _queueSub;

  /// Starts the high-speed matching process.
  Future<({String roomId, bool isCaller})> findMatch({
    required String languageCode,
    required String continent,
    required bool wantsGames,
    required bool wantsVideo,
    required bool preferSameLanguage,
    required bool preferSameContinent,
  }) async {
    final currentUid = uid;
    if (currentUid == 'unauthenticated') throw Exception('User not logged in');

    await GotchaaPerformanceTraces.instance.startVibeTalkMatch();
    try {
    // 1. Initial attempt to grab an existing waiting user
    final initialMatch = await _tryToGrabMatch(
      currentUid: currentUid,
      languageCode: languageCode,
      continent: continent,
      wantsVideo: wantsVideo,
      strict: true,
    );
    if (initialMatch != null) return initialMatch;

    // 2. Not found immediately? Join the queue and wait
    final queueRef = _db.collection('vibetalk_queue').doc(currentUid);
    await queueRef.set({
      'uid': currentUid,
      'isMatched': false,
      'matchedWith': null,
      'roomId': null,
      'joinedAt': FieldValue.serverTimestamp(),
      'languageCode': languageCode,
      'continent': continent,
      'wantsGames': wantsGames,
      'wantsVideo': wantsVideo,
    });

    final completer = Completer<({String roomId, bool isCaller})>();
    int searchSeconds = 0;

    // 3. Start a timer to periodically try grabbing others while waiting
    // This handles the case where two people joined almost at the same time
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (completer.isCompleted) {
        timer.cancel();
        return;
      }

      searchSeconds += 3;
      
      // Every 10 seconds, we get less strict
      final bool isStrict = searchSeconds < 15;

      final grabbedMatch = await _tryToGrabMatch(
        currentUid: currentUid,
        languageCode: languageCode,
        continent: continent,
        wantsVideo: wantsVideo,
        strict: isStrict,
      );

      if (grabbedMatch != null && !completer.isCompleted) {
        timer.cancel();
        await queueRef.delete().catchError((_) {});
        completer.complete(grabbedMatch);
      }
    });

    // 4. Listen for someone ELSE grabbing US
    _queueSub = queueRef.snapshots().listen((snap) async {
      if (!snap.exists || completer.isCompleted) return;
      final data = snap.data();
      
      if (data != null && data['isMatched'] == true && data['roomId'] != null) {
        final roomId = data['roomId'] as String;
        _queueSub?.cancel();
        if (!completer.isCompleted) {
          completer.complete((roomId: roomId, isCaller: false));
        }
      }
    });

    try {
      return await completer.future.timeout(const Duration(seconds: 60));
    } on TimeoutException {
      await cancelMatch();
      throw Exception('No one is online right now. Try again in a minute!');
    } catch (e) {
      await cancelMatch();
      rethrow;
    }
    } finally {
      await GotchaaPerformanceTraces.instance.stopVibeTalkMatch();
    }
  }

  /// Internal helper to look for candidates and perform an atomic "grab"
  Future<({String roomId, bool isCaller})?> _tryToGrabMatch({
    required String currentUid,
    required String languageCode,
    required String continent,
    required bool wantsVideo,
    required bool strict,
  }) async {
    try {
      Query query = _db.collection('vibetalk_queue')
          .where('isMatched', isEqualTo: false)
          .where('wantsVideo', isEqualTo: wantsVideo);

      if (strict) {
        // In strict mode, we prefer people from the same continent
        query = query.where('continent', isEqualTo: continent);
      }

      final snapshot = await query.orderBy('joinedAt').limit(10).get();
      final candidates = snapshot.docs.where((d) => d.id != currentUid).toList();

      if (candidates.isEmpty) return null;

      // Pick the best candidate (simplifying scoring to speed up)
      DocumentSnapshot? target;
      if (strict) {
        // Try to find someone with same language among continent matches
        target = candidates.firstWhere(
          (c) => (c.data()! as Map)['languageCode'] == languageCode,
          orElse: () => candidates.first,
        );
      } else {
        target = candidates.first; // Just grab the oldest waiting person
      }

      final roomId = const Uuid().v4();
      final targetRef = target.reference;
      final targetId = target.id;

      final success = await _db.runTransaction<bool>((tx) async {
        final freshSnap = await tx.get(targetRef);
        final data = freshSnap.data() as Map<String, dynamic>?;
        if (!freshSnap.exists || data?['isMatched'] == true) return false;

        tx.update(targetRef, {
          'isMatched': true,
          'matchedWith': currentUid,
          'roomId': roomId,
        });

        tx.set(_db.collection('vibetalk_rooms').doc(roomId), {
          'id': roomId,
          'callerId': currentUid,
          'calleeId': targetId,
          'users': [targetId, currentUid],
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'reconnectionState': 'stable',
        });
        return true;
      });

      if (success) {
        return (roomId: roomId, isCaller: true);
      }
    } catch (e) {
      
    }
    return null;
  }

  Future<void> cancelMatch() async {
    await _queueSub?.cancel();
    await _db.collection('vibetalk_queue').doc(uid).delete().catchError((_) {});
  }
}
