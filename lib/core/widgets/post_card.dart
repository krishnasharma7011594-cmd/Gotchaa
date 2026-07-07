import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../features/profile/presentation/screens/user_profile_screen.dart';
import '../../features/reporting/report_dialog.dart';
import '../models/post_model.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/social_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/comments_sheet.dart';
import 'gotchaa_like_button.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({required this.post, super.key});
  final PostModel post;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with SingleTickerProviderStateMixin {
  bool _isLikedLocal = false;
  bool _isBookmarkedLocal = false;
  int _likesCountLocal = 0;
  int _commentsCountLocal = 0;
  bool _isLikedInitialized = false;
  bool _isBookmarkedInitialized = false;
  bool _showHeartAnimation = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _likesCountLocal = widget.post.likesCount;
    _commentsCountLocal = widget.post.commentsCount;
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heartScale = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.elasticOut),
    );

    if (widget.post.isVideo && widget.post.mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.post.mediaUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController!.setLooping(true);
            _videoController!.play();
            _videoController!.setVolume(1.0);
          }
        });
    }
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _handleLikeCheck(bool isStreamLiked) {
    if (!_isLikedInitialized) {
      _isLikedLocal = isStreamLiked;
      _isLikedInitialized = true;
    }
  }

  void _handleBookmarkCheck(bool isStreamBookmarked) {
    if (!_isBookmarkedInitialized) {
      _isBookmarkedLocal = isStreamBookmarked;
      _isBookmarkedInitialized = true;
    }
  }

  void _toggleLike(String myUid) {
    if (myUid.isEmpty) return;
    final myProfile = ref.read(currentUserProfileProvider).value;
    if (myProfile == null) return;

    final willLike = !_isLikedLocal;
    setState(() {
      _isLikedLocal = willLike;
      _likesCountLocal += willLike ? 1 : -1;
      if (willLike) _showHeartAnimation = true;
    });

    if (willLike) {
      HapticFeedback.mediumImpact();
      _heartAnimController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _showHeartAnimation = false);
          _heartAnimController.reset();
        });
      });
      ref.read(socialRepositoryProvider).likeContent(
            contentId: widget.post.postId,
            uid: myUid,
            contentType: 'posts',
            contentOwnerId: widget.post.uid,
            contentOwnerName: widget.post.username,
            likerName: myProfile.displayName,
            likerPhotoUrl: myProfile.photoUrl,
          );
    } else {
      HapticFeedback.lightImpact();
      ref.read(socialRepositoryProvider).unlikeContent(
            contentId: widget.post.postId,
            uid: myUid,
            contentType: 'posts',
          );
    }
  }

  void _toggleBookmark(String myUid) {
    if (myUid.isEmpty) return;
    final willBookmark = !_isBookmarkedLocal;
    setState(() {
      _isBookmarkedLocal = willBookmark;
    });

    HapticFeedback.lightImpact();
    if (willBookmark) {
      ref
          .read(socialRepositoryProvider)
          .bookmarkPost(postId: widget.post.postId, uid: myUid);
    } else {
      ref
          .read(socialRepositoryProvider)
          .unbookmarkPost(postId: widget.post.postId, uid: myUid);
    }
  }

  void _sharePost() {
    HapticFeedback.lightImpact();
    // In a real app, this would be a dynamic link.
    Share.share(
        'Check out this post by ${widget.post.username} on GOTCHAA!\n\n${widget.post.caption}');
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(currentUserProvider)?.uid ?? '';
    final likedAsync = ref.watch(isContentLikedProvider((
      contentId: widget.post.postId,
      uid: myUid,
      contentType: 'posts',
      parentId: null,
    )));
    likedAsync.whenData(_handleLikeCheck);

    final bookmarkedAsync = ref.watch(
        isPostBookmarkedProvider((postId: widget.post.postId, uid: myUid)));
    bookmarkedAsync.whenData(_handleBookmarkCheck);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            UserProfileScreen(uid: widget.post.uid)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.electricBlue,
                          AppColors.electricBlue.withOpacity(0.5)
                        ],
                      ),
                    ),
                    child: Hero(
                      tag: 'profile_avatar_${widget.post.uid}',
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: widget.post.userPhoto.isNotEmpty
                            ? CachedNetworkImageProvider(widget.post.userPhoto)
                            : null,
                        backgroundColor: context.shimmerBase,
                        child: widget.post.userPhoto.isEmpty
                            ? Text(
                                widget.post.username.isNotEmpty
                                    ? widget.post.username[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: context.textPrimary),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.username.isNotEmpty
                            ? widget.post.username
                            : 'User',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: context.textPrimary),
                      ),
                      if (widget.post.authorNation != null)
                        Text(
                          '${widget.post.authorNation} • ${_timeSince(widget.post.createdAt)}',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: context.textSecondary),
                        )
                      else
                        Text(
                          _timeSince(widget.post.createdAt),
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: context.textSecondary),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon:
                      Icon(Icons.more_horiz_rounded, color: context.iconMuted),
                  onSelected: (v) async {
                    if (v == 'report') {
                      showReportBottomSheet(
                        context,
                        reportedUserId: widget.post.uid,
                        contentType: 'post',
                        contentId: widget.post.postId,
                        contentPreview: widget.post.caption,
                      );
                    } else if (v == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title:
                              Text('Delete Post?', style: GoogleFonts.outfit()),
                          content: Text(
                              'This will permanently remove this post.',
                              style: GoogleFonts.outfit()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child:
                                  Text('Cancel', style: GoogleFonts.outfit()),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: Text('Delete',
                                  style:
                                      GoogleFonts.outfit(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(postRepositoryProvider)
                            .deletePost(widget.post.postId);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    if (myUid == widget.post.uid)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(value: 'report', child: Text('Report')),
                  ],
                ),
              ],
            ),
          ),

          // ── Media ────────────────────────────────────────────────
          if (widget.post.mediaUrl.isNotEmpty)
            GestureDetector(
              onDoubleTap: () => _toggleLike(myUid),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildMediaWidget(),
                  if (_showHeartAnimation)
                    ScaleTransition(
                      scale: _heartScale,
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 100,
                        shadows: [
                          Shadow(
                              color: Colors.black26,
                              blurRadius: 15,
                              offset: Offset(0, 4))
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // ── AI Music Attachment ────────────────────────────
          if (widget.post.soundId != null && widget.post.soundPlaybackUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.cardBg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.divider.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.music_note_rounded,
                          color: AppColors.electricBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.soundPrompt ?? 'AI Music Vibe',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: context.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Gemini Lyria 3 • AI Generated',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: context.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final playbackUrl = widget.post.soundPlaybackUrl;
                        if (playbackUrl == null) return;
                        if (_isPlaying) {
                          await _audioPlayer.pause();
                        } else {
                          await _audioPlayer.setUrl(playbackUrl);
                          await _audioPlayer.play();
                        }
                        if (mounted) setState(() => _isPlaying = !_isPlaying);
                      },
                      icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: AppColors.electricBlue,
                          size: 32),
                    ),
                  ],
                ),
              ),
            ),

          // ── Action Bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GotchaaLikeButton(
                    contentId: widget.post.postId,
                    contentType: 'posts',
                    initialCount: widget.post.likesCount,
                    ownerId: widget.post.uid,
                    ownerName: widget.post.username,
                  ),
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '$_commentsCountLocal',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CommentsSheet(
                      postId: widget.post.postId,
                      onCommentAdded: () {
                        if (mounted) {
                          setState(() {
                            _commentsCountLocal++;
                          });
                        }
                      },
                      onCommentDeleted: () {
                        if (mounted) {
                          setState(() {
                            if (_commentsCountLocal > 0) _commentsCountLocal--;
                          });
                        }
                      },
                    ),
                  ),
                ),
                _ActionButton(
                  icon: Icons.send_rounded,
                  onTap: _sharePost,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _toggleBookmark(myUid),
                  icon: Icon(
                    _isBookmarkedLocal
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _isBookmarkedLocal
                        ? AppColors.electricBlue
                        : context.iconSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Caption ──────────────────────────────────────────────
          if (widget.post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.post.username}  ',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: context.textPrimary),
                    ),
                    TextSpan(
                      text: widget.post.caption,
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: context.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaWidget() {
    if (widget.post.isVideo) {
      if (_isVideoInitialized && _videoController != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  if (!_videoController!.value.isPlaying)
                    Container(
                      color: Colors.black26,
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.post.mediaThumbnailUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: widget.post.mediaThumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                  ),
                const Center(
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white70, size: 48),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CachedNetworkImage(
          imageUrl: widget.post.mediaUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: 350,
            color: context.shimmerBase,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 350,
            color: context.shimmerBase,
            child: Icon(Icons.broken_image_rounded,
                size: 40, color: context.iconSecondary),
          ),
        ),
      );
    }
  }

  String _timeSince(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.onTap, this.label, this.color});
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon,
                  color: color ?? Theme.of(context).iconTheme.color, size: 22),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(label!,
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      );
}
