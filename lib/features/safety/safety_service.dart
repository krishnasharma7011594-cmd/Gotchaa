import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SafetyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? 'anonymous';

  /// Blocks a user
  Future<void> blockUser(String targetUserId) async {
    if (_currentUserId == 'anonymous') return;

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('blocked')
        .doc(targetUserId)
        .set({
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mutes a user
  Future<void> muteUser(String targetUserId) async {
    if (_currentUserId == 'anonymous') return;

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('muted')
        .doc(targetUserId)
        .set({
      'mutedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Checks if a user is blocked by the current user
  Future<bool> isBlocked(String targetUserId) async {
    if (_currentUserId == 'anonymous') return false;

    final doc = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('blocked')
        .doc(targetUserId)
        .get();

    return doc.exists;
  }

  /// Checks if a user is muted by the current user
  Future<bool> isMuted(String targetUserId) async {
    if (_currentUserId == 'anonymous') return false;

    final doc = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('muted')
        .doc(targetUserId)
        .get();

    return doc.exists;
  }
}
