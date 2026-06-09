import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final e2eeServiceProvider = Provider<E2EEService>((ref) => E2EEService());

// ---------------------------------------------------------------------------
// E2EE Service (Version 2 — True E2EE via ECDH)
// ---------------------------------------------------------------------------

class E2EEService {
  static final E2EEService _instance = E2EEService._internal();
  factory E2EEService() => _instance;
  E2EEService._internal();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final _aesGcm = AesGcm.with256bits();
  final _x25519 = X25519();
  final Map<String, SecretKey> _keyCache = {};

  // ---------------------------------------------------------------------------
  // 1. Key Generation (Per User)
  // ---------------------------------------------------------------------------

  Future<String> generateAndStoreIdentityKeyPair(String uid) async {
    final keyPair = await _x25519.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    await _secureStorage.write(
      key: 'x25519_private_key_$uid',
      value: base64Encode(privateKeyBytes),
    );

    return base64Encode(publicKey.bytes);
  }

  // ---------------------------------------------------------------------------
  // 2. Shared Secret Generation (Per Conversation)
  // ---------------------------------------------------------------------------

  Future<SecretKey> getOrCreateChatKey(String chatId, String otherUserId) async {
    // Guard: do not attempt key derivation if either ID is missing.
    if (chatId.isEmpty || otherUserId.isEmpty) {
      throw Exception('getOrCreateChatKey: chatId or otherUserId is empty');
    }

    if (_keyCache.containsKey(chatId)) {
      return _keyCache[chatId]!;
    }

    final storageKey = 'v2_shared_secret_$chatId';
    final stored = await _secureStorage.read(key: storageKey);
    if (stored != null) {
      final key = SecretKey(base64Decode(stored));
      _keyCache[chatId] = key;
      return key;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('No user logged in');
    final myUid = currentUser.uid;

    final myPrivKeyBase64 =
        await _secureStorage.read(key: 'x25519_private_key_$myUid');
    if (myPrivKeyBase64 == null) {
      throw Exception('Private key not found. Call generateAndStoreIdentityKeyPair first.');
    }

    final myPrivKeyBytes = base64Decode(myPrivKeyBase64);
    final myKeyPair = await _x25519.newKeyPairFromSeed(myPrivKeyBytes);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .get()
        .timeout(const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timed out fetching recipient public key'));
    if (!doc.exists) throw Exception('User not found: $otherUserId');

    final otherPubKeyBase64 = doc.data()?['identityPublicKey'] as String?;
    if (otherPubKeyBase64 == null) {
      throw Exception('Recipient has not set up E2EE yet. Ask them to open the app.');
    }

    final otherPubKeyBytes = base64Decode(otherPubKeyBase64);
    final otherPubKey =
        SimplePublicKey(otherPubKeyBytes, type: KeyPairType.x25519);

    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: otherPubKey,
    );

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final finalKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode('gotchaa_chat_v2_$chatId'),
    );

    final finalKeyBytes = await finalKey.extractBytes();
    await _secureStorage.write(
        key: storageKey, value: base64Encode(finalKeyBytes));
    _keyCache[chatId] = finalKey;

    return finalKey;
  }

  // ---------------------------------------------------------------------------
  // 3. Encrypt / Decrypt
  // ---------------------------------------------------------------------------

  Future<String> encrypt(String plaintext, SecretKey key) async {
    try {
      final nonce = _aesGcm.newNonce();
      final secretBox = await _aesGcm.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
        nonce: nonce,
      );
      final combined = Uint8List.fromList(
        nonce + secretBox.cipherText + secretBox.mac.bytes,
      );
      return base64Encode(combined);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> decrypt(String encryptedBase64, SecretKey key) async {
    try {
      final data = _tryBase64Decode(encryptedBase64);
      if (data == null || data.length < 28) return encryptedBase64;

      final nonce = data.sublist(0, 12);
      final macBytes = data.sublist(data.length - 16);
      final cipherText = data.sublist(12, data.length - 16);

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
      final clearBytes = await _aesGcm.decrypt(secretBox, secretKey: key);
      return utf8.decode(clearBytes);
    } catch (_) {
      return encryptedBase64;
    }
  }

  Future<String> encryptForChat(String plaintext, String chatId, String otherUserId) async {
    try {
      final key = await getOrCreateChatKey(chatId, otherUserId);
      final nonce = _aesGcm.newNonce();
      final secretBox = await _aesGcm.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
        nonce: nonce,
      );
      final combined = Uint8List.fromList(
        nonce + secretBox.cipherText + secretBox.mac.bytes,
      );
      return base64Encode(combined);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> decryptForChat(String encryptedBase64, String chatId, String otherUserId) async {
    try {
      final key = await getOrCreateChatKey(chatId, otherUserId);
      final data = _tryBase64Decode(encryptedBase64);
      if (data == null || data.length < 28) return encryptedBase64;

      final nonce = data.sublist(0, 12);
      final macBytes = data.sublist(data.length - 16);
      final cipherText = data.sublist(12, data.length - 16);

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
      final clearBytes = await _aesGcm.decrypt(secretBox, secretKey: key);
      return utf8.decode(clearBytes);
    } on SecretBoxAuthenticationError {
      // ⚠️ Message Integrity Check (Task 3)
      return '⚠️ Message may have been tampered with';
    } catch (_) {
      return encryptedBase64;
    }
  }

  Future<Uint8List> encryptFile(Uint8List fileBytes, String chatId, String otherUserId) async {
    final key = await getOrCreateChatKey(chatId, otherUserId);
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(fileBytes, secretKey: key, nonce: nonce);
    return Uint8List.fromList(nonce + secretBox.cipherText + secretBox.mac.bytes);
  }

  Future<Uint8List> decryptFile(Uint8List encryptedBytes, String chatId, String otherUserId) async {
    final key = await getOrCreateChatKey(chatId, otherUserId);
    final nonce = encryptedBytes.sublist(0, 12);
    final macBytes = encryptedBytes.sublist(encryptedBytes.length - 16);
    final cipherText = encryptedBytes.sublist(12, encryptedBytes.length - 16);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
    final clearBytes = await _aesGcm.decrypt(secretBox, secretKey: key);
    return Uint8List.fromList(clearBytes);
  }

  // ---------------------------------------------------------------------------
  // 4. Session lifecycle & Key Management
  // ---------------------------------------------------------------------------

  void clearMemoryCache() {
    _keyCache.clear();
  }

  // Task 4: Key Rotation
  Future<void> rotateKeys() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('No user logged in');
    
    // Generate new key pair on new device or manual rotation
    final newPubKeyBase64 = await generateAndStoreIdentityKeyPair(currentUser.uid);
    
    // Update public key in Firestore
    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
      'identityPublicKey': newPubKeyBase64,
      'keyRotationDate': FieldValue.serverTimestamp(),
    });
    
    clearMemoryCache();
  }

  // Task 6: Key Backup & Restore
  Future<String> exportKeyBackup(String passphrase) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('No user logged in');
    
    final privKeyBase64 = await _secureStorage.read(key: 'x25519_private_key_${currentUser.uid}');
    if (privKeyBase64 == null) throw Exception('No private key to backup');
    
    final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 100000, bits: 256);
    final salt = _aesGcm.newNonce(); 
    final derivedKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(privKeyBase64),
      secretKey: derivedKey,
      nonce: nonce,
    );
    
    final combined = Uint8List.fromList(salt + nonce + secretBox.cipherText + secretBox.mac.bytes);
    return base64Encode(combined);
  }

  Future<void> importKeyBackup(String backupBase64, String passphrase) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('No user logged in');
    
    final data = base64Decode(backupBase64);
    if (data.length < 12 + 12 + 16) throw Exception('Invalid backup format');
    
    final salt = data.sublist(0, 12);
    final nonce = data.sublist(12, 24);
    final macBytes = data.sublist(data.length - 16);
    final cipherText = data.sublist(24, data.length - 16);
    
    final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 100000, bits: 256);
    final derivedKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
    final clearBytes = await _aesGcm.decrypt(secretBox, secretKey: derivedKey);
    final privKeyBase64 = utf8.decode(clearBytes);
    
    await _secureStorage.write(
      key: 'x25519_private_key_${currentUser.uid}',
      value: privKeyBase64,
    );
    
    clearMemoryCache();
  }

  Future<void> cleanupOrphanedKeys(List<String> activeChatIds) async {
    try {
      final all = await _secureStorage.readAll();
      final activeKeys = activeChatIds.map((id) => 'v2_shared_secret_$id').toSet();
      
      for (final k in all.keys) {
        if (k.startsWith('v2_shared_secret_') && !activeKeys.contains(k)) {
          await _secureStorage.delete(key: k);
        }
      }
    } catch (_) {}
  }

  Future<void> clearAllSessionData() async {
    try {
      final keys = await _secureStorage.readAll();
      for (final key in keys.keys) {
        if (key.startsWith('shared_secret_') || 
            key.startsWith('v2_shared_secret_') ||
            key.startsWith('chat_key_') ||
            key.startsWith('x25519_private_key_')) {
          await _secureStorage.delete(key: key);
        }
      }
      _keyCache.clear();
    } catch (_) {}
  }

  // Task 5: Safety Number Verification
  Future<String> calculateSafetyNumber(String chatId, String otherUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('No user logged in');
    final myUid = currentUser.uid;

    final myPrivKeyBase64 = await _secureStorage.read(key: 'x25519_private_key_$myUid');
    if (myPrivKeyBase64 == null) throw Exception('Private key not found for current user');
    final myPrivKeyBytes = base64Decode(myPrivKeyBase64);
    final myKeyPair = await _x25519.newKeyPairFromSeed(myPrivKeyBytes);
    final myPubKey = await myKeyPair.extractPublicKey();

    final doc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
    if (!doc.exists) throw Exception('User not found');
    final otherPubKeyBase64 = doc.data()?['identityPublicKey'] as String?;
    if (otherPubKeyBase64 == null) throw Exception('Other user does not have a public key');
    final otherPubKeyBytes = base64Decode(otherPubKeyBase64);

    final combinedKeys = [
      ...myPubKey.bytes,
      ...otherPubKeyBytes,
    ]..sort();

    // SHA-256 for standard fingerprinting
    final sink = Sha256().newHashSink();
    sink.add(combinedKeys);
    sink.close();

    final hash = await sink.hash();
    final hexHash = hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
    
    // First 40 chars of the SHA-256 hex
    final clean = hexHash.substring(0, 40);
    final groups = <String>[];
    for (int i = 0; i < clean.length; i += 5) {
      groups.add(clean.substring(i, i + 5));
    }
    return groups.join("  ");
  }

  Future<void> deleteUserData(String uid) async {
    await clearAllSessionData();
  }

  // ---------------------------------------------------------------------------
  // 5. Forward Secrecy Foundation (Task 8 - Double Ratchet)
  // ---------------------------------------------------------------------------
  // Fully comments how this lays groundwork for the Signal Protocol Double Ratchet
  // to provide Perfect Forward Secrecy (PFS).

  /// Creates the initial ratchet state for a new conversation.
  /// Foundation of the Signal Protocol Double Ratchet algorithm.
  /// Full Double Ratchet provides Perfect Forward Secrecy (PFS) —
  /// even if one key is compromised, past/future messages stay secure.
  Future<RatchetState> createInitialRatchetState(
    SecretKey sharedSecret,
  ) async {
    return RatchetState(
      rootKey: sharedSecret,
      chainKey: sharedSecret,
      messageKeys: {},
      messageNumber: 0,
    );
  }

  /// Perform a symmetric-key ratchet step (Signal Protocol / Double Ratchet).
  /// Derives a unique Message Key per message and advances the Chain Key.
  /// Compromising one message key does NOT compromise past or future keys — PFS.
  Future<RatchetState> ratchetStep(RatchetState state) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

    // Derive Message Key (KDF input constant = 0x01)
    final messageKey = await hkdf.deriveKey(
      secretKey: state.chainKey,
      nonce: [0x01],
    );

    // Derive next Chain Key (KDF input constant = 0x02) — advances the ratchet
    final nextChainKey = await hkdf.deriveKey(
      secretKey: state.chainKey,
      nonce: [0x02],
    );

    // Cache this message key for out-of-order decryption support
    state.messageKeys[state.messageNumber] = messageKey;

    return RatchetState(
      rootKey: state.rootKey,
      chainKey: nextChainKey,
      messageKeys: state.messageKeys,
      messageNumber: state.messageNumber + 1,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Uint8List? _tryBase64Decode(String input) {
    final s = input.trim();
    try {
      return base64Decode(base64.normalize(s));
    } catch (_) {}
    try {
      return base64Url.decode(base64Url.normalize(s));
    } catch (_) {}
    return null;
  }
}

class RatchetState {
  final SecretKey rootKey;
  final SecretKey chainKey;
  final Map<int, SecretKey> messageKeys;
  final int messageNumber;

  RatchetState({
    required this.rootKey,
    required this.chainKey,
    required this.messageKeys,
    this.messageNumber = 0,
  });
}
