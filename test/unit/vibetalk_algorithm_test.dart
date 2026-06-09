import 'package:flutter_test/flutter_test.dart';

// Simulated VibeTalk Algorithm based on user requirements
int calculateVibeTalkScore({
  required bool languageMatch,
  required bool sameContinent,
  required int commonGamesCount,
  required int waitTimeSeconds,
}) {
  int score = 0;

  if (languageMatch) score += 40;
  if (sameContinent) score += 20;

  // Common games score: 20 points max
  if (commonGamesCount > 0) score += 20;

  // Wait time scores up to 20 points
  int waitScore = (waitTimeSeconds ~/ 10);
  if (waitScore > 20) waitScore = 20;
  score += waitScore;

  if (score > 100) score = 100;
  return score;
}

bool checkVibeTalkRateLimit(int joinCountPerHour) {
  return joinCountPerHour < 10;
}

void main() {
  group('VibeTalk Algorithm Tests', () {
    test('Perfect match (same language + continent + games) scores highest',
        () {
      final score = calculateVibeTalkScore(
        languageMatch: true,
        sameContinent: true,
        commonGamesCount: 1,
        waitTimeSeconds: 200, // Max wait score
      );
      expect(score, equals(100));
    });

    test('Language match scores 40 points', () {
      final score = calculateVibeTalkScore(
        languageMatch: true,
        sameContinent: false,
        commonGamesCount: 0,
        waitTimeSeconds: 0,
      );
      expect(score, equals(40));
    });

    test('Same continent scores 20 points', () {
      final score = calculateVibeTalkScore(
        languageMatch: false,
        sameContinent: true,
        commonGamesCount: 0,
        waitTimeSeconds: 0,
      );
      expect(score, equals(20));
    });

    test('Common games score 20 points', () {
      final score = calculateVibeTalkScore(
        languageMatch: false,
        sameContinent: false,
        commonGamesCount: 1,
        waitTimeSeconds: 0,
      );
      expect(score, equals(20));
    });

    test('Wait time scores up to 20 points', () {
      final score = calculateVibeTalkScore(
        languageMatch: false,
        sameContinent: false,
        commonGamesCount: 0,
        waitTimeSeconds: 200,
      );
      expect(score, equals(20));
    });

    test('Total score never exceeds 100', () {
      final score = calculateVibeTalkScore(
        languageMatch: true,
        sameContinent: true,
        commonGamesCount: 5,
        waitTimeSeconds: 1000,
      );
      expect(score, lessThanOrEqualTo(100));
    });

    test('Rate limit blocks after 10 joins per hour', () {
      expect(checkVibeTalkRateLimit(5), isTrue);
      expect(checkVibeTalkRateLimit(10), isFalse); // Blocks at 10
      expect(checkVibeTalkRateLimit(15), isFalse);
    });
  });
}
