/// Firestore Collection Schema: takedown_requests
/// 
/// Document ID: Auto-generated
/// Fields:
/// - contentId: String (ID of the content to remove)
/// - contentType: String ("post", "comment", "user", etc.)
/// - reason: String (Why it needs removal)
/// - status: String ("pending", "actioned", "rejected")
/// - requestedAt: Timestamp (When requested)
/// - mustActionBy: Timestamp (requestedAt + 36 hours)
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class ContentTakedownService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Flags content for takedown as required by IT Rules 2021 (36-hour resolution).
  Future<void> flagForTakedown({
    required String contentId,
    required String contentType,
    required String reason,
  }) async {
    final now = DateTime.now();
    final mustActionBy = now.add(const Duration(hours: 36));

    await _firestore.collection('takedown_requests').add({
      'contentId': contentId,
      'contentType': contentType,
      'reason': reason,
      'status': 'pending',
      'requestedAt': Timestamp.fromDate(now),
      'mustActionBy': Timestamp.fromDate(mustActionBy),
    });
  }
}
