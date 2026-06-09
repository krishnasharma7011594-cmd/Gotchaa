import 'package:cloud_firestore/cloud_firestore.dart';

class CustomPrivacyList {
  CustomPrivacyList({required this.id, required this.name, required this.uids});

  factory CustomPrivacyList.fromMap(Map<String, dynamic> data) =>
      CustomPrivacyList(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        uids: List<String>.from(data['uids'] ?? []),
      );
  final String id;
  final String name;
  final List<String> uids;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'uids': uids,
      };
}

class UserProfile {
  UserProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.createdAt,
    this.email = '',
    this.photoUrl = '',
    this.bio = '',
    this.karma = 500,
    this.lovers = 0,
    this.lovely = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isVerified = false,
    this.isLimitedUser = false,
    this.inviteCode = '',
    this.joinedWithCode = '',
    this.inviteLimit = 5,
    this.invitesUsed = 0,
    this.remainingInvites = 5,
    this.deviceId,
    this.invitedUsers = const [],
    this.blockedUids = const [],
    this.mutedUids = const [],
    this.ghostUids = const [],
    this.friendUids = const [],
    this.customPrivacyLists = const [],
    this.totalInvites = 0,
    this.isInviteRewardClaimed = false,
    this.phoneNumber,
    this.gender,
    this.birthday,
    this.lastUsernameUpdate,
    this.isPrivate,
    this.showActivityStatus,
    this.pushNotificationsEnabled,
    this.emailNotificationsEnabled,
    this.isTwoFactorEnabled,
    this.identityPublicKey,
    this.stayAnonymousInConnections = false,
    this.nation,
    this.isOnline = false,
    this.lastSeen,
    this.fcmToken,
    this.privacyAcceptedVersion,
    this.legalAcceptedAt,
    this.ageTier,
    this.ageVerified = false,
    this.hasPickedLanguage = false,
    this.termsAcceptedVersion,
    this.language,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String id) =>
      UserProfile(
        uid: id,
        username: data['username'] ?? '',
        displayName: data['displayName'] ?? '',
        email: data['email'] ?? '',
        photoUrl: data['photoUrl'] ?? '',
        bio: data['bio'] ?? '',
        karma: (data['karma'] ?? 500) as int,
        lovers: (data['lovers'] ?? 0) as int,
        lovely: (data['lovely'] ?? 0) as int,
        followersCount: (data['followersCount'] ?? 0) as int,
        followingCount: (data['followingCount'] ?? 0) as int,
        isVerified: data['isVerified'] ?? false,
        isLimitedUser: data['isLimitedUser'] ?? false,
        inviteCode: data['inviteCode'] ?? '',
        joinedWithCode: data['joinedWithCode'] ?? '',
        inviteLimit: (data['inviteLimit'] ?? 5) as int,
        invitesUsed: (data['invitesUsed'] ?? 0) as int,
        remainingInvites: (data['remainingInvites'] ?? 5) as int,
        deviceId: data['deviceId'],
        invitedUsers: List<String>.from(data['invitedUsers'] ?? []),
        blockedUids: List<String>.from(data['blockedUids'] ?? []),
        mutedUids: List<String>.from(data['mutedUids'] ?? []),
        ghostUids: List<String>.from(data['ghostUids'] ?? []),
        friendUids: List<String>.from(data['friendUids'] ?? []),
        customPrivacyLists: (data['customPrivacyLists'] as List? ?? [])
            .map((e) => CustomPrivacyList.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        totalInvites: (data['totalInvites'] ?? 0) as int,
        isInviteRewardClaimed: data['isInviteRewardClaimed'] ?? false,
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        phoneNumber: data['phoneNumber'],
        gender: data['gender'],
        birthday: data['birthday'] != null && data['birthday'] is Timestamp
            ? (data['birthday'] as Timestamp).toDate()
            : null,
        lastUsernameUpdate: data['lastUsernameUpdate'] != null &&
                data['lastUsernameUpdate'] is Timestamp
            ? (data['lastUsernameUpdate'] as Timestamp).toDate()
            : null,
        isPrivate: data['isPrivate'],
        showActivityStatus: data['showActivityStatus'],
        pushNotificationsEnabled: data['pushNotificationsEnabled'],
        emailNotificationsEnabled: data['emailNotificationsEnabled'],
        isTwoFactorEnabled: data['isTwoFactorEnabled'],
        identityPublicKey: data['identityPublicKey'],
        stayAnonymousInConnections: data['stayAnonymousInConnections'] ?? false,
        nation: data['nation'] as Map<String, dynamic>?,
        isOnline: data['isOnline'] ?? false,
        lastSeen: data['lastSeen'] != null && data['lastSeen'] is Timestamp
            ? (data['lastSeen'] as Timestamp).toDate()
            : null,
        fcmToken: data['fcmToken'],
        hasPickedLanguage: data['hasPickedLanguage'] ?? false,
        termsAcceptedVersion: data['termsAcceptedVersion'],
        privacyAcceptedVersion: data['privacyAcceptedVersion'],
        legalAcceptedAt: data['legalAcceptedAt'] != null &&
                data['legalAcceptedAt'] is Timestamp
            ? (data['legalAcceptedAt'] as Timestamp).toDate()
            : null,
        ageTier: data['ageTier'] as int?,
        ageVerified: data['ageVerified'] ?? false,
      );

  /// Merges public and private data into a single UserProfile.
  factory UserProfile.fromMergedMaps({
    required Map<String, dynamic> publicData,
    required Map<String, dynamic> privateData,
    required String uid,
  }) {
    final merged = Map<String, dynamic>.from(publicData)..addAll(privateData);
    return UserProfile.fromMap(merged, uid);
  }
  final String uid;
  final String username;
  final String displayName;
  final String email;
  final String photoUrl;
  final String bio;
  final int karma;
  final int lovers;
  final int lovely;
  final int followersCount;
  final int followingCount;
  final bool isVerified;
  final bool isLimitedUser;
  final String inviteCode;
  final String joinedWithCode;
  final int inviteLimit;
  final int invitesUsed;
  final int remainingInvites;
  final String? deviceId;
  final List<String> invitedUsers;
  final List<String> blockedUids;
  final List<String> mutedUids;
  final List<String> ghostUids;
  final List<String> friendUids;
  final List<CustomPrivacyList> customPrivacyLists;
  final int totalInvites;
  final bool isInviteRewardClaimed;
  final DateTime createdAt;
  final String? phoneNumber;
  final String? gender;
  final DateTime? birthday;
  final bool hasPickedLanguage;
  final String? termsAcceptedVersion;
  final String? privacyAcceptedVersion;
  final DateTime? legalAcceptedAt;

  final DateTime? lastUsernameUpdate;
  final bool? isPrivate;
  final bool? showActivityStatus;
  final bool? pushNotificationsEnabled;
  final bool? emailNotificationsEnabled;
  final bool? isTwoFactorEnabled;
  final String? identityPublicKey;
  final bool? stayAnonymousInConnections;
  final Map<String, dynamic>? nation;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;
  final int? ageTier;
  final bool ageVerified;
  final String? language;

  static List<String> get publicFields => [
        'uid',
        'username',
        'displayName',
        'photoUrl',
        'bio',
        'karma',
        'lovers',
        'lovely',
        'followersCount',
        'followingCount',
        'isVerified',
        'createdAt',
        'isOnline',
        'lastSeen',
        'nation',
        'identityPublicKey',
        'stayAnonymousInConnections',
        'isPrivate',
        'language'
      ];

  static List<String> get privateFields => [
        'email',
        'inviteCode',
        'joinedWithCode',
        'inviteLimit',
        'invitesUsed',
        'remainingInvites',
        'deviceId',
        'invitedUsers',
        'totalInvites',
        'isInviteRewardClaimed',
        'phoneNumber',
        'gender',
        'birthday',
        'showActivityStatus',
        'pushNotificationsEnabled',
        'emailNotificationsEnabled',
        'isTwoFactorEnabled',
        'fcmToken',
        'isLimitedUser',
        'lastUsernameUpdate',
        'hasPickedLanguage',
        'termsAcceptedVersion',
        'privacyAcceptedVersion',
        'legalAcceptedAt',
        'blockedUids',
        'mutedUids',
        'ghostUids',
        'friendUids',
        'customPrivacyLists',
        'ageTier',
        'ageVerified'
      ];

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'bio': bio,
        'karma': karma,
        'lovers': lovers,
        'lovely': lovely,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'isVerified': isVerified,
        'isLimitedUser': isLimitedUser,
        'inviteCode': inviteCode,
        'joinedWithCode': joinedWithCode,
        'inviteLimit': inviteLimit,
        'invitesUsed': invitesUsed,
        'remainingInvites': remainingInvites,
        'deviceId': deviceId,
        'invitedUsers': invitedUsers,
        'blockedUids': blockedUids,
        'mutedUids': mutedUids,
        'ghostUids': ghostUids,
        'friendUids': friendUids,
        'customPrivacyLists': customPrivacyLists.map((e) => e.toMap()).toList(),
        'totalInvites': totalInvites,
        'isInviteRewardClaimed': isInviteRewardClaimed,
        'createdAt': Timestamp.fromDate(createdAt),
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (gender != null) 'gender': gender,
        if (birthday != null) 'birthday': Timestamp.fromDate(birthday!),
        if (lastUsernameUpdate != null)
          'lastUsernameUpdate': Timestamp.fromDate(lastUsernameUpdate!),
        'isPrivate': isPrivate,
        'showActivityStatus': showActivityStatus,
        'pushNotificationsEnabled': pushNotificationsEnabled,
        'emailNotificationsEnabled': emailNotificationsEnabled,
        'isTwoFactorEnabled': isTwoFactorEnabled,
        if (identityPublicKey != null) 'identityPublicKey': identityPublicKey,
        'stayAnonymousInConnections': stayAnonymousInConnections,
        if (nation != null) 'nation': nation,
        'isOnline': isOnline,
        if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
        if (fcmToken != null) 'fcmToken': fcmToken,
        'hasPickedLanguage': hasPickedLanguage,
        if (termsAcceptedVersion != null)
          'termsAcceptedVersion': termsAcceptedVersion,
        if (privacyAcceptedVersion != null)
          'privacyAcceptedVersion': privacyAcceptedVersion,
        if (legalAcceptedAt != null)
          'legalAcceptedAt': Timestamp.fromDate(legalAcceptedAt!),
        'ageTier': ageTier,
        'ageVerified': ageVerified,
        if (language != null) 'language': language,
      };

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? email,
    String? photoUrl,
    String? bio,
    int? karma,
    int? lovers,
    int? lovely,
    int? followersCount,
    int? followingCount,
    bool? isVerified,
    bool? isLimitedUser,
    String? inviteCode,
    String? joinedWithCode,
    int? inviteLimit,
    int? invitesUsed,
    int? remainingInvites,
    String? deviceId,
    List<String>? invitedUsers,
    List<String>? blockedUids,
    List<String>? mutedUids,
    List<String>? ghostUids,
    List<String>? friendUids,
    List<CustomPrivacyList>? customPrivacyLists,
    int? totalInvites,
    bool? isInviteRewardClaimed,
    String? phoneNumber,
    String? gender,
    DateTime? birthday,
    DateTime? lastUsernameUpdate,
    bool? isPrivate,
    bool? showActivityStatus,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? isTwoFactorEnabled,
    String? identityPublicKey,
    bool? stayAnonymousInConnections,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    bool? hasPickedLanguage,
    String? termsAcceptedVersion,
    String? privacyAcceptedVersion,
    DateTime? legalAcceptedAt,
    int? ageTier,
    bool? ageVerified,
    String? language,
  }) =>
      UserProfile(
        uid: uid,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        bio: bio ?? this.bio,
        karma: karma ?? this.karma,
        lovers: lovers ?? this.lovers,
        lovely: lovely ?? this.lovely,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount ?? this.followingCount,
        isVerified: isVerified ?? this.isVerified,
        isLimitedUser: isLimitedUser ?? this.isLimitedUser,
        inviteCode: inviteCode ?? this.inviteCode,
        joinedWithCode: joinedWithCode ?? this.joinedWithCode,
        inviteLimit: inviteLimit ?? this.inviteLimit,
        invitesUsed: invitesUsed ?? this.invitesUsed,
        remainingInvites: remainingInvites ?? this.remainingInvites,
        deviceId: deviceId ?? this.deviceId,
        invitedUsers: invitedUsers ?? this.invitedUsers,
        blockedUids: blockedUids ?? this.blockedUids,
        mutedUids: mutedUids ?? this.mutedUids,
        ghostUids: ghostUids ?? this.ghostUids,
        friendUids: friendUids ?? this.friendUids,
        customPrivacyLists: customPrivacyLists ?? this.customPrivacyLists,
        totalInvites: totalInvites ?? this.totalInvites,
        isInviteRewardClaimed:
            isInviteRewardClaimed ?? this.isInviteRewardClaimed,
        createdAt: createdAt,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        gender: gender ?? this.gender,
        birthday: birthday ?? this.birthday,
        lastUsernameUpdate: lastUsernameUpdate ?? this.lastUsernameUpdate,
        isPrivate: isPrivate ?? this.isPrivate,
        showActivityStatus: showActivityStatus ?? this.showActivityStatus,
        pushNotificationsEnabled:
            pushNotificationsEnabled ?? this.pushNotificationsEnabled,
        emailNotificationsEnabled:
            emailNotificationsEnabled ?? this.emailNotificationsEnabled,
        isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
        identityPublicKey: identityPublicKey ?? this.identityPublicKey,
        stayAnonymousInConnections:
            stayAnonymousInConnections ?? this.stayAnonymousInConnections,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen ?? this.lastSeen,
        fcmToken: fcmToken ?? this.fcmToken,
        hasPickedLanguage: hasPickedLanguage ?? this.hasPickedLanguage,
        termsAcceptedVersion: termsAcceptedVersion ?? this.termsAcceptedVersion,
        privacyAcceptedVersion:
            privacyAcceptedVersion ?? this.privacyAcceptedVersion,
        legalAcceptedAt: legalAcceptedAt ?? this.legalAcceptedAt,
        ageTier: ageTier ?? this.ageTier,
        ageVerified: ageVerified ?? this.ageVerified,
        language: language ?? this.language,
      );
}
