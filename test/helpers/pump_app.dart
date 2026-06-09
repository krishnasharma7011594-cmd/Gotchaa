import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gotchaa/core/theme/app_theme.dart';
import 'package:gotchaa/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gotchaa/core/providers/shared_prefs_provider.dart';
import 'package:gotchaa/core/providers/auth_providers.dart';
import 'package:gotchaa/features/chat/providers/chat_providers.dart';
import 'package:gotchaa/core/providers/repository_providers.dart';
import 'package:gotchaa/core/repositories/social_repository.dart';
import 'mock_firebase.dart';

extension PumpApp on WidgetTester {
  /// Compatibility wrapper for existing tests that call `pumpApp`.
  /// It simply forwards to `pumpGotchaaApp`.
  Future<void> pumpApp(Widget widget,
      {List<Override> overrides = const [], bool settle = true}) async {
    await pumpGotchaaApp(widget, overrides: overrides, settle: settle);
  }

  /// Pumps a widget wrapped in ProviderScope, MaterialApp, and GoRouter.
  Future<void> pumpGotchaaApp(Widget widget,
      {List<Override> overrides = const [], bool settle = true}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockAuth = getMockAuth();
    final fakeFirestore = getFakeFirestore();

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => widget),
      ],
    );

    await pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firestoreProvider.overrideWithValue(fakeFirestore),
          firebaseAuthProvider.overrideWithValue(mockAuth),
          authStateProvider
              .overrideWith((ref) => Stream.value(mockAuth.currentUser)),
          socialRepositoryProvider
              .overrideWithValue(SocialRepository(db: fakeFirestore)),
          ...overrides,
        ],
        child: MaterialApp.router(
          theme: AppTheme.fromGotchaaTheme(
              AppThemes.allThemes[ThemeType.gotchaaLight]!),
          routerConfig: router,
        ),
      ),
    );

    // Handle async loading states by settling
    if (settle) {
      await pumpAndSettle();
    } else {
      await pump();
    }
  }

  /// Finder helper for common GOTCHAA widgets or texts
  Finder findText(String text) => find.text(text);
  Finder findIcon(IconData icon) => find.byIcon(icon);
  Finder findButtonByText(String text) =>
      find.widgetWithText(ElevatedButton, text);
}

/// Standalone function as requested by user
Future<void> pumpGotchaaApp(WidgetTester tester, Widget widget,
    {List<Override> overrides = const [], bool settle = true}) async {
  await tester.pumpGotchaaApp(widget, overrides: overrides, settle: settle);
}

/// Compatibility top‑level function matching older test code.
Future<void> pumpApp(WidgetTester tester, Widget widget,
    {List<Override> overrides = const [], bool settle = true}) async {
  await tester.pumpGotchaaApp(widget, overrides: overrides, settle: settle);
}
