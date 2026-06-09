import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:gotchaa/core/constants/app_constants.dart';
import 'package:gotchaa/core/logging/app_logger.dart';

/// Records and verifies legal policy acceptance in `users_private`.
class LegalAcceptanceService {
  LegalAcceptanceService._();

  static final _functions = FirebaseFunctions.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Server-side check on login — returns whether user must re-accept policies.
  static Future<PolicyCheckResult> checkPolicyOnLogin() async {
    try {
      final callable = _functions.httpsCallable('checkPolicyOnLogin');
      final result = await callable.call<Map<String, dynamic>>();
      final data = Map<String, dynamic>.from(result.data as Map);
      return PolicyCheckResult(
        requiresReacceptance: data['requiresReacceptance'] as bool? ?? false,
        requiredPrivacyVersion: data['requiredPrivacyVersion'] as String? ?? LegalConfig.privacyVersion,
        requiredTermsVersion: data['requiredTermsVersion'] as String? ?? LegalConfig.termsVersion,
        acceptedPrivacyVersion: data['acceptedPrivacyVersion'] as String?,
        acceptedTermsVersion: data['acceptedTermsVersion'] as String?,
      );
    } catch (e) {
      AppLogger.e('LegalAcceptanceService: checkPolicyOnLogin failed', e);
      return PolicyCheckResult.fallbackRequiresCheck();
    }
  }

  /// Records acceptance with server-captured IP in users_private.
  static Future<void> recordAcceptance({required String uid}) async {
    try {
      final callable = _functions.httpsCallable('recordLegalAcceptance');
      await callable.call<Map<String, dynamic>>({
        'privacyPolicyVersion': LegalConfig.privacyVersion,
        'termsVersion': LegalConfig.termsVersion,
      });
    } catch (e) {
      AppLogger.e('LegalAcceptanceService: recordLegalAcceptance failed, using Firestore fallback', e);
      await _firestore.collection('users_private').doc(uid).set({
        'privacyPolicyVersion': LegalConfig.privacyVersion,
        'termsVersion': LegalConfig.termsVersion,
        'acceptedAt': FieldValue.serverTimestamp(),
        'ipAddressAtAcceptance': 'client_fallback',
      }, SetOptions(merge: true));
    }
  }
}

class PolicyCheckResult {
  const PolicyCheckResult({
    required this.requiresReacceptance,
    required this.requiredPrivacyVersion,
    required this.requiredTermsVersion,
    this.acceptedPrivacyVersion,
    this.acceptedTermsVersion,
  });

  final bool requiresReacceptance;
  final String requiredPrivacyVersion;
  final String requiredTermsVersion;
  final String? acceptedPrivacyVersion;
  final String? acceptedTermsVersion;

  factory PolicyCheckResult.fallbackRequiresCheck() => const PolicyCheckResult(
        requiresReacceptance: true,
        requiredPrivacyVersion: LegalConfig.privacyVersion,
        requiredTermsVersion: LegalConfig.termsVersion,
      );
}
