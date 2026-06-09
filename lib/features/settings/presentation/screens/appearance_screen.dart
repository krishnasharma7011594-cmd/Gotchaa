import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme_model.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Appearance & Themes', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // ── Live Mini Chat Preview ──────────────────────────────────────────
          _buildLivePreview(context, themeState.currentTheme),

          const SizedBox(height: 32),

          // ── Dark Themes ─────────────────────────────────────────────────────
          _buildThemeSection(
            context,
            ref,
            'Dark Themes',
            ThemeType.values.where((t) => 
              AppThemes.allThemes[t]!.brightness == Brightness.dark && 
              t != ThemeType.aurora && 
              t != ThemeType.auroraLight
            ).toList(),
            themeState.darkThemeType,
          ),

          const SizedBox(height: 24),

          // ── Light Themes ────────────────────────────────────────────────────
          _buildThemeSection(
            context,
            ref,
            'Light Themes',
            ThemeType.values.where((t) => 
              AppThemes.allThemes[t]!.brightness == Brightness.light && 
              t != ThemeType.aurora && 
              t != ThemeType.auroraLight
            ).toList(),
            themeState.lightThemeType,
          ),

          const SizedBox(height: 24),

          // ── Universal ──────────────────────────────────────────────────────
          _buildUniversalSection(context, ref, themeState),

          const SizedBox(height: 32),

          // ── Theme Mode ──────────────────────────────────────────────────────
          _buildModeSelector(context, ref, themeState),

          const SizedBox(height: 24),

          // ── Message Corner Radius ──────────────────────────────────────────
          _buildCornerRadiusSlider(context, ref, themeState),

          const SizedBox(height: 24),

          // ── Chat List View ──────────────────────────────────────────────────
          _buildChatListViewSelector(context, ref, themeState),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLivePreview(BuildContext context, GotchaaThemeData theme) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMiniBubble(theme, 'Hey! Check out this new theme ✨', true),
          const SizedBox(height: 12),
          _buildMiniBubble(theme, 'Wow, looks super premium! 😍', false),
          const SizedBox(height: 12),
          _buildMiniBubble(theme, 'The colors are so smooth.', true),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));

  Widget _buildMiniBubble(GotchaaThemeData theme, String text, bool isMe) => Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: isMe ? theme.bubbleMe : theme.bubbleThem,
          borderRadius: BorderRadius.circular(theme.cornerRadius).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
          gradient: isMe ? theme.accentGradient : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: isMe ? Colors.white : theme.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );

  Widget _buildThemeSection(BuildContext context, WidgetRef ref, String title, List<ThemeType> themes, ThemeType selectedType) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final type = themes[index];
              final theme = AppThemes.allThemes[type]!;
              final isSelected = selectedType == type;

              return GestureDetector(
                onTap: () => ref.read(themeProvider.notifier).setThemeType(type),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? theme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 8)
                    ] : [],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [theme.backgroundColor, theme.primaryColor],
                            ),
                          ),
                          child: Center(
                            child: isSelected 
                              ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24)
                              : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        theme.name.split(' ').first,
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );

  Widget _buildUniversalSection(BuildContext context, WidgetRef ref, GotchaaThemeState themeState) {
    final theme = AppThemes.allThemes[ThemeType.aurora]!;
    final isSelected = themeState.darkThemeType == ThemeType.aurora || themeState.lightThemeType == ThemeType.aurora;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Universal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => ref.read(themeProvider.notifier).setThemeType(ThemeType.aurora),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: theme.accentGradient,
                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                boxShadow: isSelected ? [
                  BoxShadow(color: theme.primaryColor.withValues(alpha: 0.4), blurRadius: 15)
                ] : [],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aurora', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Premium adaptive theme', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.check_circle_rounded, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, WidgetRef ref, GotchaaThemeState themeState) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildModeBtn(context, ref, 'Light', ThemeMode.light, themeState.themeMode == ThemeMode.light),
            _buildModeBtn(context, ref, 'Dark', ThemeMode.dark, themeState.themeMode == ThemeMode.dark),
            _buildModeBtn(context, ref, 'System', ThemeMode.system, themeState.themeMode == ThemeMode.system),
          ],
        ),
      ),
    );

  Widget _buildModeBtn(BuildContext context, WidgetRef ref, String label, ThemeMode mode, bool isSelected) => Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).cardTheme.color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
            ] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
          ),
        ),
      ),
    );

  Widget _buildCornerRadiusSlider(BuildContext context, WidgetRef ref, GotchaaThemeState themeState) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Message Corner Radius', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              Text('${themeState.messageCornerRadius.toInt()}px', style: GoogleFonts.outfit(color: Colors.grey)),
            ],
          ),
          Slider(
            value: themeState.messageCornerRadius,
            min: 4,
            max: 28,
            activeColor: themeState.currentTheme.primaryColor,
            onChanged: (v) => ref.read(themeProvider.notifier).setCornerRadius(v),
          ),
        ],
      ),
    );

  Widget _buildChatListViewSelector(BuildContext context, WidgetRef ref, GotchaaThemeState themeState) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chat List View', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChatLineBtn(context, ref, 'Two Lines', 2, themeState.chatListViewLines == 2),
              const SizedBox(width: 12),
              _buildChatLineBtn(context, ref, 'Three Lines', 3, themeState.chatListViewLines == 3),
            ],
          ),
        ],
      ),
    );

  Widget _buildChatLineBtn(BuildContext context, WidgetRef ref, String label, int lines, bool isSelected) => Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).setChatListViewLines(lines),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                lines == 2 ? Icons.view_headline_rounded : Icons.view_list_rounded,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
