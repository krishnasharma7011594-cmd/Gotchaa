import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/gotchaa_like_button.dart';
import '../../../../core/models/vybz_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/social_providers.dart';
import '../../../../core/providers/vybz_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/video_manager.dart';
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
    if (_pageController.position.pixels >= _pageController.position.maxScrollExtent - 200) {
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
            return Center(child: Text(context.tr('vybz_no_vybz'), style: const TextStyle(color: Colors.white)));
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
                    ref.read(activeVybzIdProvider.notifier).state = vybzList[index].id;
                    
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
                        _buildTopTab(context.tr('vybz_following'), isSelected: false),
                        const SizedBox(width: 20),
                        _buildTopTab(context.tr('vybz_for_you'), isSelected: true),
                      ],
                    ),
                    PositionedDirectional(
                      start: 16,
                      child: GestureDetector(
                        onTap: () => mainShellScaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, st) => Center(child: Text(context.tr('error_prefix', args: [e.toString()]), style: const TextStyle(color: Colors.white))),
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
          VybzVideoPlayer(videoUrl: widget.vybz.videoUrl, vybzId: widget.vybz.id)
        else
          CachedNetworkImage(
            imageUrl: 'https://picsum.photos/seed/${widget.vybz.id}/1080/1920',
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
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
        
        PositionedDirectional(
          end: 15,
          bottom: 120,
          child: RepaintBoundary(
            child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: GotchaaLikeButton(
                  contentId: widget.vybz.id,
                  contentType: 'vybz',
                  initialCount: widget.vybz.likesCount,
                  ownerId: widget.vybz.creatorId,
                  ownerName: widget.vybz.creatorUsername,
                  iconSize: 28,
                  textSize: 13,
                ),
              ),
              _buildActionButton(
                Icons.comment_rounded, 
                _commentsCountLocal.toString(),
                onTap: () {
                   if (!hasAccess) {
                    _showLockedFeatureNotice(context, ref, context.tr('profile_locked_karma_title'), context.tr('profile_locked_karma_msg'));
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
              _buildActionButton(
                Icons.share_rounded, 
                context.tr('vybz_share'),
                onTap: () {
                  Share.share('Check out this Vybz on Gotchaa! ${widget.vybz.videoUrl}');
                },
              ),
              _buildActionButton(
                Icons.volunteer_activism_rounded, 
                context.tr('vybz_appreciate'), 
                isSpecial: true,
                onTap: () async {
                  if (!hasAccess) {
                    _showLockedFeatureNotice(context, ref, context.tr('profile_locked_karma_title'), context.tr('profile_locked_karma_msg'));
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
                        SnackBar(
                          content: Text('Appreciation sent! 🌟'),
                          backgroundColor: AppColors.electricBlue,
                        ),
                      );
                    }
                  } catch (e) {
                     // ignore
                  }
                },
              ),
              Consumer(builder: (context, ref, _) {
                final myUid = ref.read(authStateProvider).value?.uid ?? '';
                final bookmarkedAsync = ref.watch(isPostBookmarkedProvider((postId: widget.vybz.id, uid: myUid)));
                final isBookmarked = bookmarkedAsync.value ?? false;
                
                return _buildActionButton(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded, 
                  isBookmarked ? context.tr('profile_tab_saved') : context.tr('btn_save'),
                  onTap: () {
                    if (myUid.isEmpty) return;
                    if (isBookmarked) {
                      ref.read(socialRepositoryProvider).unbookmarkPost(postId: widget.vybz.id, uid: myUid);
                    } else {
                      ref.read(socialRepositoryProvider).bookmarkPost(postId: widget.vybz.id, uid: myUid);
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
        
        PositionedDirectional(
          start: 20,
          end: 80,
          bottom: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(uid: widget.vybz.creatorId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Hero(
                      tag: 'profile_avatar_${widget.vybz.creatorId}',
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white10,
                        backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/100?u=${widget.vybz.creatorId}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '@${widget.vybz.creatorId.substring(0, 8)}...', 
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                '${widget.vybz.caption} ${widget.vybz.hashtags.map((h) => '#$h').join(' ')}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.music_note_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    context.tr('vybz_original_sound'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLockedFeatureNotice(BuildContext context, WidgetRef ref, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 28),
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
            child: Text(context.tr('btn_later'), style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final profile = ref.read(currentUserProfileProvider).asData?.value;
              if (profile?.uid != null) {
                ref.read(firestoreRepositoryProvider).setLimitedAccess(
                  uid: profile!.uid,
                  isLimited: false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              context.tr('btn_unlock_now'),
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {bool isSpecial = false, VoidCallback? onTap}) => Padding(
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
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
}
