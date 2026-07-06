import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum MediaUploadKind { profile, post, story, thumbnail, chat }

class CompressedMedia {
  const CompressedMedia({
    required this.fullBytes,
    this.thumbnailBytes,
  });

  final Uint8List fullBytes;
  final Uint8List? thumbnailBytes;
}

/// Resizes and compresses images; video compression is handled server-side
/// by the `compressUploadedVideo` Cloud Function (FFmpeg).
class MediaCompressionService {
  MediaCompressionService._();
  static final MediaCompressionService instance = MediaCompressionService._();

  Future<CompressedMedia> compressImageBytes(
    Uint8List input, {
    required MediaUploadKind kind,
  }) async {
    final decoded = img.decodeImage(input);
    if (decoded == null) {
      return CompressedMedia(fullBytes: input);
    }

    final (maxW, maxH, quality) = switch (kind) {
      MediaUploadKind.profile => (500, 500, 80),
      MediaUploadKind.post => (1080, 1080, 85),
      MediaUploadKind.story => (1080, 1920, 85),
      MediaUploadKind.chat => (1080, 1080, 85),
      MediaUploadKind.thumbnail => (200, 200, 60),
    };

    final resized = img.copyResize(
      decoded,
      width: decoded.width > maxW ? maxW : null,
      height: decoded.height > maxH ? maxH : null,
      maintainAspect: true,
    );

    final fullBytes =
        Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    Uint8List? thumbBytes;
    if (kind != MediaUploadKind.thumbnail && kind != MediaUploadKind.profile) {
      final thumb = img.copyResize(decoded,
          width: 200, height: 200, maintainAspect: true);
      thumbBytes = Uint8List.fromList(img.encodeJpg(thumb, quality: 60));
    }

    return CompressedMedia(fullBytes: fullBytes, thumbnailBytes: thumbBytes);
  }

  /// Video compression is done server-side by the Cloud Function.
  /// Returns null so callers fall back to uploading the original file directly.
  Future<String?> compressVideoPath(String path) async {
    return null;
  }
}

