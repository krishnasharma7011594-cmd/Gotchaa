import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/post_providers.dart';
import '../../../../core/providers/shell_navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feed_list_view.dart';
import '../../../../core/widgets/stories_bar.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
      length: 3,
      initialIndex: 1, // Start on 'For You'
      child: Scaffold(
        backgroundColor: context.bg,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: true,
                pinned: false, // App bar hides on scroll for immersive feel
                snap: true,
                backgroundColor: context.bg,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(shellPageControllerProvider).animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: Icon(Icons.camera_alt_outlined, color: context.iconPrimary, size: 26),
                ),
                title: Text(
                  'GOTCHAA',
                  style: GoogleFonts.satisfy(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(shellPageControllerProvider).animateToPage(
                        2,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Icon(Icons.chat_bubble_outline_rounded, color: context.iconPrimary, size: 24),
                  ),
                  const SizedBox(width: 4),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      isScrollable: true,
                      labelColor: context.textPrimary,
                      unselectedLabelColor: context.textSecondary,
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 16),
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(width: 3, color: AppColors.electricBlue),
                        insets: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Following'),
                        Tab(text: 'For You'),
                        Tab(text: 'Nearby'),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: StoriesBar(isExplore: false),
                ),
              ),
            ],
          body: TabBarView(
            children: [
              // Following Feed
              FeedListView(
                feedAsync: ref.watch(followingFeedProvider),
                onRefresh: () => ref.invalidate(followingFeedProvider),
                onLoadMore: () => ref.read(postsFeedLimitProvider.notifier).state += 10,
                emptyTitle: 'No posts from people you follow',
                emptySubtitle: 'Discover interesting people and follow them to see their posts here.',
                emptyActionLabel: 'Explore People',
                onEmptyAction: () => ref.read(shellPageControllerProvider).animateToPage(
                  3,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
              // For You Feed
              FeedListView(
                feedAsync: ref.watch(forYouFeedProvider),
                onRefresh: () => ref.invalidate(forYouFeedProvider),
                onLoadMore: () => ref.read(postsFeedLimitProvider.notifier).state += 10,
                emptyTitle: 'Building your feed...',
                emptySubtitle: 'The more you interact, the better your feed gets. Go explore something!',
              ),
              // Nearby Feed
              FeedListView(
                feedAsync: ref.watch(nearbyFeedProvider),
                onRefresh: () => ref.invalidate(nearbyFeedProvider),
                onLoadMore: () => ref.read(postsFeedLimitProvider.notifier).state += 10,
                emptyTitle: 'No posts nearby',
                emptySubtitle: 'Nobody has posted from your area yet. Be the first!',
              ),
            ],
          ),
        ),
      ),
    );
}

