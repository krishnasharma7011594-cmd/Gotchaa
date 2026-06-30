import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:just_audio/just_audio.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../config/app_config.dart';
import '../../../core/config/app_config.dart' as secure_config;
import '../../../core/services/audio_focus_manager.dart';
import '../domain/models/bro_message.dart';
import '../domain/models/bro_response.dart';
import '../presentation/providers/bro_providers.dart';

class BroOrchestrator {

  BroOrchestrator(this._ref) {
    _initFallback();
    _setupAudioPlayerListeners();
  }
  final Ref _ref;
  final String _baseUrl = AppConfig.instance.backendUrl;

  late final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _localAuth = LocalAuthentication();
  final _uuid = const Uuid();

  GenerativeModel? _geminiFallback;

  void _setupAudioPlayerListeners() {
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed || state == ProcessingState.idle) {
        _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_output');
      }
    });
  }

  void _initFallback() {
    const apiKey = secure_config.AppConfig.geminiApiKey;
    if (apiKey.isNotEmpty) {
      _geminiFallback = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );
    }
  }

  // ── Voice Lifecycle ────────────────────────────────────────────────────────

  Future<void> startListening() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _ref
            .read(audioFocusManagerProvider)
            .requestAudioFocus('bro_input', AudioRequester.broInput);

        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/bro_input_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
      }
    } catch (e) {
      print('BRO Listening Error: $e');
      await _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_input');
    }
  }

  Future<BroResponse> stopListeningAndProcess() async {
    try {
      final path = await _audioRecorder.stop();
      await _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_input');

      if (path == null) return BroResponse.failed('No audio detected');
      return await _processVoiceInput(File(path));
    } catch (e) {
      return BroResponse.failed('Failed to stop recording: $e');
    }
  }

  // ── Processing ─────────────────────────────────────────────────────────────

  Future<BroResponse> _processVoiceInput(File audioFile) async {
    final startTime = DateTime.now();
    _ref.read(broLoadingProvider.notifier).state = true;

    try {
      final formData = FormData.fromMap({
        'audio':
            await MultipartFile.fromFile(audioFile.path, filename: 'input.m4a'),
      });

      final response = await _dio.post('/bro/voice-chat', data: formData);
      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      final broResponse = _parseFastApiResponse(response.data, executionTime);

      if (broResponse.data != null && broResponse.data['audio_url'] != null) {
        await _ref
            .read(audioFocusManagerProvider)
            .requestAudioFocus('bro_output', AudioRequester.broOutput);
        await _audioPlayer.setUrl(broResponse.data['audio_url']);
        _audioPlayer.play();
      }

      await _handlePostProcessing(broResponse);
      return broResponse;
    } catch (e) {
      return _fallbackToGemini(
          'Incoming voice transcript placeholder', startTime);
    } finally {
      _ref.read(broLoadingProvider.notifier).state = false;
    }
  }

  Future<BroResponse> processTextQuery(String query) async {
    final startTime = DateTime.now();
    _ref.read(broLoadingProvider.notifier).state = true;

    try {
      final response = await _dio.post('/bro/chat', data: {'query': query});
      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      final broResponse = _parseFastApiResponse(response.data, executionTime);

      await _handlePostProcessing(broResponse);
      return broResponse;
    } catch (e) {
      return _fallbackToGemini(query, startTime);
    } finally {
      _ref.read(broLoadingProvider.notifier).state = false;
    }
  }

  Future<BroResponse> _fallbackToGemini(
      String query, DateTime startTime) async {
    if (_geminiFallback == null) {
      return BroResponse.failed('Fallback unavailable.');
    }

    try {
      final content = [Content.text(query)];
      final response = await _geminiFallback!.generateContent(content);
      final text = response.text ?? 'Error thinking.';

      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      final broResponse = BroResponse(
        actionType: BroActionType.none,
        status: BroStatus.success,
        text: text,
        executionTime: executionTime,
      );

      await _handlePostProcessing(broResponse);
      return broResponse;
    } catch (e) {
      return BroResponse.failed('Gemini fallback failed: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _handlePostProcessing(BroResponse response) async {
    final msg = BroMessage(
      id: _uuid.v4(),
      role: BroRole.assistant,
      content: response.text,
      timestamp: DateTime.now(),
      type: BroMessageType.text,
    );
    _ref.read(broMessagesProvider.notifier).addMessage(msg);

    if (response.actionType == BroActionType.payment) {
      final authenticated = await _authenticateUser();
      if (!authenticated) throw Exception('Biometric failed.');
    }
  }

  BroResponse _parseFastApiResponse(
      dynamic responseData, double executionTime) {
    final actionStr = responseData['action'] ?? 'none';
    final actionType = BroActionType.values.firstWhere(
      (e) => e.name == actionStr,
      orElse: () => BroActionType.none,
    );

    return BroResponse(
      actionType: actionType,
      status: responseData['status'] == 'success'
          ? BroStatus.success
          : BroStatus.failed,
      text: responseData['text'] ?? 'Done!',
      data: responseData['data'],
      executionTime: executionTime,
      error: responseData['error'],
    );
  }

  Future<bool> _authenticateUser() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return true;
      return await _localAuth.authenticate(
        localizedReason: 'Verify identity',
        options:
            const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
