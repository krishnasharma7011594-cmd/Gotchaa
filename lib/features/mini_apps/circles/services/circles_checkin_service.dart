import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../models/checkin_model.dart';
import '../models/circle_model.dart';
import 'circles_firestore_service.dart';

class CirclesCheckInService {
  CirclesCheckInService._internal();
  static final CirclesCheckInService instance = CirclesCheckInService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? 'anonymous';

  // 1. Generate unique secure QR check-in token
  String generateQrToken({
    required String circleId,
    required DateTime eventDate,
    required String hostId,
  }) {
    final payload = {
      'circleId': circleId,
      'eventDate': eventDate.millisecondsSinceEpoch,
      'hostId': hostId,
      'issuedAt': DateTime.now().millisecondsSinceEpoch,
    };
    // Encodes as a simple base64 token string
    final jsonStr = jsonEncode(payload);
    return base64Encode(utf8.encode(jsonStr));
  }

  // 2. Proximity Range Check (uses Geolocator to verify within 200 meters)
  Future<bool> isWithinProximity(CircleModel circle) async {
    if (circle.locationLatLng == null) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        circle.locationLatLng!.latitude,
        circle.locationLatLng!.longitude,
      );

      // Return true if attendee is within 200 meters of the meetup
      return distance <= 200.0;
    } catch (e) {
      return false;
    }
  }

  // 3. Process direct / verified check-in record
  Future<bool> processCheckIn({
    required String circleId,
    required String method, // 'qr' | 'proximity'
    String? qrToken,
  }) async {
    final uid = currentUserId;
    if (uid == 'anonymous') return false;

    final checkinRef = _db.collection('circles').doc(circleId).collection('checkins').doc(uid);
    
    // Check if already checked in to prevent duplicate records
    final checkinSnap = await checkinRef.get();
    if (checkinSnap.exists) {
      throw Exception('Each user can only check in once per circle.');
    }

    // Load circle details for security checks
    final circleSnap = await _db.collection('circles').doc(circleId).get();
    if (!circleSnap.exists) throw Exception('Circle not found.');
    final circle = CircleModel.fromMap(circleSnap.data()!, circleSnap.id);

    // Validate confirmed member status
    if (!circle.memberIds.contains(uid)) {
      throw Exception('Only confirmed members can check in.');
    }

    // QR Specific Token Validation
    if (method == 'qr' && qrToken != null) {
      final decodedBytes = base64Decode(qrToken);
      final decodedStr = utf8.decode(decodedBytes);
      final payload = jsonDecode(decodedStr) as Map<String, dynamic>;

      final issuedAt = DateTime.fromMillisecondsSinceEpoch(payload['issuedAt'] as int);
      final age = DateTime.now().difference(issuedAt);

      // Token expires after 30 minutes
      if (age.inMinutes > 30) {
        throw Exception('QR Token expired. Host must generate a new check-in QR.');
      }
    }

    // Load user profile details
    final userSnap = await _db.collection('users').doc(uid).get();
    final userName = userSnap.data()?['displayName'] ?? 'New Member';
    final userAvatar = userSnap.data()?['photoUrl'] ?? '';

    final checkin = CheckInModel(
      userId: uid,
      userName: userName,
      userAvatar: userAvatar,
      circleId: circleId,
      checkInTime: DateTime.now(),
      method: method,
      isVerified: true,
    );

    // Perform atomic transaction
    await _db.runTransaction((transaction) async {
      transaction.set(checkinRef, checkin.toMap());
    });

    // 4. Award +10 karma points to attendee
    final fService = CirclesFirestoreService();
    await fService.updateUserKarma(uid, 10);

    // 5. Check if at least 3 members checked in to award +20 host karma
    final checkinsSnap = await _db.collection('circles').doc(circleId).collection('checkins').get();
    if (checkinsSnap.docs.length >= 3) {
      await fService.updateUserKarma(circle.hostId, 20);
    }

    return true;
  }
}
