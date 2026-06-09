import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/karma/presentation/screens/karma_dashboard_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../l10n/app_localizations_x.dart';
import '../providers/language_provider.dart';
import '../providers/profile_providers.dart';
import '../providers/repository_providers.dart';
import '../theme/app_colors.dart';

class GlassSidebar extends ConsumerWidget {
  const GlassSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    ref.watch(languageProvider); // Force rebuild when language changes

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
      ),
      child: Drawer(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              // Semi-transparent background
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Profile Header ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
                      child: profileAsync.when(
                        data: (profile) {
                          if (profile == null) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: profile.photoUrl,
                                  imageBuilder: (context, imageProvider) =>
                                      CircleAvatar(
                                    radius: 36,
                                    backgroundColor: Colors.white,
                                    backgroundImage: imageProvider,
                                  ),
                                  placeholder: (context, url) =>
                                      const CircleAvatar(
                                    radius: 36,
                                    backgroundColor: Colors.white,
                                    child: BlurHash(
                                        hash: 'L5H2EC=pPdpWXVJs00QQV_9H00XY'),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const CircleAvatar(
                                    radius: 36,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.person,
                                        size: 36, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName
                                    : context.tr('sidebar_user_placeholder'),
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Karma Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: AppColors.electricGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.local_fire_department_rounded,
                                        size: 14,
                                        color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${profile.karma} ${context.tr('sidebar_karma_badge')}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(color: Colors.black12, height: 1),
                    ),
                    const SizedBox(height: 20),

                    // ── Menu Items ─────────────────────────────────────────
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _MenuItem(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Coming Soon',
                            subtitle: 'A new social experience is unfolding...',
                            isLocked: false,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1A1D26),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.auto_awesome_rounded,
                                          color: Colors.amber, size: 28),
                                      SizedBox(width: 12),
                                      Text(
                                        'Coming Soon',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  content: const Text(
                                    'A new social experience is unfolding...',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK',
                                          style: TextStyle(
                                              color: AppColors.electricBlue)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.local_fire_department_rounded,
                            title: context.tr('sidebar_karma'),
                            subtitle: context.tr('sidebar_karma_sub'),
                            isLocked: profileAsync.asData?.value?.isVerified ==
                                    false &&
                                profileAsync.asData?.value?.isLimitedUser !=
                                    true,
                            onTap: () {
                              final profile = profileAsync.asData?.value;
                              final isLimited = profile?.isLimitedUser == true;
                              if (profile?.isVerified == false && !isLimited) {
                                _showLockedFeatureNotice(
                                  context,
                                  ref,
                                  title:
                                      context.tr('sidebar_karma_locked_title'),
                                  message:
                                      context.tr('sidebar_karma_locked_desc'),
                                );
                                return;
                              }
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const KarmaDashboardScreen()));
                            },
                          ),
                          _MenuItem(
                            icon: Icons.settings_rounded,
                            title: context.tr('sidebar_settings'),
                            subtitle: context.tr('sidebar_settings_sub'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SettingsScreen()));
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLockedFeatureNotice(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded,
                color: AppColors.electricBlue, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.grey[400], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('btn_maybe_later'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final profile =
                  ref.read(currentUserProfileProvider).asData?.value;
              if (profile?.uid != null) {
                await ref.read(firestoreRepositoryProvider).setLimitedAccess(
                      uid: profile!.uid,
                      isLimited: false,
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(context.tr('mini_apps_enter_invite'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLocked = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                _isPressed ? Colors.white.withOpacity(0.4) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(widget.icon, size: 22, color: AppColors.electricBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                widget.isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: widget.isLocked
                    ? AppColors.electricBlue.withOpacity(0.5)
                    : Colors.black26,
              ),
            ],
          ),
        ),
      );
}
