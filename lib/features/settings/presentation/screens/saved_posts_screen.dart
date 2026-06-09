import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/post_model.dart';
import '../../../../core/providers/post_providers.dart';
import '../../../../core/theme/app_colors.dart';

class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPostsAsync = ref.watch(savedPostsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Saved',
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
      body: savedPostsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.bookmark_border_rounded,
                      size: 48,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Save Photos and Videos',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'When you save photos and videos, they\'ll appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostItem(context, post);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(context.tr('error_prefix', args: [e.toString()]))),
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, PostModel post) {
    final isVideo =
        post.mediaUrl.contains('.mp4') || post.mediaUrl.contains('video');

    return GestureDetector(
      onTap: () {
        // Show post detail or navigate to post
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: post.mediaUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.withValues(alpha: 0.1),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.black87,
              child: const Icon(Icons.play_circle_outline,
                  color: Colors.white, size: 32),
            ),
          ),
          if (isVideo)
            const Positioned(
              top: 8,
              right: 8,
              child:
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }
}
