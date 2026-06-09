import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/age_provider.dart';

enum RestrictionType {
  social,
  adult,
}

class RestrictedFeature extends ConsumerWidget {
  const RestrictedFeature({
    required this.child,
    super.key,
    this.type = RestrictionType.social,
    this.fallback,
  });
  final Widget child;
  final RestrictionType type;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageStatus = ref.watch(ageProvider);
    final notifier = ref.read(ageProvider.notifier);

    bool hasAccess = false;
    if (type == RestrictionType.social) {
      hasAccess = notifier.canAccessSocialFeatures();
    } else {
      hasAccess = notifier.canAccessAdultContent();
    }

    if (hasAccess) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    // Default restricted UI
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: isDark ? Colors.white38 : Colors.black38,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            notifier.getInaccessibilityMessage(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
