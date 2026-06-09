import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

/// Returns a fake Firestore instance for testing.
FakeFirebaseFirestore getFakeFirestore() {
  final firestore = FakeFirebaseFirestore();
  // Seed with realistic data if needed
  return firestore;
}

/// Returns a mock Firebase Auth instance for testing.
MockFirebaseAuth getMockAuth(
    {bool signedIn = true,
    String uid = 'test_uid',
    String email = 'test@example.com'}) {
  if (signedIn) {
    final user = MockUser(
      uid: uid,
      email: email,
      displayName: 'Test User',
      isEmailVerified: true,
    );
    return MockFirebaseAuth(signedIn: true, mockUser: user);
  }
  return MockFirebaseAuth();
}

/// Setup function that initializes all mocks before each test
void setupFirebaseMocks() {
  // Register fallback values for mocktail if needed
  registerFallbackValue(Uri());
}
