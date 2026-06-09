import 'package:flutter/material.dart';

enum ThemeType {
  // Dark Themes
  midnightPurple,
  cyberBlue,
  sunsetNeon,
  emeraldNight,
  // Light Themes
  softLavender,
  skyBreeze,
  peachBloom,
  mintFresh,
  // Universal
  aurora,
  auroraLight,
  // Standard
  gotchaaDark,
  gotchaaLight,
}

class GotchaaThemeData {
  GotchaaThemeData({
    required this.name,
    required this.type,
    required this.brightness,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.accentGradient,
    required this.bubbleMe,
    required this.bubbleThem,
    this.backgroundGradient,
    this.cornerRadius = 16.0,
  });
  final String name;
  final ThemeType type;
  final Brightness brightness;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final LinearGradient? backgroundGradient;
  final LinearGradient accentGradient;
  final Color bubbleMe;
  final Color bubbleThem;
  final double cornerRadius;

  GotchaaThemeData copyWith({
    double? cornerRadius,
  }) =>
      GotchaaThemeData(
        name: name,
        type: type,
        brightness: brightness,
        primaryColor: primaryColor,
        accentColor: accentColor,
        backgroundColor: backgroundColor,
        surfaceColor: surfaceColor,
        cardColor: cardColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        dividerColor: dividerColor,
        backgroundGradient: backgroundGradient,
        accentGradient: accentGradient,
        bubbleMe: bubbleMe,
        bubbleThem: bubbleThem,
        cornerRadius: cornerRadius ?? this.cornerRadius,
      );
}

class AppThemes {
  static final Map<ThemeType, GotchaaThemeData> allThemes = {
    // ── DARK THEMES ──────────────────────────────────────────────────────────
    ThemeType.midnightPurple: GotchaaThemeData(
      name: 'Midnight Purple',
      type: ThemeType.midnightPurple,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF7C5CFC),
      accentColor: const Color(0xFFB57BEA),
      backgroundColor: const Color(0xFF0D0D0D),
      surfaceColor: const Color(0xFF1A1A1A),
      cardColor: const Color(0xFF252525),
      textPrimary: Colors.white,
      textSecondary: Colors.grey[400]!,
      dividerColor: Colors.white10,
      accentGradient:
          const LinearGradient(colors: [Color(0xFF7C5CFC), Color(0xFFB57BEA)]),
      bubbleMe: const Color(0xFF7C5CFC),
      bubbleThem: const Color(0xFF252525),
    ),
    ThemeType.cyberBlue: GotchaaThemeData(
      name: 'Cyber Blue',
      type: ThemeType.cyberBlue,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF0070FF),
      accentColor: const Color(0xFF00D1FF),
      backgroundColor: const Color(0xFF050B18),
      surfaceColor: const Color(0xFF0D1526),
      cardColor: const Color(0xFF162033),
      textPrimary: const Color(0xFFE3F2FD),
      textSecondary: const Color(0xFF90A4AE),
      dividerColor: Colors.white10,
      accentGradient:
          const LinearGradient(colors: [Color(0xFF0070FF), Color(0xFF00D1FF)]),
      bubbleMe: const Color(0xFF0070FF),
      bubbleThem: const Color(0xFF162033),
    ),
    ThemeType.sunsetNeon: GotchaaThemeData(
      name: 'Sunset Neon',
      type: ThemeType.sunsetNeon,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFFF4D6D),
      accentColor: const Color(0xFFFF8A00),
      backgroundColor: const Color(0xFF0F090A),
      surfaceColor: const Color(0xFF1F1214),
      cardColor: const Color(0xFF2D1B1E),
      textPrimary: Colors.white,
      textSecondary: Colors.grey[400]!,
      dividerColor: Colors.white10,
      accentGradient:
          const LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFFFF8A00)]),
      bubbleMe: const Color(0xFFFF4D6D),
      bubbleThem: const Color(0xFF2D1B1E),
    ),
    ThemeType.emeraldNight: GotchaaThemeData(
      name: 'Emerald Night',
      type: ThemeType.emeraldNight,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF00C897),
      accentColor: const Color(0xFF1DE9B6),
      backgroundColor: const Color(0xFF0A110F),
      surfaceColor: const Color(0xFF14221E),
      cardColor: const Color(0xFF1E332D),
      textPrimary: const Color(0xFFE0F2F1),
      textSecondary: const Color(0xFF80CBC4),
      dividerColor: Colors.white10,
      accentGradient:
          const LinearGradient(colors: [Color(0xFF00C897), Color(0xFF1DE9B6)]),
      bubbleMe: const Color(0xFF00C897),
      bubbleThem: const Color(0xFF1E332D),
    ),

    // ── LIGHT THEMES ─────────────────────────────────────────────────────────
    ThemeType.softLavender: GotchaaThemeData(
      name: 'Soft Lavender',
      type: ThemeType.softLavender,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF916BFF),
      accentColor: const Color(0xFFD1C4E9),
      backgroundColor: const Color(0xFFF9F7FF),
      surfaceColor: Colors.white,
      cardColor: const Color(0xFFF3F0FF),
      textPrimary: const Color(0xFF2D2D2D),
      textSecondary: const Color(0xFF757575),
      dividerColor: Colors.black12,
      accentGradient:
          const LinearGradient(colors: [Color(0xFF916BFF), Color(0xFFB39DDB)]),
      bubbleMe: const Color(0xFF916BFF),
      bubbleThem: const Color(0xFFEDE7F6),
    ),
    ThemeType.skyBreeze: GotchaaThemeData(
      name: 'Sky Breeze',
      type: ThemeType.skyBreeze,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF03A9F4),
      accentColor: const Color(0xFFB3E5FC),
      backgroundColor: const Color(0xFFF1F9FF),
      surfaceColor: Colors.white,
      cardColor: const Color(0xFFE1F5FE),
      textPrimary: const Color(0xFF1A237E),
      textSecondary: const Color(0xFF546E7A),
      dividerColor: Colors.black12,
      accentGradient:
          const LinearGradient(colors: [Color(0xFF03A9F4), Color(0xFF81D4FA)]),
      bubbleMe: const Color(0xFF03A9F4),
      bubbleThem: const Color(0xFFE1F5FE),
    ),
    ThemeType.peachBloom: GotchaaThemeData(
      name: 'Peach Bloom',
      type: ThemeType.peachBloom,
      brightness: Brightness.light,
      primaryColor: const Color(0xFFFF8A65),
      accentColor: const Color(0xFFFFCCBC),
      backgroundColor: const Color(0xFFFFF7F5),
      surfaceColor: Colors.white,
      cardColor: const Color(0xFFFFEBE6),
      textPrimary: const Color(0xFF4E342E),
      textSecondary: const Color(0xFF8D6E63),
      dividerColor: Colors.black12,
      accentGradient:
          const LinearGradient(colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)]),
      bubbleMe: const Color(0xFFFF8A65),
      bubbleThem: const Color(0xFFFFEBE6),
    ),
    ThemeType.mintFresh: GotchaaThemeData(
      name: 'Mint Fresh',
      type: ThemeType.mintFresh,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF4DB6AC),
      accentColor: const Color(0xFFB2DFDB),
      backgroundColor: const Color(0xFFF0F7F6),
      surfaceColor: Colors.white,
      cardColor: const Color(0xFFE0F2F1),
      textPrimary: const Color(0xFF004D40),
      textSecondary: const Color(0xFF455A64),
      dividerColor: Colors.black12,
      accentGradient:
          const LinearGradient(colors: [Color(0xFF4DB6AC), Color(0xFF80CBC4)]),
      bubbleMe: const Color(0xFF4DB6AC),
      bubbleThem: const Color(0xFFE0F2F1),
    ),

    // ── UNIVERSAL ────────────────────────────────────────────────────────────
    ThemeType.aurora: GotchaaThemeData(
      name: 'Aurora',
      type: ThemeType.aurora,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF3DDEC8),
      accentColor: const Color(0xFFB57BEA),
      backgroundColor: const Color(0xFF0A0A0A),
      surfaceColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      textPrimary: Colors.white,
      textSecondary: Colors.grey[400]!,
      dividerColor: Colors.white10,
      accentGradient: const LinearGradient(
        colors: [Color(0xFFB57BEA), Color(0xFF7BBFEA), Color(0xFF3DDEC8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      backgroundGradient: const LinearGradient(
        colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      bubbleMe: const Color(0xFF3DDEC8),
      bubbleThem: const Color(0xFF1E1E1E),
    ),
    ThemeType.auroraLight: GotchaaThemeData(
      name: 'Aurora Light',
      type: ThemeType.auroraLight,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF3DDEC8),
      accentColor: const Color(0xFFB57BEA),
      backgroundColor: const Color(0xFFF0FDFB),
      surfaceColor: Colors.white,
      cardColor: const Color(0xFFE6FFFA),
      textPrimary: const Color(0xFF004D40),
      textSecondary: const Color(0xFF455A64),
      dividerColor: Colors.black12,
      accentGradient: const LinearGradient(
        colors: [Color(0xFFB57BEA), Color(0xFF7BBFEA), Color(0xFF3DDEC8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      bubbleMe: const Color(0xFF3DDEC8),
      bubbleThem: const Color(0xFFE6FFFA),
    ),

    // ── STANDARD ─────────────────────────────────────────────────────────────
    ThemeType.gotchaaDark: GotchaaThemeData(
      name: 'Gotchaa Dark',
      type: ThemeType.gotchaaDark,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF0070FF),
      accentColor: const Color(0xFF00D1FF),
      backgroundColor: const Color(0xFF0D0D0D),
      surfaceColor: const Color(0xFF1A1A1A),
      cardColor: const Color(0xFF252525),
      textPrimary: Colors.white,
      textSecondary: Colors.grey[400]!,
      dividerColor: Colors.white10,
      accentGradient:
          const LinearGradient(colors: [Color(0xFF0070FF), Color(0xFF00D1FF)]),
      bubbleMe: const Color(0xFF0070FF),
      bubbleThem: const Color(0xFF252525),
    ),
    ThemeType.gotchaaLight: GotchaaThemeData(
      name: 'Gotchaa Light',
      type: ThemeType.gotchaaLight,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF0070FF),
      accentColor: const Color(0xFF00D1FF),
      backgroundColor: Colors.white,
      surfaceColor: const Color(0xFFF8F9FA),
      cardColor: Colors.white,
      textPrimary: Colors.black,
      textSecondary: Colors.grey[600]!,
      dividerColor: Colors.black12,
      accentGradient:
          const LinearGradient(colors: [Color(0xFF0070FF), Color(0xFF00D1FF)]),
      bubbleMe: const Color(0xFF0070FF),
      bubbleThem: const Color(0xFFF3F3F3),
    ),
  };
}
