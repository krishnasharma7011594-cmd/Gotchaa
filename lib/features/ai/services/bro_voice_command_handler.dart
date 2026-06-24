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
        onError: (error) => _handleBroError("STT Error: ${error.errorMsg}"),
      );
      
      await _tts.setLanguage("en-IN"); // Hinglish context
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeechCompletion(true); // Wait for speaking to finish to trigger completion tasks

      // Start wake word detection if requested
      // Note: Real wake-word usually requires a native plugin like Porcupine,
      // but we emulate with continuous STT here as requested.
      startWakeWordDetection();
    } catch (e) {
      _handleBroError("Failed to initialize voice engines: $e");
    }
  }

  // ── Wake Word & Listening ──────────────────────────────────────────────────

  Future<void> startWakeWordDetection() async {
    // Guard checking if already listening or wake-word is active to prevent race conditions
    if (state == BroVoiceState.wakeWordDetection) {
      debugPrint("BroVoiceCommandHandler: Wake-word detection already active. Skipping restart.");
      return;
    }
    if (state == BroVoiceState.listening) {
      debugPrint("BroVoiceCommandHandler: Active listening currently active. Skipping wake-word restart.");
      return;
    }
    if (state != BroVoiceState.idle) {
      debugPrint("BroVoiceCommandHandler: Cannot start wake-word detection. Current state is $state, not idle.");
      return;
    }
    
    debugPrint("BroVoiceCommandHandler: [Restart Point] Starting wake-word detection loop.");
    state = BroVoiceState.wakeWordDetection;
    
    // In wake word mode, we listen without audio focus request (passive)
    // or with low priority if the platform allows.
    await _stt.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        if (text.contains("gotchaa") || text.contains("bro") || text.contains("hey gotchaa")) {
          debugPrint("BroVoiceCommandHandler: Wake-word detected ('$text'). Starting active command listening.");
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
      await _ref.read(audioFocusManagerProvider).requestAudioFocus('bro_input', AudioRequester.broInput);
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
          _handleBroError("I didn't catch that. Please try again.");
          cancelListening();
        }
      });
    } catch (e) {
      _handleBroError("Could not start listening: $e");
    }
  }

  Future<void> cancelListening() async {
    await _stt.stop();
    await _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_input');
    state = BroVoiceState.idle;
    _listeningTimer?.cancel();
  }

  // ── Processing & Execution ─────────────────────────────────────────────────

  Future<void> _processCommand(String transcript) async {
    if (transcript.isEmpty) {
      _handleBroError("I didn't catch that.");
      return;
    }

    _listeningTimer?.cancel();
    state = BroVoiceState.processing;
    
    // Release input focus before moving to output phase
    await _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_input');

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
        _handleBroError(response.error ?? "Failed to process command.");
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
    await _ref.read(audioFocusManagerProvider).requestAudioFocus('bro_output', AudioRequester.broOutput);
    
    await _tts.speak(text);
    
    // This functions as the TTS completion callback since _tts.awaitSpeechCompletion(true) is set
    debugPrint("BroVoiceCommandHandler: TTS completed speaking. Releasing focus and transitioning to idle.");
    await _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_output');
    state = BroVoiceState.idle;
    
    debugPrint("BroVoiceCommandHandler: [Restart Point] Restarting wake-word detection after speech completion.");
    await startWakeWordDetection();
  }

  // ── Error & Fallback ───────────────────────────────────────────────────────

  void _handleOfflineFallback(String transcript) {
    if (_offlineCommandQueue.length >= 5) _offlineCommandQueue.removeAt(0);
    _offlineCommandQueue.add(transcript);
    
    _speakResponse("I'm currently offline, boss. I've queued your request and will sync it once we're back online.");
  }

  void _handleBroError(String message) {
    debugPrint("BroVoiceCommandHandler: [Error Handler] Error occurred: $message");
    state = BroVoiceState.error;
    
    // Speak the error message via TTS. The _speakResponse method will automatically
    // restart wake-word detection when speaking completes.
    _speakResponse(message);
    
    // Fallback safety timer in case speaking fails to trigger or complete
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && state == BroVoiceState.error) {
        debugPrint("BroVoiceCommandHandler: [Error Handler Fallback] Resetting state to idle.");
        state = BroVoiceState.idle;
        startWakeWordDetection();
      }
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
