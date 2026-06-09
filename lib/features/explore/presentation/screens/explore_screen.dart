import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/firebase/performance_traces.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/feed_item.dart';
import '../../../../core/models/post_model.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/post_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/block_mute_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stories_bar.dart';
import '../../../home/presentation/screens/main_shell.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import 'post_detail_screen.dart';

final userSearchProvider =
    FutureProvider.family<List<UserProfile>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final users = await ref.read(firestoreRepositoryProvider).searchUsers(query.trim());
  final blockedUids = ref.read(blockedUidsProvider).value ?? [];
  return users.where((u) => !blockedUids.contains(u.uid)).toList();
});

final postSearchProvider =
    FutureProvider.family<List<PostModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final List<PostModel> posts;
  if (query.startsWith('#')) {
    posts = await ref.read(firestoreRepositoryProvider).searchHashtags(query);
  } else {
    posts = await ref.read(firestoreRepositoryProvider).searchPosts(query);
  }
  final blockedUids = ref.read(blockedUidsProvider).value ?? [];
  return posts.where((p) => !blockedUids.contains(p.uid)).toList();
});

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({
    super.key,
    this.showHeader = true,
    this.showScaffold = true,
  });
  final bool showHeader;
  final bool showScaffold;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> with SingleTickerProviderStateMixin {
  int _selectedCategoryTab = 0;
  int _searchResultTab = 0; // 0: Users, 1: Posts
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  static const _categoryKeys = [
    'explore_category_foryou',
    'explore_category_trending',
    'explore_category_art',
    'explore_category_tech',
    'explore_category_lifestyle'
  ];

  @override
  void initState() {
    super.initState();
    GotchaaPerformanceTraces.instance.startFeedLoad();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() =>
        setState(() => _searchQuery = _searchController.text.trim()));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (mounted) ref.read(postsFeedLimitProvider.notifier).state += 10;
    }
  }

  @override
  void dispose() {
    GotchaaPerformanceTraces.instance.stopFeedLoad();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(forYouFeedProvider); 

    final Widget content = Column(
      children: [
        // ── Search bar ──────────────────────────────────────────
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      mainShellScaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: context.inputFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.menu_rounded,
                        color: context.iconPrimary, size: 24),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: context.inputFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: context.tr('explore_search_hint'),
                        hintStyle: GoogleFonts.outfit(
                            color: context.textHint, fontSize: 14),
                        icon: Icon(Icons.search_rounded,
                            color: context.textHint, size: 20),
                        border: InputBorder.none,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                                child: Icon(Icons.close_rounded,
                                    color: context.textHint, size: 20),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Tabs (Category or Search Result) ──────────────────
        const SizedBox(height: 14),
        if (_searchQuery.isEmpty)
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categoryKeys.length,
              itemBuilder: (_, i) {
                final active = _selectedCategoryTab == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategoryTab = i),
                    child: Column(
                      children: [
                        Text(
                          context.tr(_categoryKeys[i]),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: active
                                ? AppColors.electricBlue
                                : context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (active)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.electricBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          Row(
            children: [
              const SizedBox(width: 16),
              _buildSearchTab(0, context.tr('explore_tab_users')),
              const SizedBox(width: 8),
              _buildSearchTab(1, context.tr('explore_tab_posts')),
              const SizedBox(width: 8),
              _buildSearchTab(2, context.tr('explore_tab_hashtags')),
            ],
          ),

        const SizedBox(height: 14),
        if (_searchQuery.isEmpty) ...[
          const StoriesBar(isExplore: true),
          const SizedBox(height: 14),
        ],

        // ── Feed / Search results ────────────────────────────────
        if (_searchQuery.isNotEmpty)
          Expanded(
            child: _buildSearchResults(),
          )
        else
          Expanded(
            child: postsAsync.when(
              data: (items) {
                if (items.isEmpty) return _emptyState();
                return GridView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120, left: 2, right: 2, top: 2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    if (item is PostFeedItem) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: item.post),
                            ),
                          );
                        },
                        child: Container(
                          color: context.inputFill,
                          child: item.post.mediaUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: item.post.mediaUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: context.inputFill),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                )
                              : Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      item.post.caption,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(fontSize: 10),
                                    ),
                                  ),
                                ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore_off_rounded,
                        size: 48, color: context.iconMuted),
                    const SizedBox(height: 16),
                    Text(context.tr('explore_error_load'),
                        style: GoogleFonts.outfit(
                            color: context.textSecondary, fontSize: 15)),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(forYouFeedProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.tr('explore_retry')),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    if (widget.showScaffold) {
      return Scaffold(
        backgroundColor: context.bg,
        body: SafeArea(bottom: false, child: content),
      );
    }
    return content;
  }

  Widget _buildSearchTab(int index, String label) {
    final active = _searchResultTab == index;
    return GestureDetector(
      onTap: () => setState(() => _searchResultTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.electricBlue : context.inputFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResultTab == 0) {
      // User Search
      return Consumer(builder: (context, ref, _) {
        final searchResult = ref.watch(userSearchProvider(_searchQuery));
        return searchResult.when(
          data: (users) {
            if (users.isEmpty) return _noResults();
            return ListView.builder(
              itemCount: users.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: Hero(
                    tag: 'profile_avatar_${user.uid}',
                    child: CircleAvatar(
                      backgroundImage: user.photoUrl.isNotEmpty ? CachedNetworkImageProvider(user.photoUrl) : null,
                    ),
                  ),
                  title: Text(user.username, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text(user.displayName, style: GoogleFonts.outfit(color: context.textSecondary, fontSize: 12)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(uid: user.uid))),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(context.tr('error_prefix', args: [e.toString()]))),
        );
      });
    } else {
      // Post / Hashtag Search
      final query = _searchResultTab == 2 && !_searchQuery.startsWith('#') ? '#$_searchQuery' : _searchQuery;
      return Consumer(builder: (context, ref, _) {
        final searchResult = ref.watch(postSearchProvider(query));
        return searchResult.when(
          data: (posts) {
            if (posts.isEmpty) return _noResults();
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: posts.length,
              padding: const EdgeInsets.only(bottom: 120, left: 2, right: 2, top: 2),
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                  child: Container(
                    color: context.inputFill,
                    child: post.mediaUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: post.mediaUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: context.inputFill),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                post.caption,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 10),
                              ),
                            ),
                          ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(context.tr('error_prefix', args: [e.toString()]))),
        );
      });
    }
  }

  Widget _noResults() => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: context.iconMuted),
          const SizedBox(height: 16),
          Text(context.tr('explore_no_results', namedArgs: {'query': _searchQuery}), style: GoogleFonts.outfit(color: context.textSecondary)),
        ],
      ),
    );

  Widget _emptyState() => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.explore_rounded,
                size: 40, color: AppColors.electricBlue),
          ),
          const SizedBox(height: 20),
          Text(context.tr('explore_empty_title'),
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
          const SizedBox(height: 8),
          Text(context.tr('explore_empty_subtitle'),
              style: GoogleFonts.outfit(
                  color: context.textSecondary, fontSize: 14)),
        ],
      ),
    );
}

