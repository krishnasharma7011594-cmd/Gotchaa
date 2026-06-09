import 'dart:math';
import 'package:flutter/material.dart';

class SpeedLinesPainter extends CustomPainter {
  // Seeded for consistent line positions per frame

  SpeedLinesPainter(this.intensity, this.dominantColor);
  final double intensity; // 0.0 to 1.0 (based on tiltVelocity)
  final Color dominantColor;
  final Random _rand = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity < 0.3) return; // Only show at high speeds

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        sqrt(size.width * size.width + size.height * size.height) / 2;

    // Draw radially outward lines
    final int numLines = (intensity * 100).toInt();
    final paint = Paint()
      ..color = dominantColor.withOpacity(intensity * 0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < numLines; i++) {
      final double angle = _rand.nextDouble() * 2 * pi;
      // Lines start somewhat near the center but mostly on the edges
      final double startRadius = maxRadius * (0.4 + _rand.nextDouble() * 0.4);
      final double endRadius = maxRadius;

      // Add slight jitter for anime effect
      final double jump = _rand.nextDouble() *
          20.0 *
          sin(DateTime.now().millisecondsSinceEpoch / 10.0);

      final start = Offset(center.dx + cos(angle) * (startRadius + jump),
          center.dy + sin(angle) * (startRadius + jump));

      final end = Offset(center.dx + cos(angle) * endRadius,
          center.dy + sin(angle) * endRadius);

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedLinesPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}
