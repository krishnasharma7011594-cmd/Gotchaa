import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gotchaa/core/theme/app_theme.dart';
import 'package:gotchaa/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

extension PumpApp on WidgetTester {
  /// Compatibility wrapper for existing tests that call `pumpApp`.
  /// It simply forwards to `pumpGotchaaApp`.
  Future<void> pumpApp(Widget widget,
      {List<Override> overrides = const []}) async {
    await pumpGotchaaApp(widget, overrides: overrides);
  }

  /// Pumps a widget wrapped in ProviderScope, MaterialApp, and GoRouter.
  Future<void> pumpGotchaaApp(Widget widget,
      {List<Override> overrides = const []}) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => widget),
      ],
    );

    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: AppTheme.fromGotchaaTheme(
              AppThemes.allThemes[ThemeType.gotchaaLight]!),
          routerConfig: router,
        ),
      ),
    );

    // Handle async loading states by settling
    await pumpAndSettle();
  }

  /// Finder helper for common GOTCHAA widgets or texts
  Finder findText(String text) => find.text(text);
  Finder findIcon(IconData icon) => find.byIcon(icon);
  Finder findButtonByText(String text) =>
      find.widgetWithText(ElevatedButton, text);
}

/// Standalone function as requested by user
Future<void> pumpGotchaaApp(WidgetTester tester, Widget widget,
    {List<Override> overrides = const []}) async {
  await tester.pumpGotchaaApp(widget, overrides: overrides);
}

/// Compatibility top‑level function matching older test code.
Future<void> pumpApp(WidgetTester tester, Widget widget,
    {List<Override> overrides = const []}) async {
  await tester.pumpGotchaaApp(widget, overrides: overrides);
}
