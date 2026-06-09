import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/services/presentation/screens/web_browser_screen.dart';
import '../../features/services/providers/services_provider.dart';
import '../services/analytics_service.dart';

import '../../features/auth/presentation/screens/age_verification_screen.dart';
import '../../features/auth/presentation/screens/first_time_language_screen.dart';
import '../../features/auth/presentation/screens/invite_code_screen.dart';
import '../../features/auth/presentation/screens/legal_consent_gate_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/home/presentation/screens/gotchaa_app_shell.dart';
import '../../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../../features/settings/presentation/screens/terms_of_service_screen.dart';
import '../providers/age_provider.dart';
import '../providers/auth_providers.dart';
import '../providers/language_provider.dart';
import '../providers/legal_provider.dart';
import '../providers/profile_providers.dart';
import 'resolve_username_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: routerNotifier,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const GotchaaAppShell(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/invite',
        builder: (context, state) => const InviteCodeScreen(),
      ),
      GoRoute(
        path: '/language-picker',
        builder: (context, state) => const FirstTimeLanguageScreen(),
      ),
      GoRoute(
        path: '/@:username',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return ResolveUsernameScreen(username: username);
        },
      ),
      GoRoute(
        path: '/profile/:username',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return ResolveUsernameScreen(username: username);
        },
      ),
      GoRoute(
        path: '/legal-consent',
        builder: (context, state) => const LegalConsentGateScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/age-verification',
        builder: (context, state) => const AgeVerificationScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLegalAccepted = ref.read(legalAcceptedProvider);
      final authState = ref.read(authStateProvider);
      final profileState = ref.read(currentUserProfileProvider);
      final hasPickedLanguage = ref.read(hasPickedLanguageProvider);

      final user = authState.asData?.value;
      final profile = profileState.asData?.value;

      final matchedLocation = state.matchedLocation;
      final isLegalRoute = matchedLocation == '/legal-consent' || 
                           matchedLocation == '/privacy' || 
                           matchedLocation == '/terms';
      final isLoggingIn = matchedLocation == '/login';

      // 0. Legal Check — force re-acceptance when Privacy/Terms version changes
      if (user != null && !isLegalAccepted) {
        return isLegalRoute ? null : '/legal-consent';
      }

      // If we are on legal-consent, move on
      if (matchedLocation == '/legal-consent') {
        return user == null ? '/login' : '/';
      }

      // 1. Auth Check
      if (user == null) {
        return isLoggingIn || isLegalRoute ? null : '/login';
      }

      // 2. Profile Check (Wait for profile to load)
      if (profileState.isLoading) return null;
      if (profile == null) return null; 

      final isGuest = user.isAnonymous;
      
      // 3. Email Verification
      if (!isGuest && !user.emailVerified) {
        if (state.matchedLocation == '/verify-email' || isLegalRoute) return null;
        return '/verify-email';
      }
      
      // 4. Redirect to home if on a gate screen but all checks passed
      final isGateRoute = matchedLocation == '/login' ||
                          matchedLocation == '/verify-email';

      if (isGateRoute) return '/';

      return null;
    },
  );
});

class RouterNotifier extends ChangeNotifier {

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (prev, next) {
      final user = next.asData?.value;
      if (user != null) {
        _ref.read(legalAcceptedProvider.notifier).syncPolicyCheckFromServer();
      }
      notifyListeners();
    });
    _ref.listen(currentUserProfileProvider, (_, __) => notifyListeners());
    _ref.listen(hasPickedLanguageProvider, (_, __) => notifyListeners());
    _ref.listen(legalAcceptedProvider, (_, __) => notifyListeners());
    _ref.listen(ageProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerNotifierProvider = Provider<RouterNotifier>(RouterNotifier.new);


enum ServiceType {
  all,
  food,
  grocery,
  shopping,
  fashion,
  hotels,
  travel,
  entertainment,
  health,
  home,
  transport,
}

class GotchaaRouter {
  static void openService(ServiceType type) {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      final container = ProviderScope.containerOf(context);
      final services = container.read(servicesProvider);
      final service = services.firstWhere(
        (s) => s.category.name == type.name,
        orElse: () => services.first,
      );
      
      AnalyticsService.logEvent(name: 'service_opened', parameters: {'service_id': service.id});
      if (service.id == 'uber') {
        AnalyticsService.logEvent(name: 'uber_opened');
      } else if (service.id == 'rapido') {
        AnalyticsService.logEvent(name: 'rapido_opened');
      } else if (['eatsure', 'fassos', 'zepto', 'flipkart', 'ajio', 'nykaa', 'oyo', 'airbnb', 'district', 'practo'].contains(service.id)) {
        AnalyticsService.logEvent(name: '${service.id}_opened');
      }

      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => GotchaaWebBrowserScreen(service: service),
        ),
      );
    }
  }

  static void openServiceById(String id) {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      final container = ProviderScope.containerOf(context);
      final services = container.read(servicesProvider);
      final service = services.firstWhere(
        (s) => s.id == id,
        orElse: () => services.first,
      );
      
      AnalyticsService.logEvent(name: 'service_opened', parameters: {'service_id': service.id});
      if (service.id == 'uber') {
        AnalyticsService.logEvent(name: 'uber_opened');
      } else if (service.id == 'rapido') {
        AnalyticsService.logEvent(name: 'rapido_opened');
      } else if (['eatsure', 'fassos', 'zepto', 'flipkart', 'ajio', 'nykaa', 'oyo', 'airbnb', 'district', 'practo'].contains(service.id)) {
        AnalyticsService.logEvent(name: '${service.id}_opened');
      }

      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => GotchaaWebBrowserScreen(service: service),
        ),
      );
    }
  }
}


