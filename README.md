# GOTCHAA – Breaking Language Barriers with AI
**Google Solution Challenge 2026 Submission**

GOTCHAA is a multilingual social super-app designed to break global communication barriers. Using Google Gemini AI and ML Kit, it enables real-time cross-cultural connection while fostering global peace and reduced inequality.

## 🏆 UN SDG Alignment
- **SDG 10: Reduced Inequalities**: Breaking digital and language isolation for underrepresented communities.
* **SDG 16: Peace, Justice, and Strong Institutions**: Fostering cross-cultural dialogue to reduce xenophobia and build global empathy.

## 🛠️ Google Technology Stack
- **Flutter**: Beautiful, high-performance cross-platform UI.
- **Firebase**:
  - **Authentication**: Secure Google Sign-In.
  - **Cloud Firestore**: Real-time social graph and messaging.
  - **Cloud Functions**: Secure server-side logic and Gemini AI proxy.
  - **Cloud Storage**: E2EE encrypted media and profile assets.
  - **App Check**: Play Integrity / DeviceCheck protection.
  - **FCM**: Real-time push notifications.
  - **Performance, Analytics, Crashlytics**: Production monitoring.
- **Google AI & ML**:
  - **Gemini Pro**: Intelligent multilingual support assistant.
  - **ML Kit Translation**: Real-time on-device chat translation.
  - **ML Kit Language ID**: Automatic detection of 100+ languages.
  - **ML Kit Face Detection**: Smart focus for VibeTalk video.
  - **ML Kit Selfie Segmentation**: Privacy-first background blur.

## 🏗️ Technical Architecture
GOTCHAA follows **Clean Architecture** principles to ensure scalability and testability:
- **Presentation**: Riverpod for state management, following the MVVM pattern.
- **Domain**: Pure Dart entities and use cases (business logic).
- **Data**: Repository pattern with remote (Firebase) and local (Hive) data sources.
- **Security**: AES-256 End-to-End Encryption (E2EE) for all private messages.

## 🚀 Setup & Installation

### Prerequisites
- Flutter SDK (3.22.0+)
- Firebase CLI installed and logged in
- A Gemini API Key from [Google AI Studio](https://aistudio.google.com/)

### 1. Clone & Install
```bash
git clone https://github.com/yourusername/Gotchaa.git
cd Gotchaa
flutter pub get
```

### 2. Configure Firebase
- Create a project in the [Firebase Console](https://console.firebase.google.com/).
- Run `flutterfire configure` to generate `firebase_options.dart`.
- Enable Auth (Google), Firestore, Storage, and Functions.

### 3. Run Development
```bash
# Injected API key via dart-define for security
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

## 📦 Production Build
To generate the final production release:

### Android
```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

### iOS
```bash
flutter build ios --release --obfuscate --split-debug-info=build/symbols --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

## 🧪 Testing
```bash
# Unit & Widget Tests
flutter test

# Integration (Smoke) Tests
flutter test integration_test/smoke_test.dart
```

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

---
**Connecting the world, one vibe at a time.**
