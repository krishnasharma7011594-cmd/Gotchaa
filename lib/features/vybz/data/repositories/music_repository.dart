// lib/features/vybz/data/repositories/music_repository.dart
//
// Calls Firebase Cloud Functions — no Railway/Express needed.
// The four callable functions are: generateSound, listSoundLibrary,
// getSoundPlaybackUrl, attachSoundToPost.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sound_model.dart';

class MusicRepository {
  MusicRepository(this._functions);

  final FirebaseFunctions _functions;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Wraps a [FirebaseFunctionsException] into a friendlier message.
  Exception _wrap(Object e) {
    if (e is FirebaseFunctionsException) {
      return Exception(e.message ?? e.code);
    }
    return Exception(e.toString());
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Generates an AI music clip from [prompt] and returns the [SoundModel].
  Future<SoundModel> generateSound(String prompt) async {
    if (prompt.isEmpty || prompt.length > 300) {
      throw ArgumentError('Prompt must be 1–300 characters');
    }
    try {
      final result = await _functions
          .httpsCallable('generateSound')
          .call<Map<Object?, Object?>>({'prompt': prompt});

      return SoundModel.fromJson(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      throw _wrap(e);
    }
  }

  /// Returns a paginated list of public sounds from the library.
  Future<List<SoundModel>> listLibrary({
    String sort = 'recent',
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('listSoundLibrary')
          .call<List<Object?>>({
        'sort': sort,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      });

      return (result.data)
          .map((e) => SoundModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw _wrap(e);
    }
  }

  /// Fetches a fresh signed playback URL for [soundId].
  Future<String> getPlaybackUrl(String soundId) async {
    try {
      final result = await _functions
          .httpsCallable('getSoundPlaybackUrl')
          .call<Map<Object?, Object?>>({'soundId': soundId});

      return result.data['url'] as String;
    } catch (e) {
      throw _wrap(e);
    }
  }

  /// Attaches [soundId] to [postId], incrementing the sound's usageCount.
  Future<void> attachSoundToPost(String soundId, String postId) async {
    try {
      await _functions
          .httpsCallable('attachSoundToPost')
          .call({'soundId': soundId, 'postId': postId});
    } catch (e) {
      throw _wrap(e);
    }
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  return MusicRepository(FirebaseFunctions.instance);
});
