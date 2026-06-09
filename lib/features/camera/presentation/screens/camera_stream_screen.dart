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
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gotchaa/core/permissions/permission_manager.dart';

import '../../../create/presentation/screens/post_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ISOLATE — converts raw YUV bytes (not CameraImage!) to RGBA
// CameraImage itself CANNOT be sent across isolates — only its extracted bytes.
// ─────────────────────────────────────────────────────────────────────────────

class _FramePayload {

  _FramePayload({
    required this.width,
    required this.height,
    required this.format,
    required this.planes,
    required this.strides,
    required this.pixelStrides,
    required this.reply,
  });
  final int width;
  final int height;
  final String format; // 'yuv420' | 'bgra8888' | 'nv21'
  final List<Uint8List> planes;
  final List<int> strides;
  final List<int?> pixelStrides;
  final SendPort reply;
}

void _workerMain(SendPort mainPort) {
  final recv = ReceivePort();
  mainPort.send(recv.sendPort);

  recv.listen((msg) {
    if (msg is! _FramePayload) return;

    try {
      final w = msg.width;
      final h = msg.height;
      final rgba = Uint8List(w * h * 4);

      if (msg.format == 'bgra8888') {
        // BGRA → RGBA (swap R and B)
        final src = msg.planes[0];
        for (int i = 0; i < w * h; i++) {
          final o = i * 4;
          rgba[o]     = src[o + 2]; // R ← B-channel
          rgba[o + 1] = src[o + 1]; // G
          rgba[o + 2] = src[o];     // B ← R-channel
          rgba[o + 3] = 255;
        }
        msg.reply.send(rgba);
        return;
      }

      // YUV420 / NV21
      if (msg.planes.length < 3) { msg.reply.send(null); return; }

      final yB = msg.planes[0];
      final uB = msg.planes[1];
      final vB = msg.planes[2];
      final yS = msg.strides[0];
      final uvS = msg.strides[1];
      final uvP = msg.pixelStrides[1] ?? 1;

      for (int row = 0; row < h; row++) {
        final yRow   = row * yS;
        final rgbaRow = row * w * 4;
        final uvRow  = (row >> 1) * uvS;

        for (int col = 0; col < w; col++) {
          final yi  = yRow + col;
          final uvi = uvRow + (col >> 1) * uvP;

          if (yi >= yB.length || uvi >= uB.length || uvi >= vB.length) continue;

          final Y = yB[yi];
          final U = uB[uvi];
          final V = vB[uvi];

          final yp = (Y - 16) * 1.164;
          final us = U - 128;
          final vs = V - 128;

          final r = (yp + vs * 1.596).round().clamp(0, 255);
          final g = (yp - us * 0.392 - vs * 0.813).round().clamp(0, 255);
          final b = (yp + us * 2.017).round().clamp(0, 255);

          final o = rgbaRow + col * 4;
          rgba[o]     = r;
          rgba[o + 1] = g;
          rgba[o + 2] = b;
          rgba[o + 3] = 255;
        }
      }
      msg.reply.send(rgba);
    } catch (_) {
      msg.reply.send(null);
    }
  });
}

/// Extracts sendable byte copies from a CameraImage and sends to the isolate.
/// CameraImage itself must NEVER be sent across isolates.
class _FrameProcessor {
  static SendPort? _port;
  static Isolate? _iso;
  static bool _ready = false;

  static Future<void> start() async {
    if (_ready) return;
    final recv = ReceivePort();
    _iso = await Isolate.spawn(_workerMain, recv.sendPort);
    recv.listen((m) { if (m is SendPort) { _port = m; _ready = true; } });
    // Wait for handshake
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!_ready && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  static Future<ui.Image?> process(CameraImage img) async {
    if (!_ready || _port == null) return null;
    final reply = ReceivePort();

    // ✅ Extract bytes BEFORE sending — CameraImage cannot cross isolate boundary
    final planes = img.planes
        .map((p) => Uint8List.fromList(p.bytes))
        .toList();
    final strides = img.planes.map((p) => p.bytesPerRow).toList();
    final pixelStrides = img.planes.map((p) => p.bytesPerPixel).toList();

    _port!.send(_FramePayload(
      width: img.width,
      height: img.height,
      format: img.format.group.name,
      planes: planes,
      strides: strides,
      pixelStrides: pixelStrides,
      reply: reply.sendPort,
    ));

    final result = await reply.first
        .timeout(const Duration(seconds: 2), onTimeout: () => null);
    reply.close();

    if (result is! Uint8List) return null;

    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      result, img.width, img.height, ui.PixelFormat.rgba8888,
      c.complete,
    );
    return c.future;
  }

  static void dispose() {
    _iso?.kill(priority: Isolate.immediate);
    _iso = null; _port = null; _ready = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTERS — pure enum + stateless ColorFilter matrix approach
// ─────────────────────────────────────────────────────────────────────────────

enum CameraFilter {
  normal, noir, golden, arctic, vivid, faded,
  warm, cool, retro, drama, pastel, neon, vintage,
}

const _filterLabel = {
  CameraFilter.normal: 'Normal',  CameraFilter.noir: 'Noir',
  CameraFilter.golden: 'Golden',  CameraFilter.arctic: 'Arctic',
  CameraFilter.vivid: 'Vivid',    CameraFilter.faded: 'Faded',
  CameraFilter.warm: 'Warm',      CameraFilter.cool: 'Cool',
  CameraFilter.retro: 'Retro',    CameraFilter.drama: 'Drama',
  CameraFilter.pastel: 'Pastel',  CameraFilter.neon: 'Neon',
  CameraFilter.vintage: 'Vintage',
};

const _filterEmoji = {
  CameraFilter.normal: '🎥',  CameraFilter.noir: '⬛',
  CameraFilter.golden: '🌅',  CameraFilter.arctic: '❄️',
  CameraFilter.vivid: '🌈',   CameraFilter.faded: '🌫️',
  CameraFilter.warm: '🔥',    CameraFilter.cool: '🫐',
  CameraFilter.retro: '📼',   CameraFilter.drama: '🎭',
  CameraFilter.pastel: '🍬',  CameraFilter.neon: '💡',
  CameraFilter.vintage: '📷',
};

ColorFilter? _colorFilterFor(CameraFilter f) {
  List<double>? m;
  switch (f) {
    case CameraFilter.noir:
      m = [.33,.33,.33,0,0, .33,.33,.33,0,0, .33,.33,.33,0,0, 0,0,0,1,0];
    case CameraFilter.golden:
      m = [1.2,0,0,0,15, 0,1.05,0,0,5, 0,0,.8,0,0, 0,0,0,1,0];
    case CameraFilter.arctic:
      m = [.85,0,0,0,0, 0,1.1,0,0,5, 0,0,1.3,0,10, 0,0,0,1,0];
    case CameraFilter.vivid:
      m = [1.3,0,0,0,0, 0,1.3,0,0,0, 0,0,1.3,0,0, 0,0,0,1,0];
    case CameraFilter.faded:
      m = [.85,0,0,0,30, 0,.85,0,0,30, 0,0,.85,0,35, 0,0,0,1,0];
    case CameraFilter.warm:
      m = [1.3,0,0,0,10, 0,1.0,0,0,0, 0,0,0.7,0,-10, 0,0,0,1,0];
    case CameraFilter.cool:
      m = [.8,0,0,0,-10, 0,1.0,0,0,0, 0,0,1.3,0,10, 0,0,0,1,0];
    case CameraFilter.retro:
      m = [1.2,0,0,0,10, 0,.9,0,0,5, 0,0,.6,0,0, 0,0,0,1,0];
    case CameraFilter.drama:
      m = [1.4,0,0,0,-20, 0,1.2,0,0,-10, 0,0,1.0,0,-5, 0,0,0,1,0];
    case CameraFilter.pastel:
      m = [.8,0,0,0,50, 0,.8,0,0,50, 0,0,.8,0,60, 0,0,0,1,0];
    case CameraFilter.neon:
      m = [1.5,0,0,0,0, 0,1.5,0,0,0, 0,0,2.0,0,0, 0,0,0,1,0];
    case CameraFilter.vintage:
      m = [1.1,.1,0,0,10, 0,.9,.1,0,5, 0,.1,.7,0,0, 0,0,0,1,0];
    default:
      return null;
  }
  return ColorFilter.matrix(m);
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMERA PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _LivePainter extends CustomPainter {

  _LivePainter(this.frame, this.sensorOrientation, this.isFront, this.filter);
  final ui.Image? frame;
  final int sensorOrientation;
  final bool isFront;
  final CameraFilter filter;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    if (frame == null) return;

    final iw = frame!.width.toDouble();
    final ih = frame!.height.toDouble();

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    // ✅ Correct Android Camera2 rotation formula:
    // Back camera:  rotate by sensorOrientation
    // Front camera: rotate by (360 - sensorOrientation) % 360
    // This is the standard compensation used by Camera2/CameraX APIs.
    // Without this, front cameras with sensorOrientation=270 (Nothing, Pixel,
    // Samsung) appear 180° upside down.
    final int effectiveOrientation = isFront
        ? (360 - sensorOrientation) % 360
        : sensorOrientation;

    canvas.rotate(effectiveOrientation * math.pi / 180.0);

    // Mirror front camera horizontally (selfie flip)
    if (isFront) canvas.scale(-1, 1);

    final drawW = (effectiveOrientation == 90 || effectiveOrientation == 270) ? ih : iw;
    final drawH = (effectiveOrientation == 90 || effectiveOrientation == 270) ? iw : ih;
    final scale = math.max(size.width / drawW, size.height / drawH);
    canvas.scale(scale);

    final paint = Paint();
    final cf = _colorFilterFor(filter);
    if (cf != null) paint.colorFilter = cf;
    canvas.drawImage(frame!, Offset(-iw / 2, -ih / 2), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LivePainter old) =>
      old.frame != frame || old.filter != filter;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CameraStreamScreen extends StatefulWidget {
  const CameraStreamScreen({super.key});
  @override
  State<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen>
    with WidgetsBindingObserver {
  CameraController? _ctrl;
  bool _initializing = true;
  String? _error;
  bool _isFront = false;
  List<CameraDescription> _cameras = [];

  ui.Image? _frame;
  bool _busy = false;
  int _lastMs = 0;
  static const _targetMs = 33; // ~30 fps cap

  CameraFilter _filter = CameraFilter.normal;
  bool _capturing = false;
  final ImagePicker _picker = ImagePicker();

  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.inactive) _stopStream();
    if (s == AppLifecycleState.resumed) _startStream();
  }

  // ── init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    if (!mounted) return;
    setState(() { _initializing = true; _error = null; });
    try {
      // Camera permission
      final camGranted = await PermissionManager.requestCameraPermission(context);
      if (!camGranted) throw Exception('Camera permission denied.\nPlease go to Settings → Apps → Gotchaa → Permissions and enable Camera.');

      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('No camera found on this device.');

      await _FrameProcessor.start();
      await _openCamera(_cameras.first);
    } catch (e) {
      if (mounted) setState(() { _initializing = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Future<void> _openCamera(CameraDescription cam) async {
    // Dispose previous safely
    final old = _ctrl;
    _ctrl = null;
    if (old != null) {
      if (old.value.isStreamingImages) {
        try { await old.stopImageStream(); } catch (_) {}
      }
      await old.dispose();
    }

    final c = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await c.initialize();
    } catch (e) {
      await c.dispose();
      throw Exception('Camera failed to start: $e\n\nTry closing other camera apps and retry.');
    }

    _ctrl = c;
    _isFront = cam.lensDirection == CameraLensDirection.front;

    await _startStream();
    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _startStream() async {
    if (_ctrl == null) return;
    if (!_ctrl!.value.isInitialized) return;
    if (_ctrl!.value.isStreamingImages) return;
    try {
      await _ctrl!.startImageStream(_onFrame);
    } catch (e) {
      
    }
  }

  Future<void> _stopStream() async {
    if (_ctrl == null) return;
    if (!_ctrl!.value.isInitialized) return;
    if (!_ctrl!.value.isStreamingImages) return;
    try {
      await _ctrl!.stopImageStream();
    } catch (e) {
      
    }
  }

  void _onFrame(CameraImage img) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_busy || now - _lastMs < _targetMs) return;
    _busy = true;
    _lastMs = now;

    _FrameProcessor.process(img).then((result) {
      if (result != null && mounted) setState(() => _frame = result);
      _busy = false;
    }).catchError((e) {
      
      _busy = false;
    });
  }

  Future<void> _flip() async {
    if (_cameras.length < 2) return;
    setState(() => _initializing = true);
    try {
      final next = _isFront
          ? _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back)
          : _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
      await _openCamera(next);
    } catch (e) {
      if (mounted) setState(() { _initializing = false; _error = 'Flip failed: $e'; });
    }
  }

  Future<void> _capture() async {
    if (_capturing || _frame == null) return;
    setState(() => _capturing = true);
    try {
      await _stopStream();

      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) { await _startStream(); return; }

      final img   = await boundary.toImage(pixelRatio: 3);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) { await _startStream(); return; }

      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/gotcha_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailsScreen(mediaFile: file, isVideo: false),
          ),
        );
      }
    } catch (e) {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      await _startStream();
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? media = await _picker.pickMedia();
      if (media != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailsScreen(
              mediaFile: File(media.path),
              isVideo: media.path.endsWith('.mp4') || media.path.endsWith('.mov'),
            ),
          ),
        );
      }
    } catch (e) {
      
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopStream().then((_) => _ctrl?.dispose());
    _FrameProcessor.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live camera view
          RepaintBoundary(
            key: _repaintKey,
            child: CustomPaint(
              painter: _LivePainter(
                _frame,
                _ctrl?.description.sensorOrientation ?? 90,
                _isFront,
                _filter,
              ),
              size: Size.infinite,
            ),
          ),

          // Loading state
          if (_initializing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: Colors.cyanAccent, strokeWidth: 3),
                    const SizedBox(height: 20),
                    Text('Starting camera…',
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),

          // Error state
          if (_error != null && !_initializing)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off_rounded,
                      color: Color(0xFFFF4D4D), size: 72),
                  const SizedBox(height: 24),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _init,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                  ),
                  const SizedBox(height: 12),
                  const TextButton(
                    onPressed: openAppSettings,
                    child: Text('Open App Settings',
                        style: TextStyle(color: Colors.white38)),
                  ),
                ],
              ),
            ),

          // Camera controls — only when live
          if (!_initializing && _error == null) ...[
            // Top bar
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pill(Icons.close_rounded, onTap: () => Navigator.maybePop(context)),
                      _pill(Icons.flip_camera_android_rounded, onTap: _flip),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _filterRow(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _galleryBtn(),
                            _shutterBtn(),
                            const SizedBox(width: 50), // Spacer for balance
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

  Widget _pill(IconData icon, {required VoidCallback onTap}) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );

  Widget _filterRow() => SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: CameraFilter.values.map((f) {
          final active = f == _filter;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _filter = f); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              width: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? Colors.cyanAccent : Colors.white24,
                  width: active ? 2.5 : 1,
                ),
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0057FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(colors: [Colors.black54, Colors.black38]),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_filterEmoji[f]!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    _filterLabel[f]!,
                    style: GoogleFonts.outfit(
                      color: active ? Colors.black : Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

  Widget _shutterBtn() => GestureDetector(
      onTap: _capturing ? null : _capture,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 78, height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(color: Colors.cyanAccent.withOpacity(0.35),
                blurRadius: 24, spreadRadius: 3),
          ],
        ),
        child: _capturing
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                    color: Colors.cyanAccent, strokeWidth: 3),
              )
            : const Icon(Icons.circle, color: Colors.white, size: 58),
      ),
    );

  Widget _galleryBtn() => GestureDetector(
      onTap: _pickFromGallery,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 26),
      ),
    );
}
