# GOTCHAA Pre-Launch Checklist

Complete every item before Play Store / App Store submission.  
**Package ID (Android):** `com.gotchaa.gotchaa` · **Legal versions:** Privacy & Terms `v3.0`

---

## Security (must all be checked)

- [x] Firestore rules restrict chat to participants only
- [x] E2EE claims removed — accurate security language used
- [x] FCM token in `users_private` only
- [x] Firebase App Check using Play Integrity in release (`kReleaseMode`) *(Verified in `lib/main.dart`)*
- [x] No API keys in tracked files (use `--dart-define` / `AppConfig`) *(Verified in `lib/core/config/app_config.dart`)*
- [x] No debug logs in release build (`AppLogger` only) *(Raw debugPrint/print redirected to AppLogger)*
- [x] Screenshot prevention on sensitive screens (`SecureScreen` / karma / personal info)
- [x] 2FA available for account deletion
- [x] Login session alerts + active sessions screen
- [x] CSAM hash gate on image uploads

---

## Legal (must all be checked)

- [x] Privacy Policy Version 3.0 published
- [x] Terms of Service Version 3.0 published
- [x] Community Guidelines published
- [x] Cookie Policy published
- [x] Age gate blocks under 13
- [x] VibeTalk blocked for under 18
- [x] Analytics consent modal implemented
- [x] Virtual currency disclaimer on all wallet screens
- [x] WebView trademark disclaimer implemented
- [x] Open source licenses screen in settings

---

## Play Store (must all be checked)

- [x] `targetSdkVersion = 34` (`android/app/build.gradle.kts`)
- [x] `READ_EXTERNAL_STORAGE` removed from manifest
- [x] Release signing configured (`key.properties` + release `signingConfig`)
- [x] ProGuard / R8 enabled (`isMinifyEnabled = true`)
- [x] AAB builds successfully (`flutter build appbundle --release`)
- [x] App tested on Android 8.0 minimum
- [x] App tested on Android 14 latest
- [x] No crashes in monkey testing
- [x] `android:label` = GOTCHAA
- [x] Locale config for 14 languages *(Verified in `locales_config.xml`)*

---

## Content & moderation (must all be checked)

- [x] Content moderation system active
- [x] Report button on posts, comments, profiles, chat, VibeTalk
- [x] CSAM detection implemented
- [x] Profanity filter active (Remote Config + local list)
- [x] VibeTalk safety warning + emergency exit + shake report

---

## Performance & cost (must all be checked)

- [x] Firestore offline persistence enabled
- [x] Feed / chat / notifications / followers paginated
- [x] `FirestoreCostGuard` warns above 1000 reads/session (debug)
- [x] Image compression + thumbnails on upload
- [x] Video compression before upload
- [x] Offline banner + action queue for messages/likes/posts

---

## Automated validation

Run before each release candidate:

```bash
bash scripts/validate_launch.sh
```

Expected output: **READY FOR LAUNCH** (or fix all FAIL items).

---

## Version metadata

| Platform | Field | Value |
|----------|--------|--------|
| pubspec | version | `1.0.0+1` |
| iOS | CFBundleShortVersionString | `1.0.0` |
| Android | applicationId | `com.gotchaa.gotchaa` |

---

*Last updated: May 2026*
