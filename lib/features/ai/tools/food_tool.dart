import 'bro_tool.dart';

class FoodTool extends BroTool {
  @override
  String get name => 'search_food';

  @override
  String get description =>
      'Searches for food options based on cravings and suggests highly-rated nearby options.';

  @override
  Map<String, dynamic> get parameters => {
        'craving': 'What the user wants to eat (e.g., Pizza, Biryani)',
        'max_budget': 'Optional: maximum price range',
      };

  @override
  bool get requiresBiometrics =>
      false; // Initial search doesn't need biometrics

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    final craving = arguments['craving'] as String;

    // Mocking a search across providers (Zomato/Swiggy)
    // In production, this would call specialized 3rd party API aggregators

    final results = [
      {
        'name': 'Leo\'s Artisan Pizza',
        'rating': 4.8,
        'avg_time': '25 mins',
        'popular': 'Pepperoni Pizza'
      },
      {
        'name': 'EVOO Eatery',
        'rating': 4.6,
        'avg_time': '40 mins',
        'popular': 'Margherita'
      },
    ];

    return {
      'status': 'success',
      'query': craving,
      'recommendations': results,
      'message':
          'I found some top-rated places for $craving. Leo\'s is highly rated and the fastest right now.',
    };
  }
}
