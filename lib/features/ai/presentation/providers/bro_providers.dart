import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/bro_intent.dart';
import '../../domain/models/bro_message.dart';
import '../../services/bro_orchestrator.dart';

// Complete Voice State Machine
enum BroVoiceStateV2 {
  idle,
  permission,
  starting,
  listening,
  transcribing,
  thinking,
  speaking,
  error,
  stopped
}

// StateNotifier for Messages
class BroMessagesNotifier extends StateNotifier<List<BroMessage>> {
  BroMessagesNotifier()
      : super([
          BroMessage(
            id: 'welcome',
            role: BroRole.assistant,
            content:
                "Yo! I'm BRO. I can help you navigate Gotchaa, launch your Mini Apps (like Uber, Swiggy, Spotify), or just chat. Bol, kya help karu?",
            timestamp: DateTime.now(),
            type: BroMessageType.text,
          )
        ]);

  void addMessage(BroMessage message) {
    state = [...state, message];
  }

  void clear() {
    state = [];
  }
}

final broMessagesProvider =
    StateNotifierProvider<BroMessagesNotifier, List<BroMessage>>(
        (ref) => BroMessagesNotifier());

// Loading State
final broLoadingProvider = StateProvider<bool>((ref) => false);

// Live Transcription State
final broLiveTranscriptProvider = StateProvider<String>((ref) => '');

// Settings
class BroSettings {
  BroSettings({
    this.voiceSpeed = 1.0,
    this.language = 'hinglish',
    this.autoPlayVoice = true,
  });
  final double voiceSpeed;
  final String language; // e.g., 'hinglish', 'english'
  final bool autoPlayVoice;

  BroSettings copyWith({
    double? voiceSpeed,
    String? language,
    bool? autoPlayVoice,
  }) =>
      BroSettings(
        voiceSpeed: voiceSpeed ?? this.voiceSpeed,
        language: language ?? this.language,
        autoPlayVoice: autoPlayVoice ?? this.autoPlayVoice,
      );
}

class BroSettingsNotifier extends StateNotifier<BroSettings> {
  BroSettingsNotifier() : super(BroSettings());

  void setVoiceSpeed(double speed) => state = state.copyWith(voiceSpeed: speed);
  void setLanguage(String lang) => state = state.copyWith(language: lang);
  void toggleAutoPlay(bool val) => state = state.copyWith(autoPlayVoice: val);
}

final broSettingsProvider =
    StateNotifierProvider<BroSettingsNotifier, BroSettings>(
        (ref) => BroSettingsNotifier());

// Context Provider mapping current UI state to BRO Context
final broContextProvider = Provider<BroContext>((ref) {
  // Read shell page index (camera=0, chat=1, explore=2, mini_apps=3, vybz=4, profile=5)
  // In `floating_gemini_overlay.dart`, ref.watch(broContextProvider) will retrieve current screen.
  // We'll import appropriate shell providers to resolve current screen.
  return const BroContext(
    currentScreen: 'home',
    isInMiniApp: false,
    isMicActive: false,
    isRecording: false,
    language: 'hinglish',
    theme: 'dark',
  );
});

// BRO Orchestrator instance — used by overlay and voice handler
final broOrchestratorProvider = Provider(BroOrchestrator.new);
