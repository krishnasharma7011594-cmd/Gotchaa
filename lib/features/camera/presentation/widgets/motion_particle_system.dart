import 'dart:math';
import 'package:flutter/material.dart';
import '../../motion/sensor_state.dart';

enum MotionParticleType { sakura, snow, galaxy }

class PhysicsParticle {

  PhysicsParticle({
    required this.x, required this.y, 
    required this.vx, required this.vy, 
    required this.size, required this.color,
    required this.lifetime, required this.angle
  });
  double x, y;
  double vx, vy;
  double size;
  Color color;
  double lifetime;
  double angle;
}

class MotionParticleSystem extends StatefulWidget {

  const MotionParticleSystem({
    required this.child, required this.sensorStream, required this.type, super.key,
  });
  final Widget child;
  final Stream<SensorState> sensorStream;
  final MotionParticleType type;

  @override
  State<MotionParticleSystem> createState() => _MotionParticleSystemState();
}

class _MotionParticleSystemState extends State<MotionParticleSystem> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  List<PhysicsParticle> _particles = [];
  SensorState _lastState = SensorState.zero();
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    widget.sensorStream.listen((state) {
      _lastState = state;
    });

    _ticker = AnimationController(vsync: this, duration: const Duration(hours: 1))..forward();
    _ticker.addListener(_updatePhysics);
  }

  void _updatePhysics() {
    final Size size = MediaQuery.of(context).size;
    if (_particles.isEmpty) {
      _initParticles(size);
    }

    // Determine environmental forces off sensors
    // tiltX = lean left/right. Lean right (+90) -> gravity pushes to right (+x)
    final double gravityX = (_lastState.tiltX / 90.0) * 5.0; // Gravity vector
    final double gravityY = max(2, (1.0 - (_lastState.tiltY.abs() / 90.0)) * 5.0); // Always falls down somewhat

    // Wind vector driven by tilt velocity
    final double windX = _lastState.tiltVelocity > 10 ? (_lastState.tiltX > 0 ? 3.0 : -3.0) : 0.0;
    
    // Shake causes turbulence burst
    final double turbulence = _lastState.shakeIntensity * 20.0;

    final List<PhysicsParticle> active = [];
    for (final p in _particles) {
      p.lifetime -= 0.016; // Approx 60fps delta
      
      // Swirl driven by gyroscope Z rotation
      final double spinFactor = _lastState.rotationZ / 180.0 * pi;
      if (widget.type == MotionParticleType.galaxy) {
         p.vx += cos(spinFactor) * 0.5 - sin(spinFactor) * 0.5;
         p.vy += sin(spinFactor) * 0.5 + cos(spinFactor) * 0.5;
      }

      // Apply forces
      p.vx = p.vx * 0.98 + (gravityX * 0.1) + (windX * 0.1) + ((_rand.nextDouble() - 0.5) * turbulence);
      p.vy = p.vy * 0.98 + (gravityY * 0.1) + ((_rand.nextDouble() - 0.5) * turbulence);

      p.x += p.vx;
      p.y += p.vy;
      p.angle += p.vx * 0.05;

      // Respawn
      if (p.lifetime > 0 && p.y < size.height + 50 && p.x > -50 && p.x < size.width + 50) {
        active.add(p);
      } else {
        active.add(_spawnParticle(size, initial: false));
      }
    }

    setState(() => _particles = active);
  }

  void _initParticles(Size size) {
    final int count = widget.type == MotionParticleType.galaxy ? 250 : 100;
    for (int i = 0; i < count; i++) {
        _particles.add(_spawnParticle(size, initial: true));
    }
  }

  PhysicsParticle _spawnParticle(Size size, {bool initial = false}) {
    double x = _rand.nextDouble() * size.width;
    double y = initial ? _rand.nextDouble() * size.height : -20;
    
    Color color = Colors.white;
    double pSize = 5;
    
    if (widget.type == MotionParticleType.sakura) {
      color = Colors.pinkAccent;
      pSize = _rand.nextDouble() * 10 + 5;
    } else if (widget.type == MotionParticleType.galaxy) {
      final cols = [Colors.deepPurpleAccent, Colors.blueAccent, Colors.pink, Colors.white];
      color = cols[_rand.nextInt(cols.length)];
      pSize = _rand.nextDouble() * 3 + 1;
      if (initial == false) {
         x = size.width / 2;
         y = size.height / 2;
      }
    }

    return PhysicsParticle(
      x: x, y: y,
      vx: _rand.nextDouble() * 2 - 1,
      vy: _rand.nextDouble() * 2 - 1,
      size: pSize, color: color,
      lifetime: _rand.nextDouble() * 5 + 3,
      angle: _rand.nextDouble() * pi * 2,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: CustomPaint(painter: PhysicsParticlePainter(_particles, widget.type)),
        )
      ],
    );
}

class PhysicsParticlePainter extends CustomPainter {

  PhysicsParticlePainter(this.ps, this.type);
  final List<PhysicsParticle> ps;
  final MotionParticleType type;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in ps) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);
      
      final paint = Paint()..color = p.color.withOpacity((p.lifetime / 5.0).clamp(0.0, 1.0));

      if (type == MotionParticleType.sakura) {
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5), paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size, paint);
      }
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
