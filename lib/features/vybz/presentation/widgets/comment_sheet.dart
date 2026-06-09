import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/comment_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/vybz_providers.dart';
import '../../../../core/theme/app_colors.dart';

class CommentSheet extends ConsumerStatefulWidget {

  const CommentSheet({
    required this.vybzId, super.key,
    this.onCommentAdded,
    this.onCommentDeleted,
  });
  final String vybzId;
  final VoidCallback? onCommentAdded;
  final VoidCallback? onCommentDeleted;

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    final profile = ref.read(currentUserProfileProvider).value;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final comment = CommentModel(
        id: '',
        uid: user.uid,
        username: profile?.username ?? user.displayName ?? 'User',
        userPhoto: profile?.photoUrl ?? user.photoURL ?? '',
        text: text,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreRepositoryProvider).addVybzComment(widget.vybzId, comment);
      _commentController.clear();
      widget.onCommentAdded?.call();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(vybzCommentsProvider(widget.vybzId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Comments',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24, height: 32),
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet. Be the first!',
                      style: GoogleFonts.outfit(color: Colors.white54),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index] as CommentModel;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CachedNetworkImage(
                            imageUrl: comment.userPhoto.isNotEmpty ? comment.userPhoto : 'https://i.pravatar.cc/150',
                            imageBuilder: (context, imageProvider) => CircleAvatar(
                              radius: 18,
                              backgroundImage: imageProvider,
                            ),
                            placeholder: (context, url) => const CircleAvatar(
                              radius: 18,
                              child: BlurHash(hash: 'L5H2EC=pPdpWXVJs00QQV_9H00XY'),
                            ),
                            errorWidget: (context, url, error) => const CircleAvatar(
                              radius: 18,
                              child: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '@${comment.username.isNotEmpty ? comment.username : 'user'}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeago.format(comment.createdAt),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.text,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGlow)),
              error: (e, st) => Center(child: Text(context.tr('error_prefix', args: [e.toString()]), style: const TextStyle(color: Colors.white))),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white38),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isSubmitting) const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.electricBlue),
                        ),
                      ) else IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.electricBlue),
                        onPressed: _submitComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
