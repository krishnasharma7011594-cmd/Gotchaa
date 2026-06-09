#!/bin/bash

# Pre-release check script for GOTCHAA

echo "============================================="
echo "Running GOTCHAA Pre-Release Checks"
echo "============================================="

FAILURES=0

# a. Grep for print( in lib/
echo -n "Checking for raw print() calls in lib/... "
matches=$(grep -r "\bprint(" lib/)
if [ -n "$matches" ]; then
  echo "WARN"
  echo "Found raw print() calls:"
  echo "$matches"
else
  echo "PASS"
fi

# b. Check build.gradle.kts for debug signing config
echo -n "Checking for debug signing config in release build... "
if [ -f "android/app/build.gradle.kts" ]; then
  # Simple check for the debug getByName call
  matches=$(grep "signingConfigs.getByName(\"debug\")" android/app/build.gradle.kts)
  if [ -n "$matches" ]; then
    echo "WARN"
    echo "Found debug signing config reference in android/app/build.gradle.kts"
  else
    echo "PASS"
  fi
else
  echo "SKIPPED (android/app/build.gradle.kts not found)"
fi

# c. Check .gitignore contains key.properties and *.jks
echo -n "Checking .gitignore for key.properties and *.jks... "
if [ -f ".gitignore" ]; then
  has_key_prop=$(grep "key.properties" .gitignore)
  has_jks=$(grep "\.jks" .gitignore)
  
  if [ -n "$has_key_prop" ] && [ -n "$has_jks" ]; then
    echo "PASS"
  else
    echo "WARN"
    if [ -z "$has_key_prop" ]; then echo "  key.properties is missing from .gitignore"; fi
    if [ -z "$has_jks" ]; then echo "  *.jks is missing from .gitignore"; fi
  fi
else
  echo "WARN (.gitignore not found)"
fi

# d. Runs flutter analyze and fails on errors
echo "Running flutter analyze..."
flutter analyze
if [ $? -ne 0 ]; then
  echo "FAIL: Flutter analysis found errors."
  FAILURES=$((FAILURES+1))
else
  echo "PASS: Flutter analysis passed."
fi

# e. Outputs PASS/FAIL summary
echo "============================================="
if [ $FAILURES -eq 0 ]; then
  echo "PRE-RELEASE CHECK: PASS"
  exit 0
else
  echo "PRE-RELEASE CHECK: FAIL ($FAILURES critical failures)"
  exit 1
fi
