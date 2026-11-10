import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/services/secure_launcher.dart';
import '../lib/theme/app_theme.dart';

void main() {
  group('SecureLauncher.isAllowed', () {
    test('allows HTTPS URLs on allowlisted hosts', () {
      expect(
          SecureLauncher.isAllowed('https://github.com/owner/repo'), isTrue);
      expect(
          SecureLauncher.isAllowed(
              'https://raw.githubusercontent.com/owner/repo/main/README.md'),
          isTrue);
      expect(SecureLauncher.isAllowed('https://play.google.com/store/apps'),
          isTrue);
    });

    test('rejects cleartext HTTP', () {
      expect(
          SecureLauncher.isAllowed('http://github.com/owner/repo'), isFalse);
    });

    test('rejects hosts outside the allowlist', () {
      expect(SecureLauncher.isAllowed('https://evil.example.com'), isFalse);
      expect(SecureLauncher.isAllowed('https://github.com.evil.example.com'),
          isFalse);
    });

    test('rejects malformed input', () {
      expect(SecureLauncher.isAllowed('not a url'), isFalse);
      expect(SecureLauncher.isAllowed(''), isFalse);
    });
  });

  group('AppTheme', () {
    test('default skin is the lime identity', () {
      expect(AppTheme.lime, AppTheme.limeDefault);
      expect(AppTheme.canvas, const Color(0xFF0A0E08));
      expect(AppTheme.surface, const Color(0xFF141A10));
      expect(AppTheme.lightPaper, const Color(0xFFF1F4E9));
    });
  });
}
