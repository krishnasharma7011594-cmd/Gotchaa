import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/permissions/permission_manager.dart';

import '../../../create/presentation/screens/post_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ISOLATE WORKER — processes YUV → RGBA on a background thread
// ─────────────────────────────────────────────────────────────────────────────

class _IsolateMsg {
  _IsolateMsg({
    required this.width,
    required this.height,
    required this.format,
    required this.planes,
    required this.strides,
    required this.pixelStrides,
    required this.replyPort,
  });
  final int width;
  final int height;
  final String format;
  final List<Uint8List> planes;
  final List<int> strides;
  final List<int?> pixelStrides;
  final SendPort replyPort;
}

void _isolateEntry(SendPort mainSend) {
  final recv = ReceivePort();
  mainSend.send(recv.sendPort);

  recv.listen((msg) {
    if (msg is! _IsolateMsg) return;
    try {
      final w = msg.width;
      final h = msg.height;
      final rgba = Uint8List(w * h * 4);

      if (msg.format == 'bgra8888') {
        // Already BGRA — convert to RGBA by swapping B and R
        final src = msg.planes[0];
        for (int i = 0; i < w * h; i++) {
          final o = i * 4;
          rgba[o] = src[o + 2]; // R
          rgba[o + 1] = src[o + 1]; // G
          rgba[o + 2] = src[o]; // B
          rgba[o + 3] = 255;
        }
        msg.replyPort.send(rgba);
        return;
      }

      // YUV420 / NV21 path
      if (msg.planes.length < 3) {
        msg.replyPort.send(null);
        return;
      }

      final yBytes = msg.planes[0];
      final uBytes = msg.planes[1];
      final vBytes = msg.planes[2];
      final yStride = msg.strides[0];
      final uvStride = msg.strides[1];
      final uvPixelStride = msg.pixelStrides[1] ?? 1;

      for (int row = 0; row < h; row++) {
        final yRowOff = row * yStride;
        final rgbaOff = row * w * 4;
        final uvRowOff = (row >> 1) * uvStride;

        for (int col = 0; col < w; col++) {
          final yIdx = yRowOff + col;
          final uvIdx = uvRowOff + (col >> 1) * uvPixelStride;

          if (yIdx >= yBytes.length ||
              uvIdx >= uBytes.length ||
              uvIdx >= vBytes.length) continue;

          final Y = yBytes[yIdx];
          final U = uBytes[uvIdx];
          final V = vBytes[uvIdx];

          final yPart = (Y - 16) * 1.164;
          final uSub = U - 128;
          final vSub = V - 128;

          final r = (yPart + vSub * 1.596).round().clamp(0, 255);
          final g = (yPart - uSub * 0.392 - vSub * 0.813).round().clamp(0, 255);
          final b = (yPart + uSub * 2.017).round().clamp(0, 255);

          final o = rgbaOff + col * 4;
          rgba[o] = r;
          rgba[o + 1] = g;
          rgba[o + 2] = b;
          rgba[o + 3] = 255;
        }
      }
      msg.replyPort.send(rgba);
    } catch (e) {
      msg.replyPort.send(null);
    }
  });
}

class IsolateWorker {
  static SendPort? _sendPort;
  static Isolate? _isolate;
  static bool _ready = false;

  static Future<void> start() async {
    if (_ready) return;
    final recv = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, recv.sendPort);
    recv.listen((msg) {
      if (msg is SendPort) {
        _sendPort = msg;
        _ready = true;
      }
    });
    // Wait up to 3 seconds for isolate to be ready
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (!_ready && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  static Future<ui.Image?> process(CameraImage image) async {
    if (!_ready || _sendPort == null) return null;

    final replyPort = ReceivePort();
    _sendPort!.send(_IsolateMsg(
      width: image.width,
      height: image.height,
      format: image.format.group.name,
      planes: image.planes.map((p) => Uint8List.fromList(p.bytes)).toList(),
      strides: image.planes.map((p) => p.bytesPerRow).toList(),
      pixelStrides: image.planes.map((p) => p.bytesPerPixel).toList(),
      replyPort: replyPort.sendPort,
    ));

    final response = await replyPort.first
        .timeout(const Duration(seconds: 2), onTimeout: () => null);
    replyPort.close();

    if (response is! Uint8List) return null;

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      response,
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  static void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _ready = false;
    _sendPort = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────────

enum FilterType {
  normal,
  noir,
  golden,
  arctic,
  vivid,
  faded,
  warm,
  cool,
  retro,
  drama,
  pastel,
  neon,
  vintage,
}

const _filterNames = {
  FilterType.normal: 'Normal',
  FilterType.noir: 'Noir',
  FilterType.golden: 'Golden',
  FilterType.arctic: 'Arctic',
  FilterType.vivid: 'Vivid',
  FilterType.faded: 'Faded',
  FilterType.warm: 'Warm',
  FilterType.cool: 'Cool',
  FilterType.retro: 'Retro',
  FilterType.drama: 'Drama',
  FilterType.pastel: 'Pastel',
  FilterType.neon: 'Neon',
  FilterType.vintage: 'Vintage',
};

const _filterEmojis = {
  FilterType.normal: '🎥',
  FilterType.noir: '⬛',
  FilterType.golden: '🌅',
  FilterType.arctic: '❄️',
  FilterType.vivid: '🌈',
  FilterType.faded: '🌫️',
  FilterType.warm: '🔥',
  FilterType.cool: '🫐',
  FilterType.retro: '📼',
  FilterType.drama: '🎭',
  FilterType.pastel: '🍬',
  FilterType.neon: '💡',
  FilterType.vintage: '📷',
};

Paint _buildFilterPaint(FilterType type) {
  final p = Paint();
  List<double>? matrix;
  switch (type) {
    case FilterType.noir:
      matrix = [
        0.33,
        0.33,
        0.33,
        0,
        0,
        0.33,
        0.33,
        0.33,
        0,
        0,
        0.33,
        0.33,
        0.33,
        0,
        0,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.golden:
      matrix = [
        1.2,
        0,
        0,
        0,
        15,
        0,
        1.05,
        0,
        0,
        5,
        0,
        0,
        0.8,
        0,
        0,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.arctic:
      matrix = [
        0.85,
        0,
        0,
        0,
        0,
        0,
        1.1,
        0,
        0,
        5,
        0,
        0,
        1.3,
        0,
        10,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.vivid:
      matrix = [
        1.3,
        0,
        0,
        0,
        0,
        0,
        1.3,
        0,
        0,
        0,
        0,
        0,
        1.3,
        0,
        0,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.faded:
      matrix = [
        0.85,
        0,
        0,
        0,
        30,
        0,
        0.85,
        0,
        0,
        30,
        0,
        0,
        0.85,
        0,
        35,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.warm:
      matrix = [
        1.3,
        0,
        0,
        0,
        10,
        0,
        1.0,
        0,
        0,
        0,
        0,
        0,
        0.7,
        0,
        -10,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.cool:
      matrix = [
        0.8,
        0,
        0,
        0,
        -10,
        0,
        1.0,
        0,
        0,
        0,
        0,
        0,
        1.3,
        0,
        10,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.retro:
      matrix = [
        1.2,
        0,
        0,
        0,
        10,
        0,
        0.9,
        0,
        0,
        5,
        0,
        0,
        0.6,
        0,
        0,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.drama:
      matrix = [
        1.4,
        0,
        0,
        0,
        -20,
        0,
        1.2,
        0,
        0,
        -10,
        0,
        0,
        1.0,
        0,
        -5,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.pastel:
      matrix = [
        0.8,
        0,
        0,
        0,
        50,
        0,
        0.8,
        0,
        0,
        50,
        0,
        0,
        0.8,
        0,
        60,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.neon:
      matrix = [
        1.5,
        0,
        0,
        0,
        0,
        0,
        1.5,
        0,
        0,
        0,
        0,
        0,
        2.0,
        0,
        0,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.vintage:
      matrix = [
        1.1,
        0.1,
        0,
        0,
        10,
        0,
        0.9,
        0.1,
        0,
        5,
        0,
        0.1,
        0.7,
        0,
        0,
        0,
        0,
        0,
        1,
        0
      ];
      break;
    case FilterType.normal:
      break;
  }
  if (matrix != null) {
    p.colorFilter = ColorFilter.matrix(matrix);
  }
  return p;
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMERA PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _CameraPainter extends CustomPainter {
  _CameraPainter({
    required this.frame,
    required this.sensorOrientation,
    required this.isFront,
    required this.filter,
  });
  final ui.Image? frame;
  final int sensorOrientation;
  final bool isFront;
  final FilterType filter;

  @override
  void paint(Canvas canvas, Size size) {
    // Always fill black background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    if (frame == null) return;

    final imgW = frame!.width.toDouble();
    final imgH = frame!.height.toDouble();

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    // Rotate
    final angle = sensorOrientation * math.pi / 180.0;
    canvas.rotate(angle);

    // Mirror front camera
    if (isFront) canvas.scale(-1, 1);

    // Scale to fill
    double drawW, drawH;
    if (sensorOrientation == 90 || sensorOrientation == 270) {
      drawW = imgH;
      drawH = imgW;
    } else {
      drawW = imgW;
      drawH = imgH;
    }
    final scale = math.max(size.width / drawW, size.height / drawH);
    canvas.scale(scale);

    // Draw frame with filter
    final paint = _buildFilterPaint(filter);
    canvas.drawImage(frame!, Offset(-imgW / 2, -imgH / 2), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CameraPainter old) =>
      old.frame != frame || old.filter != filter;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CameraFilterScreen extends StatefulWidget {
  const CameraFilterScreen({super.key});

  @override
  State<CameraFilterScreen> createState() => _CameraFilterScreenState();
}

class _CameraFilterScreenState extends State<CameraFilterScreen>
    with WidgetsBindingObserver {
  CameraController? _ctrl;
  List<CameraDescription> _cameras = [];

  // State
  bool _isInitializing = true;
  String? _errorMessage;
  FilterType _activeFilter = FilterType.normal;
  bool _isCapturing = false;
  bool _isFrontCamera = false;

  // Frame
  ui.Image? _currentFrame;
  bool _isProcessingFrame = false;
  int _lastFrameTime = 0;
  static const _frameIntervalMs = 33; // ~30fps cap

  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _stopStream();
    } else if (state == AppLifecycleState.resumed) {
      _startStream();
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // 1. Request permissions
      final camGranted =
          await PermissionManager.requestCameraPermission(context);
      if (!camGranted) {
        throw Exception(
            'Camera permission denied. Please enable it in Settings.');
      }

      // 2. Get cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras found on this device.');
      }

      // 3. Start isolate
      await IsolateWorker.start();

      // 4. Init controller
      await _initCamera(_cameras.first);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _initCamera(CameraDescription cam) async {
    // Dispose of the old controller safely
    final old = _ctrl;
    _ctrl = null;
    if (old != null) {
      try {
        await old.stopImageStream();
      } catch (_) {}
      await old.dispose();
    }

    final controller = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
    } catch (e) {
      await controller.dispose();
      throw Exception('Camera init failed: $e');
    }

    _ctrl = controller;
    _isFrontCamera = cam.lensDirection == CameraLensDirection.front;

    await _startStream();

    if (mounted) setState(() => _isInitializing = false);
  }

  Future<void> _startStream() async {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (_ctrl!.value.isStreamingImages) return;

    try {
      await _ctrl!.startImageStream(_onFrame);
    } catch (e) {}
  }

  Future<void> _stopStream() async {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (!_ctrl!.value.isStreamingImages) return;
    try {
      await _ctrl!.stopImageStream();
    } catch (e) {}
  }

  void _onFrame(CameraImage image) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_isProcessingFrame || now - _lastFrameTime < _frameIntervalMs) return;

    _isProcessingFrame = true;
    _lastFrameTime = now;

    IsolateWorker.process(image).then((img) {
      if (img != null && mounted) {
        setState(() => _currentFrame = img);
      }
      _isProcessingFrame = false;
    }).catchError((e) {
      _isProcessingFrame = false;
    });
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _isInitializing = true);
    final next = _isFrontCamera ? _cameras.first : _cameras.last;
    try {
      await _initCamera(next);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Failed to flip camera: $e';
        });
      }
    }
  }

  Future<void> _capture() async {
    if (_isCapturing || _currentFrame == null) return;
    setState(() => _isCapturing = true);

    try {
      // Capture the rendered canvas (not the raw frame)
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/gotcha_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        await _stopStream();
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  PostDetailsScreen(mediaFile: file, isVideo: false)),
        );
        await _startStream();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Capture failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopStream().then((_) => _ctrl?.dispose());
    IsolateWorker.dispose();
    super.dispose();
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Camera view
            RepaintBoundary(
              key: _repaintKey,
              child: CustomPaint(
                painter: _CameraPainter(
                  frame: _currentFrame,
                  sensorOrientation: _ctrl?.description.sensorOrientation ?? 90,
                  isFront: _isFrontCamera,
                  filter: _activeFilter,
                ),
                size: Size.infinite,
              ),
            ),

            // Loading overlay
            if (_isInitializing)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.cyanAccent),
                      const SizedBox(height: 20),
                      Text('Starting camera…',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),

            // Error overlay
            if (_errorMessage != null)
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        color: Colors.red, size: 72),
                    const SizedBox(height: 24),
                    Text(_errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _initialize,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    const TextButton(
                      onPressed: openAppSettings,
                      child: Text('Open Settings',
                          style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ),
              ),

            // Controls (only shown when camera is live)
            if (!_isInitializing && _errorMessage == null) ...[
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _iconBtn(Icons.close, () => Navigator.pop(context)),
                        Text('GOTCHAA',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3)),
                        _iconBtn(Icons.flip_camera_android, _flipCamera),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _filterCarousel(),
                      const SizedBox(height: 24),
                      _captureRow(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );

  Widget _filterCarousel() {
    const filters = FilterType.values;
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (ctx, i) {
          final f = filters[i];
          final isActive = f == _activeFilter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? Colors.cyanAccent : Colors.white24,
                  width: isActive ? 2.5 : 1,
                ),
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF00FFFF), Color(0xFF007AFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Colors.black45, Colors.black26],
                      ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_filterEmojis[f] ?? '🎥',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    _filterNames[f] ?? '',
                    style: GoogleFonts.outfit(
                      color: isActive ? Colors.black : Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _captureRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _isCapturing ? null : _capture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: _isCapturing ? 72 : 80,
              height: _isCapturing ? 72 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: Colors.cyanAccent, strokeWidth: 3),
                    )
                  : const Icon(Icons.circle, color: Colors.white, size: 62),
            ),
          ),
        ],
      );
}
