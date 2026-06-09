/// Firestore Collection Schema: users/{uid}/consents/{consentType}
/// 
/// Document ID: consentType (e.g., "dataProcessing", "marketing")
/// Fields:
/// - granted: Boolean
/// - timestamp: Timestamp
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConsentManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Grants consent for a specific type
  Future<void> grantConsent(String consentType) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('consents')
        .doc(consentType)
        .set({
      'granted': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Revokes consent for a specific type.
  /// This will trigger the Cloud Function stub defined in functions/src/compliance/onConsentRevoked.ts
  Future<void> revokeConsent(String consentType) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('consents')
        .doc(consentType)
        .set({
      'granted': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Checks if consent is granted
  Future<bool> hasConsent(String consentType) async {
    final uid = _uid;
    if (uid == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('consents')
        .doc(consentType)
        .get();

    if (!doc.exists) return false;
    return doc.data()?['granted'] == true;
  }
}
