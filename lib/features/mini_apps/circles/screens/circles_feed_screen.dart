import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/circles_feed_provider.dart';
import '../providers/circles_onboarding_provider.dart';
import '../services/circles_notification_service.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/safety_guidelines_popup.dart';
import '../widgets/trust_badge_widget.dart';
import 'circles_create_screen.dart';
import 'circles_details_screen.dart';
import 'circles_filter_dialog.dart';
import 'circles_onboarding_screen.dart';
import 'circles_profile_screen.dart';

class CirclesFeedScreen extends ConsumerStatefulWidget {
  const CirclesFeedScreen({super.key});

  @override
  ConsumerState<CirclesFeedScreen> createState() => _CirclesFeedScreenState();
}

class _CirclesFeedScreenState extends ConsumerState<CirclesFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Initialize push notifications and show permission explain dialog on launch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await CirclesNotificationService.instance.initialize(context);
      await CirclesNotificationService.instance
          .requestPermissionWithExplanation(context);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(circlesFeedProvider.notifier).fetchFeed();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(circlesOnboardingProvider);

    return onboardingState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (onboarding) {
        // If onboarding is incomplete, redirect there
        if (!onboarding.isOnboardingComplete) {
          return const CirclesOnboardingScreen();
        }

        final feedState = ref.watch(circlesFeedProvider);

        return Scaffold(
          backgroundColor: context.bg,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(circlesFeedProvider.notifier)
                  .fetchFeed(refresh: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Branded Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CIRCLES',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Discover Nearby Vibes',
                                style: GoogleFonts.inter(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.account_circle,
                                color: Colors.white, size: 30),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const CirclesProfileScreen()),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),

                  // Search Bar & Filter Button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              onChanged: (val) {
                                ref
                                    .read(circlesFeedProvider.notifier)
                                    .updateFilters(search: val);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search hashtags, groups...',
                                hintStyle:
                                    TextStyle(color: context.textSecondary),
                                prefixIcon: Icon(Icons.search,
                                    color: context.textSecondary),
                                filled: true,
                                fillColor: context.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.tune_rounded,
                                color: Colors.white),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const CirclesFilterDialog(),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),

                  // Onboarding Check Banner if skipped / empty tags
                  if (onboarding.hobbies.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.electricGradientDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.interests_rounded,
                                  color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Personalize your feed',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Take onboarding to unlock customized matches.',
                                      style: GoogleFonts.inter(
                                          color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CirclesOnboardingScreen()),
                                  );
                                },
                                child: const Text('Do it!',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Session Read Protection Warn Label
                  if (feedState.isThrottled)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            '⚠️ Query throttling active for cost protection.',
                            style: GoogleFonts.outfit(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                  // Discover Grid
                  if (feedState.circles.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No circles near you yet.',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to create one and invite your friends!',
                                style: GoogleFonts.inter(
                                    color: context.textSecondary),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CirclesCreateScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.electricBlue),
                                child: const Text('Create a Circle',
                                    style: TextStyle(color: Colors.white)),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final circle = feedState.circles[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => SafetyGuidelinesPopup(
                                    onAccepted: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CirclesDetailsScreen(
                                              circle: circle),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              child: GlassmorphicCard(
                                blur: 10,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          circle.coverImageUrl.isNotEmpty
                                              ? circle.coverImageUrl
                                              : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            height: 160,
                                            color:
                                                Colors.purple.withOpacity(0.2),
                                            child: const Icon(Icons.image,
                                                color: Colors.white54,
                                                size: 40),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Header
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.electricBlue
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            child: Text(
                                              circle.category,
                                              style: GoogleFonts.outfit(
                                                  color: AppColors.primaryGlow,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Text(
                                            circle.city,
                                            style: GoogleFonts.inter(
                                                color: context.textSecondary,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      Text(
                                        circle.title,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        circle.description,
                                        style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),

                                      // Stats
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const TrustBadgeWidget(
                                            karmaScore:
                                                120, // Mock karma level representing community reliability
                                            attendanceRate: 95,
                                          ),
                                          Text(
                                            '${circle.memberIds.length}/${circle.memberLimit} Members',
                                            style: GoogleFonts.inter(
                                                color: Colors.white70,
                                                fontSize: 12),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: feedState.circles.length,
                      ),
                    ),

                  if (feedState.isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.electricBlue,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CirclesCreateScreen()),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Create Circle',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
