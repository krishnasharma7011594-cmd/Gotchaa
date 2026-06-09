import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/permissions/permission_manager.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/vibetalk_providers.dart';

class VibeTalkIdleView extends ConsumerWidget {
  const VibeTalkIdleView({super.key});

  void _showUpgradePrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(context.tr('vibetalk_limit_title'),
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: context.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on_rounded,
                  size: 48, color: AppColors.electricBlue),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('vibetalk_limit_desc'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: context.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('vibetalk_maybe_later'),
                style: GoogleFonts.outfit(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // In production, navigate to invite screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.tr('vibetalk_unlock_now'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<bool> _showPreMatchSafetyChecklist(BuildContext context) async {
    bool agreed = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF141416), const Color(0xFF0C0C0D)]
                  : [Colors.white, const Color(0xFFF2F4F7)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Shield Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.electricBlue,
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Before You Match',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'GOTCHAA Safety Guidelines',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.electricBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Checklist Rules
              _buildRuleItem(
                isDark,
                icon: Icons.favorite_rounded,
                title: 'Be Respectful',
                desc:
                    'Treat everyone with kindness. Harassment, hate speech, or abuse will get you banned.',
              ),
              const SizedBox(height: 16),
              _buildRuleItem(
                isDark,
                icon: Icons.no_accounts_rounded,
                title: 'No Inappropriate Content',
                desc:
                    'Nudity, vulgarity, or sexually suggestive interactions are strictly prohibited.',
              ),
              const SizedBox(height: 16),
              _buildRuleItem(
                isDark,
                icon: Icons.privacy_tip_rounded,
                title: 'Protect Your Privacy',
                desc:
                    'Do not share phone numbers, social handles, or sensitive personal data.',
              ),
              const SizedBox(height: 24),

              // Agreement Checkbox
              Theme(
                data: Theme.of(context).copyWith(
                  unselectedWidgetColor:
                      isDark ? Colors.white30 : Colors.black38,
                ),
                child: CheckboxListTile(
                  value: agreed,
                  onChanged: (val) {
                    setModalState(() {
                      agreed = val ?? false;
                    });
                  },
                  activeColor: AppColors.electricBlue,
                  checkColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    'I confirm that I am 18 or older and will strictly abide by the safety rules.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Button Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white70
                            : Colors.black.withOpacity(0.7),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: agreed ? () => Navigator.pop(ctx, true) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            isDark ? Colors.white10 : Colors.black12,
                        disabledForegroundColor:
                            isDark ? Colors.white24 : Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: Text(
                        'Enable Matching',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Widget _buildRuleItem(bool isDark,
          {required IconData icon,
          required String title,
          required String desc}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.electricBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              context.bg,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with glowing effect
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(Icons.mic_none_rounded,
                      size: 80, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 48),
                Text(
                  context.tr('vibetalk_welcome'),
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('vibetalk_description'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: context.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 64),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final profile = ref
                              .read(currentUserProfileProvider)
                              .asData
                              ?.value;
                          final state = ref.read(vibeTalkProvider);

                          if (profile != null &&
                              !profile.isVerified &&
                              state.matchCount >= 5) {
                            _showUpgradePrompt(context);
                            return;
                          }

                          // Mandatory Pre-match Safety Checklist
                          final agreed =
                              await _showPreMatchSafetyChecklist(context);
                          if (!agreed) return;

                          final micGranted = await PermissionManager
                              .requestMicrophonePermission(context);
                          if (micGranted) {
                            await ref
                                .read(vibeTalkProvider.notifier)
                                .startMatching(isVideo: false);
                          }
                        },
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                AppColors.vibrantPurple,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.mic_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('vibetalk_start_chat'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final profile = ref
                              .read(currentUserProfileProvider)
                              .asData
                              ?.value;
                          final state = ref.read(vibeTalkProvider);

                          if (profile != null &&
                              !profile.isVerified &&
                              state.matchCount >= 5) {
                            _showUpgradePrompt(context);
                            return;
                          }

                          // Mandatory Pre-match Safety Checklist
                          final agreed =
                              await _showPreMatchSafetyChecklist(context);
                          if (!agreed) return;

                          final micGranted = await PermissionManager
                              .requestMicrophonePermission(context);
                          if (micGranted) {
                            final camGranted =
                                await PermissionManager.requestCameraPermission(
                                    context);
                            if (camGranted) {
                              await ref
                                  .read(vibeTalkProvider.notifier)
                                  .startMatching(isVideo: true);
                            }
                          }
                        },
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.electricBlue,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.electricBlue
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('vibetalk_start_video'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security_rounded,
                        size: 14, color: context.textHint),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('vibetalk_encrypted'),
                      style: TextStyle(fontSize: 12, color: context.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
