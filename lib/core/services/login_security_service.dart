import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../logging/app_logger.dart';

/// Records login session and triggers new-device security alert.
class LoginSecurityService {
  LoginSecurityService._();
  static final LoginSecurityService instance = LoginSecurityService._();

  String? _lastRecordedUid;

  Future<void> onUserSignedIn(User user) async {
    if (_lastRecordedUid == user.uid) return;
    _lastRecordedUid = user.uid;

    final deviceName = await _deviceName();
    try {
      await FirebaseFunctions.instance.httpsCallable('recordLoginSession').call({
        'deviceName': deviceName,
        'location': 'Detected on sign-in',
        'isCurrent': true,
      });
      await FirebaseFunctions.instance.httpsCallable('sendLoginNotification').call({
        'deviceName': deviceName,
        'email': user.email,
      });
    } catch (e) {
      AppLogger.e('LoginSecurityService: session/notify failed', e);
    }
  }

  Future<String> _deviceName() async {
    if (kIsWeb) return 'Web browser';
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        return '${a.brand} ${a.model}';
      }
      if (Platform.isIOS) {
        final i = await info.iosInfo;
        return '${i.name} (${i.systemName} ${i.systemVersion})';
      }
    } catch (_) {}
    return 'Mobile device';
  }
}
