import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/core/widgets/gotchaa_like_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gotchaa/core/providers/auth_providers.dart';
import 'package:gotchaa/core/providers/profile_providers.dart';
import 'package:gotchaa/core/models/user_profile.dart';
import '../helpers/pump_app.dart';
import 'package:mocktail/mocktail.dart';

class MockUser extends Mock implements UserProfile {}

void main() {
  testWidgets('GotchaaLikeButton Tests', (WidgetTester tester) async {
    const contentId = 'post_123';
    const contentType = 'posts';

    // Mock user profile for the provider
    final mockUser = UserProfile(
      uid: 'test_uid',
      username: 'testuser',
      displayName: 'Test User',
      email: 'test@example.com',
      createdAt: DateTime.now(),
      hasPickedLanguage: true,
      ageVerified: true,
    );

    await tester.pumpApp(
      const GotchaaLikeButton(
        contentId: contentId,
        contentType: contentType,
        initialCount: 10,
      ),
      overrides: [
        currentUserProfileProvider.overrideWith((ref) => AsyncValue.data(mockUser)),
      ],
    );

    await tester.pumpAndSettle();

    // 1. Heart icon renders
    expect(find.byIcon(Icons.favorite_outline_rounded), findsOneWidget);

    // 2. Like count displays correctly
    expect(find.text('10'), findsOneWidget);

    // 3. Single tap triggers like callback and optimistic UI
    await tester.tap(find.byIcon(Icons.favorite_outline_rounded));
    await tester.pump(); // Pump to see optimistic update

    // 4. Optimistic UI: count updates before Firestore confirms
    expect(find.text('11'), findsOneWidget);
    
    // 5. After like: heart is filled red
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    // 6. Tap again to unlike
    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pump();

    // 7. After unlike: heart is unfilled
    expect(find.text('10'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_outline_rounded), findsOneWidget);
  });
}
