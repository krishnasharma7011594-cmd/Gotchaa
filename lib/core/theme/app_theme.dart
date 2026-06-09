import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme_model.dart';

export 'app_theme_model.dart';

class AppTheme {
  static ThemeData fromGotchaaTheme(GotchaaThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: theme.brightness,
      primaryColor: theme.primaryColor,
      scaffoldBackgroundColor: theme.backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.primaryColor,
        brightness: theme.brightness,
        background: theme.backgroundColor,
        surface: theme.surfaceColor,
        onBackground: theme.textPrimary,
        onSurface: theme.textPrimary,
        primary: theme.primaryColor,
        onPrimary: isDark ? Colors.white : Colors.white,
        secondary: theme.accentColor,
        error: const Color(0xFFFF4B4B),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: theme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: theme.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.cornerRadius)),
      ),
      dividerTheme: DividerThemeData(
        color: theme.dividerColor,
        thickness: 0.5,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => 
            s.contains(WidgetState.selected) ? theme.primaryColor : (isDark ? Colors.grey[600] : Colors.grey[400])),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? theme.primaryColor.withValues(alpha: 0.3)
                : (isDark ? Colors.white10 : Colors.grey[200])),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.surfaceColor,
        hintStyle: TextStyle(color: theme.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.cornerRadius)),
          textStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: theme.surfaceColor,
        indicatorColor: theme.primaryColor.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((s) =>
            IconThemeData(color: s.contains(WidgetState.selected) ? theme.primaryColor : theme.textSecondary)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) =>
            GoogleFonts.outfit(color: s.contains(WidgetState.selected) ? theme.primaryColor : theme.textSecondary, fontSize: 12)),
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: theme.textPrimary,
        displayColor: theme.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? theme.cardColor : theme.textPrimary,
        contentTextStyle: GoogleFonts.outfit(color: isDark ? theme.textPrimary : theme.backgroundColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  bool get isDark => theme.brightness == Brightness.dark;
  Color get primary => theme.primaryColor;
  Color get accent => theme.colorScheme.secondary;
  Color get bg => theme.scaffoldBackgroundColor;
  Color get surface => theme.colorScheme.surface;
  Color get cardBg => theme.cardTheme.color ?? theme.colorScheme.surface;
  Color get divider => theme.dividerTheme.color ?? theme.dividerColor;
  
  Color get textPrimary => theme.textTheme.bodyLarge?.color ?? (theme.brightness == Brightness.dark ? Colors.white : Colors.black);
  Color get textSecondary => theme.textTheme.bodyMedium?.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87);
  Color get textHint => theme.textTheme.bodySmall?.color ?? (theme.brightness == Brightness.dark ? Colors.white54 : Colors.black54);
  
  Color get iconPrimary => theme.iconTheme.color ?? (theme.brightness == Brightness.dark ? Colors.white : Colors.black);
  Color get iconSecondary => iconPrimary.withOpacity(0.7);
  Color get iconMuted => iconPrimary.withOpacity(0.4);
  
  Color get inputFill => theme.inputDecorationTheme.fillColor ?? (theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[200]!);
  
  Color get shimmerBase => theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[300]!;
  Color get shimmerHighlight => theme.brightness == Brightness.dark ? Colors.white24 : Colors.grey[100]!;
}
