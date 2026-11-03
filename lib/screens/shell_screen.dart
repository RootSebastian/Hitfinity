import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'body_weight_screen.dart';
import 'home_screen.dart';
import 'plan_screen.dart';
import 'steps_screen.dart';
import 'summary_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;

  // (outline icon, filled icon, label, SHORT label for narrow screens)
  static const _items = [
    (Icons.fitness_center_outlined, Icons.fitness_center, 'Train', 'Train'),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'Plan', 'Plan'),
    (Icons.directions_walk_outlined, Icons.directions_walk, 'Steps', 'Steps'),
    (Icons.monitor_weight_outlined, Icons.monitor_weight, 'Body', 'Body'),
    (Icons.bolt, Icons.bolt_rounded, 'Summary', 'More'),
  ];

  Widget _screen() => switch (_selectedIndex) {
        0 => const HomeScreen(),
        1 => const PlanScreen(),
        2 => const StepsScreen(),
        3 => const BodyWeightScreen(),
        _ => const SummaryScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (i, item) in _items.indexed)
                  NavigationRailDestination(
                    icon: Icon(item.$1),
                    selectedIcon: Icon(item.$2),
                    label: Text(item.$3),
                  ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _screen()),
          ],
        ),
      );
    }
    return Scaffold(
      body: _screen(),
      extendBody: true,
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppTheme.spaceMD, 0, AppTheme.spaceMD, AppTheme.spaceMD),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final (i, item) in _items.indexed) _navItem(i, item),
        ],
      ),
    );
  }

  Widget _navItem(int index, (IconData, IconData, String, String) item) {
    final selected = _selectedIndex == index;
    final scheme = Theme.of(context).colorScheme;

    // Adaptive: below 430px of available width, use the short
    // label ("More" instead of "Summary") so the selected pill
    // never overflows. Above it, the full label.
    final useShortLabel =
        MediaQuery.sizeOf(context).width < 430;
    final label = useShortLabel ? item.$4 : item.$3;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => _select(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 52,
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.heroGradient : null,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.$2 : item.$1,
                size: 20,
                color: selected ? Colors.white : scheme.onSurfaceVariant,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          // Never let the label itself blow up the pill
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(int i) {
    if (i == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = i);
  }
}