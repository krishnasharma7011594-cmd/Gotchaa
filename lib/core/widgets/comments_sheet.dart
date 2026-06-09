import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/profile/presentation/screens/user_profile_screen.dart';
import '../models/comment_model.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/social_providers.dart';
import '../theme/app_colors.dart';
import '../../features/reporting/report_dialog.dart';
import 'gotchaa_like_button.dart';

class CommentsSheet extends ConsumerStatefulWidget {

  const CommentsSheet({
    required this.postId, super.key,
    this.onCommentAdded,
    this.onCommentDeleted,
  });
  final String postId;
  final VoidCallback? onCommentAdded;
  final VoidCallback? onCommentDeleted;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      if (mounted) {
        ref.read(postCommentsLimitProvider(widget.postId).notifier).state += 20;
      }
    }
  }

  void _sendComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profile = ref.read(currentUserProfileProvider).asData?.value;

    final comment = CommentModel(
      id: '',
      uid: user.uid,
      username: profile?.username ?? profile?.displayName ?? '',
      userPhoto: profile?.photoUrl ?? '',
      text: text,
      createdAt: DateTime.now(),
    );

    _controller.clear();
    
    // Fire and forget (Optimistic caching by Firestore handles the rest instantly)
    ref.read(socialRepositoryProvider).addComment(postId: widget.postId, comment: comment).then((_) {
      widget.onCommentAdded?.call();
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Comments',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // ── Comments list ───────────────────────────────────────
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No comments yet',
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Be the first to comment!',
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade300,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length + 1, // +1 for loading indicator at bottom
                  itemBuilder: (ctx, i) {
                    if (i == comments.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return _CommentTile(comment: comments[i], postId: widget.postId);
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error loading comments',
                    style: GoogleFonts.outfit(color: Colors.grey)),
              ),
            ),
          ),

          // ── Input ───────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Write a comment…',
                      hintStyle: GoogleFonts.outfit(
                          color: Colors.grey.shade400, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppColors.electricBlue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendComment,
                  icon: const Icon(Icons.send_rounded,
                          color: AppColors.electricBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.postId});
  final CommentModel comment;
  final String postId;

  void _reportComment(BuildContext context) {
    showReportBottomSheet(
      context,
      reportedUserId: comment.uid,
      contentType: 'comment',
      contentId: comment.id.isNotEmpty ? comment.id : '${postId}_${comment.uid}',
      contentPreview: comment.text,
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onLongPress: () => _reportComment(context),
      child: Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(uid: comment.uid),
                ),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundImage: comment.userPhoto.isNotEmpty
                  ? CachedNetworkImageProvider(comment.userPhoto)
                  : null,
              child: comment.userPhoto.isEmpty
                  ? Text(
                      comment.username.isNotEmpty
                          ? comment.username[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(uid: comment.uid),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: comment.username.isNotEmpty
                              ? comment.username
                              : 'User',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(text: '  '),
                        TextSpan(
                          text: comment.text,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeSince(comment.createdAt),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GotchaaLikeButton(
            contentId: comment.id,
            contentType: 'comments',
            parentId: postId,
            initialCount: comment.likesCount,
            ownerId: comment.uid,
            ownerName: comment.username,
            iconSize: 18,
            textSize: 12,
          ),
        ],
      ),
    ),
    );

  String _timeSince(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}
