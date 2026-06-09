import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

class ModerationResult {
  final bool approved;
  final double confidence;
  final List<String> flaggedCategories;

  ModerationResult({
    required this.approved,
    required this.confidence,
    required this.flaggedCategories,
  });

  factory ModerationResult.fromMap(Map<String, dynamic> map) {
    return ModerationResult(
      approved: map['approved'] ?? true,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      flaggedCategories: List<String>.from(map['flaggedCategories'] ?? []),
    );
  }
}

abstract class AIModerationService {
  Future<ModerationResult> analyzeText(String text);
}

class GeminiModerationService implements AIModerationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<ModerationResult> analyzeText(String text) async {
    try {
      // Call the Firebase Cloud Function
      final callable = _functions.httpsCallable('moderateContent');
      final response = await callable.call(<String, dynamic>{
        'text': text,
      });

      if (response.data != null) {
        return ModerationResult.fromMap(Map<String, dynamic>.from(response.data));
      }
    } catch (e) {
      AppLogger.e('GeminiModerationService analyze failed', e);
    }

    // Fallback: approve if AI check fails (or fail closed depending on policy)
    // Here we fail open to not block users if the service is down, but in high-security apps you might fail closed.
    return ModerationResult(approved: true, confidence: 1.0, flaggedCategories: []);
  }
}
