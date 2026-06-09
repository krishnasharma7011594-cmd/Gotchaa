import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/core/models/feed_item.dart';
import 'package:gotchaa/core/providers/post_providers.dart';
import 'package:gotchaa/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Complete Feed Flow Test', (tester) async {
    final post = getMockPost();
    final feedItems = [
      PostFeedItem(post),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          forYouFeedProvider.overrideWith((ref) => Stream.value(feedItems)),
        ],
        child: const GotchaaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Feed is shown and renders the post caption
    expect(find.text('This is a test caption'), findsOneWidget);

    // Verify like count is shown
    expect(find.text('10'), findsOneWidget);

    // Verify comment count is shown
    expect(find.text('5'), findsOneWidget);

    // Simulate scroll
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pump();
  });
}
