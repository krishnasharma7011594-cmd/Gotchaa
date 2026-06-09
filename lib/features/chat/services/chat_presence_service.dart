import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatPresenceServiceProvider = Provider<ChatPresenceService>((ref) => ChatPresenceService());

class ChatPresenceService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void initializePresence() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final connectedRef = _db.ref('.info/connected');
    final userStatusRef = _db.ref('status/$uid');

    connectedRef.onValue.listen((event) {
      if (event.snapshot.value == true) {
        userStatusRef.onDisconnect().update({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });
        userStatusRef.update({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });
      }
    });
  }

  void setOffline() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final userStatusRef = _db.ref('status/$uid');
    userStatusRef.update({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });
  }
}
