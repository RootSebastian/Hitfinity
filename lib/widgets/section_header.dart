import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final hairline =
        AppTheme.hairline(Theme.of(context).brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Container(height: 1, color: hairline),
          ),
          if (action != null) ...[
            const SizedBox(width: AppTheme.spaceSM),
            action!,
          ],
        ],
      ),
    );
  }
}
