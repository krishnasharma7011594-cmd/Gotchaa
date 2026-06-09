import 'package:cloud_functions/cloud_functions.dart';
import 'package:otp/otp.dart';

/// Verifies TOTP for sensitive actions via Cloud Function + local fallback.
class TwoFactorService {
  TwoFactorService._();
  static final TwoFactorService instance = TwoFactorService._();

  Future<bool> verifyCode(String code, {String? localSecret}) async {
    final trimmed = code.trim().replaceAll(' ', '');
    if (trimmed.length == 6 && localSecret != null && localSecret.isNotEmpty) {
      final expected = OTP.generateTOTPCodeString(
        localSecret,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (trimmed == expected) return true;
    }
    try {
      final res =
          await FirebaseFunctions.instance.httpsCallable('verify2FA').call({
        'code': trimmed,
      });
      final data = res.data as Map?;
      return data?['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requireVerification({
    required Future<String?> Function() promptForCode,
    String? localSecret,
  }) async {
    final code = await promptForCode();
    if (code == null || code.isEmpty) return false;
    return verifyCode(code, localSecret: localSecret);
  }
}
