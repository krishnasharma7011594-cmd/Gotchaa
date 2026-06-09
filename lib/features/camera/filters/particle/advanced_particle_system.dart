import 'dart:math';
import 'package:flutter/material.dart';
import '../filter_manager.dart';

class AdvancedParticleSystem extends StatefulWidget {
  const AdvancedParticleSystem({
    required this.filter,
    required this.intensity,
    super.key,
  });
  final FilterDefinition filter;
  final double intensity;

  @override
  State<AdvancedParticleSystem> createState() => _AdvancedParticleSystemState();
}

class _AdvancedParticleSystemState extends State<AdvancedParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  List<_Particle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(hours: 1))
          ..forward();
    _ticker.addListener(_updatePhysics);
  }

  void _updatePhysics() {
    if (!mounted) return;

    // Scale count by intensity
    int baseCount = 100;
    if (widget.filter.id == 'p_galaxy') baseCount = 300;
    if (widget.filter.id == 'p_fire') baseCount = 200;

    final targetCount = (baseCount * widget.intensity).toInt();
    final Size size = MediaQuery.of(context).size;

    final List<_Particle> active = [];

    // Physics Step
    for (final p in _particles) {
      p.lifetime -= 0.016; // 60fps delta

      switch (widget.filter.id) {
        case 'p_sakura':
        case 'p_snow':
        case 'p_matrix':
          p.x += p.vx;
          p.y += p.gravity;
          p.rotation += p.rotForce;
          break;
        case 'p_confetti':
          p.gravity += 0.1; // gravity acceleration
          p.x += p.vx;
          p.y += p.gravity;
          p.rotation += p.rotForce;
          // Friction
          p.vx *= 0.98;
          break;
        case 'p_hearts':
        case 'p_bubbles':
        case 'p_fire':
          // Rising up
          p.x += p.vx + sin(p.lifetime * 5) * 0.5; // wiggle
          p.y -= p.gravity;
          break;
        case 'p_lightning':
          // Jitter
          p.x += (_rand.nextDouble() - 0.5) * 20;
          p.y += (_rand.nextDouble() - 0.5) * 20;
          break;
        case 'p_galaxy':
          // Spiral motion around center
          final double cx = size.width / 2;
          final double cy = size.height / 2;
          final double dx = p.x - cx;
          final double dy = p.y - cy;
          final double dist = sqrt(dx * dx + dy * dy);
          final double angle = atan2(dy, dx) + 0.05; // orbit speed
          p.x = cx + cos(angle) * dist * 0.99; // pull in
          p.y = cy + sin(angle) * dist * 0.99;
          break;
      }

      if (p.lifetime > 0 &&
          p.y < size.height + 50 &&
          p.y > -50 &&
          p.x > -50 &&
          p.x < size.width + 50) {
        active.add(p);
      }
    }

    // Spawner
    while (active.length < targetCount) {
      active.add(_spawnParticle(size));
    }

    setState(() => _particles = active);
  }

  _Particle _spawnParticle(Size size) {
    double x = _rand.nextDouble() * size.width;
    double y = -20;
    double vx = 0;
    double gravity = 2;
    double lifetime = 5;
    double rotForce = 0;
    Color color = Colors.white;
    double pSize = 5;

    switch (widget.filter.id) {
      case 'p_sakura':
        color = Colors.pinkAccent.withOpacity(0.8);
        gravity = _rand.nextDouble() * 2 + 1;
        vx = _rand.nextDouble() * 4 - 1; // drifts right usually
        rotForce = _rand.nextDouble() * 0.1;
        pSize = _rand.nextDouble() * 8 + 4;
        break;
      case 'p_snow':
        color = Colors.white.withOpacity(0.6);
        gravity = _rand.nextDouble() * 1.5 + 0.5;
        vx = _rand.nextDouble() * 2 - 1;
        pSize = _rand.nextDouble() * 4 + 2;
        break;
      case 'p_confetti':
        y = size.height / 2;
        x = size.width / 2; // Explode from center
        vx = (_rand.nextDouble() - 0.5) * 20;
        gravity = -(_rand.nextDouble() * 15 + 5); // shoots up
        final colors = [
          Colors.red,
          Colors.blue,
          Colors.yellow,
          Colors.green,
          Colors.purple
        ];
        color = colors[_rand.nextInt(colors.length)];
        rotForce = (_rand.nextDouble() - 0.5) * 0.5;
        pSize = 6;
        lifetime = 3;
        break;
      case 'p_hearts':
      case 'p_bubbles':
        y = size.height + 20; // spawns bottom
        gravity = _rand.nextDouble() * 3 + 2; // rises fast
        color = widget.filter.id == 'p_hearts'
            ? Colors.redAccent
            : Colors.cyanAccent.withOpacity(0.5);
        pSize = _rand.nextDouble() * 10 + 5;
        break;
      case 'p_fire':
        // spawns along bottom edge, red/orange
        y = size.height + 10;
        gravity = _rand.nextDouble() * 5 + 3;
        final cIndex = _rand.nextInt(3);
        color = cIndex == 0
            ? Colors.red
            : cIndex == 1
                ? Colors.orange
                : Colors.yellow;
        lifetime = _rand.nextDouble() * 1.5 + 0.5;
        pSize = 10 * (_rand.nextDouble() + 0.5);
        break;
      case 'p_galaxy':
        x = _rand.nextDouble() * size.width;
        y = _rand.nextDouble() * size.height; // spawn anywhere
        final colors = [
          Colors.deepPurple,
          Colors.indigo,
          Colors.lightBlueAccent,
          Colors.white
        ];
        color = colors[_rand.nextInt(colors.length)];
        pSize = _rand.nextDouble() * 3 + 1;
        lifetime = _rand.nextDouble() * 3 + 2;
        break;
      case 'p_matrix':
        color = Colors.greenAccent;
        gravity = _rand.nextDouble() * 5 + 5; // falls fast
        pSize = 14;
        break;
    }

    return _Particle(
        x: x,
        y: y,
        vx: vx,
        gravity: gravity,
        rotForce: rotForce,
        size: pSize,
        color: color,
        lifetime: lifetime,
        angle: 0);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.intensity == 0.0) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _MultiParticlePainter(_particles, widget.filter.id),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.gravity,
    required this.rotForce,
    required this.size,
    required this.color,
    required this.lifetime,
    required this.angle,
    this.rotation = 0.0,
  });
  double x, y, vx, gravity, rotForce, size, lifetime, angle, rotation;
  Color color;
}

class _MultiParticlePainter extends CustomPainter {
  _MultiParticlePainter(this.ps, this.mode);
  final List<_Particle> ps;
  final String mode;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in ps) {
      final paint = Paint()
        ..color = p.color.withOpacity((p.lifetime / 3.0).clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (mode == 'p_sakura') {
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 1.5),
            paint);
      } else if (mode == 'p_confetti') {
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
            paint);
      } else if (mode == 'p_matrix') {
        // Simple representation of characters
        _drawText(canvas, String.fromCharCode(0x30A0 + Random().nextInt(96)),
            paint.color, p.size);
      } else if (mode == 'p_hearts') {
        _drawHeart(canvas, p.size, paint);
      } else if (mode == 'p_bubbles') {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawCircle(Offset.zero, p.size, paint);
      } else {
        // default dots (snow, fire, galaxy)
        canvas.drawCircle(Offset.zero, p.size, paint);
      }
      canvas.restore();
    }
  }

  void _drawText(Canvas c, String t, Color col, double s) {
    final tp = TextPainter(
        text: TextSpan(
            text: t,
            style: TextStyle(color: col, fontSize: s, fontFamily: 'Courier')),
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(c, Offset(-s / 2, -s / 2));
  }

  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final Path path = Path();
    path.moveTo(0, size / 4);
    path.cubicTo(-size / 2, -size / 4, -size, size / 2, 0, size);
    path.cubicTo(size, size / 2, size / 2, -size / 4, 0, size / 4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
