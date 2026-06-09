import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final List<Color>? borderGradients;
  final double borderWidth;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 15.0,
    this.borderGradients,
    this.borderWidth = 1.2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradients = [
      Colors.white.withOpacity(0.15),
      Colors.white.withOpacity(0.05),
      Colors.purpleAccent.withOpacity(0.1),
    ];

    final widget = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.02),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _GlassBorderPainter(
              borderRadius: borderRadius,
              borderWidth: borderWidth,
              gradientColors: borderGradients ?? defaultGradients,
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }
    return widget;
  }
}

class _GlassBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final List<Color> gradientColors;

  _GlassBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    
    final paint = Paint()
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
