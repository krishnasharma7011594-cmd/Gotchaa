import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class VibeTalkCooldownScreen extends StatelessWidget {
  const VibeTalkCooldownScreen({super.key});

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_off_rounded, size: 64, color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 32),
            Text(
              'Take a Breath 🧘',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You've skipped too many matches recently. Please wait a moment before trying again to keep the community healthy.",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Unlocking in 55s',
              style: TextStyle(color: context.textHint, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
}

