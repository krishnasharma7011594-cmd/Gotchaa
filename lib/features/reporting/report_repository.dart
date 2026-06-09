import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'report_categories.dart';
import 'report_model.dart';

class ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> submitReport(ReportModel report) async {
    final isChildSafety = ReportCategories.isChildSafety(report.category);
    final data = report.toMap()
      ..['isCsamFlag'] = report.isCsamFlag || isChildSafety
      ..['contentHidden'] = report.contentHidden || isChildSafety
      ..['priority'] =
          isChildSafety ? 'critical' : _priorityForSeverity(report.severity);

    final ref = await _firestore.collection('moderation_reports').add(data);

    // Dynamic Moderation Workflow: Check for 3+ reports in 24 hours
    final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
    final reportsQuery = await _firestore
        .collection('moderation_reports')
        .where('contentId', isEqualTo: report.contentId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(oneDayAgo))
        .get();

    if (reportsQuery.docs.length >= 3 || isChildSafety) {
      await _hideContent(report.contentType, report.contentId);

      // Add to moderator review queue
      await _firestore
          .collection('moderation_queue')
          .doc(report.contentId.replaceAll('/', '_'))
          .set({
        'contentId': report.contentId,
        'contentType': report.contentType,
        'reportsCount': reportsQuery.docs.length,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending_review',
        'contentPreview': report.contentPreview,
        'reportedUserId': report.reportedUserId,
      });

      if (isChildSafety) {
        try {
          await FirebaseFunctions.instance
              .httpsCallable('notifyAdminModeration')
              .call({
            'reportId': ref.id,
            'priority': 'critical',
            'category': report.category,
          });
        } catch (_) {}
      }
    }

    return ref.id;
  }

  String _priorityForSeverity(String severity) {
    switch (severity) {
      case 'critical':
        return 'critical';
      case 'high':
        return 'high';
      default:
        return 'normal';
    }
  }

  Future<void> _hideContent(String contentType, String contentId) async {
    try {
      switch (contentType) {
        case 'post':
          await _firestore.collection('posts').doc(contentId).update({
            'isHidden': true,
            'hiddenReason': 'moderation_limit',
          });
          break;
        case 'vybz':
          await _firestore.collection('vybz').doc(contentId).update({
            'isHidden': true,
            'hiddenReason': 'moderation_limit',
          });
          break;
        case 'message':
          final parts = contentId.split('/');
          if (parts.length >= 2) {
            await _firestore
                .collection('chats')
                .doc(parts[0])
                .collection('messages')
                .doc(parts[1])
                .update({'isHidden': true});
          }
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  Future<List<ReportModel>> getUserReportHistory(String userId) async {
    final snapshot = await _firestore
        .collection('moderation_reports')
        .where('reportedByUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => ReportModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
