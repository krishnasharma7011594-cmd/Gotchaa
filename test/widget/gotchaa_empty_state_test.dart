import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/core/widgets/gotchaa_empty_state.dart';
import '../helpers/pump_app.dart';

void main() {
  group('GotchaaEmptyState Tests', () {
    testWidgets('Renders title and subtitle correctly', (WidgetTester tester) async {
      await tester.pumpApp(
        const GotchaaEmptyState(
          icon: Icons.star,
          title: 'Custom Title',
          subtitle: 'Custom Subtitle',
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom Subtitle'), findsOneWidget);
    });

    testWidgets('CTA button present and tappable when provided', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpApp(
        GotchaaEmptyState(
          icon: Icons.star,
          title: 'Title',
          subtitle: 'Subtitle',
          actionLabel: 'Tap Me',
          onAction: () => tapped = true,
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);
      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    testWidgets('.chat() named constructor renders correct content', (WidgetTester tester) async {
      await tester.pumpApp(const GotchaaEmptyState.chat());

      expect(find.text('No conversations yet'), findsOneWidget);
      expect(find.text('Find someone interesting and start an encrypted conversation.'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });

    testWidgets('.notifications() named constructor renders correct content', (WidgetTester tester) async {
      await tester.pumpApp(const GotchaaEmptyState.notifications());

      expect(find.text('All caught up!'), findsOneWidget);
      expect(find.text('You have no new notifications. Go make some connections!'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });
  });
}
