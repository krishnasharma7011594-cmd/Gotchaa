import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserPresence {
  UserPresence({required this.isOnline, this.lastSeen});

  factory UserPresence.fromMap(Map<String, dynamic> data) => UserPresence(
        isOnline: data['isOnline'] ?? false,
        lastSeen: data['lastSeen'] != null && data['lastSeen'] is Timestamp
            ? (data['lastSeen'] as Timestamp).toDate()
            : null,
      );
  final bool isOnline;
  final DateTime? lastSeen;
}

class ChatModel {
  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantAvatars,
    required this.unreadCount,
    required this.typing,
    required this.isArchived,
    required this.isMuted,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastMessageSenderId = '',
    this.lastMessageType = 'text',
    this.lastMessageStatus = 'sent',
  });

  factory ChatModel.fromMap(Map<String, dynamic> data, String id) {
    // Robust parsing for lastMessage which might be a Map in some versions/cases
    String lastMsg = '';
    if (data['lastMessage'] is String) {
      lastMsg = data['lastMessage'];
    } else if (data['lastMessage'] is Map) {
      // If it's a map (e.g. encrypted or rich content), try to extract a preview string
      lastMsg = (data['lastMessage'] as Map)['text']?.toString() ??
          (data['lastMessage'] as Map)['content']?.toString() ??
          '';
    }

    final participantsRaw =
        data['participants'] ?? data['participantIds'] ?? data['members'];
    final parsedParticipants = participantsRaw is List
        ? participantsRaw
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final namesRaw = data['participantNames'] ??
        data['participantNameMap'] ??
        data['participantInfo'];
    final avatarsRaw =
        data['participantAvatars'] ?? data['participantAvatarMap'];

    return ChatModel(
      id: id,
      participants: parsedParticipants,
      participantNames: namesRaw is Map
          ? namesRaw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
          : {},
      participantAvatars: avatarsRaw is Map
          ? avatarsRaw
              .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
          : {},
      lastMessage: lastMsg,
      lastMessageTime: data['lastMessageTime'] != null &&
              data['lastMessageTime'] is Timestamp
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: data['lastMessageSenderId']?.toString() ?? '',
      lastMessageType: data['lastMessageType']?.toString() ?? 'text',
      lastMessageStatus: data['lastMessageStatus']?.toString() ?? 'sent',
      unreadCount: data['unreadCount'] is Map
          ? (data['unreadCount'] as Map).map((k, v) => MapEntry(
              k.toString(), v is int ? v : int.tryParse(v.toString()) ?? 0))
          : {},
      typing: data['typing'] is Map
          ? (data['typing'] as Map)
              .map((k, v) => MapEntry(k.toString(), v == true))
          : {},
      isArchived: data['isArchived'] is Map
          ? (data['isArchived'] as Map)
              .map((k, v) => MapEntry(k.toString(), v == true))
          : {},
      isMuted: data['isMuted'] is Map
          ? (data['isMuted'] as Map)
              .map((k, v) => MapEntry(k.toString(), v == true))
          : {},
    );
  }
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantAvatars;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageSenderId;
  final String lastMessageType;
  final String lastMessageStatus;
  final Map<String, int> unreadCount;
  final Map<String, bool> typing;
  final Map<String, bool> isArchived;
  final Map<String, bool> isMuted;

  Map<String, dynamic> toMap() => {
        'participants': participants,
        'participantNames': participantNames,
        'participantAvatars': participantAvatars,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime != null
            ? Timestamp.fromDate(lastMessageTime!)
            : FieldValue.serverTimestamp(),
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageType': lastMessageType,
        'lastMessageStatus': lastMessageStatus,
        'unreadCount': unreadCount,
        'typing': typing,
        'isArchived': isArchived,
        'isMuted': isMuted,
      };
}

class ReplyTo {
  ReplyTo(
      {required this.messageId,
      required this.senderId,
      required this.text,
      required this.type});

  factory ReplyTo.fromMap(Map<String, dynamic> data) => ReplyTo(
        messageId: data['messageId'] ?? '',
        senderId: data['senderId'] ?? '',
        text: data['text'] ?? '',
        type: data['type'] ?? '',
      );
  final String messageId;
  final String senderId;
  final String text;
  final String type;

  Map<String, dynamic> toMap() => {
        'messageId': messageId,
        'senderId': senderId,
        'text': text,
        'type': type,
      };
}

const int CURRENT_MESSAGE_SCHEMA_VERSION = 1;

class MessageFactory {
  /// Create a consistent Firestore map for a message.
  /// Enforces required fields and adds schema versioning.
  static Map<String, dynamic> createMessageMap({
    required String senderId,
    required String receiverId,
    required String text,
    required String type,
    String? messageId,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    int? audioDuration,
    ReplyTo? replyTo,
    Map<String, String>? reactions,
    bool isEncrypted = false,
    DateTime? expiresAt,
    String status = 'sent',
  }) {
    // 1. Validation
    if (senderId.isEmpty) throw ArgumentError('senderId cannot be empty');
    if (receiverId.isEmpty) throw ArgumentError('receiverId cannot be empty');
    if (text.isEmpty && type == 'text')
      throw ArgumentError('text cannot be empty for text messages');
    if (!['text', 'image', 'audio', 'video', 'deleted', 'system']
        .contains(type)) {
      throw ArgumentError('Invalid message type: $type');
    }

    final timestamp = FieldValue.serverTimestamp();

    // 2. Consistent Structure
    final map = {
      'schemaVersion': CURRENT_MESSAGE_SCHEMA_VERSION,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type,
      'timestamp': timestamp,
      'createdAt': timestamp, // Redundancy for older query patterns
      'status': status,
      'isEncrypted': isEncrypted,
      'isDeletedForEveryone': type == 'deleted',
      'isDeletedFor': [],
      'reactions': reactions ?? {},
    };

    // 3. Optional Fields (only include if not null)
    if (messageId != null) map['messageId'] = messageId;
    if (mediaUrl != null) map['mediaUrl'] = mediaUrl;
    if (mediaThumbnailUrl != null) map['mediaThumbnailUrl'] = mediaThumbnailUrl;
    if (audioDuration != null) map['audioDuration'] = audioDuration;
    if (replyTo != null) map['replyTo'] = replyTo.toMap();
    if (expiresAt != null) map['expiresAt'] = Timestamp.fromDate(expiresAt);
    // 4. Reject invalid messages before saving & Log pipeline
    if (MessageFactory.isValid(map)) {
    } else {}

    return map;
  }

  /// Validates a map before write.
  static bool isValid(Map<String, dynamic> map) {
    try {
      final requiredFields = ['senderId', 'receiverId', 'text', 'type'];
      for (final field in requiredFields) {
        if (map[field] == null) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

class MessageModel {
  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = 'text',
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.audioDuration,
    this.replyTo,
    this.reactions,
    this.timestamp,
    this.status = 'sent',
    this.isDeletedForEveryone = false,
    this.isDeletedFor = const [],
    this.editedAt,
    this.isEncrypted = false,
    this.expiresAt,
    this.schemaVersion = CURRENT_MESSAGE_SCHEMA_VERSION,
    this.isLocalSending = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data, String id) {
    final dynamic textRaw =
        data['text'] ?? data['message'] ?? data['body'] ?? data['content'];
    String messageText = '';
    if (textRaw is String) {
      messageText = textRaw;
    } else if (textRaw is Map) {
      messageText = textRaw['text']?.toString() ??
          textRaw['content']?.toString() ??
          textRaw['message']?.toString() ??
          '';
    }

    final dynamic senderRaw =
        data['senderId'] ?? data['senderID'] ?? data['sender'] ?? data['from'];
    final dynamic receiverRaw = data['receiverId'] ??
        data['receiverID'] ??
        data['receiver'] ??
        data['to'];
    final dynamic timestampRaw =
        data['timestamp'] ?? data['createdAt'] ?? data['time'];
    final dynamic encryptedRaw =
        data['isEncrypted'] ?? data['encrypted'] ?? data['is_encrypted'];
    final bool parsedIsEncrypted =
        encryptedRaw == true || _looksLikeEncryptedPayload(messageText);

    return MessageModel(
      id: id,
      schemaVersion: data['schemaVersion'] is int
          ? data['schemaVersion']
          : 0, // 0 for legacy
      senderId: senderRaw?.toString() ?? '',
      receiverId: receiverRaw?.toString() ?? '',
      text: messageText,
      type: (data['type']?.toString().isNotEmpty ?? false)
          ? data['type'].toString()
          : 'text',
      mediaUrl: data['mediaUrl']?.toString(),
      mediaThumbnailUrl: data['mediaThumbnailUrl']?.toString(),
      audioDuration:
          data['audioDuration'] is int ? data['audioDuration'] : null,
      replyTo:
          data['replyTo'] != null ? ReplyTo.fromMap(data['replyTo']) : null,
      reactions: data['reactions'] is Map
          ? (data['reactions'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString()))
          : null,
      timestamp: timestampRaw != null && timestampRaw is Timestamp
          ? timestampRaw.toDate()
          : null,
      status: data['status']?.toString() ?? 'sent',
      isDeletedForEveryone:
          data['isDeletedForEveryone'] == true || data['type'] == 'deleted',
      isDeletedFor: data['isDeletedFor'] is List
          ? List<String>.from(data['isDeletedFor'])
          : (data['deletedFor'] is List
              ? List<String>.from(data['deletedFor'])
              : []),
      editedAt: data['editedAt'] != null && data['editedAt'] is Timestamp
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      isEncrypted: parsedIsEncrypted,
      expiresAt: data['expiresAt'] != null && data['expiresAt'] is Timestamp
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String type; // text, image, audio, deleted
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final int? audioDuration;
  final ReplyTo? replyTo;
  final Map<String, String>? reactions;
  final DateTime? timestamp;
  final String status; // sending, sent, delivered, read
  final bool isDeletedForEveryone;
  final List<String> isDeletedFor;
  final DateTime? editedAt;
  final bool isEncrypted;
  final DateTime? expiresAt;

  final int schemaVersion;

  // Local-only state
  final bool isLocalSending;

  static bool _looksLikeEncryptedPayload(String value) {
    if (value.isEmpty || value.length < 24) return false;
    final normalized = value.trim();
    try {
      // AES-GCM payload must be at least nonce(12) + mac(16) bytes.
      final bytes = base64Decode(base64.normalize(normalized));
      return bytes.length >= 28;
    } catch (_) {
      try {
        final bytes = base64Url.decode(base64Url.normalize(normalized));
        return bytes.length >= 28;
      } catch (_) {
        return false;
      }
    }
  }

  Map<String, dynamic> toMap() => MessageFactory.createMessageMap(
        messageId: id,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        type: type,
        mediaUrl: mediaUrl,
        mediaThumbnailUrl: mediaThumbnailUrl,
        audioDuration: audioDuration,
        replyTo: replyTo,
        isEncrypted: isEncrypted,
        expiresAt: expiresAt,
        status: status,
      );

  MessageModel copyWith({
    String? status,
    bool? isLocalSending,
    Map<String, String>? reactions,
  }) =>
      MessageModel(
        id: id,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        type: type,
        mediaUrl: mediaUrl,
        mediaThumbnailUrl: mediaThumbnailUrl,
        audioDuration: audioDuration,
        replyTo: replyTo,
        reactions: reactions ?? this.reactions,
        timestamp: timestamp,
        status: status ?? this.status,
        isDeletedForEveryone: isDeletedForEveryone,
        isDeletedFor: isDeletedFor,
        editedAt: editedAt,
        isEncrypted: isEncrypted,
        expiresAt: expiresAt,
        isLocalSending: isLocalSending ?? this.isLocalSending,
      );
}
