import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/post_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/shell_navigation_provider.dart';
import '../../../../core/providers/social_providers.dart';
import '../../../../core/providers/vybz_providers.dart';
import '../../../../core/services/block_mute_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../chat/presentation/screens/chat_conversation_screen.dart';
import '../../../explore/presentation/screens/post_detail_screen.dart';
import '../../../reporting/report_dialog.dart';
import 'creator_analytics_screen.dart';
import 'follow_list_screen.dart';

/// A provider that streams another user's profile by uid.
final _otherProfileProvider = StreamProvider.family<UserProfile?, String>(
    (ref, uid) =>
        ref.watch(firestoreRepositoryProvider).getUserProfileStream(uid));

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({required this.uid, super.key});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(currentUserProvider)?.uid;
    final blockedUids = ref.watch(blockedUidsProvider).value ?? [];

    if (myUid != null && blockedUids.contains(uid)) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        appBar: AppBar(
          backgroundColor: AppColors.darkBg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'User not available',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final profileAsync = ref.watch(_otherProfileProvider(uid));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('profile_title'))),
            body: Center(child: Text(context.tr('user_not_found'))),
          );
        }
        return _OtherProfileView(
          profile: profile,
          myUid: myUid ?? '',
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
            child: Text(context.tr('error_prefix', args: [e.toString()]))),
      ),
    );
  }
}

class _OtherProfileView extends ConsumerStatefulWidget {
  const _OtherProfileView({
    required this.profile,
    required this.myUid,
  });
  final UserProfile profile;
  final String myUid;

  @override
  ConsumerState<_OtherProfileView> createState() => _OtherProfileViewState();
}

class _OtherProfileViewState extends ConsumerState<_OtherProfileView> {
  int _selectedTab = 0; // 0 for Posts, 1 for Vybz
  bool _isFollowingInitialized = false;
  bool _isFollowingLocal = false;
  int _followersCountLocal = 0;
  bool _isMessageLoading = false;

  @override
  void initState() {
    super.initState();
    _followersCountLocal = widget.profile.followersCount;
  }

  @override
  void didUpdateWidget(covariant _OtherProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isFollowingInitialized &&
        widget.profile.followersCount != oldWidget.profile.followersCount) {
      _followersCountLocal = widget.profile.followersCount;
    }
  }

  void _handleFollowStreamUpdate(bool isStreamFollowing) {
    if (!_isFollowingInitialized) {
      _isFollowingLocal = isStreamFollowing;
      _isFollowingInitialized = true;
    }
  }

  void _toggleFollow() {
    final willFollow = !_isFollowingLocal;
    setState(() {
      _isFollowingLocal = willFollow;
      _followersCountLocal += willFollow ? 1 : -1;
    });

    final social = ref.read(socialRepositoryProvider);
    final firestoreRepo = ref.read(firestoreRepositoryProvider);

    if (willFollow) {
      // 1. Perform Follow
      social
          .followUser(myUid: widget.myUid, targetUid: widget.profile.uid)
          .catchError((e) {
        if (mounted) {
          setState(() {
            _isFollowingLocal = !willFollow;
            _followersCountLocal += willFollow ? -1 : 1;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(context.tr('error_prefix', args: [e.toString()]))));
        }
      });

      // 2. Automatically initialize chat so they show up in each other's lists
      firestoreRepo.getOrCreateDirectChat(widget.myUid, widget.profile.uid);
    } else {
      social
          .unfollowUser(myUid: widget.myUid, targetUid: widget.profile.uid)
          .catchError((e) {
        if (mounted) {
          setState(() {
            _isFollowingLocal = !willFollow;
            _followersCountLocal += willFollow ? -1 : 1;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(context.tr('error_prefix', args: [e.toString()]))));
        }
      });
    }
  }

  void _showProfileOptions(BuildContext context, bool isMuted) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
              title: Text(
                'Block @${widget.profile.username}',
                style: GoogleFonts.outfit(
                    color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.darkSurface,
                    title: Text('Block User',
                        style: GoogleFonts.outfit(color: Colors.white)),
                    content: Text(
                        'Are you sure you want to block @${widget.profile.username}? They will not be able to message you, view your profile, or see your posts.',
                        style: GoogleFonts.outfit(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel',
                            style: GoogleFonts.outfit(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Block',
                            style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(profileRepositoryProvider).blockUser(
                        currentUid: widget.myUid,
                        targetUid: widget.profile.uid,
                      );
                  if (mounted) {
                    Navigator.pop(
                        context); // Go back since they are now blocked
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Blocked @${widget.profile.username}')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(
                  isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: Colors.white),
              title: Text(
                isMuted
                    ? 'Unmute @${widget.profile.username}'
                    : 'Mute @${widget.profile.username}',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                if (isMuted) {
                  await ref.read(profileRepositoryProvider).unmuteUser(
                        currentUid: widget.myUid,
                        targetUid: widget.profile.uid,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Unmuted @${widget.profile.username}')),
                    );
                  }
                } else {
                  await ref.read(profileRepositoryProvider).muteUser(
                        currentUid: widget.myUid,
                        targetUid: widget.profile.uid,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Muted @${widget.profile.username}')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.myUid == widget.profile.uid;
    final isPrivate = widget.profile.isPrivate ?? false;

    final mutedUids = ref.watch(mutedUidsProvider).value ?? [];
    final isMuted = mutedUids.contains(widget.profile.uid);

    // Check if following
    final followAsync = ref.watch(isFollowingProvider(
        (myUid: widget.myUid, targetUid: widget.profile.uid)));
    final isFollowing = followAsync.value ?? false;

    final showContent = isMe || !isPrivate || isFollowing;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.darkBg,
            elevation: 0,
            actions: [
              if (!isMe)
                IconButton(
                  icon: const Icon(Icons.flag_outlined, color: Colors.white),
                  tooltip: 'Report',
                  onPressed: () => showReportBottomSheet(
                    context,
                    reportedUserId: widget.profile.uid,
                    contentType: 'profile',
                    contentId: widget.profile.uid,
                    contentPreview: widget.profile.username,
                  ),
                ),
            ],
            flexibleSpace: RepaintBoundary(
              child: FlexibleSpaceBar(
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
                            AppColors.electricBlue.withValues(alpha: 0.6),
                            Colors.purple.withValues(alpha: 0.3),
                            Colors.blue.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.8),
                              Colors.white,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: Hero(
                              tag: 'profile_avatar_${widget.profile.uid}',
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade100,
                                backgroundImage:
                                    widget.profile.photoUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            widget.profile.photoUrl)
                                        : null,
                                child: widget.profile.photoUrl.isEmpty
                                    ? Text(
                                        widget.profile.displayName.isNotEmpty
                                            ? widget.profile.displayName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: GoogleFonts.outfit(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.electricBlue
                                              .withValues(alpha: 0.5),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.profile.displayName,
                            style: GoogleFonts.outfit(
                              color: Colors.black,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '@${widget.profile.username}',
                            style: GoogleFonts.outfit(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Block (Glass style)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.darkDivider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Consumer(builder: (context, innerRef, _) {
                          final postsAsync = innerRef
                              .watch(userPostsProvider(widget.profile.uid));
                          return _stat(
                            postsAsync.when(
                              data: (list) => list.length.toString(),
                              error: (_, __) => '0',
                              loading: () => '...',
                            ),
                            context.tr('profile_tab_posts'),
                          );
                        }),
                        Consumer(builder: (context, innerRef, _) {
                          // Sync local followers count with stream if not currently interacting
                          final profileStream = innerRef
                              .watch(_otherProfileProvider(widget.profile.uid));
                          final currentCount =
                              profileStream.value?.followersCount ??
                                  _followersCountLocal;

                          return InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowListScreen(
                                  uid: widget.profile.uid,
                                  username: widget.profile.username,
                                  showFollowers: true,
                                ),
                              ),
                            ),
                            child: _stat('$currentCount',
                                context.tr('profile_followers')),
                          );
                        }),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                uid: widget.profile.uid,
                                username: widget.profile.username,
                                showFollowers: false,
                              ),
                            ),
                          ),
                          child: _stat(widget.profile.followingCount.toString(),
                              context.tr('profile_following')),
                        ),
                        _stat(widget.profile.karma.toString(),
                            context.tr('profile_karma')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bio Section
                  Text(
                    context.tr('profile_bio_label'),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.electricBlue.withOpacity(0.8),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.profile.bio.isNotEmpty
                        ? widget.profile.bio
                        : context.tr('profile_bio_default'),
                    style: GoogleFonts.outfit(
                      color: AppColors.darkTextPrimary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions Row
                  if (isMe)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CreatorAnalyticsScreen())),
                        icon: const Icon(Icons.insights_rounded, size: 20),
                        label: Text(context.tr('profile_pro_dashboard')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          textStyle: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 48,
                            child: Consumer(builder: (context, innerRef, _) {
                              final followAsync = innerRef.watch(
                                  isFollowingProvider((
                                myUid: widget.myUid,
                                targetUid: widget.profile.uid
                              )));

                              // Sync local follow state with stream
                              final isFollowing =
                                  followAsync.value ?? _isFollowingLocal;

                              return ElevatedButton(
                                onPressed: _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowing
                                      ? AppColors.darkSurface
                                      : AppColors.electricBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: isFollowing
                                        ? const BorderSide(
                                            color: AppColors.darkDivider)
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Text(
                                  isFollowing
                                      ? context.tr('profile_following_status')
                                      : context.tr('profile_follow'),
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isMessageLoading
                                  ? null
                                  : () async {
                                      setState(() => _isMessageLoading = true);
                                      final safeMyUid = widget.myUid.isNotEmpty
                                          ? widget.myUid
                                          : ref.read(currentUserProvider)?.uid;

                                      if (safeMyUid == null) {
                                        setState(
                                            () => _isMessageLoading = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(context
                                                  .tr('login_to_message'))),
                                        );
                                        return;
                                      }

                                      try {
                                        final chatId = await ref
                                            .read(firestoreRepositoryProvider)
                                            .getOrCreateDirectChat(
                                              safeMyUid,
                                              widget.profile.uid,
                                            );

                                        if (mounted) {
                                          setState(
                                              () => _isMessageLoading = false);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ChatConversationScreen(
                                                chatId: chatId,
                                                userName:
                                                    widget.profile.displayName,
                                                userAvatar:
                                                    widget.profile.photoUrl,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          setState(
                                              () => _isMessageLoading = false);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(context.tr(
                                                    'start_chat_failed',
                                                    args: [e.toString()]))),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkSurface,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(
                                      color: AppColors.darkDivider),
                                ),
                              ),
                              child: _isMessageLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      context.tr('profile_message'),
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.darkDivider),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _showProfileOptions(context, isMuted);
                            },
                            icon: const Icon(Icons.more_horiz_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),

                  // Content Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: _TabButton(
                          label: context.tr('profile_tab_posts'),
                          isActive: _selectedTab == 0,
                        ),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: _TabButton(
                          label: context.tr('profile_tab_vybz'),
                          isActive: _selectedTab == 1,
                        ),
                      ),
                      const SizedBox(width: 24),
                      _TabButton(
                        label: context.tr('profile_tab_tagged'),
                        isActive: _selectedTab == 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────
          if (showContent)
            _selectedTab == 0
                ? _PostsGrid(uid: widget.profile.uid)
                : _VybzGrid(uid: widget.profile.uid)
          else
            SliverToBoxAdapter(
              child: _buildPrivateAccountPlaceholder(context),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivateAccountPlaceholder(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkDivider),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 40, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('profile_private_title'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('profile_private_msg'),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _stat(String value, String label) => Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkTextPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      );
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.isActive});
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? AppColors.darkTextPrimary
                  : AppColors.darkTextSecondary,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.electricBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Posts grid for a user
// ═══════════════════════════════════════════════════════════════════════════════

class _PostsGrid extends ConsumerWidget {
  const _PostsGrid({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(uid));

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 48, color: Colors.grey.shade200),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('profile_no_vibes'),
                      style: GoogleFonts.outfit(
                          color: Colors.grey.shade400, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final post = posts[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: post.mediaUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: post.mediaUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey.shade100),
                          )
                        : Container(
                            color:
                                AppColors.electricBlue.withValues(alpha: 0.05),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  post.caption,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: AppColors.electricBlue),
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              },
              childCount: posts.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(context.tr('profile_load_failed'),
                style: GoogleFonts.outfit(color: Colors.grey)),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Vybz grid for a user
// ═══════════════════════════════════════════════════════════════════════════════

class _VybzGrid extends ConsumerWidget {
  const _VybzGrid({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vybzAsync = ref.watch(userVybzProvider(uid));

    return vybzAsync.when(
      data: (vybzList) {
        if (vybzList.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(Icons.video_library_outlined,
                        size: 48, color: Colors.grey.shade200),
                    const SizedBox(height: 12),
                    Text(
                      'No Vybz yet',
                      style: GoogleFonts.outfit(
                          color: Colors.grey.shade400, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(userVybzProvider(uid)),
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.electricBlue, size: 16),
                      label: Text('Check for new Reels', style: GoogleFonts.outfit(color: AppColors.electricBlue)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 9 / 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final vybz = vybzList[i];
                return GestureDetector(
                  onTap: () {
                    // Navigate to Vybz Feed starting at this index
                    ref.read(shellPageControllerProvider).jumpToPage(3);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: AppColors.darkSurface),
                        const Center(
                            child: Icon(Icons.play_circle_outline,
                                color: Colors.white24, size: 30)),
                        if (vybz.videoUrl.isNotEmpty) ...[
                          // You could add a thumbnail here if you have one
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Row(
                              children: [
                                const Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  vybz.viewsCount.toString(),
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: vybzList.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text('Failed to load Vybz',
                style: GoogleFonts.outfit(color: Colors.grey)),
          ),
        ),
      ),
    );
  }
}
