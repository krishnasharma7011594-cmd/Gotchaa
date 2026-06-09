import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/age_tier.dart';
import '../models/user_profile.dart';
import 'auth_providers.dart';
import 'profile_providers.dart';
import 'shared_prefs_provider.dart';

final ageProvider = StateNotifierProvider<AgeNotifier, AgeStatus>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final user = ref.watch(currentUserProvider);
  final notifier = AgeNotifier(ref, prefs, user?.uid);
  ref.listen<AsyncValue<UserProfile?>>(currentUserProfileProvider, (prev, next) {
    final profile = next.asData?.value;
    if (profile != null) {
      notifier.updateFromProfile(profile);
    }
  }, fireImmediately: true);
  return notifier;
});

class AgeNotifier extends StateNotifier<AgeStatus> {
  // Existing constructor and fields remain unchanged.

  /// Public helper to refresh age status when profile data changes.
  void updateFromProfile(UserProfile profile) {
    _loadStatus(profile);
    // If a local under‑13 block flag exists but we now have a profile,
    // clear it because the user may have become verified/older.
    if (_prefs?.getBool('blocked_under_13') == true) {
      _prefs?.remove('blocked_under_13');
    }
  }
  AgeNotifier(this.ref, this._prefs, this._uid) : super(AgeStatus.initial()) {
    _loadStatus(null);
  }

  final Ref ref;
  final SharedPreferences? _prefs;
  final String? _uid;

  String get _tierKey => _uid != null ? '${_uid}_age_tier' : 'age_tier';
  String get _verifiedKey => _uid != null ? '${_uid}_age_verified' : 'age_verified';
  String get _dobKey => _uid != null ? '${_uid}_age_dob' : 'age_dob';

  void _loadStatus(UserProfile? profile) {
    // Guard: if prefs not ready, stay at initial state
    if (_prefs == null) return;

    // 0. Check if locally blocked under 13 *and not verified* (or not adult in profile)
    if (_prefs!.getBool('blocked_under_13') == true &&
        !(profile?.ageVerified ?? false) &&
        !(profile?.ageTier == AgeTier.adult.index)) {
      state = AgeStatus(
        tier: AgeTier.under13Blocked,
        isVerified: false,
      );
      return;
    }

    // 1. Check SharedPreferences
    final tierIndex = _prefs!.getInt(_tierKey);
    final isVerifiedLocal = _prefs!.getBool(_verifiedKey) ?? false;
    final dobString = _prefs!.getString(_dobKey);

    // 2. Check Profile (Firestore)
    final isVerifiedCloud = profile?.ageVerified ?? false;
    final tierIndexCloud = profile?.ageTier;
    final dobCloud = profile?.birthday;
    final isUserDeclaredAdult = tierIndexCloud == AgeTier.adult.index;

    if (isVerifiedCloud || isVerifiedLocal || isUserDeclaredAdult) {
      final tier = tierIndexCloud != null 
          ? AgeTier.values[tierIndexCloud] 
          : (tierIndex != null ? AgeTier.values[tierIndex] : AgeTier.adult);
          
      state = AgeStatus(
        tier: tier,
        isVerified: true,
        dateOfBirth: dobCloud ?? (dobString != null ? DateTime.parse(dobString) : null),
      );
      
      // Sync local prefs if cloud is verified or local is verified
      if (isVerifiedCloud && !isVerifiedLocal) {
        _prefs!.setInt(_tierKey, tier.index);
        _prefs!.setBool(_verifiedKey, true);
        if (dobCloud != null) {
          _prefs!.setString(_dobKey, dobCloud.toIso8601String());
        }
      }
    } else {
      // If NOT verified but we have a birthday in cloud, treat it as verified
      if (dobCloud != null) {
        final age = _calculateAge(dobCloud);
        AgeTier tier;
        if (age < 13) {
          tier = AgeTier.under13Blocked;
        } else if (age <= 15) {
          tier = AgeTier.junior;
        } else if (age <= 17) {
          tier = AgeTier.teen;
        } else {
          tier = AgeTier.adult;
        }
        state = AgeStatus(
          tier: tier,
          isVerified: true, 
          dateOfBirth: dobCloud,
        );
        _prefs!.setBool(_verifiedKey, true);
        _prefs!.setInt(_tierKey, tier.index);
        _prefs!.setString(_dobKey, dobCloud.toIso8601String());
        
        // Also sync the flag back to firestore just in case it was missing
        if (_uid != null) {
          FirebaseFirestore.instance.collection('users_private').doc(_uid).update({
            'ageVerified': true,
          }).catchError((_) => null);
        }
      }
    }
  }

  Future<void> setDateOfBirth(DateTime dob) async {
    final age = _calculateAge(dob);
    if (age < 13) {
      // Block completely. No birthday collected or saved!
      state = AgeStatus(
        tier: AgeTier.under13Blocked,
        dateOfBirth: null,
        isVerified: false,
      );
      await _prefs?.setBool('blocked_under_13', true);
      return;
    }
    
    AgeTier tier;
    if (age <= 15) {
      tier = AgeTier.junior;
    } else if (age <= 17) {
      tier = AgeTier.teen;
    } else {
      tier = AgeTier.adult;
    }
    await verifyAge(dob, tier);
  }

  Future<void> verifyAge(DateTime dob, AgeTier tier) async {
    // 1. Update state
    state = AgeStatus(
      tier: tier,
      dateOfBirth: dob,
      isVerified: true,
    );

    // 2. Save locally
    await _prefs?.setInt(_tierKey, tier.index);
    await _prefs?.setBool(_verifiedKey, true);
    await _prefs?.setString(_dobKey, dob.toIso8601String());

    // 3. Sync to Firestore
    if (_uid != null) {
      await FirebaseFirestore.instance.collection('users_private').doc(_uid).set({
        'ageTier': tier.index,
        'ageVerified': true,
        'birthday': Timestamp.fromDate(dob),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((_) => null);
    }
    // Clear any local under-13 block flag now that age is verified
    await _prefs?.remove('blocked_under_13');
  }

  Future<void> submitParentalConsent(String parentEmail) async {
    if (_uid != null) {
      await FirebaseFirestore.instance.collection('parental_consents').doc(_uid).set({
        'parentEmail': parentEmail,
        'confirmed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> checkParentalConsentStatus() async {
    if (_uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('parental_consents').doc(_uid).get();
    if (doc.exists && doc.data()?['confirmed'] == true) {
      // Consent approved! Update age status to coppaLimited
      state = AgeStatus(
        tier: AgeTier.coppaLimited,
        isVerified: true,
        dateOfBirth: null, // do not store child birthdate PII
      );
      
      // Update local prefs
      await _prefs?.setInt(_tierKey, AgeTier.coppaLimited.index);
      await _prefs?.setBool(_verifiedKey, true);
      await _prefs?.remove('blocked_under_13'); // Clear local blocked flag
      
      // Sync to private Firestore
      await FirebaseFirestore.instance.collection('users_private').doc(_uid).set({
        'ageTier': AgeTier.coppaLimited.index,
        'ageVerified': true,
        'coppaConsentConfirmed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return true;
    }
    return false;
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  bool canAccessSocialFeatures() => 
      state.tier == AgeTier.junior || 
      state.tier == AgeTier.teen || 
      state.tier == AgeTier.adult;

  bool canAccessAdultContent() => state.tier == AgeTier.adult;

  String getInaccessibilityMessage() {
    if (state.tier == AgeTier.under13Blocked) {
      return 'GOTCHAA is not available for users under 13. We care about keeping young people safe online.';
    }
    if (state.tier == AgeTier.coppaLimited) {
      return 'Under 13 accounts with parental consent have extremely limited features.';
    }
    return 'This content is restricted based on your age.';
  }
}
