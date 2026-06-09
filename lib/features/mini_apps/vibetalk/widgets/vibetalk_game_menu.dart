import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/vibetalk_providers.dart';
import '../services/vibetalk_game_service.dart';

void showVibeTalkGameMenu(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 5,
            )
          ]
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Break the Ice 🧊',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
            const SizedBox(height: 6),
            Text(
              'Choose a mini-game to play with your match',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 14,
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: VibeTalkGameService.availableGameTypes.asMap().entries.map((entry) {
                final index = entry.key;
                final type = entry.value;
                return _buildGameOption(context, ref, type)
                    .animate(delay: (100 + (index * 50)).ms)
                    .fadeIn(duration: 300.ms)
                    .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
  );
}

Widget _buildGameOption(BuildContext context, WidgetRef ref, String type) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        ref.read(vibeTalkProvider.notifier).startGame(type);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      splashColor: context.accent.withValues(alpha: 0.2),
      highlightColor: context.accent.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: context.accent.withValues(alpha: 0.08),
          border: Border.all(color: context.accent.withValues(alpha: 0.2), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          VibeTalkGameService.getLabelForType(type),
          style: TextStyle(
            color: context.accent, 
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    ),
  );

