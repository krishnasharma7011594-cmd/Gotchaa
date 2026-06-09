import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/circle_model.dart';

class CirclesLiveLocationService {
  CirclesLiveLocationService._internal();
  static final CirclesLiveLocationService instance = CirclesLiveLocationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? 'anonymous';

  Timer? _shareTimer;
  StreamSubscription? _mapSubscription;
  bool _isSharing = false;
  bool get isSharing => _isSharing;

  // 1. Verifies if event window is active (eventDate to eventDate + 4 hours)
  bool isEventWindowActive(CircleModel circle) {
    final now = DateTime.now();
    final start = circle.eventDate;
    final end = circle.eventDate.add(const Duration(hours: 4));
    return now.isAfter(start) && now.isBefore(end);
  }

  // 2. Start Live Location Sharing
  Future<void> startSharing(String circleId, CircleModel circle) async {
    if (!isEventWindowActive(circle)) {
      throw Exception('Location sharing is only active during the 4-hour event window.');
    }

    // Verify checked-in status
    final uid = currentUserId;
    final checkinSnap = await _db.collection('circles').doc(circleId).collection('checkins').doc(uid).get();
    if (!checkinSnap.exists) {
      throw Exception('Only users who have successfully checked in can share live locations.');
    }

    _isSharing = true;
    _shareTimer?.cancel();
    
    // Initial upload
    await _uploadLocation(circleId);

    // Upload every 30 seconds to minimize Firestore writes (Cost Protection)
    _shareTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isSharing) {
        timer.cancel();
        return;
      }
      await _uploadLocation(circleId);
    });
  }

  // Upload GPS point to Firestore
  Future<void> _uploadLocation(String circleId) async {
    final uid = currentUserId;
    if (uid == 'anonymous') return;

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userSnap = await _db.collection('users').doc(uid).get();
      final userName = userSnap.data()?['displayName'] ?? 'Member';
      final userAvatar = userSnap.data()?['photoUrl'] ?? '';

      await _db.collection('circles').doc(circleId).collection('liveLocations').doc(uid).set({
        'userId': uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error uploading live location: $e');
    }
  }

  // 3. Stop Location Sharing and immediately purge data from Firestore
  Future<void> stopSharing(String circleId) async {
    _isSharing = false;
    _shareTimer?.cancel();
    final uid = currentUserId;
    if (uid != 'anonymous') {
      await _db.collection('circles').doc(circleId).collection('liveLocations').doc(uid).delete().catchError((_) {});
    }
  }

  // 4. Listen to other sharing members in the circle (Firestore Cost Protection: limited update intervals)
  Stream<List<Map<String, dynamic>>> listenToLiveLocations(String circleId) => _db.collection('circles').doc(circleId).collection('liveLocations')
        .snapshots()
        .map((snap) {
          final now = DateTime.now();
          return snap.docs.map((doc) {
            final data = doc.data();
            final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate() ?? now;
            final diffMins = now.difference(lastUpdated).inMinutes;
            
            return {
              'userId': data['userId'] ?? '',
              'userName': data['userName'] ?? '',
              'userAvatar': data['userAvatar'] ?? '',
              'latitude': data['latitude'] as double,
              'longitude': data['longitude'] as double,
              'lastUpdated': lastUpdated,
              'minutesAgo': diffMins,
              'isOffline': diffMins >= 2, // Offline pin fade threshold
            };
          }).toList();
        });

  // Clean listeners on leaving or backgrounding
  void disposeListeners(String circleId) {
    stopSharing(circleId);
    _mapSubscription?.cancel();
  }
}
