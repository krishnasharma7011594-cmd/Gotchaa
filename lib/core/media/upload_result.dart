/// Result of a media upload including optional thumbnail URL.
class MediaUploadResult {
  const MediaUploadResult({
    required this.url,
    this.thumbnailUrl,
  });

  final String url;
  final String? thumbnailUrl;
}

typedef UploadProgressCallback = void Function(double progress);
