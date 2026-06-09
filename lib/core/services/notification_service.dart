import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../logging/app_logger.dart';

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Request permissions (prompts user on first launch)
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.i('NotificationService: user granted permission');

      // Get token and store securely in users_private
      final String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToPrivateCollection(token);
      }
    }

    // Re-save whenever the FCM token is rotated by Google
    _messaging.onTokenRefresh.listen(_saveTokenToPrivateCollection);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.i('NotificationService: foreground message received');
      AppLogger.i('  data: ${message.data}');
      if (message.notification != null) {
        AppLogger.i('NotificationService: notification — '
            'title=${message.notification?.title}, '
            'body=${message.notification?.body}');
      }
    });
  }

  /// Saves the FCM token ONLY to [users_private/{uid}] — owner-readable only.
  ///
  /// SECURITY FIX: The previous implementation wrote the token to
  /// [users/{uid}] which is readable by every authenticated user.
  /// FCM tokens are sensitive — a leaked token lets anyone push
  /// notifications to that device. Moving it to users_private fixes this.
  Future<void> _saveTokenToPrivateCollection(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users_private').doc(user.uid).set(
        {
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      AppLogger.i(
          'NotificationService: FCM token saved to users_private/${user.uid}');
    } catch (e) {
      AppLogger.e('NotificationService: failed to save FCM token', e);
    }
  }

  /// Call this on sign-out to prevent stale tokens delivering notifications
  /// to a device that is no longer logged in.
  Future<void> clearTokenOnSignOut() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users_private')
          .doc(user.uid)
          .set({'fcmToken': FieldValue.delete()}, SetOptions(merge: true));
      await _messaging.deleteToken();
      AppLogger.i('NotificationService: FCM token cleared on sign-out');
    } catch (e) {
      AppLogger.e('NotificationService: failed to clear FCM token', e);
    }
  }
}
