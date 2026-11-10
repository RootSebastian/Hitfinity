import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class SecureLauncher {
  SecureLauncher._();

  static const Set<String> allowedHosts = {
    'github.com',
    'www.github.com',
    'api.github.com',
    'raw.githubusercontent.com',
    'objects.githubusercontent.com',
    'githubusercontent.com',
    'play.google.com',
  };

  static bool isAllowed(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.isScheme('https') &&
        allowedHosts.contains(uri.host);
  }

  static Future<bool> open(BuildContext context, String url) async {
    if (!isAllowed(url)) return false;
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) _notify(messenger, theme);
      return launched;
    } catch (_) {
      _notify(messenger, theme);
      return false;
    }
  }

  static void _notify(ScaffoldMessengerState messenger, ThemeData theme) {
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.surfaceAlt,
        content: Text(
          'No app found to open this link',
          style: TextStyle(color: AppTheme.text),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ),
    );
  }
}
