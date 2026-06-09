import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Reusable empty state widget used across the app.
///
/// Shows a large icon, bold title, subtitle, and an optional action button.
/// Used on: home feed (no posts), chat list (no conversations),
/// notifications (no alerts), explore (no results), followers (no followers).
class GotchaaEmptyState extends StatelessWidget {
  const GotchaaEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.animate = true,
  });

  // ── Named constructors for common states ────────────────────────────────

  const GotchaaEmptyState.feed({
    super.key,
    this.actionLabel,
    this.onAction,
  })  : icon = Icons.auto_awesome_outlined,
        title = 'Your feed is quiet',
        subtitle = 'Follow people or explore trending content to fill it up!',
        iconColor = null,
        animate = true;

  const GotchaaEmptyState.following({
    super.key,
    this.actionLabel,
    this.onAction,
  })  : icon = Icons.people_outline_rounded,
        title = 'No posts from people you follow',
        subtitle =
            'Discover and follow interesting people to see their posts here.',
        iconColor = null,
        animate = true;

  const GotchaaEmptyState.chat({
    super.key,
    this.actionLabel,
    this.onAction,
  })  : icon = Icons.chat_bubble_outline_rounded,
        title = 'No conversations yet',
        subtitle =
            'Find someone interesting and start an encrypted conversation.',
        iconColor = null,
        animate = true;

  const GotchaaEmptyState.notifications({
    super.key,
    this.actionLabel,
    this.onAction,
  })  : icon = Icons.notifications_none_rounded,
        title = 'All caught up!',
        subtitle = 'You have no new notifications. Go make some connections!',
        iconColor = null,
        animate = true;

  const GotchaaEmptyState.search({
    super.key,
    this.actionLabel,
    this.onAction,
  })  : icon = Icons.search_off_rounded,
        title = 'No results found',
        subtitle = 'Try a different username, language, or keyword.',
        iconColor = null,
        animate = true;

  const GotchaaEmptyState.followers({
    super.key,
    this.actionLabel,
    this.onAction,
  })  : icon = Icons.group_add_outlined,
        title = 'No followers yet',
        subtitle =
            'Share your profile and connect with people in your language.',
        iconColor = null,
        animate = true;

  const GotchaaEmptyState.vybz({
    super.key,
    this.actionLabel,
    this.onAction,
  })  : icon = Icons.play_circle_outline_rounded,
        title = 'No Vybz yet',
        subtitle = 'Record and share your first short video to get discovered.',
        iconColor = null,
        animate = true;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.electricBlue;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing icon container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: animate ? 0.0 : 1.0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child:
                    Icon(icon, size: 44, color: color.withValues(alpha: 0.8)),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),

            // Optional action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
