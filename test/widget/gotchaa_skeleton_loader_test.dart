import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/core/widgets/gotchaa_skeleton_loader.dart';
import 'package:shimmer/shimmer.dart';
import '../helpers/pump_app.dart';

void main() {
  group('GotchaaSkeletonLoader Tests', () {
    testWidgets('Feed skeleton renders with shimmer',
        (WidgetTester tester) async {
      await tester.pumpApp(const GotchaaSkeletonLoader.feed(itemCount: 3));

      // Verify Shimmer is present
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('Chat list skeleton renders with shimmer',
        (WidgetTester tester) async {
      await tester.pumpApp(const GotchaaSkeletonLoader.chatList(itemCount: 5));

      // Verify Shimmer is present
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('Profile skeleton renders with shimmer',
        (WidgetTester tester) async {
      await tester.pumpApp(const GotchaaSkeletonLoader.profile());

      // Verify Shimmer is present
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('Card skeleton renders with shimmer',
        (WidgetTester tester) async {
      await tester.pumpApp(const GotchaaSkeletonLoader.card());

      // Verify Shimmer is present
      expect(find.byType(Shimmer), findsOneWidget);
    });
  });
}
