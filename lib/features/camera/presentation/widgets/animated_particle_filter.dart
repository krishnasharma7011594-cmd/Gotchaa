import 'dart:math';
import 'package:flutter/material.dart';

enum ParticleFilterType {
  fallingSakura,
  snowGlobe,
  confettiBurst,
}

class AnimatedParticleFilter extends StatefulWidget {
  const AnimatedParticleFilter({
    required this.child,
    required this.filterType,
    super.key,
  });
  final Widget child;
  final ParticleFilterType filterType;

  @override
  State<AnimatedParticleFilter> createState() => _AnimatedParticleFilterState();
}

class _AnimatedParticleFilterState extends State<AnimatedParticleFilter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _controller.addListener(() {
      _updateParticles();
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isEmpty) {
      _initParticles(MediaQuery.of(context).size);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedParticleFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterType != widget.filterType) {
      _particles.clear();
      _initParticles(MediaQuery.of(context).size);
    }
  }

  void _initParticles(Size size) {
    int count = 0;
    switch (widget.filterType) {
      case ParticleFilterType.fallingSakura:
        count = 50;
        break;
      case ParticleFilterType.snowGlobe:
        count = 100;
        break;
      case ParticleFilterType.confettiBurst:
        count = 150;
        break;
    }

    for (int i = 0; i < count; i++) {
      _particles.add(_createParticle(size, initial: true));
    }
  }

  Particle _createParticle(Size size, {bool initial = false}) {
    double x = _random.nextDouble() * size.width;
    double y = initial ? _random.nextDouble() * size.height : -20;

    Color color = Colors.white;
    double sizeVal = 5;
    double speedX = 0;
    double speedY = 0;
    final double rotationSpeed = _random.nextDouble() * 0.2 - 0.1;

    switch (widget.filterType) {
      case ParticleFilterType.fallingSakura:
        color = Colors.pinkAccent.withOpacity(0.8);
        sizeVal = _random.nextDouble() * 10 + 5;
        speedY = _random.nextDouble() * 2 + 1;
        speedX = _random.nextDouble() * 2 - 1; // drifting
        break;
      case ParticleFilterType.snowGlobe:
        color = Colors.white.withOpacity(_random.nextDouble() * 0.5 + 0.3);
        sizeVal = _random.nextDouble() * 4 + 2;
        speedY = _random.nextDouble() * 3 + 1;
        speedX = _random.nextDouble() * 4 - 2; // wind drift
        break;
      case ParticleFilterType.confettiBurst:
        final colors = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple
        ];
        color = colors[_random.nextInt(colors.length)];
        sizeVal = _random.nextDouble() * 8 + 4;

        // Burst outward from bottom center instead of falling from top
        if (!initial) {
          x = size.width / 2 + (_random.nextDouble() * 40 - 20);
          y = size.height;
          speedY = -(_random.nextDouble() * 15 + 5);
          speedX = _random.nextDouble() * 10 - 5;
        } else {
          speedY = _random.nextDouble() * 5 - 2;
          speedX = _random.nextDouble() * 4 - 2;
        }
        break;
    }

    return Particle(
      x: x,
      y: y,
      speedX: speedX,
      speedY: speedY,
      size: sizeVal,
      color: color,
      rotation: _random.nextDouble() * pi * 2,
      rotationSpeed: rotationSpeed,
    );
  }

  void _updateParticles() {
    final size = MediaQuery.of(context).size;
    final List<Particle> active = [];

    for (final p in _particles) {
      if (widget.filterType == ParticleFilterType.confettiBurst) {
        p.speedY += 0.2; // Gravity effect
      } else if (widget.filterType == ParticleFilterType.snowGlobe) {
        p.speedX += (_random.nextDouble() - 0.5) * 0.5; // Wind turbulence
        p.speedX = p.speedX.clamp(-3.0, 3.0);
      } else if (widget.filterType == ParticleFilterType.fallingSakura) {
        p.speedX =
            sin(DateTime.now().millisecondsSinceEpoch / 1000.0 + p.size) *
                1.5; // Gentle sway
      }

      p.x += p.speedX;
      p.y += p.speedY;
      p.rotation += p.rotationSpeed;

      // Restock particles when off-screen
      if (widget.filterType == ParticleFilterType.confettiBurst) {
        if (p.y < size.height + 50 && p.x > -50 && p.x < size.width + 50) {
          active.add(p);
        } else {
          active.add(_createParticle(size));
        }
      } else {
        if (p.y > size.height + 20) {
          active.add(_createParticle(size));
        } else {
          active.add(p);
        }
      }
    }
    _particles = active;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          IgnorePointer(
            child: CustomPaint(
              painter: ParticlePainter(
                  particles: _particles, type: widget.filterType),
            ),
          ),
        ],
      );
}

class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
  double x, y, speedX, speedY, size, rotation, rotationSpeed;
  Color color;
}

class ParticlePainter extends CustomPainter {
  ParticlePainter({required this.particles, required this.type});
  final List<Particle> particles;
  final ParticleFilterType type;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (type == ParticleFilterType.fallingSakura) {
        // Draw an oval petal shape
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 1.5),
          Paint()..color = p.color,
        );
      } else if (type == ParticleFilterType.confettiBurst) {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          Paint()..color = p.color,
        );
      } else {
        // SnowGlobe
        canvas.drawCircle(Offset.zero, p.size, Paint()..color = p.color);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
