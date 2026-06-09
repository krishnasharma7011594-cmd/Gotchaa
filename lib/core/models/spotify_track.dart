class SpotifyTrack { // The 30-second premium-free clip

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.albumArtUrl,
    this.previewUrl,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) => SpotifyTrack(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Track',
      artist: (json['artists'] as List?)?.first['name'] ?? 'Unknown Artist',
      albumArtUrl: json['album']?['images']?[0]?['url'] ?? '',
      previewUrl: json['preview_url'],
    );
  final String id;
  final String name;
  final String artist;
  final String albumArtUrl;
  final String? previewUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artist': artist,
    'albumArtUrl': albumArtUrl,
    'previewUrl': previewUrl,
  };
}
