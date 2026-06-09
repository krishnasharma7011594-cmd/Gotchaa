import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'sensor_state.dart';

/// Sensor fusion service using a complementary filter with proper Δt tracking.
///
/// Rule 3 compliance:
///   const double alpha = 0.98;
///   final double dt = currentTime - lastTime; // seconds, clamped
///   tiltX = alpha * (tiltX + gyroX * dt) + (1 - alpha) * accelTiltX;
///   tiltY = alpha * (tiltY + gyroY * dt) + (1 - alpha) * accelTiltY;
class MotionSensorService with WidgetsBindingObserver {
  factory MotionSensorService() => _instance;
  MotionSensorService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }
  // ─── Singleton ────────────────────────────────────────────────────────────
  static final MotionSensorService _instance = MotionSensorService._internal();

  // ─── Public stream ────────────────────────────────────────────────────────
  final _stateSubject = BehaviorSubject<SensorState>.seeded(SensorState.zero());
  Stream<SensorState> get sensorStateStream => _stateSubject.stream;
  SensorState get currentState => _stateSubject.value;

  // ─── Isolate plumbing ─────────────────────────────────────────────────────
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // ─── Adaptive power management ────────────────────────────────────────────
  Timer? _stillnessTimer;
  bool _isLowPowerMode = false;

  Duration get _sensorInterval => _isLowPowerMode
      ? const Duration(milliseconds: 33)  // ~30 Hz when still
      : const Duration(milliseconds: 10); // ~100 Hz when moving

  bool _initialized = false;
  bool _isPaused = false;

  // ─── Public API ───────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _isolate = await Isolate.spawn(
      _sensorProcessingIsolate,
      _receivePort.sendPort,
    );

    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _startSensorListening();
      } else if (message is Map<String, dynamic>) {
        final state = SensorState(
          tiltX: (message['tiltX'] as double).clamp(-90.0, 90.0),
          tiltY: (message['tiltY'] as double).clamp(-90.0, 90.0),
          rotationZ: (message['rotationZ'] as double) % 360.0,
          shakeIntensity: (message['shakeIntensity'] as double).clamp(0.0, 1.0),
          isShaking: message['isShaking'] as bool,
          tiltVelocity: (message['tiltVelocity'] as double).clamp(0.0, 1000.0),
          motionBlurVector: Offset(
            message['blurX'] as double,
            message['blurY'] as double,
          ),
          stabilizedTilt: Offset(
            message['stabX'] as double,
            message['stabY'] as double,
          ),
        );
        _stateSubject.add(state);
        _checkStillness(state.tiltVelocity);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseSensors();
    } else if (state == AppLifecycleState.resumed) {
      _resumeSensors();
    }
  }

  void _pauseSensors() {
    if (_isPaused) return;
    _isPaused = true;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    
  }

  void _resumeSensors() {
    if (!_isPaused || !_initialized) return;
    _isPaused = false;
    _startSensorListening();
    
  }

  void _startSensorListening() {
    if (_isPaused) return;
    
    _accelSub?.cancel();
    _gyroSub?.cancel();

    _accelSub =
        accelerometerEventStream(samplingPeriod: _sensorInterval).listen((e) {
      _sendPort?.send({'type': 'accel', 'x': e.x, 'y': e.y, 'z': e.z});
    });

    _gyroSub =
        gyroscopeEventStream(samplingPeriod: _sensorInterval).listen((e) {
      _sendPort?.send({'type': 'gyro', 'x': e.x, 'y': e.y, 'z': e.z});
    });
  }

  void _checkStillness(double velocity) {
    if (velocity > 5.0) {
      _stillnessTimer?.cancel();
      if (_isLowPowerMode) {
        _isLowPowerMode = false;
        _restartSensors();
      }
      _stillnessTimer = Timer(const Duration(seconds: 3), () {
        _isLowPowerMode = true;
        _restartSensors();
      });
    }
  }

  void _restartSensors() {
    if (_isPaused) return;
    _startSensorListening();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _stateSubject.close();
    _initialized = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Isolate entry point — runs entirely off the main thread
// ─────────────────────────────────────────────────────────────────────────────
void _sensorProcessingIsolate(SendPort mainSendPort) {
  final port = ReceivePort();
  mainSendPort.send(port.sendPort);

  // ── Complementary filter state (all angles in degrees) ──────────────────
  double roll = 0;   // tiltX
  double pitch = 0;  // tiltY
  double yaw = 0;    // rotationZ (gyro only — no magnetometer)

  // ── Accelerometer snapshot (needed for gravity-based correction) ─────────
  double accelX = 0, accelY = 0, accelZ = 0;

  // ── Shake detection ──────────────────────────────────────────────────────
  final List<double> recentAccels = [];
  int consecutiveShakeFrames = 0;

  // ── Delta-time tracking (Rule 3: must include dt in gyro integration) ────
  int lastTimestampMs = DateTime.now().millisecondsSinceEpoch;

  // Complementary filter constant — 98% gyro, 2% accelerometer correction
  const double alpha = 0.98;

  // ── Max dt clamp: prevent huge spike on first frame or after resume ───────
  const double maxDtSeconds = 0.05; // 50 ms cap = minimum 20 Hz effective

  port.listen((message) {
    if (message is! Map<String, dynamic>) return;

    final type = message['type'] as String;
    final x = message['x'] as double;
    final y = message['y'] as double;
    final z = message['z'] as double;

    // ── Δt computation (Rule 3) ─────────────────────────────────────────────
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final double dt = ((nowMs - lastTimestampMs) / 1000.0).clamp(0.001, maxDtSeconds);
    lastTimestampMs = nowMs;

    if (type == 'accel') {
      // Store latest accelerometer reading for complementary filter correction
      accelX = x;
      accelY = y;
      accelZ = z;

      // ── Shake intensity ─────────────────────────────────────────────────
      final double magnitude = sqrt(x * x + y * y + z * z);
      final double rawShake = (magnitude - 9.81).abs();

      recentAccels.add(rawShake);
      if (recentAccels.length > 10) recentAccels.removeAt(0);

      final double avgShake =
          recentAccels.reduce((a, b) => a + b) / recentAccels.length;
      final double intensity = (avgShake / 15.0).clamp(0.0, 1.0);

      if (intensity > 0.4) {
        consecutiveShakeFrames++;
      } else {
        consecutiveShakeFrames = 0;
      }
    } else if (type == 'gyro') {
      // ── Complementary filter (Rule 3 exact pattern) ──────────────────────
      // Gravity vector → accelerometer-derived roll & pitch
      final double accelRoll =
          atan2(accelY, accelZ) * 180.0 / pi;
      final double accelPitch =
          atan2(-accelX, sqrt(accelY * accelY + accelZ * accelZ)) * 180.0 / pi;

      // Gyroscope integration with Δt — gyro values are in rad/s
      final double gyroRoll  = roll  + (x * 180.0 / pi) * dt;
      final double gyroPitch = pitch + (y * 180.0 / pi) * dt;
      yaw = yaw + (z * 180.0 / pi) * dt;

      // Fuse: 98% trust gyro integration, 2% drift correction from gravity
      final double oldRoll = roll;
      final double oldPitch = pitch;

      roll  = alpha * gyroRoll  + (1.0 - alpha) * accelRoll;
      pitch = alpha * gyroPitch + (1.0 - alpha) * accelPitch;

      // ── Derived quantities ───────────────────────────────────────────────
      final double dRoll  = roll  - oldRoll;
      final double dPitch = pitch - oldPitch;
      final double tiltVelocity =
          dt > 0 ? sqrt(dRoll * dRoll + dPitch * dPitch) / dt : 0.0;

      // Motion blur vector: proportional to angular velocity in gyro
      final double blurX = -y * 12.0; // pitch angular velocity → horizontal blur
      final double blurY =  x * 12.0; // roll angular velocity  → vertical blur

      mainSendPort.send({
        'tiltX': roll,
        'tiltY': pitch,
        'rotationZ': yaw % 360.0,
        'shakeIntensity': recentAccels.isNotEmpty
            ? (recentAccels.last / 15.0).clamp(0.0, 1.0)
            : 0.0,
        'isShaking': consecutiveShakeFrames >= 3,
        'tiltVelocity': tiltVelocity.clamp(0.0, 1000.0),
        'blurX': blurX,
        'blurY': blurY,
        'stabX': roll * 0.85,
        'stabY': pitch * 0.85,
      });
    }
  });
}
