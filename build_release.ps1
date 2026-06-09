# GOTCHAA Production Build Script (Windows PowerShell)

param (
    [Parameter(Mandatory=$true)]
    [string]$GeminiApiKey
)

$ErrorActionPreference = "Stop"

Write-Host "Starting Build..."

flutter clean
flutter pub get

flutter build apk --release --obfuscate --split-debug-info=build/symbols/android --dart-define=GEMINI_API_KEY=$GeminiApiKey

Write-Host "Build Complete!"
