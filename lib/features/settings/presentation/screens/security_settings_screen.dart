import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/security/secure_screen.dart';
import '../../../../core/theme/app_colors.dart';
import 'active_sessions_screen.dart';
import 'e2ee_key_management_screen.dart';
import 'two_factor_setup_screen.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SecureScreen(
      child: Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FB),
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('security_title'),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
                color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSecuritySection(
            context,
            context.tr('security_section_login'),
            [
              _SecurityTile(
                title: context.tr('security_tile_password'),
                icon: Icons.key_rounded,
                onTap: () => _handlePasswordReset(context),
              ),
              profileAsync.when(
                data: (profile) => _SecurityTileSwitch(
                  title: context.tr('security_tile_2fa'),
                  icon: Icons.phonelink_lock_rounded,
                  value: profile?.isTwoFactorEnabled ?? false,
                  onChanged: (v) {
                    if (v) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const TwoFactorSetupScreen()));
                    } else {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        ref.read(profileRepositoryProvider).updatePrivacySettings(
                          uid: uid,
                          settings: {'isTwoFactorEnabled': false},
                        );
                      }
                    }
                  },
                ),
                loading: () => _SecurityTile(title: context.tr('loading'), icon: Icons.refresh, onTap: null),
                error: (_, __) => _SecurityTile(title: context.tr('error_loading'), icon: Icons.error, onTap: null),
              ),
              _SecurityTile(
                title: context.tr('security_tile_saved_login'),
                icon: Icons.save_rounded,
                onTap: () => _showComingSoon(context, context.tr('security_tile_saved_login')),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSecuritySection(
            context,
            'End-to-End Encryption',
            [
              _SecurityTile(
                title: 'Encryption & Keys',
                icon: Icons.enhanced_encryption_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const E2eeKeyManagementScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSecuritySection(
            context,
            context.tr('security_section_checks'),
            [
              _SecurityTile(
                title: 'Active Sessions',
                icon: Icons.devices_rounded,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ActiveSessionsScreen())),
              ),
              _SecurityTile(
                title: context.tr('security_tile_emails'),
                icon: Icons.email_outlined,
                onTap: () => _showComingSoon(context, context.tr('security_tile_emails')),
              ),
              _SecurityTile(
                title: context.tr('security_tile_checkup'),
                icon: Icons.verified_user_outlined,
                onTap: () => _showComingSoon(context, context.tr('security_tile_checkup')),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('security_footer_desc'),
            style: GoogleFonts.outfit(
              color: Colors.grey,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _handlePasswordReset(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('security_password_reset_sent'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('error_prefix', args: [e.toString()]))),
          );
        }
      }
    }
  }

  void _showComingSoon(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.outfit()),
        content: Text(context.tr('security_coming_soon', namedArgs: {'title': title}), style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('ok'))),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, String title, List<Widget> tiles) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: tiles,
          ),
        ),
      ],
    );
  }
}

class _SecurityTile extends StatelessWidget {

  const _SecurityTile({
    required this.title,
    required this.icon,
    this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.electricBlue, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
class _SecurityTileSwitch extends StatelessWidget {

  const _SecurityTileSwitch({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.electricBlue, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.electricBlue,
          ),
        ],
      ),
    );
  }
}
