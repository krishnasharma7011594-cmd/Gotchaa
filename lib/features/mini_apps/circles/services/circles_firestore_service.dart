import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/circle_join_request.dart';
import '../models/circle_message.dart';
import '../models/circle_model.dart';
import '../models/user_onboarding_model.dart';

class CirclesFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Session read monitor for Firestore Cost Protection (max 1000 reads per session)
  int _sessionReadCount = 0;
  int get sessionReadCount => _sessionReadCount;
  bool get isThrottled => _sessionReadCount >= 1000;

  void _incrementReads(int count) {
    _sessionReadCount += count;
    if (_sessionReadCount >= 1000) {
      debugPrint(
          'WARNING: Circles Firestore reads exceeded 1000! Throttling active.');
    }
  }

  String get currentUserId => _auth.currentUser?.uid ?? 'anonymous';

  // Enforces max 3 active circles per user
  Future<bool> canCreateCircle() async {
    if (isThrottled) return false;
    final uid = currentUserId;
    final snap = await _db
        .collection('circles')
        .where('hostId', isEqualTo: uid)
        .where('isActive', isEqualTo: true)
        .get();

    _incrementReads(snap.docs.length);
    return snap.docs.length < 3;
  }

  // Create circle
  Future<CircleModel> createCircle(CircleModel circle) async {
    if (isThrottled) {
      throw Exception('Firestore queries throttled. Please try again later.');
    }
    final docRef = _db.collection('circles').doc();
    final newCircle = circle.copyWith(id: docRef.id, hostId: currentUserId);
    await docRef.set(newCircle.toMap());

    // Add host as a confirmed member instantly
    await docRef.update({
      'memberIds': FieldValue.arrayUnion([currentUserId])
    });

    // Award karma to host (+20 karma)
    await updateUserKarma(currentUserId, 20);

    return newCircle;
  }

  // Fetch paginated feed (10 circles max)
  Future<List<CircleModel>> fetchCirclesFeed({
    DocumentSnapshot? startAfterDoc,
    String? categoryFilter,
    String? cityFilter,
    String? searchQuery,
  }) async {
    if (isThrottled) return [];

    Query query = _db.collection('circles').where('isActive', isEqualTo: true);

    if (categoryFilter != null &&
        categoryFilter.isNotEmpty &&
        categoryFilter != 'All') {
      query = query.where('category', isEqualTo: categoryFilter);
    }
    if (cityFilter != null && cityFilter.isNotEmpty) {
      query = query.where('city', isEqualTo: cityFilter);
    }

    query = query.orderBy('createdAt', descending: true).limit(10);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final snap = await query.get();
    _incrementReads(snap.docs.length);

    List<CircleModel> circles = snap.docs
        .map((doc) =>
            CircleModel.fromMap(doc.data()! as Map<String, dynamic>, doc.id))
        .toList();

    // Client-side local search / hashtags support
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      final isHashtag = queryLower.startsWith('#');
      circles = circles.where((c) {
        if (isHashtag) {
          final cleanTag = queryLower.replaceAll('#', '');
          return c.tags.any((t) => t.toLowerCase() == cleanTag) ||
              c.category.toLowerCase() == cleanTag;
        } else {
          return c.title.toLowerCase().contains(queryLower) ||
              c.description.toLowerCase().contains(queryLower) ||
              c.tags.any((t) => t.toLowerCase().contains(queryLower));
        }
      }).toList();
    }

    return circles;
  }

  // Onboarding profile storage
  Future<void> saveOnboarding(UserOnboarding onboarding) async {
    if (isThrottled) return;
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('circles_profile')
        .doc('onboarding')
        .set(onboarding.toMap());
  }

  // Onboarding profile load
  Future<UserOnboarding?> loadOnboarding() async {
    if (isThrottled) return null;
    final snap = await _db
        .collection('users')
        .doc(currentUserId)
        .collection('circles_profile')
        .doc('onboarding')
        .get();
    _incrementReads(1);
    if (!snap.exists || snap.data() == null) return null;
    return UserOnboarding.fromMap(snap.data()!, currentUserId);
  }

  // Join System
  Future<void> sendJoinRequest(String circleId, String introMessage) async {
    if (isThrottled) return;
    final userSnap = await _db.collection('users').doc(currentUserId).get();
    _incrementReads(1);
    final userName = userSnap.data()?['displayName'] ?? 'New Member';
    final userAvatar = userSnap.data()?['photoUrl'] ?? '';
    final karma = userSnap.data()?['karmaScore'] ?? 10;

    String tier = 'New';
    if (karma > 200) {
      tier = 'Verified';
    } else if (karma > 50) tier = 'Trusted';

    final docRef = _db.collection('circle_join_requests').doc();
    final req = CircleJoinRequest(
      requestId: docRef.id,
      circleId: circleId,
      userId: currentUserId,
      userName: userName,
      userAvatar: userAvatar,
      introMessage: introMessage,
      karmaScore: karma,
      trustTier: tier,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await docRef.set(req.toMap());
  }

  // Accept/reject request
  Future<void> updateJoinRequest(CircleJoinRequest request, bool accept) async {
    if (isThrottled) return;
    final status = accept ? 'accepted' : 'rejected';
    await _db.collection('circle_join_requests').doc(request.requestId).update({
      'status': status,
    });

    if (accept) {
      // Add member to circle
      await _db.collection('circles').doc(request.circleId).update({
        'memberIds': FieldValue.arrayUnion([request.userId])
      });
      // Award attendee karma +10 for verified check-in / joining
      await updateUserKarma(request.userId, 10);
    }
  }

  // Streams join requests for host
  Stream<List<CircleJoinRequest>> streamHostRequests(String circleId) {
    if (isThrottled) return Stream.value([]);
    return _db
        .collection('circle_join_requests')
        .where('circleId', isEqualTo: circleId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      _incrementReads(snap.docs.length);
      return snap.docs
          .map((doc) => CircleJoinRequest.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Stream paginated messages (max 50 messages)
  Stream<List<CircleMessage>> streamChatMessages(String circleId) {
    if (isThrottled) return Stream.value([]);
    return _db
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
      _incrementReads(snap.docs.length);
      final now = DateTime.now();
      // Filter out expired TTL messages client-side
      return snap.docs
          .map((doc) => CircleMessage.fromMap(doc.data(), doc.id))
          .where((m) => m.ttl.isAfter(now))
          .toList();
    });
  }

  // Send message
  Future<void> sendChatMessage(String circleId, String text,
      {Map<String, dynamic>? pinLocation}) async {
    if (isThrottled) return;

    // Get sender info
    final userSnap = await _db.collection('users').doc(currentUserId).get();
    _incrementReads(1);
    final userName = userSnap.data()?['displayName'] ?? 'New Member';
    final userAvatar = userSnap.data()?['photoUrl'] ?? '';

    // Message expires 24 hours after the circle's event ends. Let's get circle details
    final circleSnap = await _db.collection('circles').doc(circleId).get();
    _incrementReads(1);
    final eventDate =
        (circleSnap.data()?['eventDate'] as Timestamp?)?.toDate() ??
            DateTime.now();
    final ttl = eventDate.add(const Duration(hours: 24));

    final docRef =
        _db.collection('circles').doc(circleId).collection('messages').doc();
    final msg = CircleMessage(
      messageId: docRef.id,
      chatId: circleId,
      senderId: currentUserId,
      senderName: userName,
      senderAvatar: userAvatar,
      text: text,
      timestamp: DateTime.now(),
      ttl: ttl,
      isPinned: pinLocation != null,
      pinLocation: pinLocation,
    );

    await docRef.set(msg.toMap());
  }

  // Reports
  Future<void> reportItem({
    required String itemType, // 'circle' or 'message'
    required String itemId,
    required String reportedUserId,
    required String reason,
  }) async {
    if (isThrottled) return;
    await _db.collection('reports').add({
      'itemType': itemType,
      'itemId': itemId,
      'reportedUserId': reportedUserId,
      'reporterUserId': currentUserId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Block User
  Future<void> blockUser(String blockUserId) async {
    if (isThrottled) return;
    await _db.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([blockUserId])
    });
  }

  // Get current blocked users list
  Future<List<String>> getBlockedUsers() async {
    if (isThrottled) return [];
    final userSnap = await _db.collection('users').doc(currentUserId).get();
    _incrementReads(1);
    return List<String>.from(userSnap.data()?['blockedUsers'] ?? []);
  }

  // Helpers to update user karma score
  Future<void> updateUserKarma(String userId, int points) async {
    final userRef = _db.collection('users').doc(userId);
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(userRef);
      if (snap.exists) {
        final currentKarma = snap.data()?['karmaScore'] ?? 0;
        transaction.update(userRef, {'karmaScore': currentKarma + points});
      } else {
        transaction.set(userRef, {'karmaScore': points});
      }
    });
  }
}
