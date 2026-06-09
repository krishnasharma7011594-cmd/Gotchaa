import '../logging/app_logger.dart';

/// Detects rapid repeated stream emissions (possible infinite rebuild loops).
class StreamLoopGuard {
  StreamLoopGuard({this.maxPerMinute = 10});

  final int maxPerMinute;
  final List<DateTime> _emissions = [];
  bool _broken = false;
  String? _breakReason;

  bool get isBroken => _broken;
  String? get breakReason => _breakReason;

  /// Call on each stream emission; returns false if loop should break.
  bool tick({String? label}) {
    if (_broken) return false;
    final now = DateTime.now();
    _emissions.removeWhere((t) => now.difference(t).inMinutes >= 1);
    _emissions.add(now);
    if (_emissions.length > maxPerMinute) {
      _broken = true;
      _breakReason =
          label ?? 'Stream emitted more than $maxPerMinute times per minute';
      AppLogger.e('StreamLoopGuard: $_breakReason');
      return false;
    }
    return true;
  }

  void reset() {
    _emissions.clear();
    _broken = false;
    _breakReason = null;
  }
}
