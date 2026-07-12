import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/services/audio_focus_manager.dart';
import '../presentation/providers/bro_providers.dart';

/// The BRO VoiceCommandHandler manages the end-to-end voice interaction loop.
/// It coordinates STT permission checks, continuous listening, silence detection,
/// structured routing, and TTS playback with clean state machine transitions.
class BroVoiceCommandHandler extends StateNotifier<BroVoiceStateV2> {
  BroVoiceCommandHandler(this._ref) : super(BroVoiceStateV2.idle) {
    _initializeVoiceEngines();
  }

  final Ref _ref;
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  Timer? _silenceTimer;
  Timer? _maxListenTimer;
  String _lastTranscript = '';
  int _networkRetryCount = 0;

  Future<void> _initializeVoiceEngines() async {
    try {
      await _tts.setLanguage('en-IN'); // Hinglish/Indian english voice context
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1);
      await _tts.setPitch(1);
      _tts.setCompletionHandler(() {
        developer.log('TTS playback completed', name: 'BRO.VoiceHandler');
        _transitionToIdle();
      });
    } catch (e) {
      developer.log('Failed to initialize TTS engine: $e',
          name: 'BRO.VoiceHandler');
    }
  }

  // ── Permission Handling ──────────────────────────────────────────────────

  Future<bool> _requestMicrophonePermission() async {
    state = BroVoiceStateV2.permission;
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final requestResult = await Permission.microphone.request();
    if (requestResult.isGranted) return true;

    state = BroVoiceStateV2.error;
    _ref.read(broLiveTranscriptProvider.notifier).state =
        'Microphone permission denied.';
    return false;
  }

  // ── Listening & Transcription ──────────────────────────────────────────────

  Future<void> startListening() async {
    // 1. Guard against overlapping or duplicate recording sessions
    if (state == BroVoiceStateV2.listening ||
        state == BroVoiceStateV2.transcribing) {
      developer.log('Active recording session already in progress. Skipping.',
          name: 'BRO.VoiceHandler');
      return;
    }

    // 2. Request permission first
    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) return;

    state = BroVoiceStateV2.starting;
    _ref.read(broLiveTranscriptProvider.notifier).state =
        'Connecting microphone...';

    try {
      // 3. Cancel any previous or stuck STT sessions before starting a new one
      await _stt.cancel();

      final isAvailable = await _stt.initialize(
        onStatus: _handleSttStatus,
        onError: (error) => _handleSttError(error.errorMsg, error.permanent),
      );

      if (!isAvailable) {
        state = BroVoiceStateV2.error;
        _ref.read(broLiveTranscriptProvider.notifier).state =
            'Speech recognition unavailable.';
        return;
      }

      // 4. Request audio focus
      await _ref
          .read(audioFocusManagerProvider)
          .requestAudioFocus('bro_input', AudioRequester.broInput);

      state = BroVoiceStateV2.listening;
      _ref.read(broLiveTranscriptProvider.notifier).state = 'Listening...';
      _lastTranscript = '';
      _networkRetryCount = 0;

      // 5. Start Speech Engine with continuous listening enabled
      await _stt.listen(
        onResult: (result) {
          _lastTranscript = result.recognizedWords;
          _ref.read(broLiveTranscriptProvider.notifier).state = _lastTranscript;

          if (_lastTranscript.isNotEmpty) {
            state = BroVoiceStateV2.transcribing;
            _resetSilenceTimer();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        cancelOnError: false,
        partialResults: true,
      );

      // Max timeout guard
      _maxListenTimer?.cancel();
      _maxListenTimer = Timer(const Duration(seconds: 30), () {
        if (state == BroVoiceStateV2.listening ||
            state == BroVoiceStateV2.transcribing) {
          developer.log('Max listen duration reached. Processing command.',
              name: 'BRO.VoiceHandler');
          stopListeningAndProcess();
        }
      });
    } catch (e) {
      _handleSttError('Startup exception: $e', true);
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    // Automatically stop and process after 2 seconds of silence
    _silenceTimer = Timer(const Duration(milliseconds: 2000), () {
      developer.log('Silence detected. Processing command.',
          name: 'BRO.VoiceHandler');
      stopListeningAndProcess();
    });
  }

  Future<void> stopListeningAndProcess() async {
    if (state != BroVoiceStateV2.listening &&
        state != BroVoiceStateV2.transcribing) {
      return;
    }

    _silenceTimer?.cancel();
    _maxListenTimer?.cancel();

    await _stt.stop();
    await _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_input');

    if (_lastTranscript.trim().isEmpty) {
      _transitionToIdle();
      return;
    }

    state = BroVoiceStateV2.thinking;
    await _processTranscript(_lastTranscript);
  }

  Future<void> cancelListening() async {
    _silenceTimer?.cancel();
    _maxListenTimer?.cancel();
    await _stt.cancel();
    await _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_input');
    state = BroVoiceStateV2.stopped;
    _ref.read(broLiveTranscriptProvider.notifier).state = '';
    Future.delayed(const Duration(milliseconds: 500), _transitionToIdle);
  }

  // ── Processing & Execution ─────────────────────────────────────────────────

  Future<void> _processTranscript(String transcript) async {
    try {
      final orchestrator = _ref.read(broOrchestratorProvider);
      final response = await orchestrator.processTextQuery(transcript);

      // Transition to speaking and read out BRO's response
      await _speakResponse(response.text);
    } catch (e) {
      developer.log('Processing error: $e', name: 'BRO.VoiceHandler');
      _handleBroError('Sorry bro, I ran into an issue processing that query.');
    }
  }

  Future<void> _speakResponse(String text) async {
    state = BroVoiceStateV2.speaking;

    try {
      await _ref
          .read(audioFocusManagerProvider)
          .requestAudioFocus('bro_output', AudioRequester.broOutput);
      await _tts.speak(text);
    } catch (e) {
      developer.log('TTS speaking error: $e', name: 'BRO.VoiceHandler');
      _transitionToIdle();
    }
  }

  void _transitionToIdle() {
    if (state == BroVoiceStateV2.speaking) {
      _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_output');
    }
    state = BroVoiceStateV2.idle;
    _ref.read(broLiveTranscriptProvider.notifier).state = '';
  }

  // ── Error Recovery & Handlers ──────────────────────────────────────────────

  void _handleSttError(String errorMsg, bool isPermanent) {
    developer.log('STT Error encountered: "$errorMsg", permanent: $isPermanent',
        name: 'BRO.VoiceHandler');

    // Attempt recovery on transient/network issues up to 2 times
    if (!isPermanent &&
        errorMsg.toLowerCase().contains('network') &&
        _networkRetryCount < 2) {
      _networkRetryCount++;
      developer.log(
          'Attempting transient network recovery (retry $_networkRetryCount/2)...',
          name: 'BRO.VoiceHandler');
      startListening();
      return;
    }

    _handleBroError('Speech engine error: $errorMsg');
  }

  void _handleBroError(String message) {
    state = BroVoiceStateV2.error;
    _ref.read(broLiveTranscriptProvider.notifier).state = message;
    _speakResponse(message);
  }

  void _handleSttStatus(String status) {
    developer.log('STT Status updated: $status', name: 'BRO.VoiceHandler');
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _maxListenTimer?.cancel();
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }
}

/// Provider exposing the updated state-machine-backed Voice Command Handler
final broVoiceCommandProvider =
    StateNotifierProvider<BroVoiceCommandHandler, BroVoiceStateV2>(
        BroVoiceCommandHandler.new);
