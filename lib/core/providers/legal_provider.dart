import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/user_profile.dart';
import '../services/legal_acceptance_service.dart';
import 'auth_providers.dart';
import 'profile_providers.dart';
import 'shared_prefs_provider.dart';

/// Whether user has accepted current Privacy Policy + Terms versions.
final legalAcceptedProvider = StateNotifierProvider<LegalNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final profile = ref.watch(currentUserProfileProvider).asData?.value;
  return LegalNotifier(ref, prefs, profile);
});

/// True when server or local state indicates policies need re-acceptance.
final legalReacceptanceRequiredProvider = StateProvider<bool>((ref) => false);

class LegalNotifier extends StateNotifier<bool> {
  LegalNotifier(this._ref, this._prefs, UserProfile? profile) : super(false) {
    _init(profile);
  }

  final Ref _ref;
  final SharedPreferences? _prefs;

  void _init(UserProfile? profile) {
    if (_prefs == null) return;

    final acceptedTermsLocal =
        _prefs.getString(StorageKeys.termsAcceptedVersion);
    final acceptedPrivacyLocal =
        _prefs.getString(StorageKeys.privacyAcceptedVersion);
    final acceptedTermsCloud = profile?.termsAcceptedVersion;
    final acceptedPrivacyCloud = profile?.privacyAcceptedVersion;

    final isLocalAccepted = acceptedTermsLocal == LegalConfig.termsVersion &&
        acceptedPrivacyLocal == LegalConfig.privacyVersion;
    final isCloudAccepted = acceptedTermsCloud == LegalConfig.termsVersion &&
        acceptedPrivacyCloud == LegalConfig.privacyVersion;

    if (isLocalAccepted || isCloudAccepted) {
      state = true;
      if (isCloudAccepted && !isLocalAccepted) {
        _prefs.setString(
            StorageKeys.termsAcceptedVersion, LegalConfig.termsVersion);
        _prefs.setString(
            StorageKeys.privacyAcceptedVersion, LegalConfig.privacyVersion);
        _prefs.setString(StorageKeys.legalAcceptedTimestamp,
            DateTime.now().toIso8601String());
      }
    } else {
      state = false;
      _ref.read(legalReacceptanceRequiredProvider.notifier).state = true;
    }
  }

  /// Called after login to sync with Cloud Function policy check.
  Future<void> syncPolicyCheckFromServer() async {
    final user = _ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    final result = await LegalAcceptanceService.checkPolicyOnLogin();
    if (result.requiresReacceptance) {
      state = false;
      _ref.read(legalReacceptanceRequiredProvider.notifier).state = true;
    } else if (_prefs != null) {
      final localOk = _prefs.getString(StorageKeys.termsAcceptedVersion) ==
              LegalConfig.termsVersion &&
          _prefs.getString(StorageKeys.privacyAcceptedVersion) ==
              LegalConfig.privacyVersion;
      state = localOk;
    }
  }

  Future<void> acceptLegal() async {
    if (_prefs == null) return;

    final now = DateTime.now();

    await _prefs.setString(
        StorageKeys.termsAcceptedVersion, LegalConfig.termsVersion);
    await _prefs.setString(
        StorageKeys.privacyAcceptedVersion, LegalConfig.privacyVersion);
    await _prefs.setString(
        StorageKeys.legalAcceptedTimestamp, now.toIso8601String());

    final user = _ref.read(authStateProvider).asData?.value;
    if (user != null) {
      await LegalAcceptanceService.recordAcceptance(uid: user.uid);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'termsAcceptedVersion': LegalConfig.termsVersion,
          'privacyAcceptedVersion': LegalConfig.privacyVersion,
          'legalAcceptedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    _ref.read(legalReacceptanceRequiredProvider.notifier).state = false;
    state = true;
  }

  void reset() {
    state = false;
    _ref.read(legalReacceptanceRequiredProvider.notifier).state = true;
  }
}
