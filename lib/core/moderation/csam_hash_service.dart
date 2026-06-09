import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../logging/app_logger.dart';

/// Perceptual hash (dHash) check — PhotoDNA-compatible *approach*.
/// Production CSAM lists are provided via law enforcement / NCMEC partnerships.
class CsamHashService {
  CsamHashService._();
  static final CsamHashService instance = CsamHashService._();

  /// Known-bad perceptual hashes (hex). Populated via Remote Config / server updates.
  static final Set<String> _knownHashes = {};

  static void registerKnownHashes(Iterable<String> hashes) {
    _knownHashes.addAll(hashes.map((h) => h.toLowerCase()));
  }

  Future<CsamCheckResult> checkImageBytes(Uint8List bytes,
      {required String userId}) async {
    try {
      final hash = _computeDHash(bytes);
      if (hash == null) return const CsamCheckResult.safe();

      for (final known in _knownHashes) {
        if (_hammingDistance(hash, known) <= 5) {
          await _triggerIncident(userId: userId, hash: hash);
          return CsamCheckResult.blocked(hash: hash);
        }
      }
      return CsamCheckResult.safe(hash: hash);
    } catch (e) {
      AppLogger.e('CsamHashService check failed', e);
      return const CsamCheckResult.safe();
    }
  }

  Future<void> _triggerIncident(
      {required String userId, required String hash}) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('handleCsamIncident')
          .call({
        'userId': userId,
        'perceptualHash': hash,
        'detectedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.e('CsamHashService incident CF failed', e);
    }
  }

  String? _computeDHash(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final resized = img.copyResize(decoded, width: 9, height: 8);
    final buffer = StringBuffer();
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final left = resized.getPixel(x, y);
        final right = resized.getPixel(x + 1, y);
        final l = left.r + left.g + left.b;
        final r = right.r + right.g + right.b;
        buffer.write(l > r ? '1' : '0');
      }
    }
    final bits = buffer.toString();
    final hex = StringBuffer();
    for (var i = 0; i < bits.length; i += 4) {
      final nibble = bits.substring(i, i + 4);
      hex.write(int.parse(nibble, radix: 2).toRadixString(16));
    }
    return hex.toString();
  }

  int _hammingDistance(String a, String b) {
    if (a.length != b.length) return 99;
    var d = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) d++;
    }
    return d;
  }
}

class CsamCheckResult {
  const CsamCheckResult({required this.isBlocked, this.hash});
  const CsamCheckResult.safe({this.hash}) : isBlocked = false;
  CsamCheckResult.blocked({required this.hash}) : isBlocked = true;

  final bool isBlocked;
  final String? hash;
}
