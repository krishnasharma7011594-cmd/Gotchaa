import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../logging/app_logger.dart';

/// Tracks Firestore read volume per session and logs expensive queries.
class FirestoreCostGuard {
  FirestoreCostGuard._();
  static final FirestoreCostGuard instance = FirestoreCostGuard._();

  static const int sessionWarnThreshold = 1000;

  int _sessionReads = 0;
  bool _warned = false;

  int get sessionReads => _sessionReads;

  void recordReads(int count, {String? source}) {
    if (count <= 0) return;
    _sessionReads += count;
    if (!_warned && _sessionReads > sessionWarnThreshold) {
      _warned = true;
      AppLogger.i(
        'WARNING: $_sessionReads reads this session (limit $sessionWarnThreshold)',
      );
    }
    if (count >= 50 && source != null) {
      logExpensiveQuery(source, count);
    }
  }

  void logExpensiveQuery(String name, int docCount) {
    final msg =
        'expensive_firestore_query:$name docs=$docCount session=$_sessionReads';
    AppLogger.i(msg);
    FirebaseCrashlytics.instance.log(msg);
  }

  void resetSession() {
    _sessionReads = 0;
    _warned = false;
  }
}
