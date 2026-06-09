import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../camera/filters/filter_manager.dart';

class VHSScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FilmGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.04);
    final random = Random(42);
    for (int i = 0; i < 2000; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        random.nextDouble() * 1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AROverlaysWidget extends StatelessWidget {
  const AROverlaysWidget(
      {required this.filter,
      required this.intensity,
      super.key,
      this.face,
      this.imageSize});
  final FilterDefinition filter;
  final double intensity;
  final Face? face;
  final Size? imageSize;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. Snapchat-Level Glow & Color Enhancement Layer
        SnapchatBeautyLayer(intensity: intensity),

        // 2. Face Tracking Contours (Optional Debug)
        // ...

        // 3. Specific AR Effects
        _buildFilterSpecificOverlay(size),
      ],
    );
  }

  Widget _buildFilterSpecificOverlay(Size size) {
    // Face-aware positioning with coordinate mapping fixes
    double faceX = size.width / 2;
    double faceY = size.height / 2;
    double faceWidth = 200;

    if (face != null && imageSize != null) {
      final rect = face!.boundingBox;

      // ML Kit coordinates are in image space (usually 720x1280)
      // On Android front camera, X 0 is the RIGHT of the person.
      // We need to mirror if front camera

      double relativeX = (rect.left + rect.width / 2) / imageSize!.height;
      final double relativeY = (rect.top + rect.height / 2) / imageSize!.width;

      // Front camera fix (mirroring)
      relativeX = 1.0 - relativeX;

      faceX = relativeX * size.width;
      faceY = relativeY * size.height;
      faceWidth = (rect.width / imageSize!.width) * size.width;
    }
    switch (filter.id) {
      // --- VIRAL / TRENDING (Category 6) ---
      case 'v_vhs':
        return Stack(
          children: [
            Container(color: Colors.orange.withOpacity(0.1 * intensity)),
            IgnorePointer(
              child: CustomPaint(
                painter: VHSScanlinesPainter(),
                size: Size.infinite,
              ),
            ),
            Positioned(
              bottom: 120,
              left: 20,
              child: Text(
                'REC  •',
                style: GoogleFonts.vt323(
                  color: Colors.redAccent.withOpacity(intensity),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: 20,
              child: Text(
                '12:00 AM',
                style: GoogleFonts.vt323(
                  color: Colors.white.withOpacity(intensity),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        );

      case 'v_glow':
        return const AIGlowUpOverlay();

      case 'v_anime':
        return const AnimeFaceOverlay();

      case 'v_elements':
        return const ElementControlOverlay();

      case 'v_game':
        return const ARGameOverlay();

      case 'v_cyber':
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.cyanAccent.withOpacity(0.5 * intensity),
                width: 4),
          ),
          child: Center(
            child: Container(
              height: 300,
              width: 250,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.6 * intensity),
                    width: 2),
                borderRadius: BorderRadius.circular(150),
                boxShadow: [
                  BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.3 * intensity),
                      blurRadius: 40,
                      spreadRadius: 10)
                ],
              ),
            ),
          ),
        );

      // --- FACE AR (Category 2) ---
      case 'f_fire':
        return Positioned(
          top: faceY - (30 * intensity),
          left: faceX - faceWidth / 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔥',
                  style: TextStyle(fontSize: (faceWidth / 4) * intensity)),
              SizedBox(width: faceWidth / 3),
              Text('🔥',
                  style: TextStyle(fontSize: (faceWidth / 4) * intensity)),
            ],
          ),
        );

      case 'f_crown':
      case 'f_halo':
        return Positioned(
          top: faceY - faceWidth * 0.8,
          left: faceX - faceWidth / 2,
          right: faceX - faceWidth / 2,
          child: Center(
            child: Text(
              filter.id == 'f_crown' ? '👑' : '😇',
              style: TextStyle(fontSize: faceWidth * 0.8 * intensity, shadows: [
                Shadow(
                    color: Colors.yellowAccent.withOpacity(intensity),
                    blurRadius: 20)
              ]),
            ),
          ),
        );

      case 'f_glasses':
        return Positioned(
          top: faceY - (faceWidth / 6),
          left: faceX - faceWidth / 2,
          width: faceWidth,
          child: Center(
            child: Text('🕶️',
                style: TextStyle(fontSize: faceWidth * 0.6 * intensity)),
          ),
        );

      case 'f_eye':
        if (face == null) return const SizedBox.shrink();
        final leftEye = face!.landmarks[FaceLandmarkType.leftEye];
        final rightEye = face!.landmarks[FaceLandmarkType.rightEye];
        if (leftEye == null || rightEye == null) return const SizedBox.shrink();

        final lX = leftEye.position.x * (size.width / imageSize!.width);
        final lY = leftEye.position.y * (size.height / imageSize!.height);
        final rX = rightEye.position.x * (size.width / imageSize!.width);
        final rY = rightEye.position.y * (size.height / imageSize!.height);

        return Stack(
          children: [
            Positioned(
              left: lX - 15,
              top: lY - 15,
              child: _buildEmber(intensity),
            ),
            Positioned(
              left: rX - 15,
              top: rY - 15,
              child: _buildEmber(intensity),
            ),
          ],
        );

      case 'f_glam':
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Colors.pink.withOpacity(0.1 * intensity),
            Colors.transparent
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        );

      case 'f_horns':
        return Positioned(
          top: faceY - faceWidth * 0.5,
          left: faceX - faceWidth / 2,
          width: faceWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('😈',
                  style: TextStyle(fontSize: (faceWidth / 3) * intensity)),
              SizedBox(width: faceWidth / 2),
              Text('😈',
                  style: TextStyle(fontSize: (faceWidth / 3) * intensity)),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmber(double intensity) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
          BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.8 * intensity),
              blurRadius: 15,
              spreadRadius: 5),
          BoxShadow(
              color: Colors.redAccent.withOpacity(0.5 * intensity),
              blurRadius: 25,
              spreadRadius: 2),
        ]),
      );
}

class SnapchatBeautyLayer extends StatelessWidget {
  const SnapchatBeautyLayer({required this.intensity, super.key});
  final double intensity;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // Premium Color Matrix: Pinkish glow, bright highlights, soft shadows
          ColorFiltered(
            colorFilter: ColorFilter.matrix([
              1.25, 0, 0, 0, 25 * intensity, // Red (Skin warmth)
              0, 1.15, 0, 0, 15 * intensity, // Green
              0, 0, 1.2, 0, 20 * intensity, // Blue (Clean look)
              0, 0, 0, 1.0, 0, // Alpha
            ]),
            child: BackdropFilter(
              // Premium Skin Smoothing (Snapchat Soft Focus)
              filter: ui.ImageFilter.blur(
                  sigmaX: 1.2 * intensity, sigmaY: 1.2 * intensity),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Bloom Overlay (Soft Center Glow)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  colors: [
                    Colors.white.withOpacity(0.18 * intensity),
                    Colors.transparent,
                  ],
                  radius: 1.3,
                ),
              ),
            ),
          ),

          // Slight Vignette for cinematic focus
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.8,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15 * intensity),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

class AIGlowUpOverlay extends StatefulWidget {
  const AIGlowUpOverlay({super.key});
  @override
  State<AIGlowUpOverlay> createState() => _AIGlowUpOverlayState();
}

class _AIGlowUpOverlayState extends State<AIGlowUpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _ctrl,
      child: Stack(children: [
        Container(
            decoration: BoxDecoration(
                gradient: RadialGradient(
          colors: [Colors.yellowAccent.withOpacity(0.15), Colors.transparent],
          radius: 0.8,
        ))),
        Center(
            child: Container(
                width: 200,
                height: 280,
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(140),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10)
                    ])))
      ]));
}

class AnimeFaceOverlay extends StatelessWidget {
  const AnimeFaceOverlay({super.key});
  @override
  Widget build(BuildContext context) => Stack(children: [
        Container(color: Colors.pinkAccent.withOpacity(0.1)),
        const Center(
            child: Padding(
                padding: EdgeInsets.only(bottom: 50),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('✨',
                      style: TextStyle(fontSize: 60, shadows: [
                        Shadow(color: Colors.white, blurRadius: 20)
                      ])),
                  SizedBox(width: 80),
                  Text('✨',
                      style: TextStyle(fontSize: 60, shadows: [
                        Shadow(color: Colors.white, blurRadius: 20)
                      ])),
                ])))
      ]);
}

class ElementControlOverlay extends StatefulWidget {
  const ElementControlOverlay({super.key});
  @override
  State<ElementControlOverlay> createState() => _ElementControlOverlayState();
}

class _ElementControlOverlayState extends State<ElementControlOverlay> {
  bool isFire = true;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () => setState(() => isFire = !isFire),
      behavior: HitTestBehavior.opaque,
      child: Stack(children: [
        Container(
            color: isFire
                ? Colors.deepOrange.withOpacity(0.15)
                : Colors.lightBlue.withOpacity(0.15)),
        Center(
            child: Text(isFire ? '🔥🔥🔥' : '❄️❄️❄️',
                style: const TextStyle(fontSize: 60))),
        Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Text(isFire ? 'FIRE MODE (Tap)' : 'ICE MODE (Tap)',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)))
      ]));
}

class EnvSwitcherOverlay extends StatefulWidget {
  const EnvSwitcherOverlay({super.key});
  @override
  State<EnvSwitcherOverlay> createState() => _EnvSwitcherOverlayState();
}

class _EnvSwitcherOverlayState extends State<EnvSwitcherOverlay> {
  int bgIndex = 0;
  final List<List<Color>> bgs = [
    [Colors.purple.withOpacity(0.25), Colors.blue.withOpacity(0.25)],
    [Colors.orange.withOpacity(0.25), Colors.red.withOpacity(0.25)],
    [Colors.indigo.withOpacity(0.3), Colors.black.withOpacity(0.3)],
  ];
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () => setState(() => bgIndex = (bgIndex + 1) % bgs.length),
      behavior: HitTestBehavior.opaque,
      child: Stack(children: [
        Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: bgs[bgIndex],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight))),
        Center(
            child: Container(
                width: 300,
                height: 500,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(150),
                    color: Colors.transparent,
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black54,
                          spreadRadius: 100,
                          blurRadius: 100)
                    ]))),
        Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Text('Tap to change Env',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)))
      ]));
}

class ARGameOverlay extends StatefulWidget {
  const ARGameOverlay({super.key});
  @override
  State<ARGameOverlay> createState() => _ARGameOverlayState();
}

class _ARGameOverlayState extends State<ARGameOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int score = 0;
  double heartY = -0.2;
  double heartX = 0.5;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _ctrl.addListener(() {
      setState(() {
        heartY = -0.2 + (_ctrl.value * 1.4);
        if (heartY > 1.1) {
          heartX = Random().nextDouble() * 0.8 + 0.1;
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned(
            top: 80,
            left: 20,
            child: Text('Score: $score',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold))),
        Positioned(
            top: MediaQuery.of(context).size.height * heartY,
            left: MediaQuery.of(context).size.width * heartX,
            child: GestureDetector(
                onTap: () {
                  if (!mounted) return;
                  setState(() {
                    score++;
                    heartY = -0.2;
                    heartX = Random().nextDouble() * 0.8 + 0.1;
                    _ctrl.forward(from: 0);
                    HapticFeedback.heavyImpact();
                  });
                },
                child: const Text('💖', style: TextStyle(fontSize: 60))))
      ]);
}
