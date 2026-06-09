import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/chat_models.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/moderation/auto_moderation_service.dart';
import '../../../core/moderation/content_validator.dart';
import '../../../core/moderation/profanity_filter.dart';
import '../../../core/security/e2ee_service.dart';
import '../../../core/services/offline_queue_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final svc = ChatService(ref);
  // Register this service as the handler for offline message actions.
  ref.read(offlineQueueProvider).registerHandler(
        OfflineActionType.message,
        svc._handleOfflineMessage,
      );
  return svc;
});

class ChatService {
  ChatService(this._ref);

  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // ---------------------------------------------------------------------------
  // Chat ID helper
  // ---------------------------------------------------------------------------

  String getChatId(String uid1, String uid2) =>
      uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';

  // ---------------------------------------------------------------------------
  // Create / Open chat
  // ---------------------------------------------------------------------------

  Future<String> getOrCreateChat(String otherUserId) async {
    final chatId = getChatId(currentUserId, otherUserId);
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();

      if (!doc.exists) {
        final currentUserDoc =
            await _firestore.collection('users').doc(currentUserId).get();
        final otherUserDoc =
            await _firestore.collection('users').doc(otherUserId).get();

        final currentUser =
            UserProfile.fromMap(currentUserDoc.data() ?? {}, currentUserId);
        final otherUser =
            UserProfile.fromMap(otherUserDoc.data() ?? {}, otherUserId);

        await _firestore.collection('chats').doc(chatId).set({
          'participants': [currentUserId, otherUserId],
          'participantNames': {
            currentUserId: currentUser.displayName.isNotEmpty &&
                    currentUser.displayName != 'Unknown'
                ? currentUser.displayName
                : (currentUser.username.isNotEmpty
                    ? currentUser.username
                    : 'User'),
            otherUserId: otherUser.displayName.isNotEmpty &&
                    otherUser.displayName != 'Unknown'
                ? otherUser.displayName
                : (otherUser.username.isNotEmpty ? otherUser.username : 'User'),
          },
          'participantAvatars': {
            currentUserId: currentUser.photoUrl,
            otherUserId: otherUser.photoUrl,
          },
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'lastMessageType': 'text',
          'unreadCount': {
            currentUserId: 0,
            otherUserId: 0,
          },
          'typing': {
            currentUserId: false,
            otherUserId: false,
          },
          'isArchived': {
            currentUserId: false,
            otherUserId: false,
          },
          'isMuted': {
            currentUserId: false,
            otherUserId: false,
          },
          'e2eeEnabled': false,
        });
      }
      return chatId;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Send Message — with offline queuing + E2EE
  // ---------------------------------------------------------------------------

  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String text,
    String type = 'text',
    XFile? mediaFile,
    int? audioDuration,
    ReplyTo? replyTo,
    bool isEncrypted = false,
    DateTime? expiresAt,
  }) async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.every((r) => r == ConnectivityResult.none);

    if (isOffline) {
      // Persist to Hive queue for later sync.
      await _ref.read(offlineQueueProvider).enqueue(
            OfflineAction(
              type: OfflineActionType.message,
              payload: {
                'chatId': chatId,
                'receiverId': receiverId,
                'text': text,
                'messageType': type,
                'isEncrypted': isEncrypted,
                'expiresAt': expiresAt?.toIso8601String(),
                'replyTo': replyTo != null
                    ? {
                        'messageId': replyTo.messageId,
                        'text': replyTo.text,
                        'senderId': replyTo.senderId,
                        'type': replyTo.type,
                      }
                    : null,
              },
              createdAt: DateTime.now(),
            ),
          );
      return;
    }

    await _doSendMessage(
      chatId: chatId,
      receiverId: receiverId,
      text: text,
      type: type,
      mediaFile: mediaFile,
      audioDuration: audioDuration,
      replyTo: replyTo,
      isEncrypted: isEncrypted,
      expiresAt: expiresAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Offline Queue Handler — called by OfflineQueueService on reconnection
  // ---------------------------------------------------------------------------

  Future<void> _handleOfflineMessage(OfflineAction action) async {
    final p = action.payload;
    final chatId = p['chatId'] as String;
    final receiverId = p['receiverId'] as String;
    final text = p['text'] as String;
    final type = (p['messageType'] as String?) ?? 'text';
    final isEncrypted = (p['isEncrypted'] as bool?) ?? false;
    final expiresAt = p['expiresAt'] != null
        ? DateTime.tryParse(p['expiresAt'] as String)
        : null;

    ReplyTo? replyTo;
    if (p['replyTo'] != null) {
      final r = Map<String, dynamic>.from(p['replyTo'] as Map);
      replyTo = ReplyTo(
        messageId: r['messageId'] as String,
        text: r['text'] as String,
        senderId: r['senderId'] as String,
        type: (r['type'] as String?) ?? 'text',
      );
    }

    await _doSendMessage(
      chatId: chatId,
      receiverId: receiverId,
      text: text,
      type: type,
      isEncrypted: isEncrypted,
      expiresAt: expiresAt,
      replyTo: replyTo,
    );
  }

  // ---------------------------------------------------------------------------
  // Core send implementation (shared by online and queued paths)
  // ---------------------------------------------------------------------------

  Future<void> _doSendMessage({
    required String chatId,
    required String receiverId,
    required String text,
    String type = 'text',
    XFile? mediaFile,
    int? audioDuration,
    ReplyTo? replyTo,
    bool isEncrypted = false,
    DateTime? expiresAt,
  }) async {
    // Check if blocked by either user
    final block1 = await _firestore
        .collection('blocked_accounts')
        .doc('${currentUserId}_blocked_$receiverId')
        .get();
    final block2 = await _firestore
        .collection('blocked_accounts')
        .doc('${receiverId}_blocked_$currentUserId')
        .get();
    if (block1.exists || block2.exists) {
      throw Exception('Blocked user cannot message');
    }

    final messagesRef =
        _firestore.collection('chats').doc(chatId).collection('messages');
    final chatRef = _firestore.collection('chats').doc(chatId);

    final messageDocRef = messagesRef.doc();
    final messageId = messageDocRef.id;

    String sendText = text;

    // ── Content moderation (text only) ──────────────────────────────────────
    if (type == 'text' && text.isNotEmpty) {
      final validation =
          ContentValidator().validateMessageText(text, userId: currentUserId);
      if (!validation.isValid && !validation.warningOnly) {
        throw Exception(validation.reason ?? 'Message blocked');
      }
      final scan = AutoModerationService.instance.scanText(
        text: text,
        context: FilterContext.message,
        userId: currentUserId,
        contentKey: messageId,
      );
      if (scan.isBlocked) {
        await AutoModerationService.instance.applyPostAction(
          result: scan,
          reporterUserId: currentUserId,
          reportedUserId: receiverId,
          contentType: 'message',
          contentId: '$chatId/$messageId',
          contentPreview: text,
        );
        throw Exception(scan.reason ?? 'Message blocked');
      }
      sendText = scan.maskedText ?? text;
    }

    // ── E2EE encryption ──────────────────────────────────────────────────────
    String finalText = sendText;
    if (isEncrypted && type == 'text') {
      final e2ee = _ref.read(e2eeServiceProvider);
      finalText = await e2ee.encryptForChat(sendText, chatId, receiverId);
    }

    // ── Notification-safe last-message preview ───────────────────────────────
    // Never store raw ciphertext in the chat document's lastMessage field —
    // that would expose illegible data in push notifications and the chat list.
    final String lastMessagePreview = isEncrypted
        ? (type == 'text'
            ? '🔒 Encrypted message'
            : type == 'image'
                ? '🔒 Encrypted image'
                : type == 'audio'
                    ? '🔒 Encrypted voice message'
                    : '🔒 Encrypted file')
        : (type == 'text' ? finalText : _mediaPreviewText(type));

    // ── Media upload ─────────────────────────────────────────────────────────
    String? mediaUrl;
    String? mediaThumbnailUrl;

    if (mediaFile != null) {
      final extension =
          type == 'image' ? 'jpg' : (type == 'audio' ? 'm4a' : 'mp4');
      final storageRef =
          _storage.ref().child('chat_media/$chatId/$messageId.$extension');

      final metadata = SettableMetadata(
        contentType: type == 'image'
            ? 'image/jpeg'
            : (type == 'audio' ? 'audio/mp4' : 'video/mp4'),
      );

      final bytes = await mediaFile.readAsBytes();
      await storageRef.putData(bytes, metadata);
      mediaUrl = await storageRef.getDownloadURL();
      if (type == 'image') mediaThumbnailUrl = mediaUrl;
    }

    // ── Build message model ──────────────────────────────────────────────────
    final message = MessageModel(
      id: messageId,
      senderId: currentUserId,
      receiverId: receiverId,
      text: finalText,
      type: type,
      mediaUrl: mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl,
      audioDuration: audioDuration,
      replyTo: replyTo,
      status: 'sent',
      isEncrypted: isEncrypted,
      expiresAt: expiresAt,
    );

    final messageMap = message.toMap();
    if (!MessageFactory.isValid(messageMap)) {
      throw Exception('Invalid message schema. Message could not be sent.');
    }

    // ── Batch write ──────────────────────────────────────────────────────────
    final batch = _firestore.batch();

    batch.set(messageDocRef, messageMap);

    batch.update(chatRef, {
      'lastMessage': lastMessagePreview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
      'lastMessageType': type,
      'lastMessageStatus': 'sent',
      'lastMessageIsEncrypted': isEncrypted,
      'unreadCount.$receiverId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _mediaPreviewText(String type) {
    switch (type) {
      case 'image':
        return '📷 Image';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎤 Voice message';
      default:
        return '📎 Attachment';
    }
  }

  // ---------------------------------------------------------------------------
  // Read receipts
  // ---------------------------------------------------------------------------

  Future<void> markMessagesAsRead(String chatId, String otherUserId) async {
    final messagesRef =
        _firestore.collection('chats').doc(chatId).collection('messages');
    final chatRef = _firestore.collection('chats').doc(chatId);

    final sentByOther =
        await messagesRef.where('senderId', isEqualTo: otherUserId).get();

    final unreadDocs = sentByOther.docs
        .where((doc) => (doc.data()['status'] ?? '') != 'read')
        .toList();

    if (unreadDocs.isEmpty) {
      await chatRef.update({'unreadCount.$currentUserId': 0});
      return;
    }

    final batch = _firestore.batch();
    for (final doc in unreadDocs) {
      batch.update(doc.reference, {'status': 'read'});
    }
    batch.update(chatRef, {
      'unreadCount.$currentUserId': 0,
      'lastMessageStatus': 'read',
    });
    await batch.commit();
  }

  Future<void> markMessagesAsDelivered(
      String chatId, String otherUserId) async {
    final messagesRef =
        _firestore.collection('chats').doc(chatId).collection('messages');

    final undelivered = await messagesRef
        .where('status', isEqualTo: 'sent')
        .where('senderId', isEqualTo: otherUserId)
        .get();

    if (undelivered.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in undelivered.docs) {
      batch.update(doc.reference, {'status': 'delivered'});
    }
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Typing
  // ---------------------------------------------------------------------------

  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typing.$currentUserId': isTyping,
      });
    } catch (_) {
      // Ignore — typing status is best-effort only.
    }
  }

  // ---------------------------------------------------------------------------
  // Delete / Reactions
  // ---------------------------------------------------------------------------

  Future<void> deleteMessageForMe(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isDeletedFor': FieldValue.arrayUnion([currentUserId]),
    });
  }

  Future<void> deleteMessageForEveryone(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isDeletedForEveryone': true,
      'text': 'This message was deleted',
      'type': 'deleted',
    });
  }

  Future<void> addReaction(
      String chatId, String messageId, String emoji) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$currentUserId': emoji,
    });
  }

  Future<void> deleteMessage(String chatId, String messageId,
      {required bool forEveryone}) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    if (forEveryone) {
      await messageRef.update({
        'text': '🚫 This message was deleted',
        'isDeletedForEveryone': true,
        'type': 'deleted',
        'mediaUrl': null,
      });
    } else {
      await messageRef.delete();
    }
  }

  // ---------------------------------------------------------------------------
  // Active chat tracking
  // ---------------------------------------------------------------------------

  Future<void> setActiveChat(String? chatId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'activeChatId': chatId,
      });
    } catch (_) {}
  }
}
