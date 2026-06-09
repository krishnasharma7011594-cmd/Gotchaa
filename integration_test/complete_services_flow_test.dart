import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/features/services/presentation/screens/services_screen.dart';
import 'package:gotchaa/features/services/providers/services_provider.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete Services Flow Test', (tester) async {
    final service1 = getMockService(id: '1', name: 'Food Delivery');
    final service2 = getMockService(id: '2', name: 'Ride Sharing');
    final mockServices = [service1, service2];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          servicesProvider.overrideWith((ref) => mockServices),
        ],
        child: const MaterialApp(
          home: ServicesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Services are shown
    expect(find.text('Food Delivery'), findsOneWidget);
    expect(find.text('Ride Sharing'), findsOneWidget);

    // Search for 'Food'
    await tester.enterText(find.byType(TextField), 'Food');
    await tester.pumpAndSettle();

    // Verify only Food Delivery is shown
    expect(find.text('Food Delivery'), findsOneWidget);
    expect(find.text('Ride Sharing'), findsNothing);

    // Tap service
    await tester.tap(find.text('Food Delivery'));
    await tester.pump();
  });
}
