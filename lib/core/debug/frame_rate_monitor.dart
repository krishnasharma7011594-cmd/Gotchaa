import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Logs sub-30fps frames to Crashlytics in debug/profile.
class FrameRateMonitor {
  FrameRateMonitor._();
  static FrameRateMonitor? _instance;

  static void start() {
    if (!kDebugMode) return;
    _instance ??= FrameRateMonitor._().._attach();
  }

  int _lowFpsCount = 0;
  DateTime _windowStart = DateTime.now();

  void _attach() {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        final ms = t.totalSpan.inMicroseconds / 1000;
        if (ms <= 0) continue;
        final fps = 1000 / ms;
        if (fps < 30) {
          _lowFpsCount++;
          final now = DateTime.now();
          if (now.difference(_windowStart).inSeconds >= 10 && _lowFpsCount >= 5) {
            FirebaseCrashlytics.instance.log(
              'low_fps_detected: ${fps.toStringAsFixed(1)} fps ($_lowFpsCount frames/10s)',
            );
            _lowFpsCount = 0;
            _windowStart = now;
          }
        }
      }
    });
  }
}
