# Release Build Verification Checklist

- [ ] signingConfig uses release keystore
- [ ] minifyEnabled = true
- [ ] shrinkResources = true
- [ ] No print() statements in lib/
- [ ] Firebase App Check using PlayIntegrity in release
- [ ] No API keys in tracked files
- [ ] Crashlytics enabled and tested
- [ ] All debug flags (kDebugMode guards) verified
- [ ] flutter build appbundle --release completes without errors
- [ ] AAB tested on physical device via internal testing track
- [ ] Data Safety form completed in Play Console
- [ ] Content rating questionnaire completed
- [ ] Privacy Policy URL live and submitted
- [ ] Terms of Service URL live and submitted
- [ ] Grievance Officer contact listed in app (India)
- [ ] All dangerous permissions have rationale dialogs
