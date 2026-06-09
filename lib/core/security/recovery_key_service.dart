import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RecoveryKeyService {
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _ed25519 = Ed25519();

  static const String _kMnemonic = 'e2ee_mnemonic';
  static const String _kIdentityPrivateKey = 'id_priv_';

  /// 1. Generate new 12-word mnemonic
  Future<String> generateMnemonic() async {
    final mnemonic = bip39.generateMnemonic();
    return mnemonic;
  }

  /// 2. Derive Identity Key from Mnemonic
  Future<KeyPair> deriveIdentityKey(String mnemonic, String uid) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    // Use the first 32 bytes of the seed as the private key for Ed25519
    final privKeyBytes = seed.sublist(0, 32);

    final keyPair = await _ed25519.newKeyPairFromSeed(privKeyBytes);

    // Persist mnemonic and private key locally
    await _secureStorage.write(key: _kMnemonic, value: mnemonic);
    await _secureStorage.write(
        key: '$_kIdentityPrivateKey$uid', value: base64Encode(privKeyBytes));

    return keyPair;
  }

  /// 3. Verify Mnemonic matches current key
  Future<bool> verifyMnemonic(String mnemonic, String uid) async {
    final currentPriv =
        await _secureStorage.read(key: '$_kIdentityPrivateKey$uid');
    // Fail-safe: no stored key means we cannot verify. Do NOT trust any mnemonic.
    if (currentPriv == null) return false;

    final seed = bip39.mnemonicToSeed(mnemonic);
    final derivedPrivBytes = seed.sublist(0, 32);

    // Constant-time comparison via HMAC to prevent timing side-channel attacks.
    final hmac = Hmac.sha256();
    final keyA = SecretKey(base64Decode(currentPriv));
    final keyB = SecretKey(derivedPrivBytes);
    final macA = await hmac.calculateMac([0x01], secretKey: keyA);
    final macB = await hmac.calculateMac([0x01], secretKey: keyB);
    return macA.bytes.toString() == macB.bytes.toString();
  }
}
