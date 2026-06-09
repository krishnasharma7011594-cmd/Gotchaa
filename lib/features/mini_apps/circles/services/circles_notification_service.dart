import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/circle_model.dart';
import '../screens/circles_chat_screen.dart';
import '../screens/circles_details_screen.dart';

class CirclesNotificationService {
  CirclesNotificationService._internal();
  static final CirclesNotificationService instance =
      CirclesNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? 'anonymous';

  // 1. Initialise Notification Handlers & Listeners
  Future<void> initialize(BuildContext context) async {
    // Background Message Handler setup is typically done in main.dart top-level.
    // We register foreground message listeners here.
    FirebaseMessaging.onMessage.listen((message) {
      _showForegroundBanner(context, message);
    });

    // Deep Linking Handler when clicking notification in background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(context, message.data);
    });

    // Handle terminated state launches
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(context, initialMessage.data);
    }
  }

  // 2. Register FCM tokens
  Future<void> registerFcmToken() async {
    final uid = currentUserId;
    if (uid == 'anonymous') return;

    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).set({
          'fcmTokens': FieldValue.arrayUnion([token])
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving FCM Token: $e');
    }
  }

  // 3. Friendly Permission Request Gating Dialog
  Future<void> requestPermissionWithExplanation(BuildContext context) async {
    final settings = await _fcm.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await registerFcmToken();
      return;
    }

    // Show Gen Z aesthetic explanation dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: AppColors.primaryGlow),
            const SizedBox(width: 10),
            Text(
              'Stay Synced!',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Allow notifications to receive instant host updates, pin alerts, and meetup approval alerts in real-time!',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Not Now', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final status = await _fcm.requestPermission(
                alert: true,
                badge: true,
                sound: true,
              );
              if (status.authorizationStatus ==
                  AuthorizationStatus.authorized) {
                await registerFcmToken();
              }
            },
            child: const Text('Enable',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 4. Foreground in-app notification banners
  void _showForegroundBanner(BuildContext context, RemoteMessage message) {
    final title = message.notification?.title ?? 'Circles Alert';
    final body = message.notification?.body ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.darkSurface,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.electricBlue, width: 1.5),
        ),
        behavior: SnackBarBehavior.floating,
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _handleNotificationTap(context, message.data);
          },
          child: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppColors.primaryGlow),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(body,
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Deep Link router on push notification tap
  void _handleNotificationTap(
      BuildContext context, Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final circleId = data['circleId'] as String?;

    if (circleId == null) return;

    try {
      final doc = await _db.collection('circles').doc(circleId).get();
      if (!doc.exists) return;
      final circle = CircleModel.fromMap(doc.data()!, doc.id);

      if (type == 'chat' || type == 'pinned_location') {
        // Deep link directly into group chat
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CirclesChatScreen(
                circleId: circle.id, circleTitle: circle.title),
          ),
        );
      } else {
        // Deep link into details screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CirclesDetailsScreen(circle: circle),
          ),
        );
      }
    } catch (e) {
      debugPrint('Navigation deep-link failed: $e');
    }
  }
}
