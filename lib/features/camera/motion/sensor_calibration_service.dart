import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'motion_sensor_service.dart';
import 'sensor_state.dart';

class SensorCalibrationService {
  double _baselineX = 0;
  double _baselineY = 0;
  
  bool _isCalibrating = false;
  final List<double> _calibXSamples = [];
  final List<double> _calibYSamples = [];

  Future<void> loadCalibrationInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _baselineX = prefs.getDouble('calib_x') ?? 0.0;
    _baselineY = prefs.getDouble('calib_y') ?? 0.0;
    
    _startDriftAutoRecalibration();
  }

  // Applies the user's specific baseline offset to live data
  SensorState applyCalibration(SensorState raw) => SensorState(
      tiltX: raw.tiltX - _baselineX,
      tiltY: raw.tiltY - _baselineY,
      rotationZ: raw.rotationZ,
      shakeIntensity: raw.shakeIntensity,
      isShaking: raw.isShaking,
      tiltVelocity: raw.tiltVelocity,
      motionBlurVector: raw.motionBlurVector,
      stabilizedTilt: Offset(raw.stabilizedTilt.dx - _baselineX, raw.stabilizedTilt.dy - _baselineY),
    );

  Future<void> startCalibration(Stream<SensorState> rawStream) async {
    _isCalibrating = true;
    _calibXSamples.clear();
    _calibYSamples.clear();

    final sub = rawStream.listen((state) {
      if (_isCalibrating) {
        _calibXSamples.add(state.tiltX);
        _calibYSamples.add(state.tiltY);
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    _isCalibrating = false;
    sub.cancel();

    if (_calibXSamples.isNotEmpty) {
       _baselineX = _calibXSamples.reduce((a, b) => a + b) / _calibXSamples.length;
       _baselineY = _calibYSamples.reduce((a, b) => a + b) / _calibYSamples.length;

       final prefs = await SharedPreferences.getInstance();
       await prefs.setDouble('calib_x', _baselineX);
       await prefs.setDouble('calib_y', _baselineY);
    }
  }

  // Silently recalibrates if the phone has been totally still at a weird angle for 60 seconds
  void _startDriftAutoRecalibration() {
    Timer.periodic(const Duration(seconds: 60), (timer) {
       final currentState = MotionSensorService().currentState;
       if (currentState.tiltVelocity < 0.5 && !currentState.isShaking) {
          // Slowly drag median toward current resting spot
          _baselineX = _baselineX * 0.9 + currentState.tiltX * 0.1;
          _baselineY = _baselineY * 0.9 + currentState.tiltY * 0.1;
       }
    });
  }
}

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  double progress = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _runCalibration();
  }

  Future<void> _runCalibration() async {
    // Fake progress UI loop over 5 seconds
    Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (mounted) setState(() => progress += 0.01);
      if (progress >= 1.0) {
        t.cancel();
        setState(() => _done = true);
      }
    });

    final service = SensorCalibrationService();
    // In real usage, pass raw uncalibrated stream
    await service.startCalibration(MotionSensorService().sensorStateStream);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.screen_rotation, size: 80, color: _done ? Colors.green : Colors.blueAccent),
            const SizedBox(height: 24),
            Text(
              _done ? 'Calibrated to your grip!' : 'Hold phone naturally...',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
            ),
            if (_done) ...[
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Continue')
              )
            ]
          ],
        ),
      ),
    );
}
