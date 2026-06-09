#!/bin/bash

# Pre-commit hook to check for hardcoded secrets
# Scans files in lib/ for potential API keys

echo "Running secrets check..."

# Search for AIzaSy in lib/ (excluding firebase_options.dart)
matches=$(grep -r "AIzaSy" lib/ | grep -v "firebase_options.dart")

if [ -n "$matches" ]; then
  echo "Error: Potential hardcoded API key found in source code:"
  echo "$matches"
  echo "Please use --dart-define to inject keys at build time."
  exit 1
fi

# Search for other potential secrets like "sk-" for OpenAI
matches2=$(grep -r "sk-[a-zA-Z0-9]\{48\}" lib/)
if [ -n "$matches2" ]; then
  echo "Error: Potential OpenAI secret key found:"
  echo "$matches2"
  exit 1
fi

echo "No secrets found. Proceeding with commit."
exit 0
