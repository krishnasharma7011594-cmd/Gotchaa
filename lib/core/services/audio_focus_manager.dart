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
  static final AudioFocusManager _instance = AudioFocusManager._internal();
  factory AudioFocusManager() => _instance;
  AudioFocusManager._internal() {
    _initSession();
  }

  final _focusOwner = BehaviorSubject<AudioRequester?>.seeded(null);
  
  /// Stream of the current focus owner
  Stream<AudioRequester?> get focusOwnerStream => _focusOwner.stream;
  
  /// Current owner of the audio focus
  AudioRequester? get currentFocusOwner => _focusOwner.value;

  /// Tracks active requesters
  final Set<AudioRequester> _activeRequesters = {};

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

  /// Request focus for a specific layer.
  /// 
  /// If a higher priority requester is active, this requester will wait 
  /// until focus is released.
  Future<void> requestAudioFocus(AudioRequester requester) async {
    debugPrint('AudioFocus: Requesting for $requester');
    _activeRequesters.add(requester);
    await _reevaluateFocus();
  }

  /// Release focus for a specific layer.
  Future<void> releaseAudioFocus(AudioRequester requester) async {
    debugPrint('AudioFocus: Releasing for $requester');
    _activeRequesters.remove(requester);
    await _reevaluateFocus();
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

    AudioRequester? nextOwner;

    // Priority Check
    if (_activeRequesters.contains(AudioRequester.broInput)) {
      nextOwner = AudioRequester.broInput;
      // Configure for Speech Input (High sensitivity, ducking others)
      await session.configure(const AudioSessionConfiguration.speech());
    } else if (_activeRequesters.contains(AudioRequester.broOutput)) {
      nextOwner = AudioRequester.broOutput;
      // Configure for Speech Output
      await session.configure(const AudioSessionConfiguration.speech());
    } else if (_activeRequesters.contains(AudioRequester.vybz)) {
      nextOwner = AudioRequester.vybz;
      // Configure for Music/Media
      await session.configure(const AudioSessionConfiguration.music());
    } else {
      nextOwner = null;
    }

    if (_focusOwner.value != nextOwner) {
      debugPrint('AudioFocus: Transitioning from ${_focusOwner.value} to $nextOwner');
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
  ref.onDispose(() => manager.dispose());
  return manager;
});

final audioFocusOwnerProvider = StreamProvider<AudioRequester?>((ref) {
  return ref.watch(audioFocusManagerProvider).focusOwnerStream;
});

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
