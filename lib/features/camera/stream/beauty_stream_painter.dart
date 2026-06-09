import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'beauty_models.dart';
import 'camera_stream_painter.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// BeautyStreamPainter
///
/// The production engine for Gotchaa beauty filters.
/// Coordinates Face Detection landmarks with canvas-based regional filters.
/// ─────────────────────────────────────────────────────────────────────────────
class BeautyStreamPainter extends CameraStreamPainter {
  BeautyStreamPainter() {
    _loadShaders();
  }
  BeautySettings _settings = const BeautySettings();
  BeautySettings get settings => _settings;

  List<Face>? _faces;
  Size? _lastFaceSourceSize;

  // Shaders (to be loaded)
  ui.FragmentShader? _smoothShader;
  ui.FragmentShader? _colorShader;

  Future<void> _loadShaders() async {
    try {
      final smoothProg = await ui.FragmentProgram.fromAsset(
          'assets/shaders/beauty_smooth.frag');
      _smoothShader = smoothProg.fragmentShader();

      final colorProg = await ui.FragmentProgram.fromAsset(
          'assets/shaders/beauty_color.frag');
      _colorShader = colorProg.fragmentShader();

      notifyListeners();
    } catch (e) {}
  }

  void updateSettings(BeautySettings settings) {
    _settings = settings;
    notifyListeners();
  }

  void updateFaces(List<Face> faces, Size sourceSize) {
    _faces = faces;
    _lastFaceSourceSize = sourceSize;
    // We don't notify here to avoid double-painting; we wait for the next frame
  }

  @override
  void applyFilter(ui.Canvas canvas, ui.Image frame, ui.Size size) {
    if (_faces == null || _faces!.isEmpty) {
      _applyGlobalFallbacks(canvas, frame, size);
      return;
    }

    // 1. Process each face
    for (final face in _faces!) {
      _renderFaceBeauty(canvas, frame, size, face);
    }

    // 2. Global tone/lighting
    _applyGlobalEnhancements(canvas, size);
  }

  void _renderFaceBeauty(
      ui.Canvas canvas, ui.Image frame, ui.Size size, Face face) {
    if (_lastFaceSourceSize == null) return;

    // Calculate the cover scale (same as in _DelegatePainter)
    // We assume the canvas is already rotated and translated to center
    final bool rotated90 =
        (deviceOrientationDegrees % 180 != 0); // Simplified check
    // Actually, we can just use frame and size directly

    final double drawWidth = rotated90 ? size.height : size.width;
    final double drawHeight = rotated90 ? size.width : size.height;

    final double fW = frame.width.toDouble();
    final double fH = frame.height.toDouble();

    final double scaleX = drawWidth / fW;
    final double scaleY = drawHeight / fH;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double finalW = fW * scale;
    final double finalH = fH * scale;

    // Mapping function: Landmark -> Centered Canvas
    Offset mapPoint(math.Point<int> p) {
      final double nx = (p.x / fW - 0.5) * finalW;
      final double ny = (p.y / fH - 0.5) * finalH;
      return Offset(nx, ny);
    }

    // Region 1: Skin Smoothing (Regional)
    final contour = face.contours[FaceContourType.face];
    if (contour != null && _settings.smoothness > 0) {
      final path = Path();
      final points = contour.points;
      if (points.isNotEmpty) {
        final start = mapPoint(points[0]);
        path.moveTo(start.dx, start.dy);
        for (var i = 1; i < points.length; i++) {
          final p = mapPoint(points[i]);
          path.lineTo(p.dx, p.dy);
        }
        path.close();

        // Pass size and finalDims so shader matches centered rect
        _applySkinSmoothing(canvas, frame, size, path, finalW, finalH);
      }
    }

    // Region 2: Lips (Makeup)
    if (_settings.makeupIntensity > 0) {
      _drawMakeup(canvas, face, mapPoint);
    }

    // Region 3: Eyes (Enhancement)
    if (_settings.lighting > 0 || _settings.sharpness > 0) {
      _enhanceEyes(canvas, face, mapPoint);
    }
  }

  void _applySkinSmoothing(ui.Canvas canvas, ui.Image frame, ui.Size size,
      Path skinPath, double finalW, double finalH) {
    if (_smoothShader == null) return;

    // Use a layer to mask the smoothing effect to just the skinPath
    canvas.saveLayer(null, Paint());
    canvas.clipPath(skinPath);

    _smoothShader!
      ..setFloat(0, finalW)
      ..setFloat(1, finalH)
      ..setFloat(2, _settings.smoothness.clamp(0.0, 0.3)) // Max 30% rule
      ..setImageSampler(0, frame);

    final paint = Paint()..shader = _smoothShader;
    // Draw centered rect
    canvas.drawRect(
        Rect.fromLTWH(-finalW / 2, -finalH / 2, finalW, finalH), paint);

    canvas.restore();
  }

  void _drawMakeup(
      ui.Canvas canvas, Face face, Offset Function(math.Point<int>) mapPoint) {
    // Lips
    final upperLip = face.contours[FaceContourType.upperLipTop];
    final lowerLip = face.contours[FaceContourType.lowerLipBottom];

    if (upperLip != null && lowerLip != null) {
      final lipPath = Path();
      final p1 = upperLip.points;
      final p2 = lowerLip.points;

      final start = mapPoint(p1[0]);
      lipPath.moveTo(start.dx, start.dy);
      for (final p in p1) {
        final pt = mapPoint(p);
        lipPath.lineTo(pt.dx, pt.dy);
      }
      for (final p in p2.reversed) {
        final pt = mapPoint(p);
        lipPath.lineTo(pt.dx, pt.dy);
      }
      lipPath.close();

      final paint = Paint()
        ..color = const Color(0xFFFF1493)
            .withValues(alpha: 0.2 * _settings.makeupIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawPath(lipPath, paint);
    }

    // Blush (Cheeks)
    final leftCheek = face.landmarks[FaceLandmarkType.leftCheek];
    final rightCheek = face.landmarks[FaceLandmarkType.rightCheek];
    if (leftCheek != null &&
        rightCheek != null &&
        _settings.makeupIntensity > 0.5) {
      final blushPaint = Paint()
        ..color = const Color(0xFFFFB6C1)
            .withValues(alpha: 0.1 * _settings.makeupIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawCircle(
          mapPoint(math.Point(leftCheek.position.x, leftCheek.position.y)),
          30,
          blushPaint);
      canvas.drawCircle(
          mapPoint(math.Point(rightCheek.position.x, rightCheek.position.y)),
          30,
          blushPaint);
    }
  }

  void _enhanceEyes(
      ui.Canvas canvas, Face face, Offset Function(math.Point<int>) mapPoint) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2 * _settings.lighting)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    if (leftEye != null) {
      final p = mapPoint(math.Point(leftEye.position.x, leftEye.position.y));
      canvas.drawCircle(p, 8, paint);

      // Catch light (Eye Pop)
      if (_settings.sharpness > 0.7) {
        canvas.drawCircle(
            p.translate(-2, -2), 2, Paint()..color = Colors.white);
      }
    }
    if (rightEye != null) {
      final p = mapPoint(math.Point(rightEye.position.x, rightEye.position.y));
      canvas.drawCircle(p, 8, paint);

      if (_settings.sharpness > 0.7) {
        canvas.drawCircle(
            p.translate(-2, -2), 2, Paint()..color = Colors.white);
      }
    }
  }

  void _applyGlobalEnhancements(ui.Canvas canvas, ui.Size size) {
    if (_settings.tone == 0 && _settings.lighting == 0) return;

    // We apply distinct color profiles based on tone/lighting
    // Positive tone = Warm/Gold, Negative = Cool/Blue
    final double rScale = 1.0 +
        (_settings.lighting * 0.15) +
        (_settings.tone > 0 ? _settings.tone * 0.2 : 0);
    final double gScale = 1.0 +
        (_settings.lighting * 0.1) +
        (_settings.tone > 0 ? _settings.tone * 0.1 : 0);
    final double bScale = 1.0 +
        (_settings.lighting * 0.05) +
        (_settings.tone < 0 ? _settings.tone.abs() * 0.3 : 0);

    final List<double> matrix = [
      rScale,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      gScale,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      bScale,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];

    final paint = Paint()
      ..colorFilter = ColorFilter.matrix(matrix)
      ..blendMode = BlendMode.modulate;

    // Draw over the whole frame to apply the tone
    // Since we are centered and potentially rotated, drawPaint is safest
    canvas.drawPaint(paint);
  }

  void _applyGlobalFallbacks(ui.Canvas canvas, ui.Image frame, ui.Size size) {
    // If no face, we can apply very minimal global smoothing to stay efficient
    // but the prompt says NO global filters. So if no face is detected, we draw nothing extra.
  }
}
