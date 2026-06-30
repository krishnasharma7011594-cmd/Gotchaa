import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../filters/filter_manager.dart';
import '../../motion/motion_sensor_service.dart';
import '../../motion/sensor_state.dart';

/// Maps a [FilterDefinition] and live [SensorState] to shader uniforms.
/// Each shader has a different uniform layout — this class centralises
/// that mapping so [_FilterOverlayPainter] stays generic.
class _ShaderUniforms {
  _ShaderUniforms._();

  /// Sets uniforms on [shader] for the given [filter].
  /// Returns false if the shader doesn't know the filter type.
  static void apply({
    required ui.FragmentShader shader,
    required Size size,
    required FilterDefinition filter,
    required double intensity,
    required SensorState sensor,
  }) {
    // All shaders share: uResolution (0,1) and uIntensity (2)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, intensity);

    // Motion-reactive shaders need additional uniforms
    switch (filter.id) {
      case 'm_tilt':
        // tilt_drift.frag: uTiltX (3), uTiltY (4)
        shader.setFloat(3, sensor.tiltX);
        shader.setFloat(4, sensor.tiltY);

      case 'm_shake':
        // shake_glitch.frag: uShakeIntensity (3)
        shader.setFloat(3, sensor.shakeIntensity);

      case 'm_warp':
        // time_warp.frag: uTiltX (3), uTiltY (4), uRotationZ (5)
        shader.setFloat(3, sensor.tiltX);
        shader.setFloat(4, sensor.tiltY);
        shader.setFloat(5, sensor.rotationZ);

      case 'm_edge':
        // edge_glow.frag: uTiltX (3), uTiltY (4)
        shader.setFloat(3, sensor.tiltX);
        shader.setFloat(4, sensor.tiltY);

      case 'm_zoom':
        // zoom_pulse.frag: uShakeIntensity (3)
        shader.setFloat(3, sensor.shakeIntensity);

      case 'motion_blur':
        // motion_blur.frag: uBlurVector (3, 4)
        shader.setFloat(3, sensor.motionBlurVector.dx);
        shader.setFloat(4, sensor.motionBlurVector.dy);

      case 'motion_reactive':
        // motion_reactive_base.frag: uTiltX(3) uTiltY(4) uShakeIntensity(5) uRotationZ(6)
        shader.setFloat(3, sensor.tiltX);
        shader.setFloat(4, sensor.tiltY);
        shader.setFloat(5, sensor.shakeIntensity);
        shader.setFloat(6, sensor.rotationZ);

      default:
        // Static shaders: only uResolution + uIntensity — no extra uniforms needed
        break;
    }
  }
}

/// [CustomPainter] that draws a full-screen shader overlay.
///
/// The camera feed sits beneath in the [Stack] and shows through.
/// The shader applies a colour-grading / effect overlay on top.
///
/// This avoids the Android black-screen bug caused by using
/// [ShaderMask] directly over [CameraPreview] (platform texture).
class _FilterOverlayPainter extends CustomPainter {
  _FilterOverlayPainter({
    required this.shader,
    required this.filter,
    required this.intensity,
    required this.sensor,
  });
  final ui.FragmentShader shader;
  final FilterDefinition filter;
  final double intensity;
  final SensorState sensor;

  @override
  void paint(Canvas canvas, Size size) {
    _ShaderUniforms.apply(
      shader: shader,
      size: size,
      filter: filter,
      intensity: intensity,
      sensor: sensor,
    );

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _FilterOverlayPainter old) =>
      old.sensor != sensor ||
      old.intensity != intensity ||
      old.filter.id != filter.id;
}

/// Widget that places a [CameraPreview] with a GLSL shader overlay.
///
/// Architecture (Rule 2 compliant):
/// ```
/// Stack(
///   children: [
///     CameraPreview(controller),          ← native platform view
///     RepaintBoundary(
///       child: CustomPaint(painter: _FilterOverlayPainter(...)),
///     ),
///   ],
/// )
/// ```
class ShaderCameraPreview extends StatefulWidget {
  const ShaderCameraPreview({
    required this.controller,
    required this.filter,
    required this.intensity,
    super.key,
  });
  final CameraController controller;
  final FilterDefinition filter;
  final double intensity;

  @override
  State<ShaderCameraPreview> createState() => _ShaderCameraPreviewState();
}

class _ShaderCameraPreviewState extends State<ShaderCameraPreview> {
  ui.FragmentShader? _shader;
  String? _loadedAsset;
  StreamSubscription<SensorState>? _sensorSub;
  SensorState _sensorState = SensorState.zero();

  @override
  void initState() {
    super.initState();
    _loadShader(widget.filter.shaderPath);
    _sensorSub = MotionSensorService().sensorStateStream.listen((state) {
      if (mounted) setState(() => _sensorState = state);
    });
  }

  @override
  void didUpdateWidget(covariant ShaderCameraPreview old) {
    super.didUpdateWidget(old);
    if (old.filter.shaderPath != widget.filter.shaderPath) {
      _loadShader(widget.filter.shaderPath);
    }
  }

  Future<void> _loadShader(String? assetPath) async {
    if (assetPath == null) {
      if (mounted) {
        setState(() {
          _shader = null;
          _loadedAsset = null;
        });
      }
      return;
    }
    if (assetPath == _loadedAsset) return; // already loaded
    try {
      final program = await ui.FragmentProgram.fromAsset(assetPath);
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
          _loadedAsset = assetPath;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shader = null;
          _loadedAsset = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Native camera feed — NEVER wrapped by ShaderMask
          CameraPreview(widget.controller),

          // Layer 2: Shader overlay (transparent if shader not loaded)
          if (_shader != null)
            RepaintBoundary(
              child: CustomPaint(
                painter: _FilterOverlayPainter(
                  shader: _shader!,
                  filter: widget.filter,
                  intensity: widget.intensity,
                  sensor: _sensorState,
                ),
                size: Size.infinite,
              ),
            ),
        ],
      );
}
