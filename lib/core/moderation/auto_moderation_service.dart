import 'package:cloud_functions/cloud_functions.dart';

import '../../features/reporting/report_model.dart';
import '../../features/reporting/report_repository.dart';
import '../logging/app_logger.dart';
import 'profanity_filter.dart';

enum ModerationActionType {
  allow,
  allowFlagged,
  allowWithWarning,
  block,
  blockAndReport,
}

class ModerationScanResult {
  const ModerationScanResult({
    required this.action,
    this.maskedText,
    this.reason,
    this.flags = const [],
    this.severity = 'low',
  });

  final ModerationActionType action;
  final String? maskedText;
  final String? reason;
  final List<String> flags;
  final String severity;

  bool get isBlocked =>
      action == ModerationActionType.block ||
      action == ModerationActionType.blockAndReport;
}

/// Automated scanning on post/message creation.
class AutoModerationService {
  AutoModerationService._();
  static final AutoModerationService instance = AutoModerationService._();

  final _filter = ProfanityFilter();
  final _recentHashes = <String, List<String>>{};
  static const _spamRepeatThreshold = 3;

  ModerationScanResult scanText({
    required String text,
    required FilterContext context,
    required String userId,
    required String contentKey,
    bool isPublicFeed = false,
  }) {
    final flags = <String>[];
    var severity = 'low';
    var action = ModerationActionType.allow;
    String? reason;
    var output = text;

    // Profanity
    final profanity = _filter.findMatches(text, context);
    if (profanity.isNotEmpty) {
      final highest = _filter.highestSeverity(text, context)!;
      flags.add('profanity');
      switch (highest) {
        case FilterSeverity.low:
          output = _filter.maskText(text, context);
          action = ModerationActionType.allow;
          severity = 'low';
        case FilterSeverity.medium:
          action = ModerationActionType.allowWithWarning;
          reason = 'Your content may contain language that violates our guidelines.';
          severity = 'medium';
        case FilterSeverity.high:
          action = ModerationActionType.blockAndReport;
          reason = 'This content violates GOTCHAA community standards.';
          severity = 'critical';
      }
    }

    // URLs in public feed
    if (isPublicFeed && _containsUrl(text)) {
      flags.add('external_link');
      if (_severityRank(severity) < 2) {
        action = ModerationActionType.allowFlagged;
        severity = 'medium';
        reason ??= 'Links in public posts are reviewed by our safety team.';
      }
    }

    // ALL CAPS abuse (>70% caps, length > 10)
    if (text.length > 10 && _isAllCapsAbuse(text)) {
      flags.add('all_caps');
      if (action == ModerationActionType.allow) {
        action = ModerationActionType.allowFlagged;
        severity = 'low';
      }
    }

    // Phone / email on public feed
    if (isPublicFeed) {
      if (_containsPhone(text)) {
        flags.add('phone_number');
        action = ModerationActionType.allowFlagged;
        severity = 'medium';
        reason ??= 'Sharing phone numbers publicly is restricted.';
      }
      if (_containsEmail(text)) {
        flags.add('email');
        action = ModerationActionType.allowFlagged;
        severity = 'medium';
        reason ??= 'Sharing emails publicly is restricted.';
      }
    }

    // Repeated content spam
    final history = _recentHashes.putIfAbsent(userId, () => []);
    final normalized = text.trim().toLowerCase();
    history.add(normalized);
    if (history.length > 20) history.removeAt(0);
    final repeats = history.where((h) => h == normalized).length;
    if (repeats >= _spamRepeatThreshold) {
      flags.add('spam_repeat');
      action = ModerationActionType.block;
      reason = 'Repeated identical messages detected (spam).';
      severity = 'high';
    }

    return ModerationScanResult(
      action: action,
      maskedText: output != text ? output : null,
      reason: reason,
      flags: flags,
      severity: severity,
    );
  }

  Future<void> applyPostAction({
    required ModerationScanResult result,
    required String reporterUserId,
    required String reportedUserId,
    required String contentType,
    required String contentId,
    String? contentPreview,
  }) async {
    if (result.action != ModerationActionType.blockAndReport) return;
    try {
      final report = ReportModel(
        reportedUserId: reportedUserId,
        reportedByUserId: reporterUserId,
        contentType: contentType,
        contentId: contentId,
        category: 'Hate Speech',
        subReason: 'Automated detection',
        reason: result.reason ?? 'Auto-moderation',
        status: 'pending',
        severity: result.severity,
        timestamp: DateTime.now(),
        isAutoReport: true,
        contentPreview: contentPreview,
        flags: result.flags,
      );
      await ReportRepository().submitReport(report);
      final callable = FirebaseFunctions.instance.httpsCallable('notifyAdminModeration');
      await callable.call({'contentId': contentId, 'severity': result.severity});
    } catch (e) {
      AppLogger.e('AutoModeration auto-report failed', e);
    }
  }

  int _severityRank(String s) {
    switch (s) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  bool _containsUrl(String t) => RegExp(
        r'https?://|www\.|[a-z0-9-]+\.(com|net|org|io|co|app|me)\b',
        caseSensitive: false,
      ).hasMatch(t);

  bool _containsPhone(String t) =>
      RegExp(r'\+?\d[\d\s\-().]{8,}\d').hasMatch(t);

  bool _containsEmail(String t) =>
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(t);

  bool _isAllCapsAbuse(String t) {
    final letters = t.replaceAll(RegExp('[^A-Za-z]'), '');
    if (letters.length < 8) return false;
    final upper = letters.replaceAll(RegExp('[^A-Z]'), '').length;
    return upper / letters.length > 0.7;
  }
}
