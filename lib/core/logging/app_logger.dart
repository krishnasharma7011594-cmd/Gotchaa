import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }

  static void i(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void w(String message) {
    if (kDebugMode) debugPrint('[WARN] $message');
  }

  static void e(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message ${error ?? ""}');
    } else {
      FirebaseCrashlytics.instance.log('[ERROR] $message ${error ?? ""}');
    }
  }
}
