import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../motion/sensor_state.dart';

class ParallaxFilterPainter extends CustomPainter { // Precomputed [Background, Midground, Foreground]

  ParallaxFilterPainter({
    required this.sensorState,
    this.cameraFramePreview,
    this.depthLayers,
  });
  final SensorState sensorState;
  final ui.Image? cameraFramePreview; // From background snapshot mechanism
  final List<ui.Image>? depthLayers;

  @override
  void paint(Canvas canvas, Size size) {
    if (depthLayers == null || depthLayers!.length < 3) return;

    // Use stabilized tilt to avoid tremor jitters
    // Invert tilt direction because rotating left makes scene shift right relative to screen
    final double maxShiftX = size.width * 0.15; // Max 15% parallax drift
    final double maxShiftY = size.height * 0.15;

    // Scale tilt from degrees (-90 to +90) to -1.0 to +1.0
    final double tX = (sensorState.stabilizedTilt.dx / 90.0).clamp(-1.0, 1.0);
    final double tY = (sensorState.stabilizedTilt.dy / 90.0).clamp(-1.0, 1.0);

    // Factors: Background moves least (0.3), Foreground moves most (1.0)
    const double bgFactor = 0.3;
    const double mgFactor = 0.6;
    const double fgFactor = 1;

    // Draw Background
    canvas.drawImageRect(
      depthLayers![0], 
      Rect.fromLTWH(0, 0, depthLayers![0].width.toDouble(), depthLayers![0].height.toDouble()),
      _computeDestRect(size, tX, tY, bgFactor, maxShiftX, maxShiftY),
      Paint()
    );

    // Draw Midground
    canvas.drawImageRect(
      depthLayers![1], 
      Rect.fromLTWH(0, 0, depthLayers![1].width.toDouble(), depthLayers![1].height.toDouble()),
      _computeDestRect(size, tX, tY, mgFactor, maxShiftX, maxShiftY),
      Paint()
    );

    // Draw Foreground
    canvas.drawImageRect(
      depthLayers![2], 
      Rect.fromLTWH(0, 0, depthLayers![2].width.toDouble(), depthLayers![2].height.toDouble()),
      _computeDestRect(size, tX, tY, fgFactor, maxShiftX, maxShiftY),
      Paint()
    );

    // Dynamic Vignette based on tilt angle
    // If you lean left, the left edge darkens, mimicking shadows in a box
    _drawReactiveVignette(canvas, size, tX, tY);
  }

  Rect _computeDestRect(Size size, double tX, double tY, double factor, double maxX, double maxY) {
    // Inflate dest rect slightly so when shifting it doesn't reveal hard edges
    const double inflation = 1.1; 
    final double drawWidth = size.width * inflation;
    final double drawHeight = size.height * inflation;
    
    // Shift center
    final double cx = (size.width / 2) + (tX * maxX * factor);
    final double cy = (size.height / 2) + (tY * maxY * factor);

    return Rect.fromCenter(center: Offset(cx, cy), width: drawWidth, height: drawHeight);
  }

  void _drawReactiveVignette(Canvas canvas, Size size, double tX, double tY) {
    // Shift the center of the radial gradient AWAY from the tilt
    final center = Offset(
      (size.width / 2) - (tX * size.width * 0.4),
      (size.height / 2) - (tY * size.height * 0.4)
    );

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
        stops: const [0.5, 1.0],
        focal: Alignment( -tX * 0.5, -tY * 0.5 ), // Focal shifts for 3D light illusion
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.multiply;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant ParallaxFilterPainter oldDelegate) {
    // Repaint on any sensor change > 0.5 deg
    return (oldDelegate.sensorState.stabilizedTilt.dx - sensorState.stabilizedTilt.dx).abs() > 0.5 ||
           (oldDelegate.sensorState.stabilizedTilt.dy - sensorState.stabilizedTilt.dy).abs() > 0.5;
  }
}
