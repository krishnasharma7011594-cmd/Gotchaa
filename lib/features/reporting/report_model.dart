import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  ReportModel({
    required this.reportedUserId,
    required this.reportedByUserId,
    required this.contentType,
    required this.contentId,
    required this.category,
    required this.reason,
    required this.status,
    required this.timestamp,
    this.id,
    this.subReason,
    this.moderatorNote,
    this.severity = 'medium',
    this.isCsamFlag = false,
    this.isAutoReport = false,
    this.contentHidden = false,
    this.contentPreview,
    this.flags = const [],
    this.reporterCount = 1,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) =>
      ReportModel(
        id: id,
        reportedUserId: map['reportedUserId'] ?? '',
        reportedByUserId: map['reportedByUserId'] ?? '',
        contentType: map['contentType'] ?? '',
        contentId: map['contentId'] ?? '',
        category: map['category'] ?? map['reason'] ?? '',
        subReason: map['subReason'],
        reason: map['reason'] ?? '',
        status: map['status'] ?? 'pending',
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        moderatorNote: map['moderatorNote'],
        severity: map['severity'] ?? 'medium',
        isCsamFlag: map['isCsamFlag'] == true,
        isAutoReport: map['isAutoReport'] == true,
        contentHidden: map['contentHidden'] == true,
        contentPreview: map['contentPreview'],
        flags: List<String>.from(map['flags'] ?? []),
        reporterCount: (map['reporterCount'] as num?)?.toInt() ?? 1,
      );

  final String? id;
  final String reportedUserId;
  final String reportedByUserId;
  final String contentType;
  final String contentId;
  final String category;
  final String? subReason;
  final String reason;
  final String status;
  final DateTime timestamp;
  final String? moderatorNote;
  final String severity;
  final bool isCsamFlag;
  final bool isAutoReport;
  final bool contentHidden;
  final String? contentPreview;
  final List<String> flags;
  final int reporterCount;

  Map<String, dynamic> toMap() => {
        'reportedUserId': reportedUserId,
        'reportedByUserId': reportedByUserId,
        'contentType': contentType,
        'contentId': contentId,
        'category': category,
        'subReason': subReason,
        'reason': reason,
        'status': status,
        'timestamp': Timestamp.fromDate(timestamp),
        'moderatorNote': moderatorNote,
        'severity': severity,
        'isCsamFlag': isCsamFlag,
        'isAutoReport': isAutoReport,
        'contentHidden': contentHidden,
        'contentPreview': contentPreview,
        'flags': flags,
        'reporterCount': reporterCount,
      };
}
