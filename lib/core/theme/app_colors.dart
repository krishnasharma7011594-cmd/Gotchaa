import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF007BFF);
  static const Color primaryGlow = Color(0xFF00D1FF);
  static const Color electricBlue = Color(0xFF0070FF);

  // ── Light mode backgrounds ────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFF8F9FA);

  // ── Dark mode surface tokens ──────────────────────────────────────────
  /// True page background in dark mode – pure black for OLED displays
  static const Color darkBg = Color(0xFF0D0D0D);

  /// Elevated surfaces: cards, list tiles, modals - very dark grey
  static const Color darkSurface = Color(0xFF1A1A1A);

  /// Slightly brighter card layer (badges, chips, etc.) - medium dark grey
  static const Color darkCard = Color(0xFF2A2A2A);

  /// Subtle dividers & borders - neutral dark grey
  static const Color darkDivider = Color(0xFF333333);

  /// Primary text on dark – off-white for comfortable contrast (not pure white)
  static const Color darkTextPrimary = Color(0xFFE2E2E2);

  /// Secondary / hint text on dark
  static const Color darkTextSecondary = Color(0xFF8E8E8E);

  // ── Accents ──────────────────────────────────────────────────────────
  static const Color karmaOrange = Color(0xFFFF8A00);
  static const Color karmaAura = Color(0xFFFFD700);
  static const Color vibrantPurple = Color(0xFF7C5CFC);
  static const Color error = Color(0xFFFF4B4B);

  // ── Gradients ────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFB57BEA), Color(0xFF7BBFEA), Color(0xFF3DDEC8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricGradient = LinearGradient(
    colors: [Color(0xFFB57BEA), Color(0xFF3DDEC8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient auraGradient = LinearGradient(
    colors: [karmaOrange, Color(0xFFFFD700)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Dark-surface brand gradient – subtly cooler so it pops on dark bg
  static const LinearGradient electricGradientDark = LinearGradient(
    colors: [Color(0xFF1A6FFF), Color(0xFF00D1FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
