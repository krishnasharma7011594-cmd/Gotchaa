import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/circle_model.dart';
import '../models/user_onboarding_model.dart';
import '../services/circles_firestore_service.dart';
import '../services/circles_local_cache_service.dart';
import 'circles_onboarding_provider.dart';

class CirclesFeedState {

  CirclesFeedState({
    required this.circles,
    required this.isLoading,
    required this.isThrottled,
    required this.searchQuery, required this.selectedCategory, required this.hasMore, this.error,
    this.selectedCity,
  });

  factory CirclesFeedState.initial() => CirclesFeedState(
      circles: [],
      isLoading: false,
      isThrottled: false,
      searchQuery: '',
      selectedCategory: 'All',
      hasMore: true,
    );
  final List<CircleModel> circles;
  final bool isLoading;
  final bool isThrottled;
  final String? error;
  final String searchQuery;
  final String selectedCategory;
  final String? selectedCity;
  final bool hasMore;

  CirclesFeedState copyWith({
    List<CircleModel>? circles,
    bool? isLoading,
    bool? isThrottled,
    String? error,
    String? searchQuery,
    String? selectedCategory,
    String? selectedCity,
    bool? hasMore,
  }) => CirclesFeedState(
      circles: circles ?? this.circles,
      isLoading: isLoading ?? this.isLoading,
      isThrottled: isThrottled ?? this.isThrottled,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedCity: selectedCity ?? this.selectedCity,
      hasMore: hasMore ?? this.hasMore,
    );
}

class CirclesFeedNotifier extends StateNotifier<CirclesFeedState> {

  CirclesFeedNotifier(this._firestoreService, this._ref) : super(CirclesFeedState.initial()) {
    loadCachedFeed().then((_) => fetchFeed(refresh: true));
  }
  final CirclesFirestoreService _firestoreService;
  final Ref _ref;
  DocumentSnapshot? _lastDoc;

  // Load cache immediately for instant loading
  Future<void> loadCachedFeed() async {
    final cached = await CirclesLocalCacheService.instance.getCachedCircles();
    if (cached.isNotEmpty && state.circles.isEmpty) {
      state = state.copyWith(circles: cached);
    }
  }

  // Fetch or paginate feed
  Future<void> fetchFeed({bool refresh = false}) async {
    if (state.isLoading || (!state.hasMore && !refresh)) return;

    state = state.copyWith(isLoading: true, isThrottled: _firestoreService.isThrottled);

    try {
      if (refresh) {
        _lastDoc = null;
      }

      // Query from Firestore service (max 10 elements)
      final results = await _firestoreService.fetchCirclesFeed(
        startAfterDoc: _lastDoc,
        categoryFilter: state.selectedCategory,
        cityFilter: state.selectedCity,
        searchQuery: state.searchQuery,
      );

      // Extract raw document for startAfter queries
      if (results.isNotEmpty) {
        // Query snapshot is not directly accessible here, we will fetch last element reference manually from Firebase if needed or just use limit bounds.
        // For standard startAfter logic, we can also paginate via eventDate / page offsets.
        // To simplify, we keep standard Firestore document page flags.
        state = state.copyWith(hasMore: results.length >= 10);
      } else {
        state = state.copyWith(hasMore: false);
      }

      // Score and sort based on Onboarding Recommendations
      final onboardingVal = _ref.read(circlesOnboardingProvider);
      UserOnboarding? userPref;
      if (onboardingVal is AsyncData<UserOnboarding>) {
        userPref = onboardingVal.value;
      }

      List<CircleModel> combined = refresh ? results : [...state.circles, ...results];
      
      // Filter out duplicates
      final seenIds = <String>{};
      combined = combined.where((c) => seenIds.add(c.id)).toList();

      // Apply Gen Z Smart Scoring engine
      if (userPref != null && userPref.isOnboardingComplete) {
        combined.sort((a, b) {
          final scoreA = _calculateScore(a, userPref!);
          final scoreB = _calculateScore(b, userPref);
          return scoreB.compareTo(scoreA); // High scoring first
        });
      }

      state = state.copyWith(
        circles: combined,
        isLoading: false,
        isThrottled: _firestoreService.isThrottled,
      );

      // Cache locally
      await CirclesLocalCacheService.instance.cacheCircles(combined);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Gen Z Smart Recommendation Scoring Algorithm
  int _calculateScore(CircleModel circle, UserOnboarding pref) {
    int score = 0;

    // 1. Category Match (+30)
    if (pref.hobbies.any((h) => h.toLowerCase() == circle.category.toLowerCase())) {
      score += 30;
    }

    // 2. Vibe Preference Match (+25)
    if (pref.vibePreferences.any((v) => circle.tags.any((t) => t.toLowerCase() == v.toLowerCase()))) {
      score += 25;
    }

    // 3. Location / Preferred City Match (+20)
    if (pref.preferredCities.any((c) => c.toLowerCase() == circle.city.toLowerCase())) {
      score += 20;
    }

    // 4. Language overlap (+15)
    if (pref.languages.any((l) => l.toLowerCase() == circle.language.toLowerCase())) {
      score += 15;
    }

    // 5. Trending popularity / member counts (+10)
    if (circle.memberIds.length >= 5) {
      score += 10;
    }

    return score;
  }

  void updateFilters({String? category, String? city, String? search}) {
    state = state.copyWith(
      selectedCategory: category ?? state.selectedCategory,
      selectedCity: city ?? state.selectedCity,
      searchQuery: search ?? state.searchQuery,
      hasMore: true,
    );
    fetchFeed(refresh: true);
  }

  void resetFilters() {
    state = state.copyWith(
      selectedCategory: 'All',
      selectedCity: null,
      searchQuery: '',
      hasMore: true,
    );
    fetchFeed(refresh: true);
  }
}

final circlesFeedProvider = StateNotifierProvider<CirclesFeedNotifier, CirclesFeedState>((ref) {
  final service = ref.watch(circlesFirestoreServiceProvider);
  return CirclesFeedNotifier(service, ref);
});
