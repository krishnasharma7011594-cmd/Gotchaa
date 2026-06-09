import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/features/auth/presentation/screens/login_screen.dart';
import 'package:gotchaa/core/providers/repository_providers.dart';
import 'package:gotchaa/core/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/pump_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.authStateChanges).thenAnswer((_) => Stream.value(null));
  });

  group('LoginScreen Tests', () {
    testWidgets('Fields and buttons are present', (WidgetTester tester) async {
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and Password
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Try Demo (No Sign In)'), findsOneWidget);
    });

    testWidgets('Validation errors shown on empty submit', (WidgetTester tester) async {
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      
      await tester.pumpAndSettle();

      // Tap Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pump(); // Pump to show validation errors

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Invalid email validation error', (WidgetTester tester) async {
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      
      // Tap Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });
  });
}
