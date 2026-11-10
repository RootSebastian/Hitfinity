#!/usr/bin/env bash
# HITFINITY — hardened release build.
# Produces obfuscated, icon-tree-shaken release artifacts.
# Keep build/debug-symbols/ somewhere safe: you need it to
# de-obfuscate stack traces from the wild.

set -euo pipefail

echo "── Static analysis ──────────────────────────────────"
flutter analyze

echo "── Tests ────────────────────────────────────────────"
flutter test

echo "── Building release APK (split per ABI) ─────────────"
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-symbols \
  --split-per-abi \
  --tree-shake-icons

echo "── Building release App Bundle (Play Store) ─────────"
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-symbols \
  --tree-shake-icons

echo
echo "Done. Artifacts:"
echo "  build/app/outputs/flutter-apk/*.apk"
echo "  build/app/outputs/bundle/release/app-release.aab"
echo "  build/debug-symbols/  ← back this up (stack trace symbolication)"
