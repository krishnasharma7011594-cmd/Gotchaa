import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update editable profile fields in Firestore.
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String username,
    required String bio,
    String? photoUrl,
    DateTime? birthday,
    String? language,
    int? ageTier,
    bool? ageVerified,
    bool? hasPickedLanguage,
  }) async {
    final Map<String, dynamic> publicData = {
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photoUrl != null) publicData['photoUrl'] = photoUrl;
    if (language != null) publicData['language'] = language;
    if (hasPickedLanguage != null) {
      publicData['hasPickedLanguage'] = hasPickedLanguage;
    }

    final Map<String, dynamic> privateData = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (birthday != null) {
      privateData['birthday'] = Timestamp.fromDate(birthday);
    }
    if (ageTier != null) privateData['ageTier'] = ageTier;
    if (ageVerified != null) privateData['ageVerified'] = ageVerified;

    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), publicData);
    if (privateData.length > 1) {
      // More than just updatedAt
      batch.set(_firestore.collection('users_private').doc(uid), privateData,
          SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> updatePersonalInfo({
    required String uid,
    String? phoneNumber,
    String? gender,
    DateTime? birthday,
  }) async {
    // Personal info is private — write to users_private only.
    final Map<String, dynamic> data = {};
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (gender != null) data['gender'] = gender;
    if (birthday != null) data['birthday'] = Timestamp.fromDate(birthday);

    if (data.isNotEmpty) {
      await _firestore
          .collection('users_private')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    }
  }

  /// Update privacy/security settings collectively or individually.
  /// These fields (isPrivate, showActivityStatus, etc.) are private data.
  Future<void> updatePrivacySettings({
    required String uid,
    required Map<String, dynamic> settings,
  }) async {
    final publicData = Map<String, dynamic>.fromEntries(settings.entries
        .where((e) => UserProfile.publicFields.contains(e.key)));
    final privateData = Map<String, dynamic>.fromEntries(settings.entries
        .where((e) => UserProfile.privateFields.contains(e.key)));

    final batch = _firestore.batch();
    if (publicData.isNotEmpty) {
      batch.update(_firestore.collection('users').doc(uid), publicData);
    }
    if (privateData.isNotEmpty) {
      batch.set(_firestore.collection('users_private').doc(uid), privateData,
          SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Update only the photoUrl field.
  Future<void> updateProfilePhoto({
    required String uid,
    required String photoUrl,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update E2EE Identity Public Key.
  /// Uses set+merge so it succeeds even if the doc or field doesn't exist yet
  /// (e.g. first login before full profile creation).
  Future<void> updateIdentityPublicKey({
    required String uid,
    required String publicKey,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'identityPublicKey': publicKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Check if a username is already taken by another user.
  Future<bool> isUsernameAvailable(String username, String currentUid) async {
    final doc = await _firestore
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();
    if (!doc.exists) return true;
    return doc.data()?['uid'] == currentUid;
  }

  /// Reserve the new username and release the old one. We now defer this strictly to `UsernameService.updateUsername` which has 7-day checks.
  /// But this method stays here just in case as a simple atomic update without rules.
  Future<void> updateUsername({
    required String uid,
    required String oldUsername,
    required String newUsername,
  }) async {
    final batch = _firestore.batch();

    if (oldUsername.isNotEmpty) {
      batch.delete(
          _firestore.collection('usernames').doc(oldUsername.toLowerCase()));
    }

    if (newUsername.isNotEmpty) {
      batch.set(
        _firestore.collection('usernames').doc(newUsername.toLowerCase()),
        {'uid': uid},
      );
    }

    await batch.commit();
  }

  /// Get user profile (one-shot).
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Stream user profile in real-time.
  Stream<UserProfile?> streamProfile(String uid) =>
      _firestore.collection('users').doc(uid).snapshots().map((snap) {
        if (snap.exists && snap.data() != null) {
          return UserProfile.fromMap(snap.data()!, snap.id);
        }
        return null;
      });

  Future<void> blockUser(
      {required String currentUid, required String targetUid}) async {
    final batch = _firestore.batch();

    // 1. Add to blocked_accounts collection
    final blockDoc = _firestore
        .collection('blocked_accounts')
        .doc('${currentUid}_blocked_$targetUid');
    batch.set(blockDoc, {
      'blockerId': currentUid,
      'blockedId': targetUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Update blocker's blockedUids list
    batch.update(_firestore.collection('users').doc(currentUid), {
      'blockedUids': FieldValue.arrayUnion([targetUid]),
    });

    // 3. Clean up followers/following relationships both ways
    final followerDoc1 = _firestore
        .collection('followers')
        .doc(targetUid)
        .collection('userFollowers')
        .doc(currentUid);
    final followingDoc1 = _firestore
        .collection('following')
        .doc(currentUid)
        .collection('userFollowing')
        .doc(targetUid);
    final followerDoc2 = _firestore
        .collection('followers')
        .doc(currentUid)
        .collection('userFollowers')
        .doc(targetUid);
    final followingDoc2 = _firestore
        .collection('following')
        .doc(targetUid)
        .collection('userFollowing')
        .doc(currentUid);

    // We check existence first, but in a batch we can just delete them.
    batch.delete(followerDoc1);
    batch.delete(followingDoc1);
    batch.delete(followerDoc2);
    batch.delete(followingDoc2);

    await batch.commit();
  }

  Future<void> unblockUser(
      {required String currentUid, required String targetUid}) async {
    final batch = _firestore.batch();

    final blockDoc = _firestore
        .collection('blocked_accounts')
        .doc('${currentUid}_blocked_$targetUid');
    batch.delete(blockDoc);

    batch.update(_firestore.collection('users').doc(currentUid), {
      'blockedUids': FieldValue.arrayRemove([targetUid]),
    });

    await batch.commit();
  }

  Future<void> muteUser(
      {required String currentUid, required String targetUid}) async {
    final batch = _firestore.batch();

    final muteDoc = _firestore
        .collection('muted_accounts')
        .doc('${currentUid}_muted_$targetUid');
    batch.set(muteDoc, {
      'muterId': currentUid,
      'mutedId': targetUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.update(_firestore.collection('users').doc(currentUid), {
      'mutedUids': FieldValue.arrayUnion([targetUid]),
    });

    await batch.commit();
  }

  Future<void> unmuteUser(
      {required String currentUid, required String targetUid}) async {
    final batch = _firestore.batch();

    final muteDoc = _firestore
        .collection('muted_accounts')
        .doc('${currentUid}_muted_$targetUid');
    batch.delete(muteDoc);

    batch.update(_firestore.collection('users').doc(currentUid), {
      'mutedUids': FieldValue.arrayRemove([targetUid]),
    });

    await batch.commit();
  }

  Future<void> addToGhostList(
      {required String currentUid, required String targetUid}) async {
    await _firestore.collection('users_private').doc(currentUid).update({
      'ghostUids': FieldValue.arrayUnion([targetUid]),
    });
  }

  Future<void> removeFromGhostList(
      {required String currentUid, required String targetUid}) async {
    await _firestore.collection('users_private').doc(currentUid).update({
      'ghostUids': FieldValue.arrayRemove([targetUid]),
    });
  }

  Future<void> addToFriendList(
      {required String currentUid, required String targetUid}) async {
    await _firestore.collection('users_private').doc(currentUid).update({
      'friendUids': FieldValue.arrayUnion([targetUid]),
    });
  }

  Future<void> removeFromFriendList(
      {required String currentUid, required String targetUid}) async {
    await _firestore.collection('users_private').doc(currentUid).update({
      'friendUids': FieldValue.arrayRemove([targetUid]),
    });
  }

  Future<void> createCustomList({
    required String uid,
    required String name,
    required List<String> memberUids,
  }) async {
    final listId = DateTime.now().millisecondsSinceEpoch.toString();
    final listData = {
      'id': listId,
      'name': name,
      'uids': memberUids,
    };
    await _firestore.collection('users_private').doc(uid).update({
      'customPrivacyLists': FieldValue.arrayUnion([listData]),
    });
  }

  Future<void> updateCustomList({
    required String uid,
    required String listId,
    String? name,
    List<String>? memberUids,
  }) async {
    final doc = await _firestore.collection('users_private').doc(uid).get();
    if (!doc.exists) return;

    final List<dynamic> lists = doc.data()?['customPrivacyLists'] ?? [];
    final index = lists.indexWhere((l) => l['id'] == listId);
    if (index == -1) return;

    final Map<String, dynamic> list = Map<String, dynamic>.from(lists[index]);
    if (name != null) list['name'] = name;
    if (memberUids != null) list['uids'] = memberUids;

    lists[index] = list;
    await _firestore.collection('users_private').doc(uid).update({
      'customPrivacyLists': lists,
    });
  }

  Future<void> deleteCustomList({
    required String uid,
    required String listId,
  }) async {
    final doc = await _firestore.collection('users_private').doc(uid).get();
    if (!doc.exists) return;

    final List<dynamic> lists = doc.data()?['customPrivacyLists'] ?? [];
    lists.removeWhere((l) => l['id'] == listId);

    await _firestore.collection('users_private').doc(uid).update({
      'customPrivacyLists': lists,
    });
  }
}
