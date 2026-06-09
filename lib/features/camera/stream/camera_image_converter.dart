// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class passed to the compute() isolate. Must be plain data (no closures).
// ─────────────────────────────────────────────────────────────────────────────
class _ConvertArgs {
  // 'yuv420' | 'bgra8888' | 'nv21'

  const _ConvertArgs({
    required this.width,
    required this.height,
    required this.planes,
    required this.strides,
    required this.format,
  });
  final int width;
  final int height;
  final List<Uint8List> planes;
  final List<int> strides;
  final String format;
}

/// Runs entirely off the main thread via [compute].
/// Returns raw RGBA bytes (width * height * 4).
Uint8List _convertInIsolate(_ConvertArgs args) {
  final w = args.width;
  final h = args.height;
  final rgba = Uint8List(w * h * 4);

  switch (args.format) {
    case 'yuv420':
      _yuv420ToRgba(args.planes[0], args.planes[1], args.planes[2],
          args.strides[0], args.strides[1], w, h, rgba);

    case 'nv21':
      _nv21ToRgba(args.planes[0], args.planes[1], args.strides[0],
          args.strides[1], w, h, rgba);

    case 'bgra8888': // iOS
      _bgraToRgba(args.planes[0], w, h, rgba);

    default:
      // Fallback: grey
      for (int i = 0; i < w * h; i++) {
        final o = i * 4;
        rgba[o] = rgba[o + 1] = rgba[o + 2] = 128;
        rgba[o + 3] = 255;
      }
  }
  return rgba;
}

// ─── YUV420 planar (Android camera2) ─────────────────────────────────────────
void _yuv420ToRgba(
  Uint8List yPlane,
  Uint8List uPlane,
  Uint8List vPlane,
  int yStride,
  int uvStride,
  int width,
  int height,
  Uint8List out,
) {
  for (int row = 0; row < height; row++) {
    for (int col = 0; col < width; col++) {
      final yIndex = row * yStride + col;
      final uvRow = row >> 1;
      final uvCol = col >> 1;
      final uvIndex = uvRow * uvStride + uvCol;

      final Y = yPlane[yIndex];
      final U = uPlane[uvIndex] - 128;
      final V = vPlane[uvIndex] - 128;

      // BT.601 full-swing
      final int r = (Y + 1.402 * V).round().clamp(0, 255);
      final int g = (Y - 0.344136 * U - 0.714136 * V).round().clamp(0, 255);
      final int b = (Y + 1.772 * U).round().clamp(0, 255);

      final o = (row * width + col) * 4;
      out[o] = r;
      out[o + 1] = g;
      out[o + 2] = b;
      out[o + 3] = 255;
    }
  }
}

// ─── NV21 (Android legacy HAL1) ──────────────────────────────────────────────
void _nv21ToRgba(
  Uint8List yPlane,
  Uint8List vuPlane,
  int yStride,
  int uvStride,
  int width,
  int height,
  Uint8List out,
) {
  for (int row = 0; row < height; row++) {
    for (int col = 0; col < width; col++) {
      final yIndex = row * yStride + col;
      final uvRow = row >> 1;
      final uvCol = (col >> 1) * 2; // interleaved VU
      final vuIndex = uvRow * uvStride + uvCol;

      final Y = yPlane[yIndex];
      // NV21 is V first, then U
      final V = vuPlane[vuIndex] - 128;
      final U = vuPlane[vuIndex + 1] - 128;

      final int r = (Y + 1.402 * V).round().clamp(0, 255);
      final int g = (Y - 0.344136 * U - 0.714136 * V).round().clamp(0, 255);
      final int b = (Y + 1.772 * U).round().clamp(0, 255);

      final o = (row * width + col) * 4;
      out[o] = r;
      out[o + 1] = g;
      out[o + 2] = b;
      out[o + 3] = 255;
    }
  }
}

// ─── BGRA8888 (iOS) ───────────────────────────────────────────────────────────
void _bgraToRgba(Uint8List bgra, int width, int height, Uint8List out) {
  for (int i = 0; i < width * height; i++) {
    final src = i * 4;
    final dst = i * 4;
    out[dst] = bgra[src + 2]; // R ← B
    out[dst + 1] = bgra[src + 1]; // G
    out[dst + 2] = bgra[src]; // B ← R
    out[dst + 3] = bgra[src + 3]; // A
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Converts a [CameraImage] to a [ui.Image] on a background isolate via [compute].
/// Returns null if conversion fails.
Future<ui.Image?> cameraImageToUiImage(CameraImage image) async {
  try {
    final format = _detectFormat(image);

    final args = _ConvertArgs(
      width: image.width,
      height: image.height,
      planes: image.planes.map((p) => p.bytes).toList(),
      strides: image.planes.map((p) => p.bytesPerRow).toList(),
      format: format,
    );

    // ✅ Runs off main thread — does NOT block UI
    final rgba = await compute(_convertInIsolate, args);

    // Create ui.Image from raw RGBA bytes (must be on main thread)
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  } catch (e) {
    if (kDebugMode) {
      return null;
    }
  }
  return null;
}

String _detectFormat(CameraImage image) {
  final name = image.format.group.name.toLowerCase();
  if (name.contains('yuv') || name.contains('420')) return 'yuv420';
  if (name.contains('nv21')) return 'nv21';
  if (name.contains('bgra') || name.contains('32bgra')) return 'bgra8888';
  // Default guess by plane count
  if (image.planes.length == 3) return 'yuv420';
  if (image.planes.length == 2) return 'nv21';
  return 'bgra8888';
}
