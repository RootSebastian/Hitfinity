import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'body_weight_screen.dart';
import 'home_screen.dart';
import 'plan_screen.dart';
import 'steps_screen.dart';
import 'summary_screen.dart';
import '../widgets/hit_widgets.dart';
import '../services/hit_settings.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 2;

  static const _fabIndex = 2;

  static const _items = [
    (Icons.fitness_center_outlined, Icons.fitness_center_rounded,
        'Train'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded,
        'Plan'),
    (Icons.bolt, Icons.bolt_rounded, 'Summary'),
    (Icons.monitor_weight_outlined, Icons.monitor_weight_rounded,
        'Body'),
    (Icons.directions_walk_outlined, Icons.directions_walk_rounded,
        'Steps'),
  ];

  Widget _screen() => switch (_selectedIndex) {
        0 => const HomeScreen(),
        1 => const PlanScreen(),
        2 => SummaryScreen(onOpenTab: _openTab),
        3 => const BodyWeightScreen(),
        _ => const StepsScreen(),
      };

  void _openTab(int i) => _select(i);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _rail(),
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

  Widget _rail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) {
        HitHaptics.selectionClick();
        _select(i);
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: AppTheme.canvasDeep,
      indicatorColor: AppTheme.surfaceAlt,
      selectedIconTheme:       IconThemeData(color: AppTheme.lime),
      unselectedIconTheme: IconThemeData(
          color: AppTheme.textMuted),
      selectedLabelTextStyle:       TextStyle(
        color: AppTheme.lime,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: AppTheme.textMuted,
        fontSize: 12,
      ),
      destinations: [
        for (final item in _items)
          NavigationRailDestination(
            icon: Icon(item.$1),
            selectedIcon: Icon(item.$2),
            label: Text(item.$3),
          ),
      ],
    );
  }

  Widget _bottomNav() {
    return HitBottomNav(
      items: [
        for (final item in _items) HitNavItem(item.$2, item.$3)
      ],
      centerIndex: _fabIndex,
      selectedIndex: _selectedIndex,
      onChanged: _select,
    );
  }

  void _select(int i) {
    if (i == _selectedIndex) return;
    setState(() => _selectedIndex = i);
  }
}
