#!/usr/bin/env bash
# GOTCHAA pre-launch validation
# Run from repo root: bash scripts/validate_launch.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
FAILURES=()
PASSES=0

pass() { echo -e "${GREEN}PASS${NC} $1"; PASSES=$((PASSES + 1)); }
fail() { echo -e "${RED}FAIL${NC} $1"; FAILURES+=("$1"); }

echo "=== GOTCHAA Launch Validation ==="
echo ""

# 1. No raw print() in lib/ (excluding app_logger.dart itself)
if grep -R --include="*.dart" -E '\bprint\(' lib/ 2>/dev/null \
    | grep -v 'app_logger.dart' \
    | grep -q .; then
  fail "print() statements found in lib/"
  grep -R --include="*.dart" -E '\bprint\(' lib/ 2>/dev/null \
    | grep -v 'app_logger.dart' | head -5
else
  pass "No print() in lib/"
fi

# 2. No hardcoded sensitive API keys in lib/
#    firebase_options.dart contains public client API keys — excluded.
if grep -R --include="*.dart" -E 'AIza[0-9A-Za-z_-]{20,}|sk-[a-zA-Z0-9]{20,}' lib/ 2>/dev/null \
    | grep -v 'firebase_options.dart' \
    | grep -q .; then
  fail "Possible hardcoded API keys in lib/"
else
  pass "No sensitive API keys in lib/ (firebase_options.dart excluded)"
fi

# 3. targetSdkVersion 34
if grep -q 'targetSdk = 34' android/app/build.gradle.kts 2>/dev/null; then
  pass "targetSdkVersion is 34"
else
  fail "targetSdkVersion is not 34 in android/app/build.gradle.kts"
fi

# 4. Release signing config present
if grep -q 'signingConfigs.getByName("release")' android/app/build.gradle.kts 2>/dev/null; then
  pass "Release signingConfig referenced"
else
  fail "Release signingConfig missing"
fi

# 5. key.properties gitignored
if grep -q 'key.properties' .gitignore 2>/dev/null; then
  pass "key.properties is gitignored"
else
  fail "key.properties not in .gitignore"
fi

# 6. Privacy Policy version
if grep -q "privacyVersion = 'v3.0'" lib/core/constants/app_constants.dart 2>/dev/null; then
  pass "Privacy Policy version v3.0"
else
  fail "Privacy Policy version mismatch (expected v3.0)"
fi

# 7. Terms version
if grep -q "termsVersion = 'v3.0'" lib/core/constants/app_constants.dart 2>/dev/null; then
  pass "Terms version v3.0"
else
  fail "Terms version mismatch (expected v3.0)"
fi

# 8. flutter analyze — fail only on ERROR-level issues, not infos/warnings
echo ""
echo "Running flutter analyze (this may take a few minutes)..."
mkdir -p build

# Run analyze; capture output. --no-fatal-infos / --no-fatal-warnings still
# exits 1 when issues found, so we capture exit code manually.
flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 \
  | tee build/gotchaa_analyze.txt || true

if grep -E "^  error " build/gotchaa_analyze.txt 2>/dev/null | grep -q .; then
  ERROR_COUNT=$(grep -c "^  error " build/gotchaa_analyze.txt 2>/dev/null || echo "0")
  fail "flutter analyze reported $ERROR_COUNT error(s) — see build/gotchaa_analyze.txt"
else
  INFO_COUNT=$(grep -c "^  info " build/gotchaa_analyze.txt 2>/dev/null || echo "0")
  pass "flutter analyze clean (0 errors; $INFO_COUNT infos/warnings ignored)"
fi

# 9. pubspec version
if grep -q '^version: 1.0.0+1' pubspec.yaml 2>/dev/null; then
  pass "pubspec version 1.0.0+1"
else
  fail "pubspec version is not 1.0.0+1"
fi

# 10. READ_EXTERNAL_STORAGE not in main manifest
if grep -q 'READ_EXTERNAL_STORAGE' android/app/src/main/AndroidManifest.xml 2>/dev/null; then
  fail "READ_EXTERNAL_STORAGE still in AndroidManifest"
else
  pass "READ_EXTERNAL_STORAGE removed from manifest"
fi

echo ""
echo "=== Summary ==="
echo -e "Passed: ${GREEN}${PASSES}${NC}"

if [ ${#FAILURES[@]} -eq 0 ]; then
  echo -e "${GREEN}*** READY FOR LAUNCH ***${NC}"
  exit 0
else
  echo -e "${RED}NOT READY FOR LAUNCH${NC}"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
