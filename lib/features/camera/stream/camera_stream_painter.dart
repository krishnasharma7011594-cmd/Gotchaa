// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'camera_image_converter.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CameraStreamPainter
///
/// Base class for every camera filter.
///
/// Architecture (the only one that works on real devices):
///   camera.startImageStream()
///     └─ YUV/BGRA bytes → compute() isolate
///         └─ ui.Image (RGBA)
///             └─ CustomPainter.paint()
///                 └─ drawImage + applyFilter() overlay
///
/// ⚠️ CameraPreview is NOT used anywhere.
/// ─────────────────────────────────────────────────────────────────────────────
abstract class CameraStreamPainter extends ChangeNotifier {
  // ─── State ─────────────────────────────────────────────────────────────────
  ui.Image? _currentFrame;
  ui.Image? get currentFrame => _currentFrame;

  bool _converting = false; // guard: skip if previous frame not done yet
  CameraController? _controller;
  
  /// Callback for external processing (e.g. Face Detection)
  void Function(CameraImage)? onImageCallback;

  // FPS tracking (debug)
  int _frameCount = 0;
  DateTime _fpsTimer = DateTime.now();
  double _fps = 0;
  double get fps => _fps;

  int _deviceOrientationDegrees = 0;
  void setDeviceOrientationDegrees(int degrees) {
    if (_deviceOrientationDegrees != degrees) {
      _deviceOrientationDegrees = degrees;
      notifyListeners();
    }
  }

  int get sensorOrientation => _controller?.description.sensorOrientation ?? 90;
  bool get isFrontCamera => _controller?.description.lensDirection == CameraLensDirection.front;
  int get deviceOrientationDegrees => _deviceOrientationDegrees;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  /// Call this once after [CameraController.initialize()].
  Future<void> attachController(CameraController controller) async {
    _controller = controller;

    // Stop any existing stream first
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }

    await controller.startImageStream(_onCameraImage);
  }

  Future<void> detach() async {
    if (_controller != null &&
        _controller!.value.isInitialized &&
        _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream().catchError((_) {});
    }
    _controller = null;
    _currentFrame?.dispose();
    _currentFrame = null;
    onImageCallback = null;
  }

  // ─── Frame pipeline ─────────────────────────────────────────────────────────

  void _onCameraImage(CameraImage image) async {
    // 1. Pass to external hook (e.g. Face Detection)
    onImageCallback?.call(image);

    if (_converting) return; // drop frame — previous not done
    _converting = true;

    final img = await cameraImageToUiImage(image);

    if (img != null) {
      final old = _currentFrame;
      _currentFrame = img;
      _converting = false;

      // FPS counter
      _frameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_fpsTimer).inMilliseconds;
      if (elapsed >= 1000) {
        _fps = _frameCount * 1000.0 / elapsed;
        _frameCount = 0;
        _fpsTimer = now;
      }

      // Notify on the next vsync frame to stay in-sync with the rasterizer
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
        old?.dispose();
      });
    } else {
      _converting = false;
    }
  }

  // ─── Subclass contract ──────────────────────────────────────────────────────

  /// Subclasses override this to apply their filter.
  /// [frame] is already drawn on [canvas] — subclasses may read it or ignore it
  /// and redraw with a Paint/ColorFilter/overlay.
  void applyFilter(ui.Canvas canvas, ui.Image frame, ui.Size size);

  // ─── CustomPainter factory method ─────────────────────────────────────────

  /// Returns a [CustomPainter] that delegates painting to this class.
  /// Use this as the `painter:` argument of [CustomPaint].
  CustomPainter toPainter() => _DelegatePainter(this);

  // ─── Capture ─────────────────────────────────────────────────────────────

  /// Saves the current filtered frame to a temporary file.
  Future<String?> captureImage(Size size) async {
    final frame = _currentFrame;
    if (frame == null) return null;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    // We use the same paint logic as the UI
    final dp = _DelegatePainter(this);
    dp.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final bytes = byteData.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/GOTCHA_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(bytes);

    return path;
  }

  @override
  void dispose() {
    _currentFrame?.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal painter — wraps the streaming painter
// ─────────────────────────────────────────────────────────────────────────────
class _DelegatePainter extends CustomPainter {

  _DelegatePainter(this.sp) : super(repaint: sp);
  final CameraStreamPainter sp;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final frame = sp.currentFrame;
    if (frame == null) {
      // Show black until first frame arrives
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, size.width, size.height),
        ui.Paint()..color = const ui.Color(0xFF000000),
      );
      return;
    }

    canvas.save();

    // ─── Mathematical Rotation Baseline ──────────────────────────────────────
    // On Android, sensorOrientation is 90 (back) or 270 (front).
    // The frames arrive in landscape. To get them to portrait:
    // Back: rotate 90.
    // Front: rotate 270 (or 90 with mirror flipped).
    
    final int sensorOrientation = sp.sensorOrientation;
    final int deviceOrientation = sp.deviceOrientationDegrees;

    int totalRotation;
    if (sp.isFrontCamera) {
      // Front camera logic: invert sensor rotation to correct for mirroring
      totalRotation = (sensorOrientation + deviceOrientation + 180) % 360;
    } else {
      totalRotation = (sensorOrientation - deviceOrientation + 360) % 360;
    }

    final double rotationRad = totalRotation * 3.1415926535897932 / 180.0;
    
    // Move to center
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationRad);
    
    if (sp.isFrontCamera) {
       // Flip horizontally relative to the sensor's vertical axis
       canvas.scale(-1, 1);
    }

    final bool rotated90 = (totalRotation % 180 != 0);
    final double drawWidth = rotated90 ? size.height : size.width;
    final double drawHeight = rotated90 ? size.width : size.height;

    // Cover scale factor
    final double scaleX = drawWidth / frame.width.toDouble();
    final double scaleY = drawHeight / frame.height.toDouble();
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double finalW = frame.width * scale;
    final double finalH = frame.height * scale;

    final src = ui.Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble());
    final dst = ui.Rect.fromLTWH(-finalW / 2, -finalH / 2, finalW, finalH);

    // First pass: draw raw frame (before filter)
    canvas.drawImageRect(frame, src, dst, ui.Paint());

    // Let the filter paint its effect on top while the transformation is active
    // This allows the filter to use landmarks relative to the frame center
    sp.applyFilter(canvas, frame, size);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_DelegatePainter old) => true;
}
