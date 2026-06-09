import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';

import '../filters/filter_manager.dart';
import 'motion_sensor_service.dart';
import 'sensor_state.dart';

/// Keeps a [ui.FragmentShader]'s uniforms synchronised with the latest
/// [SensorState], ticked precisely once per display frame via [Ticker].
///
/// Uniform layout contract (must match every .frag shader):
///   0 → float uResolutionX
///   1 → float uResolutionY
///   2 → float uIntensity
///   3..N → filter-specific (see [_applyMotionUniforms])
class ShaderUniformBridge {

  ShaderUniformBridge({
    required this.shader,
    required this.filter,
    required this.width,
    required this.height,
    required this.intensity,
    TickerProvider? vsync,
  }) {
    // Subscribe to live sensor stream
    MotionSensorService().sensorStateStream.listen((state) {
      _latestState = state;
    });

    if (vsync != null) {
      _ticker = vsync.createTicker((_) => _push());
      _ticker!.start();
    }
  }
  final ui.FragmentShader shader;
  final FilterDefinition filter;

  double width;
  double height;
  double intensity;

  Ticker? _ticker;
  SensorState _latestState = SensorState.zero();

  /// Push all uniforms to GPU. Call this once per frame.
  void _push() {
    // Standard block: uResolution (0,1) + uIntensity (2)
    shader.setFloat(0, width);
    shader.setFloat(1, height);
    shader.setFloat(2, intensity);

    _applyMotionUniforms();
  }

  /// Push motion-specific uniforms based on filter id.
  void _applyMotionUniforms() {
    final s = _latestState;
    switch (filter.id) {
      case 'm_tilt':
        shader.setFloat(3, s.tiltX);
        shader.setFloat(4, s.tiltY);

      case 'm_shake':
        shader.setFloat(3, s.shakeIntensity);

      case 'm_warp':
        shader.setFloat(3, s.tiltX);
        shader.setFloat(4, s.tiltY);
        shader.setFloat(5, s.rotationZ);

      case 'm_edge':
        shader.setFloat(3, s.tiltX);
        shader.setFloat(4, s.tiltY);

      case 'm_zoom':
        shader.setFloat(3, s.shakeIntensity);

      case 'motion_blur':
        shader.setFloat(3, s.motionBlurVector.dx);
        shader.setFloat(4, s.motionBlurVector.dy);

      case 'motion_reactive':
        shader.setFloat(3, s.tiltX);
        shader.setFloat(4, s.tiltY);
        shader.setFloat(5, s.shakeIntensity);
        shader.setFloat(6, s.rotationZ);

      default:
        // Static shaders: only base uniforms (0-2) needed
        break;
    }
  }

  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
  }
}
