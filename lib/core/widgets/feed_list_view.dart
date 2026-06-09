import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/feed_item.dart';
import '../theme/app_theme.dart';
import '../widgets/gotchaa_empty_state.dart';
import '../widgets/gotchaa_skeleton_loader.dart';
import 'post_card.dart';
import 'vybz_card.dart';

class FeedListView extends ConsumerWidget {
  const FeedListView({
    required this.feedAsync,
    required this.onRefresh,
    required this.onLoadMore,
    super.key,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyActionLabel,
    this.onEmptyAction,
  });
  final AsyncValue<List<FeedItem>> feedAsync;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final String? emptyTitle;
  final String? emptySubtitle;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) => feedAsync.when(
        data: (items) {
          if (items.isEmpty) return _buildEmptyState(context);

          return RefreshIndicator(
            onRefresh: () async => onRefresh(),
            color: context.accent,
            backgroundColor: context.bg,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 200) {
                  onLoadMore();
                }
                return false;
              },
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: items.length + 1,
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final item = items[index];
                  if (item is PostFeedItem) {
                    return PostCard(post: item.post);
                  } else if (item is VybzFeedItem) {
                    return VybzCard(vybz: item.vybz);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
        // Shimmer skeleton instead of spinner
        loading: () => const GotchaaSkeletonLoader.feed(itemCount: 3),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: context.iconMuted),
              const SizedBox(height: 16),
              Text('Failed to load feed',
                  style: GoogleFonts.outfit(color: context.textSecondary)),
              TextButton(onPressed: onRefresh, child: const Text('Retry')),
            ],
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context) => GotchaaEmptyState(
        icon: Icons.auto_awesome_outlined,
        title: emptyTitle ?? 'Your feed is quiet',
        subtitle:
            emptySubtitle ?? 'Follow more people or explore trending content.',
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      );
}
