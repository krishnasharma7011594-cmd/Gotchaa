import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/distributed_counter.dart';

import '../constants/pagination_constants.dart';
import '../firebase/firestore_cost_guard.dart';
import '../firebase/firestore_query_cache.dart';
import '../models/chat_models.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/user_profile.dart';
import '../models/vybz_model.dart';
import '../services/device_service.dart';
import '../services/invite_code_service.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // --- ACCOUNT OPERATIONS ---

  Future<bool> callDeleteAccountFunction() async {
    try {
      final result = await _functions.httpsCallable('deleteUserAccount').call();
      return result.data['success'] == true;
    } catch (e) {
      
      return false;
    }
  }

  // --- USER OPERATIONS ---
  
  Future<void> createUserProfile(UserProfile profile) async {
    final lowerUsername = profile.username.toLowerCase();
    final publicData = _getPublicData(profile.toMap());
    final privateData = _getPrivateData(profile.toMap());

    await _firestore.runTransaction((tx) async {
      final usernameRef = _firestore.collection('usernames').doc(lowerUsername);
      final existingUsername = await tx.get(usernameRef);
      if (existingUsername.exists && existingUsername.data()?['uid'] != profile.uid) {
        throw Exception('Username is already taken.');
      }
      
      tx.set(_firestore.collection('users').doc(profile.uid), publicData);
      tx.set(_firestore.collection('users_private').doc(profile.uid), privateData);
      tx.set(usernameRef, {'uid': profile.uid});

      // Write a public invite code index for code → uid lookup.
      // The index is keyed by code and only stores uid — no private data.
      if (profile.inviteCode.isNotEmpty) {
        tx.set(
          _firestore.collection('invite_code_index').doc(profile.inviteCode.toUpperCase()),
          {'uid': profile.uid},
        );
      }
    });
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final publicDoc = await _firestore.collection('users').doc(uid).get();
    if (!publicDoc.exists) return null;

    final isOwner = _isCurrentUser(uid);
    if (isOwner) {
      final privateDoc = await _firestore.collection('users_private').doc(uid).get();
      if (privateDoc.exists) {
        return UserProfile.fromMergedMaps(
          publicData: publicDoc.data()!,
          privateData: privateDoc.data()!,
          uid: uid,
        );
      }
    }

    return UserProfile.fromMap(publicDoc.data()!, uid);
  }

  /// Real-time stream of a single user profile document.
  Stream<UserProfile?> getUserProfileStream(String uid) {
    final publicStream = _firestore.collection('users').doc(uid).snapshots();
    
    if (!_isCurrentUser(uid)) {
      return publicStream.map((snap) {
        if (snap.exists && snap.data() != null) {
          return UserProfile.fromMap(snap.data()!, snap.id);
        }
        return null;
      });
    }

    final privateStream = _firestore.collection('users_private').doc(uid).snapshots();
    
    return Rx.combineLatest2<DocumentSnapshot<Map<String, dynamic>>, DocumentSnapshot<Map<String, dynamic>>, UserProfile?>(
      publicStream,
      privateStream,
      (publicSnap, privateSnap) {
        if (!publicSnap.exists) return null;
        return UserProfile.fromMergedMaps(
          publicData: publicSnap.data() ?? {},
          privateData: privateSnap.data() ?? {},
          uid: uid,
        );
      },
    );
  }

  bool _isCurrentUser(String uid) => FirebaseAuth.instance.currentUser?.uid == uid;

  Map<String, dynamic> _getPublicData(Map<String, dynamic> data) => Map.fromEntries(data.entries.where((e) => UserProfile.publicFields.contains(e.key)));

  Map<String, dynamic> _getPrivateData(Map<String, dynamic> data) => Map.fromEntries(data.entries.where((e) => UserProfile.privateFields.contains(e.key)));

  /// Safety net: if a user is authenticated but has no Firestore doc,
  /// create one with sensible defaults so the profile page never shows
  /// "not found".
  Future<UserProfile> ensureUserDocument({
    required String uid,
    required String email,
    required String displayName,
    required String photoUrl,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final privateRef = _firestore.collection('users_private').doc(uid);
    
    final snap = await docRef.get();
    if (snap.exists && snap.data() != null) {
      final privateSnap = await privateRef.get();
      return UserProfile.fromMergedMaps(
        publicData: snap.data()!,
        privateData: privateSnap.data() ?? {},
        uid: uid,
      );
    }

    // Create the missing document
    final deviceId = await DeviceService.getDeviceId();
    final fullData = {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'username': '',
      'photoUrl': photoUrl,
      'bio': '',
      'karma': 500,
      'lovers': 0,
      'lovely': 0,
      'followersCount': 0,
      'followingCount': 0,
      'isVerified': false,
      'isLimitedUser': false,
      'inviteCode': InviteCodeService.generateCode(),
      'joinedWithCode': '',
      'inviteLimit': 5,
      'invitesUsed': 0,
      'remainingInvites': 5,
      'deviceId': deviceId,
      'invitedUsers': [],
      'totalInvites': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'hasPickedLanguage': false,
    };

    final publicData = _getPublicData(fullData);
    final privateData = _getPrivateData(fullData);

    final batch = _firestore.batch();
    batch.set(docRef, publicData);
    batch.set(privateRef, privateData);
    await batch.commit();

    return UserProfile.fromMap(fullData, uid);
  }

  Future<void> updateIdentityPublicKey(String uid, String publicKey) async {
    await _firestore.collection('users').doc(uid).update({
      'identityPublicKey': publicKey,
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _firestore.collection('usernames').doc(username).get();
    return !doc.exists;
  }

  /// Verifies an invite code and marks the user as verified.
  /// 
  /// Returns 'success' if valid, or an error message.
  Future<String> verifyInviteCode({
    required String code,
    required String currentUserUid,
  }) async {
    try {
      final codeUpper = code.trim().toUpperCase();
      
      // 1. Rate Limiting Check
      final rateLimitDoc = await _firestore
          .collection('rate_limits')
          .doc(currentUserUid)
          .get();
      
      if (rateLimitDoc.exists) {
        final lastAttempt = (rateLimitDoc.data()!['lastAttempt'] as Timestamp).toDate();
        final count = rateLimitDoc.data()!['count'] as int;
        if (DateTime.now().difference(lastAttempt).inHours < 1 && count >= 5) {
          return 'Too many attempts. Please try again in an hour.';
        }
      }

      // Check System Invite Codes first (Admin Panel)
      final systemCodeDoc = await _firestore.collection('invite_codes').doc(codeUpper).get();

      if (systemCodeDoc.exists) {
        final data = systemCodeDoc.data()!;
        if (data['status'] == 'disabled' || data['status'] == 'inactive') {
          return 'This invite code is no longer active.';
        }
        
        final usage = (data['usage'] ?? data['uses'] ?? 0) as int;
        final limit = (data['limit'] ?? data['maxUses'] ?? 10) as int;

        if (usage >= limit) {
          return 'This system invite code has reached its limit.';
        }

        final batch = _firestore.batch();

        // Register user as verified
        batch.update(_firestore.collection('users').doc(currentUserUid), {
          'isVerified': true,
        });
        batch.update(_firestore.collection('users_private').doc(currentUserUid), {
          'isLimitedUser': false,
          'joinedWithCode': codeUpper,
        });

        // Increment system code usage
        batch.update(systemCodeDoc.reference, {
          'usage': FieldValue.increment(1),
          'uses': FieldValue.increment(1), // Backwards compatibility depending on what was used
        });

        // Update Analytics
        final analyticsRef = _firestore.collection('inviteAnalytics').doc(codeUpper);
        batch.set(analyticsRef, {
          'code': codeUpper,
          'createdBy': 'admin',
          'totalUses': FieldValue.increment(1),
          'successfulJoins': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();

        // Reset rate limit on success
        await _firestore.collection('rate_limits').doc(currentUserUid).delete();

        return 'success';
      }

      // If not a system code, look up User Invite Codes via the public index.
      // invite_code_index/{code} => {uid} — no private data is exposed.
      final indexDoc = await _firestore.collection('invite_code_index').doc(codeUpper).get();

      if (!indexDoc.exists || indexDoc.data()?['uid'] == null) {
        // Log failed attempt
        await _firestore.collection('rate_limits').doc(currentUserUid).set({
          'lastAttempt': FieldValue.serverTimestamp(),
          'count': FieldValue.increment(1),
        }, SetOptions(merge: true));
        return 'Invalid invite code. Please check and try again.';
      }

      final ownerId = indexDoc.data()!['uid'] as String;
      // Load owner's private data to check remaining invites
      final ownerPrivateDoc = await _firestore.collection('users_private').doc(ownerId).get();
      
      if (ownerId == currentUserUid) {
        return 'You cannot use your own invite code.';
      }

      // 3. Scarcity Check — read from private doc
      final remaining = (ownerPrivateDoc.data()?['remainingInvites'] ?? 5) as int;
      if (remaining <= 0) {
        return 'This invite code has reached its maximum usage limit.';
      }

      final batch = _firestore.batch();

      // 4. Mark current user as verified
      batch.update(_firestore.collection('users').doc(currentUserUid), {
        'isVerified': true,
      });
      batch.update(_firestore.collection('users_private').doc(currentUserUid), {
        'isLimitedUser': false,
        'joinedWithCode': codeUpper,
      });

      // 5. Update Inviter's Scarcity & Tracking
      batch.update(_firestore.collection('users').doc(ownerId), {
        'karma': FieldValue.increment(100), // Initial reward
      });
      batch.update(_firestore.collection('users_private').doc(ownerId), {
        'invitesUsed': FieldValue.increment(1),
        'remainingInvites': FieldValue.increment(-1),
        'totalInvites': FieldValue.increment(1),
        'invitedUsers': FieldValue.arrayUnion([currentUserUid]),
      });

      // 6. Update Analytics
      final analyticsRef = _firestore.collection('inviteAnalytics').doc(codeUpper);
      batch.set(analyticsRef, {
        'code': codeUpper,
        'createdBy': ownerId,
        'totalUses': FieldValue.increment(1),
        'successfulJoins': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      // Reset rate limit on success
      await _firestore.collection('rate_limits').doc(currentUserUid).delete();

      return 'success';
    } catch (e) {
      return 'Error verifying code. Please try again later.';
    }
  }

  /// Sets whether the user is in limited access mode.
  /// Finalizes the invite reward (100 Karma) once the user is deemed "active".
  Future<bool> finalizeInviteReward({
    required String uid,
    required String joinedWithCode,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      
      return await _firestore.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists) return false;
        
        final profile = UserProfile.fromMap(userSnap.data()!, userSnap.id);
        if (profile.isInviteRewardClaimed) return false;

        // Find the inviter via the invite_code_index
        final indexDoc = await _firestore
            .collection('invite_code_index')
            .doc(joinedWithCode.toUpperCase())
            .get();

        if (!indexDoc.exists || indexDoc.data()?['uid'] == null) return false;
        final inviterRef = _firestore.collection('users').doc(indexDoc.data()!['uid'] as String);

        // 1. Reward inviter with 100 Karma
        transaction.update(inviterRef, {
          'karma': FieldValue.increment(100),
        });

        // 2. Mark reward as claimed for current user
        transaction.update(_firestore.collection('users_private').doc(uid), {
          'isInviteRewardClaimed': true,
        });

        return true;
      });
    } catch (e) {
      
      return false;
    }
  }

  Future<void> setLimitedAccess({
    required String uid,
    required bool isLimited,
  }) async {
    await _firestore.collection('users_private').doc(uid).update({
      'isLimitedUser': isLimited,
    });
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    
    // We will search by username prefix
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<PostModel>> searchPosts(String query) async {
    if (query.trim().isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    
    // Search posts where searchKeywords array contains the query
    final snapshot = await _firestore
        .collection('posts')
        .where('searchKeywords', arrayContains: lowerQuery)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();

    return snapshot.docs
        .map((doc) => PostModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<PostModel>> searchHashtags(String hashtag) async {
    if (hashtag.trim().isEmpty) return [];
    
    final tag = hashtag.startsWith('#') ? hashtag.substring(1) : hashtag;
    
    final snapshot = await _firestore
        .collection('posts')
        .where('hashtags', arrayContains: tag.toLowerCase())
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();

    return snapshot.docs
        .map((doc) => PostModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // --- CHAT OPERATIONS ---

  Stream<List<ChatModel>> getChats(String uid, {int limit = 20}) => _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          FirestoreCostGuard.instance.recordReads(snapshot.docs.length, source: 'getChats');
          final chats = snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
            .toList();
          return chats;
        });

  Future<({List<ChatModel> chats, DocumentSnapshot? lastDoc})> getChatsPage(
    String uid, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    var query = _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await FirestoreQueryCache.instance.get(query);
    FirestoreCostGuard.instance.recordReads(snapshot.docs.length, source: 'getChatsPage');
    final chats = snapshot.docs
        .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
        .toList();
    return (
      chats: chats,
      lastDoc: snapshot.docs.isEmpty ? null : snapshot.docs.last,
    );
  }

  Future<String> createChat(List<String> participants) async {
    final docRef = await _firestore.collection('chats').add({
      'participants': participants,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
    });
    return docRef.id;
  }

  /// Gets or creates a 1-on-1 chat between two users.
  /// Uses a deterministic ID based on the two UIDs to ensure only one chat exists between them.
  Future<String> getOrCreateDirectChat(String uid1, String uid2) async {
    final participants = [uid1, uid2]..sort();
    final chatId = participants.join('_');
    final chatRef = _firestore.collection('chats').doc(chatId);
    
    final snap = await chatRef.get();
    if (!snap.exists) {
      // Fetch names and avatars for caching to avoid "Unknown" in lists
      final u1Doc = await _firestore.collection('users').doc(uid1).get();
      final u2Doc = await _firestore.collection('users').doc(uid2).get();
      
      final names = {
        uid1: u1Doc.data()?['displayName'] ?? 'User',
        uid2: u2Doc.data()?['displayName'] ?? 'User',
      };
      final avatars = {
        uid1: u1Doc.data()?['photoUrl'] ?? '',
        uid2: u2Doc.data()?['photoUrl'] ?? '',
      };

      await chatRef.set({
        'participants': participants,
        'participantNames': names,
        'participantAvatars': avatars,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'isDirect': true,
        'typing': {uid1: false, uid2: false},
        'unreadCount': {uid1: 0, uid2: 0},
      });
    }
    return chatId;
  }

  Stream<List<MessageModel>> getMessages(
    String chatId, {
    int limit = PaginationLimits.messagesPageSize,
  }) =>
      _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            FirestoreCostGuard.instance
                .recordReads(snapshot.docs.length, source: 'getMessages');
            return snapshot.docs
                .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
                .toList();
          });

  Future<({List<MessageModel> messages, DocumentSnapshot? lastDoc})> getMessagesPage(
    String chatId, {
    int limit = PaginationLimits.messagesPageSize,
    DocumentSnapshot? startAfter,
  }) async {
    var query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await FirestoreQueryCache.instance.get(query);
    FirestoreCostGuard.instance.recordReads(snapshot.docs.length, source: 'getMessagesPage');
    final messages = snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
        .toList();
    return (
      messages: messages,
      lastDoc: snapshot.docs.isEmpty ? null : snapshot.docs.last,
    );
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    final batch = _firestore.batch();
    
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));
    
    // Create updated message with expiration and required fields
    final updatedMessage = MessageModel(
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId,
      text: message.text,
      type: message.type,
      mediaUrl: message.mediaUrl,
      mediaThumbnailUrl: message.mediaThumbnailUrl,
      isEncrypted: message.isEncrypted,
      status: message.status,
      timestamp: message.timestamp ?? now,
      expiresAt: expiresAt,
    );
    
    final messageMap = updatedMessage.toMap();
    if (!MessageFactory.isValid(messageMap)) {
      
      throw Exception('Invalid message schema');
    }

    final msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(msgRef, messageMap);
    
    // C-4 FIX: Never store plaintext or ciphertext in lastMessage preview.
    // Store only safe, non-sensitive metadata so the chat list can render
    // "🔒 Encrypted message" without leaking content.
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': {
        'senderId': updatedMessage.senderId,
        'isEncrypted': updatedMessage.isEncrypted,
        'type': updatedMessage.type,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  Future<void> deleteMessage(String chatId, String messageId, {bool forEveryone = false}) async {
    final msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId);
    
    if (forEveryone) {
      await msgRef.update({
        'isDeleted': true,
        'text': 'This message was deleted',
      });
    } else {
      // In a real app, "Delete for me" might involve a list of users who deleted it.
      // For simplicity here, we'll just delete the document if it's "for everyone" 
      // or just mark it as deleted for the UI to handle.
      await msgRef.delete();
    }
  }

  Future<void> editMessage(String chatId, String messageId, String newText) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText,
      'isEdited': true,
    });
  }

  Future<void> deleteChat(String chatId) async {
    // Delete all messages first
    final messages = await _firestore.collection('chats').doc(chatId).collection('messages').get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete the chat document
    batch.delete(_firestore.collection('chats').doc(chatId));
    
    await batch.commit();
  }

  // --- VYBZ OPERATIONS ---

  Stream<List<VybzModel>> getVybzFeed({int limit = 50}) => _firestore
        .collection('vybz')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VybzModel.fromMap(doc.data(), doc.id))
            .toList());

  Stream<List<VybzModel>> getUserVybz(String uid, {int limit = 50}) => _firestore
        .collection('vybz')
        .where('creatorId', isEqualTo: uid)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
            .map((doc) => VybzModel.fromMap(doc.data(), doc.id))
            .toList();
          // Sort locally
          items.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return items;
        });

  Future<void> postVybz(VybzModel vybz) async {
    await _firestore.collection('vybz').add(vybz.toMap());
  }

  Future<void> likeVybz(String vybzId) async {
    final vybzRef = _firestore.collection('vybz').doc(vybzId);
    await DistributedCounter.increment(vybzRef, 'likes');
  }

  Future<void> incrementVybzViews(String vybzId) async {
    final vybzRef = _firestore.collection('vybz').doc(vybzId);
    await DistributedCounter.increment(vybzRef, 'viewsCount');
  }

  Stream<List<CommentModel>> getVybzComments(String vybzId) => _firestore
        .collection('vybz')
        .doc(vybzId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
            .toList());

  Future<void> addVybzComment(String vybzId, CommentModel comment) async {
    final batch = _firestore.batch();
    
    final commentRef = _firestore
        .collection('vybz')
        .doc(vybzId)
        .collection('comments')
        .doc();
    
    batch.set(commentRef, comment.toMap());
    
    final vybzRef = _firestore.collection('vybz').doc(vybzId);
    DistributedCounter.incrementInBatch(batch, vybzRef, 'commentsCount');

    await batch.commit();
  }

  Future<void> appreciateVybz({
    required String vybzId,
    required String senderId,
    required String receiverId,
  }) async {
    final batch = _firestore.batch();

    // 1. Update Receiver's Karma
    batch.update(_firestore.collection('users').doc(receiverId), {
      'karma': FieldValue.increment(10), // Flat 10 Karma points for an appreciation
    });

    // 2. Update Vybz appreciate count
    final vybzRef = _firestore.collection('vybz').doc(vybzId);
    DistributedCounter.incrementInBatch(batch, vybzRef, 'appreciations');

    await batch.commit();
  }

  Future<void> requestInviteCode({required String uid, required String email}) async {
    await _firestore.collection('inviteRequests').doc(uid).set({
      'uid': uid,
      'email': email,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Stream<UserPresence?> getUserPresenceStream(String uid) => _firestore.collection('presence').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserPresence.fromMap(doc.data()!);
    });

  Stream<Map<String, bool>> getTypingStream(String chatId) => _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return {};
      final data = doc.data()!;
      if (data['typing'] is Map) {
        return (data['typing'] as Map).map((k, v) => MapEntry(k.toString(), v == true));
      }
      return {};
    });
}
