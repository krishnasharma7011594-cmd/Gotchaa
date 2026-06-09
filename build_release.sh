#!/bin/bash
# GOTCHAA Production Build Script (Linux/macOS)

set -e

# Configuration
GEMINI_KEY=$1
if [ -z "$GEMINI_KEY" ]; then
    echo "Error: GEMINI_API_KEY is required as the first argument."
    echo "Usage: ./build_release.sh <your_gemini_key>"
    exit 1
fi

echo "🚀 Starting GOTCHAA Production Build..."

# 1. Clean & Prepare
echo "🧹 Cleaning project..."
flutter clean
flutter pub get

# 2. Audit
echo "🔍 Running code analysis..."
flutter analyze

# 3. Android Build
echo "🤖 Building Android App Bundle (AAB)..."
flutter build appbundle --release \
    --obfuscate --split-debug-info=build/symbols/android \
    --dart-define=GEMINI_API_KEY=$GEMINI_KEY

echo "🤖 Building Android APK..."
flutter build apk --release \
    --obfuscate --split-debug-info=build/symbols/android \
    --dart-define=GEMINI_API_KEY=$GEMINI_KEY

# 4. iOS Build
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS Archive..."
    flutter build ios --release \
        --obfuscate --split-debug-info=build/symbols/ios \
        --dart-define=GEMINI_API_KEY=$GEMINI_KEY
else
    echo "⚠️ Skipping iOS build (not on macOS)."
fi

echo "✅ Build Process Complete!"
echo "Android APK: build/app/outputs/flutter-apk/app-release.apk"
echo "Android AAB: build/app/outputs/bundle/release/app-release.aab"
