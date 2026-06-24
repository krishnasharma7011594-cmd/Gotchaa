import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/vybz_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/social_providers.dart';
import '../../../../core/providers/vybz_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/video_manager.dart';
import '../../../../core/widgets/gotchaa_like_button.dart';
import '../../../home/presentation/screens/main_shell.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/vybz_video_player.dart';

class VybzFeedScreen extends ConsumerStatefulWidget {
  const VybzFeedScreen({super.key});

  @override
  ConsumerState<VybzFeedScreen> createState() => _VybzFeedScreenState();
}

class _VybzFeedScreenState extends ConsumerState<VybzFeedScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_pageController.position.pixels >=
        _pageController.position.maxScrollExtent - 200) {
      if (mounted) {
        ref.read(vybzFeedLimitProvider.notifier).state += 10;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    FeedVideoManager().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vybzAsync = ref.watch(vybzFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: vybzAsync.when(
        data: (vybzList) {
          if (vybzList.isEmpty) {
            return Center(
                child: Text(context.tr('vybz_no_vybz'),
                    style: const TextStyle(color: Colors.white)));
          }

          // Initialize active ID for first item
          Future.microtask(() {
            if (ref.read(activeVybzIdProvider) == null && vybzList.isNotEmpty) {
              ref.read(activeVybzIdProvider.notifier).state = vybzList[0].id;
            }
          });

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: vybzList.length + 1,
                onPageChanged: (index) {
                  if (index < vybzList.length) {
                    ref.read(activeVybzIdProvider.notifier).state =
                        vybzList[index].id;

                    // Preload the next video in the feed queue
                    if (index + 1 < vybzList.length) {
                      FeedVideoManager().preload(vybzList[index + 1].videoUrl);
                    }
                  }
                },
                itemBuilder: (context, index) {
                  if (index == vybzList.length) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  return RepaintBoundary(
                    child: _VybzItem(vybz: vybzList[index]),
                  );
                },
              ),
              PositionedDirectional(
                top: 50,
                start: 0,
                end: 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTopTab(context.tr('vybz_following'),
                            isSelected: false),
                        const SizedBox(width: 20),
                        _buildTopTab(context.tr('vybz_for_you'),
                            isSelected: true),
                      ],
                    ),
                    PositionedDirectional(
                      start: 16,
                      child: GestureDetector(
                        onTap: () =>
                            mainShellScaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.menu_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, st) => Center(
            child: Text(context.tr('error_prefix', args: [e.toString()]),
                style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildTopTab(String text, {required bool isSelected}) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 17,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.electricBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate().fadeIn().scaleX(),
        ],
      );
}

class _VybzItem extends ConsumerStatefulWidget {
  const _VybzItem({required this.vybz});
  final VybzModel vybz;

  @override
  ConsumerState<_VybzItem> createState() => _VybzItemState();
}

class _VybzItemState extends ConsumerState<_VybzItem> {
  int _commentsCountLocal = 0;
  final GlobalKey<dynamic> _likeButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _commentsCountLocal = widget.vybz.commentsCount;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).value;
    final isVerified = profile?.isVerified ?? false;
    final isLimited = profile?.isLimitedUser ?? false;
    final hasAccess = isVerified || isLimited;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.vybz.videoUrl.startsWith('http'))
          VybzVideoPlayer(
            videoUrl: widget.vybz.videoUrl,
            vybzId: widget.vybz.id,
            onDoubleTap: () {
              // Trigger the like button remotely
              final dynamic state = _likeButtonKey.currentState;
              if (state != null) {
                state.forceLike();
              }
            },
          )
        else
          CachedNetworkImage(
            imageUrl: 'https://picsum.photos/seed/${widget.vybz.id}/1080/1920',
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) =>
                const Icon(Icons.error, color: Colors.white),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
              stops: const [0, 0.3, 0.7, 1],
            ),
          ),
        ),
        // 1. User Info & Caption (Bottom Left)
        Positioned(
          left: 16,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfileScreen(uid: widget.vybz.creatorId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      backgroundImage: widget.vybz.creatorPhoto.isNotEmpty
                          ? CachedNetworkImageProvider(widget.vybz.creatorPhoto)
                          : null,
                      child: widget.vybz.creatorPhoto.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.vybz.creatorUsername.isNotEmpty
                          ? '@${widget.vybz.creatorUsername}'
                          : '@user_${widget.vybz.creatorId.substring(0, 5)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          const Shadow(color: Colors.black45, blurRadius: 4)
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.tr('profile_follow'),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.vybz.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [const Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              if (widget.vybz.hashtags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.vybz.hashtags.map((h) => '#$h').join(' '),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.music_note_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${widget.vybz.creatorUsername.isNotEmpty ? widget.vybz.creatorUsername : 'User'} • ${context.tr('vybz_original_sound')}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        shadows: [
                          const Shadow(color: Colors.black45, blurRadius: 4)
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        ),

        // 2. Action Buttons (Right Sidebar)
        Positioned(
          right: 8,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GotchaaLikeButton(
                key: _likeButtonKey,
                contentId: widget.vybz.id,
                contentType: 'vybz',
                initialCount: widget.vybz.likesCount,
                ownerId: widget.vybz.creatorId,
                ownerName: widget.vybz.creatorUsername,
                iconSize: 32,
                textSize: 12,
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                Icons.mode_comment_rounded,
                _commentsCountLocal.toString(),
                onTap: () {
                  if (!hasAccess) {
                    _showLockedFeatureNotice(
                        context,
                        ref,
                        context.tr('profile_locked_karma_title'),
                        context.tr('profile_locked_karma_msg'));
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CommentSheet(
                      vybzId: widget.vybz.id,
                      onCommentAdded: () {
                        if (mounted) {
                          setState(() {
                            _commentsCountLocal++;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                Icons.share_rounded,
                '',
                onTap: () {
                  Share.share(
                      'Check out this Vybz on Gotchaa! ${widget.vybz.videoUrl}');
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                Icons.volunteer_activism_rounded,
                '',
                isSpecial: true,
                onTap: () => _handleAppreciation(context, hasAccess),
              ),
              const SizedBox(height: 16),
              if (widget.vybz.creatorId ==
                  ref.watch(authStateProvider).value?.uid)
                _buildActionButton(
                  Icons.more_vert_rounded,
                  '',
                  onTap: () => _showVybzDeleteMenu(context, ref),
                ),
              const SizedBox(height: 24),
              // Rotating Music Disc (Instagram Style)
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [Colors.black, Colors.grey, Colors.black],
                  ),
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child:
                    const Icon(Icons.music_note, color: Colors.white, size: 18),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 4.seconds),
            ],
          ),
        ),
      ],
    );
  }

  void _showLockedFeatureNotice(
      BuildContext context, WidgetRef ref, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('btn_later'),
                style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final profile =
                  ref.read(currentUserProfileProvider).asData?.value;
              if (profile?.uid != null) {
                ref.read(firestoreRepositoryProvider).setLimitedAccess(
                      uid: profile!.uid,
                      isLimited: false,
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              context.tr('btn_unlock_now'),
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAppreciation(BuildContext context, bool hasAccess) async {
    if (!hasAccess) {
      _showLockedFeatureNotice(
          context,
          ref,
          context.tr('profile_locked_karma_title'),
          context.tr('profile_locked_karma_msg'));
      return;
    }
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      await ref.read(firestoreRepositoryProvider).appreciateVybz(
            vybzId: widget.vybz.id,
            senderId: user.uid,
            receiverId: widget.vybz.creatorId,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appreciation sent! 🌟'),
            backgroundColor: AppColors.electricBlue,
          ),
        );
      }
    } catch (e) {
      // ignore
    }
  }

  void _showVybzDeleteMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D26),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: Text(
                'Delete Reel',
                style: GoogleFonts.outfit(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmVybzDeletion(context, ref);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmVybzDeletion(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D26),
        title: Text('Delete Reel?',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: Text('This will permanently remove this Reel from Gotchaa.',
            style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Show a loading snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Working on it...'),
                  duration: Duration(seconds: 1),
                ),
              );

              try {
                await ref
                    .read(postRepositoryProvider)
                    .deletePost(widget.vybz.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reel deleted!')),
                  );
                  // Force a refresh of the feed provider
                  ref.invalidate(vybzFeedProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label,
          {bool isSpecial = false, VoidCallback? onTap}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSpecial ? AppColors.electricBlue : Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
}
