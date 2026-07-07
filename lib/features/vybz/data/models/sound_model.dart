// lib/features/vybz/data/models/sound_model.dart
//
// Data model matching the Firestore `sounds` collection schema.

class SoundModel {
  SoundModel({
    required this.soundId,
    required this.creatorId,
    required this.prompt,
    required this.model,
    required this.storagePath,
    required this.durationSec,
    this.lyrics,
    required this.usageCount,
    required this.createdAt,
    required this.visibility,
    this.playbackUrl,
  });

  factory SoundModel.fromJson(Map<String, dynamic> json) => SoundModel(
        soundId: json['soundId'] as String? ?? '',
        creatorId: json['creatorId'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        model: json['model'] as String? ?? 'lyria-3-clip',
        storagePath: json['storagePath'] as String? ?? '',
        durationSec: (json['durationSec'] as num?)?.toInt() ?? 30,
        lyrics: json['lyrics'] as String?,
        usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        visibility: json['visibility'] as String? ?? 'public',
        playbackUrl: json['playbackUrl'] as String?,
      );

  final String soundId;
  final String creatorId;
  final String prompt;
  final String model;
  final String storagePath;
  final int durationSec;
  final String? lyrics;
  final int usageCount;
  final DateTime createdAt;
  final String visibility;

  /// Signed playback URL, present only when returned from the backend.
  /// Never expose storagePath to the client.
  final String? playbackUrl;

  Map<String, dynamic> toJson() => {
        'soundId': soundId,
        'creatorId': creatorId,
        'prompt': prompt,
        'model': model,
        'durationSec': durationSec,
        'usageCount': usageCount,
        'createdAt': createdAt.toIso8601String(),
        'visibility': visibility,
        if (lyrics != null) 'lyrics': lyrics,
        if (playbackUrl != null) 'playbackUrl': playbackUrl,
        // NOTE: storagePath is intentionally omitted — never send raw GCS path to client
      };
}
