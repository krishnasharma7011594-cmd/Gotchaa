import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

/// Requesters for Audio Focus in the Gotchaa app.
enum AudioRequester {
  /// BRO Voice Input (STT microphone) - Highest Priority
  broInput,

  /// BRO Voice Output (TTS synthesis) - Medium Priority
  broOutput,

  /// Vybz Video Audio (background) - Lowest Priority
  vybz
}

/// The AudioFocusManager coordinates audio playback across different layers
/// of the application to ensure a seamless "Jarvis-like" experience.
///
/// Priority hierarchy:
/// 1. BRO voice input (pause everything, clean mic)
/// 2. BRO voice output (mute/reduce vybz, play TTS)
/// 3. Vybz (play only if BRO not active)
class AudioFocusManager {
  factory AudioFocusManager() => _instance;
  AudioFocusManager._internal() {
    _initSession();
  }
  static final AudioFocusManager _instance = AudioFocusManager._internal();

  final _focusOwner = BehaviorSubject<AudioRequester?>.seeded(null);

  /// Stream of the current focus owner
  Stream<AudioRequester?> get focusOwnerStream => _focusOwner.stream;

  /// Current owner of the audio focus
  AudioRequester? get currentFocusOwner => _focusOwner.value;

  /// Tracks active requesters
  final Map<String, AudioRequester> _activeRequesters = {};

  AudioSession? _session;

  Future<void> _initSession() async {
    try {
      _session = await AudioSession.instance;

      // Handle system-level interruptions (e.g., phone calls)
      _session?.interruptionEventStream.listen((event) {
        if (event.begin) {
          debugPrint('Audio session interrupted: pause');
          // On interruption, we might want to release focus or handle specifically
        } else {
          debugPrint('Audio session resumed');
        }
      });
    } catch (e) {
      debugPrint('Error initializing AudioSession: $e');
    }
  }

  /// Evaluates and returns the highest priority active requester.
  AudioRequester? _getHighestPriorityRequester() {
    if (_activeRequesters.isEmpty) return null;
    if (_activeRequesters.containsValue(AudioRequester.broInput)) {
      return AudioRequester.broInput;
    }
    if (_activeRequesters.containsValue(AudioRequester.broOutput)) {
      return AudioRequester.broOutput;
    }
    if (_activeRequesters.containsValue(AudioRequester.vybz)) {
      return AudioRequester.vybz;
    }
    return null;
  }

  /// Request focus for a specific layer.
  ///
  /// If a higher priority requester is active, this requester will wait
  /// until focus is released.
  Future<void> requestAudioFocus(
      String requesterKey, AudioRequester requester) async {
    debugPrint('AudioFocus: Requesting for $requesterKey ($requester)');
    final previousPriority = _getHighestPriorityRequester();
    _activeRequesters[requesterKey] = requester;
    final currentPriority = _getHighestPriorityRequester();

    if (currentPriority != previousPriority) {
      await _reevaluateFocus();
    }
  }

  /// Release focus for a specific layer.
  Future<void> releaseAudioFocus(String requesterKey) async {
    debugPrint('AudioFocus: Releasing for $requesterKey');
    final previousPriority = _getHighestPriorityRequester();
    _activeRequesters.remove(requesterKey);
    final currentPriority = _getHighestPriorityRequester();

    if (currentPriority != previousPriority) {
      await _reevaluateFocus();
    }
  }

  /// Helper to pause Vybz when BRO becomes active (Input or Output)
  Future<void> pauseVybzOnBROActive() async {
    // This is essentially managed by the priority logic, but exposed for clarity
  }

  /// Helper to resume Vybz after BRO is done
  Future<void> resumeVybzAfterBRO() async {
    // This is managed by the releaseAudioFocus logic
  }

  Future<void> _reevaluateFocus() async {
    final session = _session ?? await AudioSession.instance;
    _session = session;

    final nextOwner = _getHighestPriorityRequester();

    if (_focusOwner.value != nextOwner) {
      debugPrint(
          'AudioFocus: Transitioning from ${_focusOwner.value} to $nextOwner');

      if (nextOwner == AudioRequester.broInput) {
        await session.configure(const AudioSessionConfiguration.speech());
      } else if (nextOwner == AudioRequester.broOutput) {
        await session.configure(const AudioSessionConfiguration.speech());
      } else if (nextOwner == AudioRequester.vybz) {
        await session.configure(const AudioSessionConfiguration.music());
      }

      _focusOwner.add(nextOwner);

      if (nextOwner != null) {
        await session.setActive(true);
      } else {
        await session.setActive(false);
      }
    }
  }

  /// Clean up resources
  void dispose() {
    _focusOwner.close();
  }
}

/// Riverpod providers for easy integration
final audioFocusManagerProvider = Provider<AudioFocusManager>((ref) {
  final manager = AudioFocusManager();
  ref.onDispose(manager.dispose);
  return manager;
});

final audioFocusOwnerProvider = StreamProvider<AudioRequester?>((ref) => ref.watch(audioFocusManagerProvider).focusOwnerStream);

/// Specific provider for Vybz to know if it should be playing audio
final isVybzAudioAllowedProvider = Provider<bool>((ref) {
  final owner = ref.watch(audioFocusOwnerProvider).asData?.value;
  // Vybz is allowed to play audio ONLY if it is the current focus owner
  return owner == AudioRequester.vybz;
});

/// Specific provider for BRO Input status
final isBroInputActiveProvider = Provider<bool>((ref) {
  final owner = ref.watch(audioFocusOwnerProvider).asData?.value;
  return owner == AudioRequester.broInput;
});
