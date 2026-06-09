import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

final trendingPostsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection('trending')
      .doc('posts')
      .get();
  if (!doc.exists) return [];

  final data = doc.data()!;
  final List<dynamic> posts = data['posts'] ?? [];
  return posts.cast<Map<String, dynamic>>();
});

class TrendingScreen extends ConsumerWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingPostsProvider);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(
          'Trending 🔥',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: context.textPrimary,
          ),
        ),
        backgroundColor: context.surface,
        elevation: 0,
      ),
      body: trendingAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Text(
                'No trending posts yet.\nCheck back later!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: context.textSecondary, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _TrendingCard(post: post, rank: index + 1);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(
          child: Text('Error loading trending',
              style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.post, required this.rank});
  final Map<String, dynamic> post;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final String postId = post['postId'] ?? '';
    final double score = (post['score'] as num?)?.toDouble() ?? 0.0;
    final String category = post['category'] ?? 'general';

    // In a real app, we would fetch the post details using the postId.
    // Assuming we just display the rank and score here for now.

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: rank <= 3 ? AppColors.electricBlue : context.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trending Post ID:',
                  style:
                      GoogleFonts.outfit(fontSize: 12, color: context.textHint),
                ),
                Text(
                  postId,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: AppColors.electricBlue,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.local_fire_department,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Score: ${score.toStringAsFixed(1)}',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
