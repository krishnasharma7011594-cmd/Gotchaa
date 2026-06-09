import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gotchaa/core/providers/auth_providers.dart';
import 'mock_firebase.dart';

// Dummy providers for those that might not exist in the codebase
// but are requested by the user for testing.
final appConfigProvider = Provider((ref) => 'test_config');
final analyticsServiceProvider = Provider((ref) => 'no-op');
final firestoreProvider = Provider((ref) => getFakeFirestore());

/// Creates a ProviderContainer with overrides for testing.
ProviderContainer createTestContainer() {
  final mockAuth = getMockAuth();
  final fakeFirestore = getFakeFirestore();

  return ProviderContainer(
    overrides: [
      // authStateProvider.overrideWith((ref) => Stream.value(mockAuth.currentUser)),
      firestoreProvider.overrideWith((ref) => fakeFirestore),
      appConfigProvider.overrideWith((ref) => 'test_config'),
      analyticsServiceProvider.overrideWith((ref) => 'no-op'),
    ],
  );
}
