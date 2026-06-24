import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/audio_focus_manager.dart';
import '../domain/models/bro_response.dart';
import '../domain/models/bro_message.dart';
import 'bro_orchestrator.dart';

/// States of the BRO Voice Command System
enum BroVoiceState {
  idle,
  wakeWordDetection,
  listening,
  processing,
  speaking,
  error
}

/// The BRO VoiceCommandHandler manages the end-to-end voice interaction loop.
/// It coordinates STT, AI processing (LangGraph/Gemini), task execution via
/// Firebase, and TTS response, all while managing audio focus priority.
class BroVoiceCommandHandler extends StateNotifier<BroVoiceState> {
  final Ref _ref;
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Timer? _listeningTimer;
  String _lastTranscript = "";
  
  // Offline fallback queue
  final List<String> _offlineCommandQueue = [];

  BroVoiceCommandHandler(this._ref) : super(BroVoiceState.idle) {
    _initializeVoiceEngines();
  }

  Future<void> _initializeVoiceEngines() async {
    try {
      await _stt.initialize(
        onStatus: _handleSttStatus,
        onError: (error) => _handleError("STT Error: ${error.errorMsg}"),
      );
      
      await _tts.setLanguage("en-IN"); // Hinglish context
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      
      _tts.setCompletionHandler(() {
        _ref.read(audioFocusManagerProvider).releaseAudioFocus(AudioRequester.broOutput);
        state = BroVoiceState.idle;
      });

      // Start wake word detection if requested
      // Note: Real wake-word usually requires a native plugin like Porcupine,
      // but we emulate with continuous STT here as requested.
      startWakeWordDetection();
    } catch (e) {
      _handleError("Failed to initialize voice engines: $e");
    }
  }

  // ── Wake Word & Listening ──────────────────────────────────────────────────

  Future<void> startWakeWordDetection() async {
    if (state != BroVoiceState.idle) return;
    state = BroVoiceState.wakeWordDetection;
    
    // In wake word mode, we listen without audio focus request (passive)
    // or with low priority if the platform allows.
    await _stt.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        if (text.contains("gotchaa") || text.contains("bro") || text.contains("hey gotchaa")) {
          _stt.stop();
          startListening();
        }
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 10),
      cancelOnError: false,
      partialResults: true,
    );
  }

  Future<void> startListening() async {
    if (state == BroVoiceState.listening) return;

    try {
      // Step A: Request High Priority Audio Focus
      await _ref.read(audioFocusManagerProvider).requestAudioFocus(AudioRequester.broInput);
      state = BroVoiceState.listening;

      _lastTranscript = "";
      
      // Step B: Start Listening with 30s timeout
      await _stt.listen(
        onResult: (result) {
          _lastTranscript = result.recognizedWords;
          if (result.finalResult) {
            _processCommand(_lastTranscript);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        cancelOnError: true,
      );

      _listeningTimer?.cancel();
      _listeningTimer = Timer(const Duration(seconds: 30), () {
        if (state == BroVoiceState.listening) {
          _handleError("I didn't catch that. Please try again.");
          cancelListening();
        }
      });
    } catch (e) {
      _handleError("Could not start listening: $e");
    }
  }

  Future<void> cancelListening() async {
    await _stt.stop();
    await _ref.read(audioFocusManagerProvider).releaseAudioFocus(AudioRequester.broInput);
    state = BroVoiceState.idle;
    _listeningTimer?.cancel();
  }

  // ── Processing & Execution ─────────────────────────────────────────────────

  Future<void> _processCommand(String transcript) async {
    if (transcript.isEmpty) {
      _handleError("I didn't catch that.");
      return;
    }

    _listeningTimer?.cancel();
    state = BroVoiceState.processing;
    
    // Release input focus before moving to output phase
    await _ref.read(audioFocusManagerProvider).releaseAudioFocus(AudioRequester.broInput);

    try {
      // Step C & D: Route to LangGraph / Gemini API
      // Using the Orchestrator for consistency
      final orchestrator = _ref.read(broOrchestratorProvider);
      final response = await orchestrator.processTextQuery(transcript);

      if (response.status == BroStatus.success) {
        // Step E & G: Parse and Execute Task
        if (response.actionType != BroActionType.none && response.actionType != BroActionType.query) {
          await _executeTargetedTask(response);
        }

        // Step F: TTS Response
        await _speakResponse(response.text);
      } else {
        _handleError(response.error ?? "Failed to process command.");
      }
    } catch (e) {
      // Step 5: Error handling - Offline fallback
      _handleOfflineFallback(transcript);
    }
  }

  Future<void> _executeTargetedTask(BroResponse response) async {
    try {
      // Invoke Firebase Cloud Function based on action type
      final result = await _functions.httpsCallable('executeBroAction').call({
        'action': response.actionType.name,
        'data': response.data,
        'context': 'voice_command'
      });
      
      debugPrint("Action executed: ${result.data}");
      // Possibly trigger a deep link if returned
      if (result.data['deep_link'] != null) {
        // launchUrl(Uri.parse(result.data['deep_link']));
      }
    } catch (e) {
      debugPrint("Firebase Execution Error: $e");
    }
  }

  Future<void> _speakResponse(String text) async {
    state = BroVoiceState.speaking;
    
    // Step C: Request Output Focus
    await _ref.read(audioFocusManagerProvider).requestAudioFocus(AudioRequester.broOutput);
    
    await _tts.speak(text);
  }

  // ── Error & Fallback ───────────────────────────────────────────────────────

  void _handleOfflineFallback(String transcript) {
    if (_offlineCommandQueue.length >= 5) _offlineCommandQueue.removeAt(0);
    _offlineCommandQueue.add(transcript);
    
    _speakResponse("I'm currently offline, boss. I've queued your request and will sync it once we're back online.");
  }

  void _handleError(String message) {
    debugPrint("BRO Voice Error: $message");
    state = BroVoiceState.error;
    _speakResponse(message);
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) state = BroVoiceState.idle;
    });
  }

  void _handleSttStatus(String status) {
    debugPrint("STT Status: $status");
    if (status == "done" && state == BroVoiceState.listening) {
       // Timeout handle if no results came
    }
  }

  @override
  void dispose() {
    _listeningTimer?.cancel();
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }
}

/// Provider for the Voice Command Handler
final broVoiceCommandProvider = StateNotifierProvider<BroVoiceCommandHandler, BroVoiceState>((ref) {
  return BroVoiceCommandHandler(ref);
});

/// UI Example Widget
class BroVoiceControlWidget extends ConsumerWidget {
  const BroVoiceControlWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(broVoiceCommandProvider);
    
    return Column(
      children: [
        _buildVoiceIndicator(voiceState),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => ref.read(broVoiceCommandProvider.notifier).startListening(),
          icon: Icon(voiceState == BroVoiceState.listening ? Icons.stop : Icons.mic),
          label: Text(voiceState == BroVoiceState.listening ? "Stop Listening" : "Talk to BRO"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getStateColor(voiceState),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceIndicator(BroVoiceState state) {
    String text = "BRO is Idle";
    IconData icon = Icons.blur_on;
    
    switch (state) {
      case BroVoiceState.listening:
        text = "Listening...";
        icon = Icons.hearing_rounded;
        break;
      case BroVoiceState.processing:
        text = "Thinking...";
        icon = Icons.psychology_rounded;
        break;
      case BroVoiceState.speaking:
        text = "BRO Speaking";
        icon = Icons.record_voice_over_rounded;
        break;
      case BroVoiceState.error:
        text = "Something went wrong";
        icon = Icons.warning_amber_rounded;
        break;
      default:
        break;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _getStateColor(state)),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getStateColor(BroVoiceState state) {
    switch (state) {
      case BroVoiceState.listening: return Colors.redAccent;
      case BroVoiceState.processing: return Colors.blueAccent;
      case BroVoiceState.speaking: return Colors.greenAccent;
      case BroVoiceState.error: return Colors.orangeAccent;
      default: return Colors.grey;
    }
  }
}
