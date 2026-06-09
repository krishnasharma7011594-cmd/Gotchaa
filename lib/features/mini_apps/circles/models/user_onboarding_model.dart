class UserOnboarding {
  UserOnboarding({
    required this.userId,
    required this.hobbies,
    required this.languages,
    required this.vibePreferences,
    required this.preferredCities,
    required this.isOnboardingComplete,
  });

  factory UserOnboarding.fromMap(Map<String, dynamic> map, String uId) =>
      UserOnboarding(
        userId: uId,
        hobbies: List<String>.from(map['hobbies'] ?? []),
        languages: List<String>.from(map['languages'] ?? []),
        vibePreferences: List<String>.from(map['vibePreferences'] ?? []),
        preferredCities: List<String>.from(map['preferredCities'] ?? []),
        isOnboardingComplete: map['isOnboardingComplete'] ?? false,
      );

  factory UserOnboarding.empty(String uId) => UserOnboarding(
        userId: uId,
        hobbies: [],
        languages: ['English'],
        vibePreferences: ['casual'],
        preferredCities: [],
        isOnboardingComplete: false,
      );
  final String userId;
  final List<String> hobbies;
  final List<String> languages;
  final List<String> vibePreferences;
  final List<String> preferredCities;
  final bool isOnboardingComplete;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'hobbies': hobbies,
        'languages': languages,
        'vibePreferences': vibePreferences,
        'preferredCities': preferredCities,
        'isOnboardingComplete': isOnboardingComplete,
      };
}
