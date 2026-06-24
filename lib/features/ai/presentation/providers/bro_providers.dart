import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bro_message.dart';
import '../../services/bro_orchestrator.dart';

// StateNotifier for Messages
class BroMessagesNotifier extends StateNotifier<List<BroMessage>> {
  BroMessagesNotifier() : super([
    BroMessage(
      id: 'welcome',
      role: BroRole.assistant,
      content: "Yo! I'm BRO. Bol, kya help karu? I can book cabs, order food, or just chat.",
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

final broMessagesProvider = StateNotifierProvider<BroMessagesNotifier, List<BroMessage>>((ref) {
  return BroMessagesNotifier();
});

// Loading State
final broLoadingProvider = StateProvider<bool>((ref) => false);

// BRO Orchestrator instance
final broOrchestratorProvider = Provider((ref) => BroOrchestrator(ref));

// Settings
class BroSettings {
  final double voiceSpeed;
  final String language; // e.g., 'hinglish', 'english'
  final bool autoPlayVoice;

  BroSettings({
    this.voiceSpeed = 1.0,
    this.language = 'hinglish',
    this.autoPlayVoice = true,
  });

  BroSettings copyWith({
    double? voiceSpeed,
    String? language,
    bool? autoPlayVoice,
  }) {
    return BroSettings(
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      language: language ?? this.language,
      autoPlayVoice: autoPlayVoice ?? this.autoPlayVoice,
    );
  }
}

class BroSettingsNotifier extends StateNotifier<BroSettings> {
  BroSettingsNotifier() : super(BroSettings());

  void setVoiceSpeed(double speed) => state = state.copyWith(voiceSpeed: speed);
  void setLanguage(String lang) => state = state.copyWith(language: lang);
  void toggleAutoPlay(bool val) => state = state.copyWith(autoPlayVoice: val);
}

final broSettingsProvider = StateNotifierProvider<BroSettingsNotifier, BroSettings>((ref) {
  return BroSettingsNotifier();
});
