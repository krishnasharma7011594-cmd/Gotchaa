import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/presentation/screens/call_screen.dart';
import '../providers/auth_providers.dart';
import '../providers/repository_providers.dart';
import '../security/e2ee_service.dart';

final callManagerProvider = Provider<CallManager>(CallManager.new);

class CallManager {

  CallManager(this._ref);
  final Ref _ref;
  bool _isListening = false;

  void startListening(BuildContext context) {
    if (_isListening) return;
    _isListening = true;

    _ref.listen(authStateProvider, (previous, next) {
      final user = next.asData?.value;
      if (user != null) {
        _subscribeToCalls(context, user.uid);
      }
    });
  }

  void _subscribeToCalls(BuildContext context, String myUid) {
    FirebaseFirestore.instance
        .collection('calls')
        .where('calleeId', isEqualTo: myUid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          final callerId = data['callerId'];
          final isVideo = data['isVideo'] ?? false;
          final callId = change.doc.id;

          // Fetch caller profile for UI
          final callerProfile = await _ref.read(profileRepositoryProvider).getUserProfile(callerId);
          if (callerProfile == null) return;
          
          // Get E2EE shared secret for this caller
          final e2ee = _ref.read(e2eeServiceProvider);
          final chatId = data['chatId'];
          
          if (chatId != null && context.mounted) {
            final sharedSecret = await e2ee.getOrCreateChatKey(chatId, callerId);
            
            // Show the Incoming Call Overlay or navigate to CallScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallScreen(
                  userName: callerProfile.displayName.isNotEmpty ? callerProfile.displayName : callerProfile.username,
                  userAvatar: callerProfile.photoUrl,
                  isVideo: isVideo,
                  existingCallId: callId,
                  targetUid: callerId,
                  sharedSecret: sharedSecret,
                  chatId: chatId,
                ),
              ),
            );
          }
        }
      }
    });
  }
}
