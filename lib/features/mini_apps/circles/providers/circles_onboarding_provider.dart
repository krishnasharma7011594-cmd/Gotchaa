import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_onboarding_model.dart';
import '../services/circles_firestore_service.dart';

final circlesFirestoreServiceProvider = Provider((ref) => CirclesFirestoreService());

class CirclesOnboardingNotifier extends StateNotifier<AsyncValue<UserOnboarding>> {
  final CirclesFirestoreService _firestoreService;

  CirclesOnboardingNotifier(this._firestoreService) : super(const AsyncValue.loading()) {
    loadOnboarding();
  }

  Future<void> loadOnboarding() async {
    state = const AsyncValue.loading();
    try {
      final data = await _firestoreService.loadOnboarding();
      if (data != null) {
        state = AsyncValue.data(data);
      } else {
        state = AsyncValue.data(UserOnboarding.empty(_firestoreService.currentUserId));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveOnboarding({
    required List<String> hobbies,
    required List<String> languages,
    required List<String> vibePreferences,
    required List<String> preferredCities,
  }) async {
    try {
      final onboarding = UserOnboarding(
        userId: _firestoreService.currentUserId,
        hobbies: hobbies,
        languages: languages,
        vibePreferences: vibePreferences,
        preferredCities: preferredCities,
        isOnboardingComplete: true,
      );
      state = const AsyncValue.loading();
      await _firestoreService.saveOnboarding(onboarding);
      state = AsyncValue.data(onboarding);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> skipOnboarding() async {
    try {
      final onboarding = UserOnboarding(
        userId: _firestoreService.currentUserId,
        hobbies: [],
        languages: ['English'],
        vibePreferences: ['casual'],
        preferredCities: [],
        isOnboardingComplete: true, // Marked complete so onboarding screen is dismissed
      );
      state = const AsyncValue.loading();
      await _firestoreService.saveOnboarding(onboarding);
      state = AsyncValue.data(onboarding);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final circlesOnboardingProvider = StateNotifierProvider<CirclesOnboardingNotifier, AsyncValue<UserOnboarding>>((ref) {
  final service = ref.watch(circlesFirestoreServiceProvider);
  return CirclesOnboardingNotifier(service);
});
