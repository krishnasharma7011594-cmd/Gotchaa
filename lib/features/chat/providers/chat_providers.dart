import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chat_models.dart';
import '../../../core/models/user_profile.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/services/block_mute_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final activeChatIdProvider = StateProvider<String?>((ref) => null);

final chatListProvider = StreamProvider<List<ChatModel>>((ref) {
  final currentUserId = ref.watch(authStateProvider).value?.uid;
  if (currentUserId == null) return Stream.value([]);

  final blockedUidsAsync = ref.watch(blockedUidsProvider);
  final blockedUids = blockedUidsAsync.value ?? [];

  return ref.watch(firestoreProvider)
      .collection('chats')
      .where('participants', arrayContains: currentUserId)
      .snapshots()
      .map((snapshot) {
        final chats = snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
            .where((chat) {
              if (chat.isArchived[currentUserId] == true) return false;
              
              // Filter out chats containing blocked users
              final otherParticipant = chat.participants.firstWhere(
                (p) => p != currentUserId,
                orElse: () => '',
              );
              if (otherParticipant.isNotEmpty && blockedUids.contains(otherParticipant)) {
                return false;
              }
              return true;
            })
            .toList();
        
        // Sort locally by lastMessageTime descending
        chats.sort((a, b) {
          final timeA = a.lastMessageTime ?? DateTime(0);
          final timeB = b.lastMessageTime ?? DateTime(0);
          return timeB.compareTo(timeA);
        });
        
        return chats;
      });
});

final messageStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
  return ref.watch(firestoreProvider)
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .snapshots()
      .map((snapshot) {
        if (kDebugMode) {
          
        }
        final messages = snapshot.docs
            .map((doc) {
              final raw = doc.data();
              if (kDebugMode) {
                final rawJson = jsonEncode(_safeSerialize(raw));

              }

              final validationError = _validateMessageDoc(raw);
              if (validationError != null) {
                if (kDebugMode) {
                  
                }
                return null;
              }

              final parsed = MessageModel.fromMap(raw, doc.id);
              if (kDebugMode) {
                
              }
              return parsed;
            })
            .whereType<MessageModel>()
            .where((msg) => !msg.isDeletedFor.contains(currentUserId))
            .toList();

        // Keep newest messages first in UI while still including legacy docs
        // that may not have the `timestamp` field required by Firestore orderBy.
        messages.sort((a, b) {
          final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        return messages;
      });
});

String? _validateMessageDoc(Map<String, dynamic> raw) {
  final sender = (raw['senderId'] ?? raw['senderID'] ?? raw['sender'] ?? raw['from'])?.toString().trim() ?? '';
  if (sender.isEmpty) return 'missing senderId';

  final type = (raw['type']?.toString().trim().isNotEmpty ?? false) ? raw['type'].toString().trim() : 'text';
  const validTypes = {'text', 'image', 'video', 'audio', 'deleted'};
  if (!validTypes.contains(type)) return 'unsupported type=$type';

  final hasText = (raw['text'] ?? raw['message'] ?? raw['body'] ?? raw['content'])?.toString().trim().isNotEmpty ?? false;
  final hasMedia = raw['mediaUrl']?.toString().trim().isNotEmpty ?? false;
  if (type == 'text' && !hasText) return 'text message missing content';
  if ((type == 'image' || type == 'video') && !hasMedia) return '$type message missing mediaUrl';

  return null;
}

Object? _safeSerialize(Object? value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _safeSerialize(v)));
  }
  if (value is Iterable) {
    return value.map(_safeSerialize).toList();
  }
  return value;
}

final typingProvider = StreamProvider.family<Map<String, bool>, String>((ref, chatId) => ref.watch(firestoreProvider)
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        if (data != null && data['typing'] != null) {
          return Map<String, bool>.from(data['typing']);
        }
        return {};
      }));

final userPresenceProvider = StreamProvider.family<UserProfile?, String>((ref, userId) => ref.watch(firestoreProvider)
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        return UserProfile.fromMap(snapshot.data()!, snapshot.id);
      }));

final totalUnreadProvider = Provider<int>((ref) {
  final chats = ref.watch(chatListProvider).value ?? [];
  final currentUserId = ref.watch(authStateProvider).value?.uid;
  if (currentUserId == null) return 0;
  
  int total = 0;
  for (final chat in chats) {
    total += chat.unreadCount[currentUserId] ?? 0;
  }
  return total;
});
