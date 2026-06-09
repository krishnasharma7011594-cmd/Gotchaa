import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'gesture_motion_detector.dart';
import 'sensor_state.dart';

class MotionFeedbackService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _sensorSub;
  StreamSubscription? _gestureSub;

  bool _isShaking = false;
  double _lastTiltY = 0;

  Future<void> initialize(Stream<SensorState> sensorStream,
      Stream<MotionGestureEvent> gestureStream) async {
    // Load simple asset or synthesize tone.
    // Usually you'd use _audioPlayer.setAsset('assets/audio/whoosh.mp3');
    // For instrument feel, we can just alter pitch of a looping drone,
    // or trigger short bursts.

    _sensorSub = sensorStream.listen((state) {
      if (state.shakeIntensity > 0.8 && !_isShaking) {
        _isShaking = true;
        HapticFeedback.heavyImpact();
      } else if (state.shakeIntensity < 0.3) {
        _isShaking = false;
      }

      // Pitch shift based on tiltY
      if ((state.tiltY - _lastTiltY).abs() > 5.0) {
        // Map -90..90 to 0.5..2.0 pitch
        double pitch = 1.0 + (state.tiltY / 90.0);
        if (pitch < 0.5) pitch = 0.5;
        if (pitch > 2.0) pitch = 2.0;

        if (_audioPlayer.playing) {
          _audioPlayer.setPitch(pitch);
        }
        _lastTiltY = state.tiltY;
      }
    });

    _gestureSub = gestureStream.listen((event) {
      switch (event) {
        case MotionGestureEvent.singleShake:
          HapticFeedback.vibrate();
          break;
        case MotionGestureEvent.doubleShake:
          HapticFeedback.mediumImpact();
          // _audioPlayer.setAsset('assets/audio/whoosh.mp3');
          // _audioPlayer.play();
          break;
        case MotionGestureEvent.tiltLeft45:
          HapticFeedback.selectionClick();
          break;
        case MotionGestureEvent.spin360:
          HapticFeedback.heavyImpact();
          break;
        case MotionGestureEvent.faceDownShake:
          HapticFeedback.heavyImpact();
          break;
      }
    });
  }

  void dispose() {
    _sensorSub?.cancel();
    _gestureSub?.cancel();
    _audioPlayer.dispose();
  }
}
