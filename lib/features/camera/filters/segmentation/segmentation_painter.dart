import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import '../filter_manager.dart';

class SegmentationFilterPainter extends CustomPainter {
  SegmentationFilterPainter({
    required this.cameraFrame,
    required this.mask,
    required this.activeBackgroundFilter,
    required this.intensity,
    this.replacementBgImage,
    this.bgShader,
  });
  final ui.Image cameraFrame;
  final SegmentationMask mask;
  final FilterDefinition activeBackgroundFilter;
  final double intensity;

  // Pre-loaded assets depending on the filter (e.g. Space, Beach)
  final ui.Image? replacementBgImage;
  final ui.FragmentShader? bgShader;

  @override
  void paint(Canvas canvas, Size size) {
    // Determine the scaling factors between the ML Kit mask and the screen
    final double scaleX = size.width / mask.width;
    final double scaleY = size.height / mask.height;

    // We draw the scene by iterating over the mask or using a shader if we convert the mask to an alpha texture.
    // For high performance (60fps), iterating pixels in Dart is too slow.
    // Dart equivalent of the standard approach:
    // We compose the UI in layers: Setup Background -> Use BlendMode to cut hole -> Draw foreground on top.

    // Instead, we create a Path of the person to clip the foreground, OR we just use a fragment shader.
    // To do it pure Canvas without a mask-texture shader, we draw the BG, then using saveLayer and BlendMode.

    canvas.save();

    // -------------------------------------
    // 1. DRAW NEW BACKGROUND
    // -------------------------------------
    if (activeBackgroundFilter.id == 'bg_blur') {
      // Draw original frame and apply blur
      canvas.drawImageRect(
          cameraFrame,
          Rect.fromLTWH(0, 0, cameraFrame.width.toDouble(),
              cameraFrame.height.toDouble()),
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()
            ..imageFilter = ui.ImageFilter.blur(
                sigmaX: 10 * intensity, sigmaY: 10 * intensity));
    } else if (activeBackgroundFilter.id == 'bg_colorpop') {
      // Draw desaturated original
      const ColorFilter greyscale = ColorFilter.matrix([
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
      canvas.drawImageRect(
          cameraFrame,
          Rect.fromLTWH(0, 0, cameraFrame.width.toDouble(),
              cameraFrame.height.toDouble()),
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..colorFilter = greyscale);
    } else if (replacementBgImage != null) {
      // Draw the static/animated background image
      canvas.drawImageRect(
          replacementBgImage!,
          Rect.fromLTWH(0, 0, replacementBgImage!.width.toDouble(),
              replacementBgImage!.height.toDouble()),
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint());
    } else if (bgShader != null) {
      // Studio, Cartoon, Underwater etc using Shaders
      bgShader!.setFloat(0, size.width);
      bgShader!.setFloat(1, size.height);
      // (Optional set time uniform if animated)
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..shader = bgShader);
    }

    // -------------------------------------
    // 2. DRAW FOREGROUND (PERSON) USING MASK
    // -------------------------------------
    // WARNING: In production Flutter to reliably use ML Kit Float32 buffer as a mask for images
    // requires converting the MLKit mask buffer to a ui.Image greyscale texture, and applying a ShaderMask.
    // For architectural representation, we assume `maskAsImage` is the converted SegmentationMask.
    // Example: (Pseudo-implementation)
    /*
      canvas.saveLayer(Rect.fromLTWH(0,0,size.width,size.height), Paint());
      // Draw person
      canvas.drawImageRect(cameraFrame, ...);
      // Mask out background
      canvas.drawImageRect(maskAsImage, ..., Paint()..blendMode = BlendMode.dstIn);
      canvas.restore();
    */

    // As a placeholder for the extremely verbose byte array conversion:
    _drawForegroundWithClip(canvas, size);

    canvas.restore();
  }

  void _drawForegroundWithClip(Canvas canvas, Size size) {
    // This assumes the pipeline converts the Float32 mask buffer to a ui.Path (or simpler, an Image mask)
    // The google_ml_kit returns a flat array of confidences.
    // For 60fps performance, you MUST use Isolate or FFI to map `mask.confidences` (Float32List) to an RGBA byte array
    // where A = confidence * 255. Then ui.decodeImageFromPixels to get `ui.Image alphaMask`.

    // Once alphaMask is created:
    // canvas.saveLayer(bounds, Paint());
    // canvas.drawImageRect(cameraFrame, src, dst, Paint());
    // canvas.drawImageRect(alphaMask, src, dst, Paint()..blendMode = BlendMode.dstIn);
    // canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SegmentationFilterPainter oldDelegate) =>
      oldDelegate.cameraFrame != cameraFrame ||
      oldDelegate.intensity != intensity;
}
