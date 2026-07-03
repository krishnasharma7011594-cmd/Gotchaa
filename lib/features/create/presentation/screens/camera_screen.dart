import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../camera/filters/filter_manager.dart';
import '../../../camera/filters/filter_preview_widget.dart';
import '../../../camera/filters/particle/advanced_particle_system.dart';
import '../widgets/ar_overlays_widget.dart';
import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  final FilterManager _filterManager = FilterManager();

  // Face Detection
  late FaceDetector _faceDetector;
  Face? _detectedFace;
  Size? _lastImageSize;
  bool _isProcessing = false;

  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  bool _isFlashOn = false;

  late AnimationController _recordAnimationController;

  @override
  void initState() {
    super.initState();
    _recordAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _setCamera(_selectedCameraIndex);
    }
  }

  Future<void> _setCamera(int index) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    final oldController = _cameraController;
    if (oldController != null) {
      await oldController.dispose();
    }

    final camera = _cameras![index];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();

      // Start Image Stream for Face Detection
      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {}

    if (mounted) setState(() {});
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    HapticFeedback.lightImpact();
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    await _setCamera(_selectedCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    HapticFeedback.lightImpact();
    _isFlashOn = !_isFlashOn;
    await _cameraController!
        .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      _navigateToPreview(File(pickedFile.path), isVideo: true);
    } else {
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img != null) {
        _navigateToPreview(File(img.path), isVideo: false);
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    HapticFeedback.mediumImpact();
    try {
      final file = await _cameraController!.takePicture();
      final isFront = _cameras != null &&
          _cameras!.isNotEmpty &&
          _cameras![_selectedCameraIndex].lensDirection ==
              CameraLensDirection.front;
      _navigateToPreview(File(file.path),
          isVideo: false, isFrontCamera: isFront);
    } catch (e) {}
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _isRecording = true);
    _recordAnimationController.forward();
    try {
      await _cameraController!.startVideoRecording();
    } catch (e) {}
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isRecordingVideo) {
      return;
    }
    setState(() => _isRecording = false);
    _recordAnimationController.reverse();
    try {
      final file = await _cameraController!.stopVideoRecording();
      final isFront = _cameras != null &&
          _cameras!.isNotEmpty &&
          _cameras![_selectedCameraIndex].lensDirection ==
              CameraLensDirection.front;
      _navigateToPreview(File(file.path),
          isVideo: true, isFrontCamera: isFront);
    } catch (e) {}
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final InputImage inputImage = _convertCameraImage(image);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _detectedFace = faces.isNotEmpty ? faces.first : null;
          _lastImageSize =
              Size(image.width.toDouble(), image.height.toDouble());
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  InputImage _convertCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation
          .rotation90deg, // Adjust based on platform/orientation
      format: InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  void _navigateToPreview(File file,
      {required bool isVideo, bool isFrontCamera = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          file: file,
          isVideo: isVideo,
          isFrontCamera: isFrontCamera,
          appliedFilter: _filterManager.activeViral ??
              _filterManager.activeFaceFilter ??
              _filterManager.activeParticle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recordAnimationController.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.electricBlue)),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: _filterManager,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera Preview
            Transform.scale(
              scale: _cameraController!.value.aspectRatio * size.aspectRatio < 1
                  ? 1 /
                      (_cameraController!.value.aspectRatio * size.aspectRatio)
                  : 1,
              child: Center(
                child: CameraPreview(_cameraController!),
              ),
            ),

            // 2. Active Particle Filter Overlay
            if (_filterManager.activeParticle != null)
              AdvancedParticleSystem(
                filter: _filterManager.activeParticle!,
                intensity: _filterManager.globalIntensity,
              ),

            // 3. Viral / Sticker Overlay (with Beauty & Face Tracking)
            if (_filterManager.activeViral != null ||
                _filterManager.globalIntensity > 0)
              AROverlaysWidget(
                filter: _filterManager.activeViral ??
                    _filterManager.allFilters.first, // Default or none
                intensity: _filterManager.globalIntensity,
                face: _detectedFace,
                imageSize: _lastImageSize,
              ),

            // 4. Top Controls
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: Column(
                children: [
                  _buildCircleBtn(Icons.flip_camera_ios_rounded, _toggleCamera),
                  const SizedBox(height: 16),
                  _buildCircleBtn(
                      _isFlashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      _toggleFlash),
                ],
              ),
            ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // 5. Bottom Controls & Filter Selector
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    stops: const [0.6, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Note: passing _cameraController for live preview
                    FilterPreviewWidget(controller: _cameraController),

                    const SizedBox(height: 12),

                    // Capture Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Gallery
                          GestureDetector(
                            onTap: _pickFromGallery,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.white24, width: 1),
                              ),
                              child: const Icon(Icons.photo_library_rounded,
                                  color: Colors.white),
                            ),
                          ),

                          // Capture Button
                          GestureDetector(
                            onTap: _takePicture,
                            onLongPress: _startRecording,
                            onLongPressUp: _stopRecording,
                            child: AnimatedBuilder(
                              animation: _recordAnimationController,
                              builder: (context, child) {
                                final scale = 1.0 +
                                    (_recordAnimationController.value * 0.3);
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 4),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: _isRecording
                                              ? Colors.red
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            if (_isRecording)
                                              BoxShadow(
                                                  color: Colors.red
                                                      .withOpacity(0.5),
                                                  blurRadius: 15,
                                                  spreadRadius: 5)
                                          ]),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Camera Flip (also here for convenience)
                          GestureDetector(
                            onTap: _toggleCamera,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white24, width: 1),
                              ),
                              child: const Icon(Icons.cached_rounded,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      );
}
