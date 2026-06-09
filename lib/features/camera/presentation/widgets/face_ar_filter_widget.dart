import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum ARFilterType {
  dogFace,
  flowerCrown,
  animeEyes,
  neonFacePaint,
  goldenGlow,
  glitchFace,
  devilHorns,
  sunglasses,
  beautySmooth, // Note: Gaussian blur in CustomPainter is expensive; use BackdropFilter masking for performance
  ageFilter
}

class FaceARFilterWidget extends StatefulWidget {
  const FaceARFilterWidget({
    required this.controller,
    super.key,
    this.activeFilter = ARFilterType.neonFacePaint,
  });
  final CameraController controller;
  final ARFilterType activeFilter;

  @override
  State<FaceARFilterWidget> createState() => _FaceARFilterWidgetState();
}

class _FaceARFilterWidgetState extends State<FaceARFilterWidget> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isProcessingImage = false;
  List<Face> _faces = [];
  Size? _imageSize;
  InputImageRotation? _imageRotation;

  @override
  void initState() {
    super.initState();
    _startFaceDetection();
  }

  void _startFaceDetection() {
    widget.controller.startImageStream((image) async {
      if (_isProcessingImage) return;
      _isProcessingImage = true;

      try {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final Size imageSize =
            Size(image.width.toDouble(), image.height.toDouble());
        final imageRotation = InputImageRotationValue.fromRawValue(
                widget.controller.description.sensorOrientation) ??
            InputImageRotation.rotation0deg;

        final inputImageData = InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        );

        final inputImage =
            InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
        final faces = await _faceDetector.processImage(inputImage);

        if (mounted) {
          setState(() {
            _faces = faces;
            _imageSize = imageSize;
            _imageRotation = imageRotation;
          });
        }
      } finally {
        _isProcessingImage = false;
      }
    });
  }

  @override
  void dispose() {
    _faceDetector.close();
    widget.controller.stopImageStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(widget.controller),
          if (_faces.isNotEmpty && _imageSize != null)
            CustomPaint(
              painter: FaceFilterPainter(
                faces: _faces,
                imageSize: _imageSize!,
                rotation: _imageRotation!,
                filterType: widget.activeFilter,
              ),
            ),
        ],
      );
}

class FaceFilterPainter extends CustomPainter {
  FaceFilterPainter({
    required this.faces,
    required this.imageSize,
    required this.rotation,
    required this.filterType,
  });
  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final ARFilterType filterType;

  @override
  void paint(Canvas canvas, Size size) {
    // Math to scale ML Kit coordinates to preview screen size
    final double scaleX = size.width /
        (rotation == InputImageRotation.rotation90deg ||
                rotation == InputImageRotation.rotation270deg
            ? imageSize.height
            : imageSize.width);
    final double scaleY = size.height /
        (rotation == InputImageRotation.rotation90deg ||
                rotation == InputImageRotation.rotation270deg
            ? imageSize.width
            : imageSize.height);

    double translateX(double x) => x * scaleX;
    double translateY(double y) => y * scaleY;

    for (final Face face in faces) {
      final Rect boundingBox = Rect.fromLTRB(
        translateX(face.boundingBox.left),
        translateY(face.boundingBox.top),
        translateX(face.boundingBox.right),
        translateY(face.boundingBox.bottom),
      );

      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final noseBase = face.landmarks[FaceLandmarkType.noseBase];
      final faceContour = face.contours[FaceContourType.face];

      switch (filterType) {
        case ARFilterType.neonFacePaint:
          _drawNeonFacePaint(canvas, faceContour, translateX, translateY);
          break;
        case ARFilterType.goldenGlow:
          _drawGoldenGlow(canvas, boundingBox);
          break;
        case ARFilterType.animeEyes:
          if (leftEye != null && rightEye != null) {
            _drawAnimeEyes(canvas, leftEye.position, rightEye.position,
                translateX, translateY, boundingBox.width);
          }
          break;
        case ARFilterType.dogFace:
          if (noseBase != null) {
            _drawDogFace(
                canvas, noseBase.position, boundingBox, translateX, translateY);
          }
          break;
        case ARFilterType.flowerCrown:
          _drawFlowerCrown(canvas, boundingBox);
          break;
        case ARFilterType.devilHorns:
          _drawDevilHorns(canvas, boundingBox);
          break;
        case ARFilterType.sunglasses:
          if (leftEye != null && rightEye != null) {
            _drawSunglasses(canvas, leftEye.position, rightEye.position,
                translateX, translateY);
          }
          break;
        case ARFilterType.glitchFace:
          _drawGlitchFace(canvas, boundingBox);
          break;
        // Beauty Smooth and Age Filter require image manipulation plugins or Shaders.
        // For here, we simulate it via a mesh overlay or a tint.
        case ARFilterType.beautySmooth:
          _drawBeautySmooth(canvas, boundingBox);
          break;
        case ARFilterType.ageFilter:
          _drawAgeFilter(canvas, boundingBox);
          break;
      }
    }
  }

  void _drawNeonFacePaint(
      Canvas canvas, FaceContour? contour, Function trX, Function trY) {
    if (contour == null) return;
    final path = Path();
    for (int i = 0; i < contour.points.length; i++) {
      final p = contour.points[i];
      if (i == 0) {
        path.moveTo(trX(p.x.toDouble()), trY(p.y.toDouble()));
      } else {
        path.lineTo(trX(p.x.toDouble()), trY(p.y.toDouble()));
      }
    }

    // Outer glow
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    // Inner core line
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  void _drawAnimeEyes(Canvas canvas, Point<int> left, Point<int> right,
      Function trX, Function trY, double faceWidth) {
    final radius = faceWidth * 0.15; // Enlarged eyes
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Colors.deepPurple, Colors.black],
        stops: [0.1, 0.6, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(trX(left.x), trY(left.y)), radius: radius));

    canvas.drawCircle(
        Offset(trX(left.x.toDouble()), trY(left.y.toDouble())), radius, paint);
    canvas.drawCircle(Offset(trX(right.x.toDouble()), trY(right.y.toDouble())),
        radius, paint);

    // Sparkles
    final sparkle = Paint()..color = Colors.white;
    canvas.drawCircle(
        Offset(trX(left.x.toDouble()) + radius * 0.3,
            trY(left.y.toDouble()) - radius * 0.3),
        radius * 0.2,
        sparkle);
    canvas.drawCircle(
        Offset(trX(right.x.toDouble()) + radius * 0.3,
            trY(right.y.toDouble()) - radius * 0.3),
        radius * 0.2,
        sparkle);
  }

  void _drawGoldenGlow(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.amber.withOpacity(0.4), Colors.amber.withOpacity(0)],
      ).createShader(bounds)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(bounds.inflate(50), paint);
  }

  // Example placeholder for asset rendering using path/shapes.
  // In production, use `drawImage` or `FlutterAnimate` with positioned widgets.
  void _drawDogFace(
      Canvas canvas, Point<int> nose, Rect bounds, Function trX, Function trY) {
    // Nose dog
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(trX(nose.x.toDouble()), trY(nose.y.toDouble())),
            width: 40,
            height: 30),
        Paint()..color = Colors.black87);
    // Ears logic depends on bounding box top-left and top-right
  }

  void _drawFlowerCrown(Canvas canvas, Rect bounds) {
    // Draw a series of colorful circles as "flowers" above the bounding box
    final y = bounds.top - 20;
    final spacing = bounds.width / 5;
    final colors = [
      Colors.pink,
      Colors.yellow,
      Colors.cyan,
      Colors.purple,
      Colors.red
    ];
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(bounds.left + (i * spacing), y), 15,
          Paint()..color = colors[i]);
    }
  }

  void _drawDevilHorns(Canvas canvas, Rect bounds) {
    // Custom paths for horns at top corners of the face box
    final y = bounds.top;
    final leftX = bounds.left + bounds.width * 0.2;
    final rightX = bounds.right - bounds.width * 0.2;

    // Draw simple red triangles
    final pLeft = Path()
      ..moveTo(leftX - 15, y)
      ..lineTo(leftX + 15, y)
      ..lineTo(leftX, y - 50)
      ..close();
    final pRight = Path()
      ..moveTo(rightX - 15, y)
      ..lineTo(rightX + 15, y)
      ..lineTo(rightX, y - 50)
      ..close();

    canvas.drawPath(pLeft, Paint()..color = Colors.redAccent);
    canvas.drawPath(pRight, Paint()..color = Colors.redAccent);
  }

  void _drawSunglasses(Canvas canvas, Point<int> lEye, Point<int> rEye,
      Function trX, Function trY) {
    final leftCenter = Offset(trX(lEye.x.toDouble()), trY(lEye.y.toDouble()));
    final rightCenter = Offset(trX(rEye.x.toDouble()), trY(rEye.y.toDouble()));
    final dist = (rightCenter.dx - leftCenter.dx).abs() * 1.5;

    final paint = Paint()..color = Colors.black87;
    canvas.drawRect(
        Rect.fromCenter(center: leftCenter, width: dist, height: dist * 0.6),
        paint);
    canvas.drawRect(
        Rect.fromCenter(center: rightCenter, width: dist, height: dist * 0.6),
        paint);
    canvas.drawLine(
        leftCenter,
        rightCenter,
        Paint()
          ..color = Colors.black
          ..strokeWidth = 4);
  }

  void _drawGlitchFace(Canvas canvas, Rect bounds) {
    // Simulate split channel by drawing random lines across the face area
    final random = Random();
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.5)
      ..strokeWidth = 2;
    final paint2 = Paint()
      ..color = Colors.redAccent.withOpacity(0.5)
      ..strokeWidth = 2;

    for (int i = 0; i < 10; i++) {
      final y = bounds.top + random.nextDouble() * bounds.height;
      canvas.drawLine(Offset(bounds.left - 20, y), Offset(bounds.right + 20, y),
          (i % 2 == 0) ? paint : paint2);
    }
  }

  void _drawBeautySmooth(Canvas canvas, Rect bounds) {
    // In a real app, you would pass the image texture to a blur shader.
    // We simulate a light blurring overlay here.
    canvas.drawOval(
        bounds,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
  }

  void _drawAgeFilter(Canvas canvas, Rect bounds) {
    // Add a slight darkened/grey texture over the face area
    canvas.drawOval(bounds, Paint()..color = Colors.grey.withOpacity(0.2));
    // Add fake wrinkles (lines)
    canvas.drawLine(
        Offset(bounds.left + 10, bounds.top + 30),
        Offset(bounds.right - 10, bounds.top + 30),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(FaceFilterPainter oldDelegate) => true;
}
