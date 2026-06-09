import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme_model.dart';
import 'shared_prefs_provider.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, GotchaaThemeState>(ThemeNotifier.new);

class GotchaaThemeState {

  GotchaaThemeState({
    required this.currentTheme,
    required this.themeMode,
    required this.darkThemeType,
    required this.lightThemeType,
    this.messageCornerRadius = 16.0,
    this.chatListViewLines = 2,
  });

  factory GotchaaThemeState.initial() => GotchaaThemeState(
      currentTheme: AppThemes.allThemes[ThemeType.gotchaaLight]!,
      themeMode: ThemeMode.system,
      darkThemeType: ThemeType.midnightPurple,
      lightThemeType: ThemeType.softLavender,
      messageCornerRadius: 16,
      chatListViewLines: 2,
    );
  final GotchaaThemeData currentTheme;
  final ThemeMode themeMode;
  final ThemeType darkThemeType;
  final ThemeType lightThemeType;
  final double messageCornerRadius;
  final int chatListViewLines;

  GotchaaThemeState copyWith({
    GotchaaThemeData? currentTheme,
    ThemeMode? themeMode,
    ThemeType? darkThemeType,
    ThemeType? lightThemeType,
    double? messageCornerRadius,
    int? chatListViewLines,
  }) => GotchaaThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      themeMode: themeMode ?? this.themeMode,
      darkThemeType: darkThemeType ?? this.darkThemeType,
      lightThemeType: lightThemeType ?? this.lightThemeType,
      messageCornerRadius: messageCornerRadius ?? this.messageCornerRadius,
      chatListViewLines: chatListViewLines ?? this.chatListViewLines,
    );
}

class ThemeNotifier extends StateNotifier<GotchaaThemeState> {

  ThemeNotifier(this.ref) : super(GotchaaThemeState.initial()) {
    Future.microtask(_loadFromPrefs);
  }
  final Ref ref;

  void _loadFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    final modeIndex = prefs.getInt('theme_mode') ?? ThemeMode.system.index;
    final darkTypeName = prefs.getString('dark_theme_type') ?? ThemeType.midnightPurple.name;
    final lightTypeName = prefs.getString('light_theme_type') ?? ThemeType.softLavender.name;
    final cornerRadius = prefs.getDouble('message_corner_radius') ?? 16.0;
    final chatLines = prefs.getInt('chat_list_view_lines') ?? 2;

    final darkType = ThemeType.values.firstWhere((e) => e.name == darkTypeName, orElse: () => ThemeType.midnightPurple);
    final lightType = ThemeType.values.firstWhere((e) => e.name == lightTypeName, orElse: () => ThemeType.softLavender);

    state = GotchaaThemeState(
      currentTheme: AppThemes.allThemes[darkType]!,
      themeMode: ThemeMode.values[modeIndex],
      darkThemeType: darkType,
      lightThemeType: lightType,
      messageCornerRadius: cornerRadius,
      chatListViewLines: chatLines,
    );
    
    _updateCurrentTheme();
  }

  void _updateCurrentTheme() {
    Brightness brightness;
    if (state.themeMode == ThemeMode.system) {
      brightness = ui.PlatformDispatcher.instance.platformBrightness;
    } else {
      brightness = state.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
    }

    final theme = (brightness == Brightness.light) 
      ? AppThemes.allThemes[state.lightThemeType]! 
      : AppThemes.allThemes[state.darkThemeType]!;
      
    state = state.copyWith(currentTheme: theme.copyWith(cornerRadius: state.messageCornerRadius));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('theme_mode', mode.index);
    _updateCurrentTheme();
    HapticFeedback.lightImpact();
  }

  Future<void> setThemeType(ThemeType type) async {
    final prefs = ref.read(sharedPreferencesProvider);
    
    if (type == ThemeType.aurora || type == ThemeType.auroraLight) {
      // Universal theme logic
      state = state.copyWith(
        darkThemeType: ThemeType.aurora,
        lightThemeType: ThemeType.auroraLight,
      );
      await prefs.setString('dark_theme_type', ThemeType.aurora.name);
      await prefs.setString('light_theme_type', ThemeType.auroraLight.name);
    } else {
      final isDark = AppThemes.allThemes[type]!.brightness == Brightness.dark;
      if (isDark) {
        state = state.copyWith(darkThemeType: type);
        await prefs.setString('dark_theme_type', type.name);
      } else {
        state = state.copyWith(lightThemeType: type);
        await prefs.setString('light_theme_type', type.name);
      }
    }
    
    _updateCurrentTheme();
    HapticFeedback.mediumImpact();
  }

  Future<void> setCornerRadius(double radius) async {
    state = state.copyWith(messageCornerRadius: radius);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('message_corner_radius', radius);
    _updateCurrentTheme();
  }

  Future<void> setChatListViewLines(int lines) async {
    state = state.copyWith(chatListViewLines: lines);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('chat_list_view_lines', lines);
  }
}
