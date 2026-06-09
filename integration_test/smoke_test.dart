import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Smoke Test - App Boots', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GotchaaApp(),
      ),
    );

    // Wait for splash screen to disappear (if simulated) or just settle
    await tester.pumpAndSettle();

    // Verify Login Screen is shown (default when not logged in)
    expect(find.text('GOTCHAA'), findsOneWidget);
    expect(find.text('The Social Super App.'), findsOneWidget);
  });
}
