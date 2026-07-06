import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/post_model.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/post_providers.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/vybz_providers.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gotchaa_skeleton_loader.dart';
import '../../../home/presentation/screens/main_shell.dart';
import '../../../karma/presentation/screens/karma_dashboard_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'edit_profile_screen.dart';
import 'follow_list_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const SizedBox.shrink();
        }
        final isUnverified = profile.isVerified == false;
        return _ProfileView(profile: profile, isUnverified: isUnverified);
      },
      loading: () => const GotchaaSkeletonLoader.profile(),
      error: (e, _) => Scaffold(
        backgroundColor: context.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cloud_off_rounded, size: 56, color: context.iconMuted),
              const SizedBox(height: 16),
              Text(context.tr('profile_error_load'),
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary)),
              const SizedBox(height: 8),
              Text(context.tr('profile_error_network'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      color: context.textHint, fontSize: 14, height: 1.4)),
              const SizedBox(height: 24),
              Consumer(
                builder: (ctx, innerRef, _) => TextButton.icon(
                  onPressed: () =>
                      innerRef.invalidate(currentUserProfileProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('btn_retry'),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _ProfileView
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.profile, required this.isUnverified});
  final UserProfile profile;
  final bool isUnverified;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: context.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, ref),
              SliverToBoxAdapter(
                child: Column(children: [
                  _buildProfileHeader(context, ref),
                  _buildStatsSection(context, ref),
                  _buildKarmaBadge(context, ref),
                  _buildInviteCodeCard(context),
                  const SizedBox(height: 20),
                ]),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  context,
                  TabBar(
                    indicatorColor: AppColors.electricBlue,
                    indicatorWeight: 3,
                    labelColor: context.textPrimary,
                    unselectedLabelColor: context.textSecondary,
                    labelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    unselectedLabelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500, fontSize: 14),
                    tabs: [
                      Tab(text: context.tr('profile_tab_posts')),
                      Tab(text: context.tr('profile_tab_vybz')),
                      Tab(text: context.tr('profile_tab_saved')),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(children: [
                  _RealPostsGrid(uid: profile.uid),
                  _buildVybzGrid(context, ref, profile.uid),
                  _buildEmptyTab(context, context.tr('profile_empty_saved')),
                ]),
              ),
            ],
          ),
        ),
      );

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) =>
      SliverAppBar(
        expandedHeight: 280,
        pinned: true,
        stretch: true,
        backgroundColor: context.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
          onPressed: () => mainShellScaffoldKey.currentState?.openDrawer(),
        ),
        flexibleSpace: FlexibleSpaceBar(
          stretchModes: const [StretchMode.zoomBackground],
          background: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.electricBlue.withValues(alpha: 0.7),
                      Colors.purple.withValues(alpha: 0.4),
                      Colors.blue.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        context.bg.withValues(alpha: 0.8),
                        context.bg,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: context.shimmerBase,
                      backgroundImage: profile.photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(profile.photoUrl)
                          : null,
                      child: profile.photoUrl.isEmpty
                          ? Text(
                              profile.displayName.isNotEmpty
                                  ? profile.displayName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.outfit(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.displayName,
                      style: GoogleFonts.outfit(
                          color: context.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  Text(
                    profile.username.isNotEmpty
                        ? '@${profile.username}'
                        : profile.email,
                    style: GoogleFonts.outfit(
                        color: context.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (!profile.isVerified) {
                _showLockedFeatureNotice(
                  context,
                  ref,
                  context.tr('profile_sharing_locked'),
                  context.tr('profile_sharing_locked_msg'),
                );
                return;
              }
              Share.share(
                  context.tr('profile_share_msg', args: [profile.inviteCode]));
              AnalyticsService.logInviteSent();
            },
            icon: const Icon(Icons.share_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: context.tr('logout'),
          ),
        ],
      );

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bio Section
            Text(
              context.tr('profile_bio_label'),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.textHint,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              profile.bio.isNotEmpty
                  ? profile.bio
                  : context.tr('profile_bio_empty'),
              style: GoogleFonts.outfit(
                  color: context.textSecondary, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(children: [
              Expanded(
                child: _ActionButton(
                  label: context.tr('profile_edit'),
                  isPrimary: true,
                  onTap: () {
                    ref.read(activityServiceProvider).logAction();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                EditProfileScreen(profile: profile)));
                  },
                ),
              ),
            ]),
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                label: context.tr('profile_dashboard'),
                isPrimary: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AnalyticsDashboardScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildStatsSection(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(profile.uid));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat(
            context,
            postsAsync.when(
                data: (list) => list.length.toString(),
                error: (_, __) => '0',
                loading: () => '…'),
            context.tr('profile_tab_posts'),
          ),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FollowListScreen(
                  uid: profile.uid,
                  username: profile.username,
                  showFollowers: true,
                ),
              ),
            ),
            child: _buildStat(context, profile.followersCount.toString(),
                context.tr('profile_followers')),
          ),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FollowListScreen(
                  uid: profile.uid,
                  username: profile.username,
                  showFollowers: false,
                ),
              ),
            ),
            child: _buildStat(context, profile.followingCount.toString(),
                context.tr('profile_following')),
          ),
          _buildStat(
            context,
            (isUnverified && !profile.isLimitedUser)
                ? '🔒'
                : profile.karma.toString(),
            context.tr('profile_karma'),
            isBlurred: isUnverified && !profile.isLimitedUser,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label,
          {bool isBlurred = false}) =>
      Column(children: [
        if (isBlurred)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary)),
          )
        else
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary)),
        Text(label,
            style:
                GoogleFonts.outfit(fontSize: 13, color: context.textSecondary)),
      ]);

  Widget _buildKarmaBadge(BuildContext context, WidgetRef ref) =>
      GestureDetector(
        onTap: () {
          final isLimited = profile.isLimitedUser == true;
          if (isUnverified && !isLimited) {
            _showLockedFeatureNotice(
              context,
              ref,
              context.tr('profile_locked_karma_title'),
              context.tr('profile_locked_karma_msg'),
            );
            return;
          }
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const KarmaDashboardScreen()));
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.electricGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: AppColors.electricBlue.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            if (isUnverified && !profile.isLimitedUser)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Text(
                    context.tr('profile_karma_score',
                        args: [profile.karma.toString()]),
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              )
            else
              Text(
                  context.tr('profile_karma_score',
                      args: [profile.karma.toString()]),
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            if (isUnverified && !profile.isLimitedUser) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock_outline_rounded,
                  color: Colors.white, size: 16),
            ],
          ]),
        ).animate().shimmer(duration: 2.seconds),
      );

  Widget _buildInviteCodeCard(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_rounded,
                    color: AppColors.electricBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.tr('profile_invite_friends'),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              profile.isVerified
                  ? context.tr('profile_invite_desc')
                  : context.tr('profile_invite_desc_locked'),
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (!profile.isVerified)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: Colors.white24, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('profile_verification_required'),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: context.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildUsageStat(context, '${profile.remainingInvites}',
                      context.tr('profile_invite_left')),
                  const SizedBox(width: 12),
                  _buildUsageStat(context, '${profile.totalInvites}',
                      context.tr('profile_invite_total')),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      profile.inviteCode,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.electricBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: profile.inviteCode));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(context.tr('profile_invite_copied'))),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    color: context.iconSecondary,
                  ),
                  IconButton(
                    onPressed: () {
                      Share.share(context.tr('profile_invite_msg_alt',
                          args: [profile.inviteCode]));
                      AnalyticsService.logInviteSent();
                    },
                    icon: const Icon(Icons.share_rounded, size: 20),
                    color: context.iconSecondary,
                  ),
                ],
              ),
            ],
          ],
        ),
      );

  Widget _buildUsageStat(BuildContext context, String value, String label) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary)),
          Text(label,
              style: GoogleFonts.outfit(fontSize: 10, color: context.textHint)),
        ],
      );

  void _showLockedFeatureNotice(
      BuildContext context, WidgetRef ref, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded,
                color: AppColors.electricBlue, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                  color: context.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: context.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('btn_maybe_later'),
                style: TextStyle(color: context.textHint)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = ref.read(currentUserProvider)?.uid;
              if (uid != null) {
                await ref.read(firestoreRepositoryProvider).setLimitedAccess(
                      uid: uid,
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

  Widget _buildVybzGrid(BuildContext context, WidgetRef ref, String uid) {
    final vybzAsync = ref.watch(userVybzProvider(uid));
    return vybzAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return _buildEmptyTab(context, context.tr('profile_empty_vybz'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final vybz = list[index];
            return GestureDetector(
              onTap: () {
                // Navigate to Vybz feed tab
                // (Shell navigation to Vybz handled by main nav)
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (vybz.thumbnailUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: vybz.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.videocam_rounded,
                            color: Colors.white10, size: 36),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade900,
                      child: const Icon(Icons.videocam_rounded,
                          color: Colors.white10, size: 36),
                    ),
                  // Premium overlay: play icon + gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_outline_rounded,
                        color: Colors.white70, size: 32),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          _buildEmptyTab(context, context.tr('profile_error_vybz')),
    );
  }

  Widget _buildEmptyTab(BuildContext context, String message) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_rounded, size: 40, color: context.iconMuted),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.outfit(
                  color: context.textSecondary, fontSize: 14)),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// _RealPostsGrid
// ═══════════════════════════════════════════════════════════════════════════════

class _RealPostsGrid extends ConsumerWidget {
  const _RealPostsGrid({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(uid));
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.camera_alt_outlined,
                  size: 48, color: context.iconMuted),
              const SizedBox(height: 12),
              Text(context.tr('profile_empty_posts'),
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary)),
              const SizedBox(height: 6),
              Text(context.tr('profile_share_first'),
                  style: GoogleFonts.outfit(
                      color: context.textHint, fontSize: 13)),
            ]),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () => _showPostDetail(context, post),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (post.mediaUrl.isNotEmpty)
                    if (post.isVideo && post.mediaThumbnailUrl.isEmpty)
                      Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.videocam_rounded,
                            color: Colors.white24, size: 32),
                      )
                    else
                      CachedNetworkImage(
                        imageUrl: post.isVideo
                            ? post.mediaThumbnailUrl
                            : post.mediaUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: context.shimmerBase,
                          child: const Center(
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade900,
                          child: const Icon(Icons.videocam_rounded,
                              color: Colors.white24, size: 32),
                        ),
                      )
                  else
                    Container(
                      color: context.shimmerBase,
                      child: Icon(Icons.image_rounded,
                          color: context.iconSecondary),
                    ),
                  // Show video icon badge for video posts
                  if (post.isVideo)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.videocam_rounded,
                          color: Colors.white,
                          size: 18,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4)
                          ]),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline_rounded, size: 40, color: context.iconMuted),
          const SizedBox(height: 12),
          Text(context.tr('profile_error_posts'),
              style: GoogleFonts.outfit(color: context.textSecondary)),
        ]),
      ),
    );
  }

  void _showPostDetail(BuildContext context, PostModel post) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (post.mediaUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: post.isVideo
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        if (post.mediaThumbnailUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: post.mediaThumbnailUrl,
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            width: double.infinity,
                            height: 300,
                            color: Colors.grey.shade900,
                            child: const Icon(Icons.videocam_rounded,
                                color: Colors.white24, size: 50),
                          ),
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 64,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 8)
                          ],
                        ),
                      ],
                    )
                  : CachedNetworkImage(
                      imageUrl: post.mediaUrl,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.caption.isNotEmpty)
                  Text(post.caption,
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          height: 1.4,
                          color: context.textPrimary)),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.favorite_rounded,
                      size: 16, color: Colors.red.shade300),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: context.textSecondary)),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 16, color: context.iconMuted),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: context.textSecondary)),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Reusable sub-widgets ────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.label, required this.isPrimary, this.onTap});
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.electricBlue : context.inputFill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.outfit(
                  color: isPrimary ? Colors.white : context.textPrimary,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ),
      );
}

class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ElevatedButton.icon(
        onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        icon: const Icon(Icons.logout_rounded),
        label: Text('Sign Out', style: GoogleFonts.outfit()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
}

// ── Sliver tab-bar delegate ─────────────────────────────────────────────────

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._context, this._tabBar);
  final BuildContext _context;
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: _context.surface, child: _tabBar);

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
