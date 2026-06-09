import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class MediaEncryptionResult {

  MediaEncryptionResult({required this.remoteUrl, required this.encryptedKey, required this.nonce});
  final String remoteUrl;
  final String encryptedKey; // Base64
  final String nonce;
}

class EncryptedMediaService {
  final _aesGcm = AesGcm.with256bits();
  final _storage = FirebaseStorage.instance;

  /// 1. Encrypt and Upload File
  Future<MediaEncryptionResult> encryptAndUpload(File file, String storagePath) async {
    // A. Generate random 256-bit AES-GCM key
    final secretKey = await _aesGcm.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    
    // B. Encrypt file bytes
    final bytes = await file.readAsBytes();
    final nonce = _aesGcm.newNonce();
    final box = await _aesGcm.encrypt(
      bytes,
      secretKey: secretKey,
      nonce: nonce,
    );
    
    final encryptedPayload = Uint8List.fromList(box.cipherText + box.mac.bytes);

    // C. Upload to Firebase Storage
    final ref = _storage.ref().child(storagePath);
    final uploadTask = await ref.putData(
      encryptedPayload,
      SettableMetadata(contentType: 'application/octet-stream'),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return MediaEncryptionResult(
      remoteUrl: downloadUrl,
      encryptedKey: base64Encode(keyBytes),
      nonce: base64Encode(nonce),
    );
  }

  /// 2. Download and Decrypt File
  Future<File> downloadAndDecrypt(String url, String keyBase64, String nonceBase64, String fileName) async {
    final ref = _storage.refFromURL(url);
    final data = await ref.getData();
    if (data == null) throw Exception('Failed to download media');

    final keyBytes = base64Decode(keyBase64);
    final nonceBytes = base64Decode(nonceBase64);
    
    // AES-GCM tags are the last 16 bytes
    final mac = Mac(data.sublist(data.length - 16));
    final ciphertext = data.sublist(0, data.length - 16);
    
    final clearText = await _aesGcm.decrypt(
      SecretBox(ciphertext, nonce: nonceBytes, mac: mac),
      secretKey: SecretKey(keyBytes),
    );

    // Save to local temp file
    final tempDir = await getTemporaryDirectory();
    final localFile = File('${tempDir.path}/$fileName');
    await localFile.writeAsBytes(clearText);
    
    return localFile;
  }
}
