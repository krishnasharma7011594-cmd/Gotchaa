import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

// Simulated Trending Algorithm based on user requirements
double calculateTrendingScore({
  required int engagement, // likes + comments + shares
  required double ageHours,
}) {
  return engagement / math.pow(ageHours + 2, 1.5);
}

void main() {
  group('Trending Algorithm Tests', () {
    test('Formula calculates correctly', () {
      final score = calculateTrendingScore(engagement: 100, ageHours: 1);
      // 100 / (1 + 2)^1.5 = 100 / 3^1.5 = 100 / 5.196 = 19.24
      expect(score, closeTo(19.24, 0.01));
    });

    test(
        'Post with 100 likes at 1 hour scores higher than 100 likes at 24 hours',
        () {
      final score1 = calculateTrendingScore(engagement: 100, ageHours: 1);
      final score2 = calculateTrendingScore(engagement: 100, ageHours: 24);

      expect(score1, greaterThan(score2));
    });

    test('Post with 1000 likes beats post with 100 likes at same age', () {
      final score1 = calculateTrendingScore(engagement: 1000, ageHours: 5);
      final score2 = calculateTrendingScore(engagement: 100, ageHours: 5);

      expect(score1, greaterThan(score2));
    });

    test('Score always positive', () {
      final score = calculateTrendingScore(engagement: 0, ageHours: 10);
      expect(score, greaterThanOrEqualTo(0));
    });

    test('Age zero handled without division error', () {
      final score = calculateTrendingScore(engagement: 100, ageHours: 0);
      // 100 / (0 + 2)^1.5 = 100 / 2^1.5 = 100 / 2.828 = 35.35
      expect(score, closeTo(35.35, 0.01));
    });
  });
}
