// lib/features/vybz/data/repositories/music_repository.dart
//
// Talks to the four Express /music endpoints.
// All methods return typed results — no raw JSON or GCS paths leak out.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/app_config.dart';
import '../models/sound_model.dart';

class MusicRepository {
  MusicRepository(this._dio);

  final Dio _dio;

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<Options> _authOptions() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('User not authenticated');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// POST /music/generate
  /// Sends the prompt and returns the generated [SoundModel] including a
  /// signed playback URL. Never returns a raw storagePath.
  Future<SoundModel> generateSound(String prompt) async {
    if (prompt.isEmpty || prompt.length > 300) {
      throw ArgumentError('Prompt must be 1–300 characters');
    }
    final opts = await _authOptions();
    final resp = await _dio.post(
      '/music/generate',
      data: {'prompt': prompt},
      options: opts,
    );
    return SoundModel.fromJson(resp.data as Map<String, dynamic>);
  }

  /// GET /music/library?sort=trending|recent&cursor=&limit=
  Future<List<SoundModel>> listLibrary({
    String sort = 'recent',
    String? cursor,
    int limit = 20,
  }) async {
    final opts = await _authOptions();
    final resp = await _dio.get(
      '/music/library',
      queryParameters: {
        'sort': sort,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
      options: opts,
    );
    final data = resp.data as List<dynamic>;
    return data
        .map((e) => SoundModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /music/:soundId/playback-url
  /// Returns a signed URL string — no raw storage path exposed.
  Future<String> getPlaybackUrl(String soundId) async {
    final opts = await _authOptions();
    final resp = await _dio.get(
      '/music/$soundId/playback-url',
      options: opts,
    );
    return (resp.data as Map<String, dynamic>)['url'] as String;
  }

  /// POST /music/:soundId/attach
  Future<void> attachSoundToPost(String soundId, String postId) async {
    final opts = await _authOptions();
    await _dio.post(
      '/music/$soundId/attach',
      data: {'postId': postId},
      options: opts,
    );
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.instance.backendUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));
  return MusicRepository(dio);
});
