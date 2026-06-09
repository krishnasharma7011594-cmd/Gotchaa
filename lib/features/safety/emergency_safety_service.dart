import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/logging/app_logger.dart';

/// VibeTalk / chat emergency safety: SOS, safe word, shake report.
class EmergencySafetyService {
  EmergencySafetyService._();
  static final EmergencySafetyService instance = EmergencySafetyService._();

  static const _safeWordKey = 'vibetalk_safe_word';

  String? _safeWord;

  void setSafeWord(String word) => _safeWord = word.trim().toLowerCase();

  bool checkSafeWord(String message) {
    if (_safeWord == null || _safeWord!.isEmpty) return false;
    return message.trim().toLowerCase() == _safeWord;
  }

  Future<void> sendSilentSos({
    required String context,
    String? partnerId,
    String? roomId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('safety_alerts').add({
        'userId': uid,
        'type': 'silent_sos',
        'context': context,
        'partnerId': partnerId,
        'roomId': roomId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'priority': 'critical',
      });
      await FirebaseFunctions.instance.httpsCallable('notifyTrustTeam').call({
        'alertType': 'silent_sos',
        'userId': uid,
      });
    } catch (e) {
      AppLogger.e('EmergencySafety SOS failed', e);
    }
  }

  Future<void> submitShakeReport({
    required String roomId,
    String? partnerId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('moderation_reports').add({
      'reportedUserId': partnerId ?? 'unknown',
      'reportedByUserId': uid,
      'contentType': 'vibetalk',
      'contentId': roomId,
      'category': 'Harassment',
      'subReason': 'Emergency shake report',
      'reason': 'Device shake during VibeTalk session',
      'status': 'pending',
      'severity': 'critical',
      'timestamp': FieldValue.serverTimestamp(),
      'isCsamFlag': false,
      'priority': 'critical',
    });
  }
}
