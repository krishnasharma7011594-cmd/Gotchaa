import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/features/services/domain/models/service_model.dart';
import 'package:gotchaa/features/services/presentation/widgets/service_card.dart';
import '../helpers/pump_app.dart';

void main() {
  const testService = GotchaaService(
    id: 'test',
    name: 'Test Service',
    description: 'Test Description',
    url: 'https://test.com',
    category: ServiceCategory.other,
    brandColor: Colors.blue,
  );

  group('ServiceCard Tests', () {
    testWidgets('Renders name and description correctly', (WidgetTester tester) async {
      await tester.pumpApp(
        ServiceCard(
          service: testService,
          onTap: () {},
        ),
      );

      expect(find.text('Test Service'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('Tapping card triggers onTap callback', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpApp(
        ServiceCard(
          service: testService,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Test Service'));
      expect(tapped, isTrue);
    });

    testWidgets('Favourite icon toggles and triggers callback', (WidgetTester tester) async {
      bool toggleTapped = false;
      
      await tester.pumpApp(
        ServiceCard(
          service: testService,
          onTap: () {},
          isFavourite: false,
          onFavouriteToggle: () => toggleTapped = true,
        ),
      );

      // Should show favorite_border
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);

      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(toggleTapped, isTrue);
    });

    testWidgets('Shows filled favourite icon when isFavourite is true', (WidgetTester tester) async {
      await tester.pumpApp(
        ServiceCard(
          service: testService,
          onTap: () {},
          isFavourite: true,
          onFavouriteToggle: () {},
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });
  });
}
