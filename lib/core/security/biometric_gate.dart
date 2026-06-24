import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricGate {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate({required String reason}) async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }
}
