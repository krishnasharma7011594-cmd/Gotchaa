import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/debug/frame_rate_monitor.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/app_localizations_x.dart';
import 'core/moderation/profanity_filter.dart';
import 'core/providers/auth_providers.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/shared_prefs_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/routing/app_router.dart';
import 'core/security/e2ee_service.dart';
import 'core/services/consent_gate_service.dart';
import 'core/services/login_security_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/dev_badge.dart';
import 'features/ai/presentation/widgets/floating_gemini_overlay.dart';

void main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // NOTE: .env file removed from assets — API keys are now injected via
  // --dart-define at build time. See lib/core/config/app_config.dart.

  final sharedPrefs = await SharedPreferences.getInstance();

  // Check if consent has already been prompted (which means Firebase can be initialized)
  final hasPrompted = sharedPrefs.getBool('gdpr_consent_prompted') ?? false;
  
  if (hasPrompted) {
    await ConsentGateService.initializeFirebaseAndDependents();
  } else {
    debugPrint('Firebase initialization deferred until consent is given');
  }

  try { FrameRateMonitor.start(); } catch (e) { debugPrint('FrameRateMonitor error: $e'); }

  try {
    await ProfanityFilter().initialize();
    debugPrint('ProfanityFilter initialized successfully');
  } catch (e, stack) {
    debugPrint('ProfanityFilter initialization failed: $e');
    debugPrint('$stack');
  }

  // Clean up any orphaned E2EE keys on app startup
  try {
    E2EEService().clearMemoryCache();
    debugPrint('E2EEService memory cache cleared');
  } catch (e, stack) {
    debugPrint('E2EEService clearMemoryCache failed: $e');
    debugPrint('$stack');
  }

  // Global Error Boundary - Replace grey screen with a branded error UI
  ErrorWidget.builder = (details) => Material(
      child: Container(
        padding: const EdgeInsets.all(24),
        color: AppColors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              details.exceptionAsString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // In a global error boundary, we can't easily navigate without a navigatorKey
                // For now, we'll just display the error clearly
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const GotchaaApp(),
    ),
  );

  // Preserve splash screen for at least 1.5 seconds for branding as requested
  Future.delayed(const Duration(milliseconds: 1500), FlutterNativeSplash.remove);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const ProviderScope(child: GotchaaApp());
}

class GotchaaApp extends ConsumerWidget {
  const GotchaaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue>(authStateProvider, (prev, next) {
      final user = next.asData?.value;
      final prevUser = prev?.asData?.value;
      if (user != null && prevUser?.uid != user.uid) {
        LoginSecurityService.instance.onUserSignedIn(user);
      }
    });
    final locale = ref.watch(languageProvider);
    final themeState = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GOTCHAA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromGotchaaTheme(AppThemes.allThemes[ThemeType.gotchaaLight]!),
      darkTheme: AppTheme.fromGotchaaTheme(AppThemes.allThemes[ThemeType.gotchaaDark]!),
      themeMode: themeState.themeMode,
      locale: locale,
      routerConfig: router,
      supportedLocales: AppLocalizationsConfig.languages
          .map((l) => Locale(l.code))
          .toList(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => DevBadge(
        child: Stack(
          children: [
            if (child != null) child,
            const FloatingGeminiOverlay(),
          ],
        ),
      ),
    );
  }
}

