import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/vibetalk_providers.dart';
import '../services/vibetalk_webrtc_service.dart';

// ── Audio Waveform Painter ──
class AudioWaveformPainter extends CustomPainter {

  AudioWaveformPainter({
    required this.audioLevel,
    required this.isLocalUser,
    required this.primaryColor,
    required this.secondaryColor,
  });
  final double audioLevel;
  final bool isLocalUser;
  final Color primaryColor;
  final Color secondaryColor;
  final int barCount = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: isLocalUser 
        ? [const Color(0xFF0070FF), const Color(0xFF00D1FF)] // Local Blue
        : [primaryColor, secondaryColor], // Remote/Theme-based
    );

    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / barCount;
    final maxBarHeight = size.height;

    for (int i = 0; i < barCount; i++) {
      // Use sine for variety
      final wave = 0.8 + (0.2 * (i % 3 == 0 ? 1.0 : 0.5));
      final height = (audioLevel * maxBarHeight * wave).clamp(4.0, maxBarHeight);
      
      final x = i * spacing + (spacing / 2);
      final top = (size.height - height) / 2;
      final bottom = top + height;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) => 
      oldDelegate.audioLevel != audioLevel;
}

// ── Speaking Avatar ──
class SpeakingAvatarWidget extends StatelessWidget {

  const SpeakingAvatarWidget({
    required this.audioLevel, required this.isLocal, super.key,
    this.accentColor,
  });
  final double audioLevel;
  final bool isLocal;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final glowColor = isLocal ? Colors.blueAccent : (accentColor ?? context.accent);
    final pulseScale = 1.0 + (audioLevel * 0.1);

    return AnimatedScale(
      scale: pulseScale,
      duration: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (audioLevel > 0.05)
              BoxShadow(
                color: glowColor.withOpacity(audioLevel.clamp(0, 0.4)),
                blurRadius: 15 * audioLevel,
                spreadRadius: 2 * audioLevel,
              ),
          ],
        ),
        child: CircleAvatar(
          radius: 40,
          backgroundColor: context.surface,
          child: Icon(
            isLocal ? Icons.person_rounded : Icons.record_voice_over_rounded, 
            size: 32, 
            color: context.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Connection Quality Badge ──
class VibeQualityBadge extends StatelessWidget {
  const VibeQualityBadge({required this.quality, super.key});
  final VibeQualityState quality;

  @override
  Widget build(BuildContext context) {
    final color = switch(quality) {
      VibeQualityState.excellent => const Color(0xFF10B981), // Emerald
      VibeQualityState.good => Colors.amber,
      VibeQualityState.fair => Colors.orange,
      VibeQualityState.poor => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, 
            height: 6, 
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            context.tr('vibetalk_quality_${quality.name}'),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

