import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/app_constants.dart';
import '../models/user_profile.dart';
import '../nation/nation_data.dart';
import '../security/e2ee_service.dart';
import '../services/device_service.dart';
import '../services/invite_code_service.dart';
import 'firestore_repository.dart';

class AuthRepository {

  AuthRepository(this._firestoreRepository, this._e2eeService);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreRepository _firestoreRepository;
  final E2EEService _e2eeService;

  // ── Stream ──────────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Helper ──────────────────────────────────────────────────────────────────

  // ── Email / Password ─────────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail(
      String email, String password) async => _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);

  Future<UserCredential> signUpWithEmail(
      String email, String password, {NationData? nation}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);

    // Create Firestore document for new user
    await _createUserDocument(
      uid: credential.user!.uid,
      email: email.trim(),
      displayName: email.split('@').first,
      photoUrl: '',
      nation: nation,
    );

    return credential;
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────────

  Future<UserCredential> signInWithGoogle() async {
    UserCredential credential;

    if (kIsWeb) {
      // Web: use firebase_auth's built-in popup flow
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      credential = await _auth.signInWithPopup(googleProvider);
    } else {
      // Mobile: use the google_sign_in package
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in aborted by user');
      }
      final googleAuth = await googleUser.authentication;
      final oauthCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      credential = await _auth.signInWithCredential(oauthCredential);
    }

    // Create Firestore document only if this is a NEW user
    if (credential.additionalUserInfo?.isNewUser ?? false) {
      final user = credential.user!;
      await _createUserDocument(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
        photoUrl: user.photoURL ?? '',
      );
    }

    return credential;
  }

  // ── Apple Sign-In ────────────────────────────────────────────────────────────

  Future<UserCredential> signInWithApple() async {
    final appleProvider = OAuthProvider('apple.com')
      ..addScope('email')
      ..addScope('name');

    UserCredential credential;

    if (kIsWeb) {
      credential = await _auth.signInWithPopup(appleProvider);
    } else {
      credential = await _auth.signInWithProvider(appleProvider);
    }

    if (credential.additionalUserInfo?.isNewUser ?? false) {
      final user = credential.user!;
      await _createUserDocument(
        uid: user.uid,
        email: user.email ?? '',
        displayName:
            user.displayName ?? user.email?.split('@').first ?? 'Apple User',
        photoUrl: user.photoURL ?? '',
      );
    }

    return credential;
  }

  Future<UserCredential> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    
    // Create Firestore document only if this is a NEW user
    if (credential.additionalUserInfo?.isNewUser ?? false) {
      final user = credential.user!;
      await _createUserDocument(
        uid: user.uid,
        email: '',
        displayName: 'Guest ${user.uid.substring(0, 4)}',
        photoUrl: '',
      );
    }
    
    return credential;
  }

  // ── Sign-Out ─────────────────────────────────────────────────────────────────
  
  Future<void> signOut() async {
    // SECURITY: Clear E2EE in-memory cache. 
    // We do NOT clear secure storage here so keys persist for the next login.
    try {
      _e2eeService.clearMemoryCache();
    } catch (e) {
      
    }

    if (!kIsWeb) {
      // Also sign out from Google on mobile so the account picker shows next time
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // This triggers a verification email to the NEW email
    await user.verifyBeforeUpdateEmail(newEmail);
  }

  // ── Account Deletion ───────────────────────────────────────────────────────

  Future<void> reauthenticate(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google re-auth aborted');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Call Cloud Function to delete all data and auth account on server
    // Note: We use httpsCallable from cloud_functions package
    // Since I don't see cloud_functions provider here, I'll assume it's available via FirebaseFunctions.instance
    final result = await _firestoreRepository.callDeleteAccountFunction();
    
    if (!result) {
      throw Exception('Failed to delete account data on server');
    }

    // Clear local E2EE keys for this user
    await _e2eeService.deleteUserData(user.uid);

    // Sign out locally
    await signOut();
  }

  // ── Profile Setup ────────────────────────────────────────────────────────────

  /// Called from UsernameSetupScreen after email sign-up to set the username.
  Future<void> completeProfileSetup({
    required String username,
    required String displayName,
    String photoUrl = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Update the Auth display name too
    await user.updateDisplayName(displayName);

    final profile = UserProfile(
      uid: user.uid,
      username: username,
      displayName: displayName,
      email: user.email ?? '',
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );

    await _firestoreRepository.createUserProfile(profile);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    required String photoUrl,
    NationData? nation,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final existing = await docRef.get();
    if (existing.exists) return; // Don't overwrite existing data

    final deviceId = await DeviceService.getDeviceId();

    // Build nation sub-map (safe even when null)
    final nationMap = nation == null
        ? <String, dynamic>{}
        : {
            'homeCountry': nation.countryCode,
            'homeFlag': nation.flag,
            'homeCountryName': nation.countryName,
            'homeContinent': nation.continent,
            'currentCountry': nation.countryCode,
            'currentFlag': nation.flag,
            'currentCountryName': nation.countryName,
            'currentContinent': nation.continent,
            'isTravelling': false,
            'primaryLanguage': nation.primaryLanguage,
            'languageCode': nation.languageCode,
            'timezone': nation.timezone,
            'currencyCode': nation.currencyCode,
            'currencySymbol': nation.currencySymbol,
            'detectedVia': nation.detectedVia,
            'confidence': nation.confidence,
            'isManuallySet': nation.detectedVia == 'MANUAL',
            'detectedAt': DateTime.now(),
            'lastSeenAt': DateTime.now(),
          };

    final identityPublicKey = await _e2eeService.generateAndStoreIdentityKeyPair(uid);

    final profile = UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      username: '', // filled in by UsernameSetupScreen
      photoUrl: photoUrl,
      bio: '',
      karma: 500,
      lovers: 0,
      lovely: 0,
      isVerified: false,
      isLimitedUser: false,
      identityPublicKey: identityPublicKey,
      inviteCode: InviteCodeService.generateCode(),
      joinedWithCode: '',
      inviteLimit: 5,
      invitesUsed: 0,
      remainingInvites: 5,
      deviceId: deviceId,
      invitedUsers: [],
      totalInvites: 0,
      nation: nationMap,
      createdAt: DateTime.now(),
      termsAcceptedVersion: LegalConfig.termsVersion,
      privacyAcceptedVersion: LegalConfig.privacyVersion,
      legalAcceptedAt: DateTime.now(),
    );

    await _firestoreRepository.createUserProfile(profile);
  }
}
