import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'sensor_state.dart';

enum MotionGestureEvent {
  singleShake,
  doubleShake,
  tiltLeft45,
  spin360,
  faceDownShake
}

class GestureMotionDetector {

  GestureMotionDetector(this._sensorStream) {
    _initDetector();
  }
  final Stream<SensorState> _sensorStream;
  final _gestureSubject = PublishSubject<MotionGestureEvent>();
  
  Stream<MotionGestureEvent> get gestureStream => _gestureSubject.stream;
  StreamSubscription? _sub;

  // State Machine parameters
  int _shakeCount = 0;
  Timer? _shakeResetTimer;
  
  double _initialSpinHeading = -1;
  double _accumulatedSpin = 0;
  
  bool _isTiltedLeft = false;
  bool _cooldown = false;

  void _initDetector() {
    _sub = _sensorStream.listen((state) {
      if (_cooldown) return;

      // 1 & 2. Shake Detection (Single vs Double vs FaceDown+Shake)
      if (state.isShaking) {
        if (state.tiltY > 70 || state.tiltY < -70) {
           // Face down roughly is extreme pitch/roll. 
           // In portrait, tiltY > 70 or < -70 usually implies phone is parallel to floor.
           _trigger(MotionGestureEvent.faceDownShake);
           return;
        }

        if (_shakeCount == 0) {
          _shakeCount = 1;
          _shakeResetTimer = Timer(const Duration(milliseconds: 500), () {
            if (_shakeCount == 1) {
              _trigger(MotionGestureEvent.singleShake);
            }
            _shakeCount = 0;
          });
        } else if (_shakeCount == 1) {
          _shakeResetTimer?.cancel();
          _trigger(MotionGestureEvent.doubleShake);
          _shakeCount = 0;
        }
      }

      // 3. Slow Tilt Left > 45 deg
      if (state.tiltX < -45 && state.tiltVelocity < 30) {
         if (!_isTiltedLeft) {
            _isTiltedLeft = true;
            _trigger(MotionGestureEvent.tiltLeft45);
         }
      } else if (state.tiltX > -20) {
         _isTiltedLeft = false; // Reset
      }

      // 4. Spin 360 Logic
      if (_initialSpinHeading == -1) {
        _initialSpinHeading = state.rotationZ;
      } else {
        // Compute delta (accounting for 360 wrap)
        double dAngle = state.rotationZ - _initialSpinHeading;
        if (dAngle > 180) dAngle -= 360;
        if (dAngle < -180) dAngle += 360;
        
        _accumulatedSpin += dAngle;
        _initialSpinHeading = state.rotationZ; // Step
        
        if (_accumulatedSpin.abs() >= 350) {
           _trigger(MotionGestureEvent.spin360);
           _accumulatedSpin = 0;
        }
      }
    });
  }

  void _trigger(MotionGestureEvent event) {
    _gestureSubject.add(event);
    _cooldown = true;
    Timer(const Duration(milliseconds: 800), () {
      _cooldown = false;
    });
  }

  void dispose() {
    _sub?.cancel();
    _gestureSubject.close();
    _shakeResetTimer?.cancel();
  }
}
