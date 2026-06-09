import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/vibetalk_providers.dart';

class VibeTalkMatchingView extends ConsumerStatefulWidget {
  const VibeTalkMatchingView({super.key});

  @override
  ConsumerState<VibeTalkMatchingView> createState() =>
      _VibeTalkMatchingViewState();
}

class _VibeTalkMatchingViewState extends ConsumerState<VibeTalkMatchingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      context.accent,
                      context.accent.withValues(alpha: 0.5)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.accent.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: Colors.white, size: 50),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              context.tr('vibetalk_finding_match'),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('vibetalk_analyzing_vibes'),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: context.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 64),
            GestureDetector(
              onTap: () => ref.read(vibeTalkProvider.notifier).endChat(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: context.inputFill,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded,
                        color: Theme.of(context).colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('vibetalk_cancel_search'),
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
