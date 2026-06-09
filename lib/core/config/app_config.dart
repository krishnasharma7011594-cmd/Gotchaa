/// Secure API Configuration
///
/// API keys are injected at build time using --dart-define flags, NOT stored
/// in files bundled in the APK/IPA.
///
/// HOW TO BUILD:
/// ─────────────────────────────────────────────────────────────────────────
/// Debug (local dev):
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
///
/// Release (production):
///   flutter build apk \
///     --dart-define=GEMINI_API_KEY=your_key_here \
///     --dart-define=UBER_CLIENT_ID=your_uber_id \
///     --dart-define=UBER_CLIENT_SECRET=your_uber_secret
///
/// CI/CD (GitHub Actions / Codemagic):
///   Store keys in repository secrets, pass as --dart-define at build step.
///   Never print or log these values in CI output.
/// ─────────────────────────────────────────────────────────────────────────
///
/// WHY NOT .env FILE:
///   flutter_dotenv bundles the .env file as a Flutter asset inside the APK.
///   Anyone can unzip the APK and read it. --dart-define compiles the value
///   directly into the Dart binary using String.fromEnvironment, which is
///   harder to extract and not present as a plaintext file in the package.
/// ─────────────────────────────────────────────────────────────────────────
library;

class AppConfig {
  AppConfig._(); // static-only class

  // ── Gemini AI ─────────────────────────────────────────────────────────────

  /// Gemini API key injected at build time.
  /// Pass with: --dart-define=GEMINI_API_KEY=your_key
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Empty in debug if not passed → shows clear error
  );

  // ── Uber API ──────────────────────────────────────────────────────────────

  /// Uber Client ID injected at build time.
  /// Pass with: --dart-define=UBER_CLIENT_ID=your_id
  static const String uberClientId = String.fromEnvironment(
    'UBER_CLIENT_ID',
    defaultValue: '',
  );

  /// Uber Client Secret injected at build time.
  /// Pass with: --dart-define=UBER_CLIENT_SECRET=your_secret
  static const String uberClientSecret = String.fromEnvironment(
    'UBER_CLIENT_SECRET',
    defaultValue: '',
  );

  // ── Spotify API ───────────────────────────────────────────────────────────

  /// Spotify Client ID injected at build time.
  /// Pass with: --dart-define=SPOTIFY_CLIENT_ID=your_id
  static const String spotifyClientId = String.fromEnvironment(
    'SPOTIFY_CLIENT_ID',
    defaultValue: '',
  );

  // ── Validation ────────────────────────────────────────────────────────────

  /// Returns true if all required API keys are present.
  /// Call this in debug mode to surface missing keys early.
  static bool get allKeysPresent =>
      geminiApiKey.isNotEmpty &&
      uberClientId.isNotEmpty &&
      spotifyClientId.isNotEmpty;

  /// Throws in debug mode if a required key is missing.
  /// Call from main() during development to catch missing keys early.
  static void assertKeysPresent() {
    assert(
      geminiApiKey.isNotEmpty,
      '\n\n'
      '══════════════════════════════════════════════════════\n'
      '  GOTCHAA: GEMINI_API_KEY is not set!\n'
      '  Run with: flutter run --dart-define=GEMINI_API_KEY=your_key\n'
      '══════════════════════════════════════════════════════\n',
    );
  }
}
