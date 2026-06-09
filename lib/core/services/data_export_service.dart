import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../logging/app_logger.dart';

/// GDPR Article 20 — user data export via Cloud Function.
class DataExportService {
  DataExportService._();
  static final DataExportService instance = DataExportService._();

  final _functions = FirebaseFunctions.instance;

  /// Requests server-side export (rate limited: 1 per 30 days).
  Future<DataExportResult> requestExport() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return DataExportResult.error('You must be signed in');
    }

    try {
      final callable = _functions.httpsCallable('generateDataExport');
      final res = await callable.call<Map<String, dynamic>>();
      final data = Map<String, dynamic>.from(res.data as Map);
      return DataExportResult.success(
        message: data['message'] as String? ?? 'Export started. You will receive a link by email and notification.',
        exportId: data['exportId'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        return DataExportResult.error('You can request an export once every 30 days.');
      }
      return DataExportResult.error(e.message ?? 'Export failed');
    } catch (e) {
      AppLogger.e('DataExportService failed', e);
      return DataExportResult.error('Export failed');
    }
  }

  /// Local preview export (profile + public posts metadata only).
  Future<Map<String, dynamic>> collectLocalPreview(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final posts = await FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .limit(100)
        .get();

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': userDoc.data(),
      'postsCount': posts.docs.length,
      'posts': posts.docs.map((d) {
        final m = d.data();
        return {
          'id': d.id,
          'caption': m['caption'],
          'createdAt': m['createdAt']?.toString(),
        };
      }).toList(),
      'note': 'Full export includes messages metadata, karma, settings via email link.',
    };
  }
}

class DataExportResult {
  const DataExportResult._({required this.ok, this.message, this.exportId});
  DataExportResult.success({required this.message, this.exportId})
      : ok = true;
  DataExportResult.error(this.message) : ok = false, exportId = null;

  final bool ok;
  final String? message;
  final String? exportId;
}
