import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../widgets/hit_widgets.dart';
import 'settings_screen.dart';
import '../services/hit_settings.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, this.onOpenTab});

  final ValueChanged<int>? onOpenTab;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int _view = 0;

  final NumberFormat _fmtInt = NumberFormat('#,##0');

  static const _proteinColor = AppTheme.protein;
  static const _carbColor = AppTheme.carbs;
  static const _fatColor = AppTheme.fat;

  List<WorkoutSessionWithSets> _workouts = [];
  List<WalkSessionRow> _walks = [];
  List<BodyWeightRow> _weights = [];
  List<FoodEntryRow> _todayFood = [];
  List<FoodEntryRow> _weekFood = [];
  DietGoals _goals = const DietGoals();
  final _subs = <StreamSubscription<dynamic>>[];

  static DateTime get _todayStart {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime get _weekStart =>
      _todayStart.subtract(Duration(days: _todayStart.weekday - 1));

  @override
  void initState() {
    super.initState();

    void listen<T>(Stream<T> s, void Function(T) onUpdate) {
      _subs.add(s.listen((d) {
        if (mounted) setState(() => onUpdate(d));
      }));
    }

    listen(DatabaseProvider.instance.watchAllWorkouts(),
        (d) => _workouts = d);
    listen(DatabaseProvider.instance.watchAllWalks(), (d) => _walks = d);
    listen(DatabaseProvider.instance.watchBodyWeights(),
        (d) => _weights = d);
    listen(
        DatabaseProvider.instance
            .watchFoodEntriesForDay(DateTime.now()),
        (d) => _todayFood = d);
    listen(
        DatabaseProvider.instance.watchFoodEntriesBetween(
            _weekStart,
            _todayStart.add(const Duration(days: 1))),
        (d) => _weekFood = d);
    listen(DatabaseProvider.instance.watchDietGoals(),
        (d) => _goals = d);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  List<WorkoutSessionWithSets> get _dayWorkouts => _workouts
      .where((w) => !w.startTime.isBefore(_todayStart))
      .toList();

  List<WorkoutSessionWithSets> get _weekWorkouts => _workouts
      .where((w) => !w.startTime.isBefore(_weekStart))
      .toList();

  List<WalkSessionRow> get _dayWalks => _walks
      .where((w) => !w.startTime.isBefore(_todayStart))
      .toList();

  List<WalkSessionRow> get _weekWalks => _walks
      .where((w) => !w.startTime.isBefore(_weekStart))
      .toList();

  double get _todayKcal =>
      _todayFood.fold(0.0, (a, e) => a + e.calories);

  double get _todayProtein =>
      _todayFood.fold(0.0, (a, e) => a + e.proteinG);

  double get _todayCarbs =>
      _todayFood.fold(0.0, (a, e) => a + e.carbsG);

  double get _todayFat =>
      _todayFood.fold(0.0, (a, e) => a + e.fatG);

  List<double> get _weekKcalPerDay {
    final vals = List<double>.filled(7, 0);
    for (final e in _weekFood) {
      final i = e.date.difference(_weekStart).inDays;
      if (i >= 0 && i < 7) vals[i] += e.calories;
    }
    return vals;
  }

  int get _daysLogged {
    final days = <int>{};
    for (final e in _weekFood) {
      days.add(e.date.difference(_weekStart).inDays);
    }
    return days.length;
  }

  double get _avgKcal => _daysLogged == 0
      ? 0
      : _weekFood.fold(0.0, (a, e) => a + e.calories) /
          _daysLogged;

  Set<int> get _activeWeekDays {
    final days = <int>{};
    void mark(DateTime start) {
      final i = start.difference(_weekStart).inDays;
      if (i >= 0 && i < 7) days.add(i);
    }

    for (final w in _weekWorkouts) {
      mark(w.startTime);
    }
    for (final w in _weekWalks) {
      mark(w.startTime);
    }
    return days;
  }

  String get _verdict {
    if (_view == 0) {
      if (_dayWorkouts.isNotEmpty && _todayFood.isNotEmpty) {
        return 'Full house';
      }
      if (_dayWorkouts.isNotEmpty) return 'Trained today';
      if (_todayFood.isNotEmpty) return 'Fuelled up';
      if (_dayWalks.isNotEmpty) return 'On the move';
      return 'Clean slate';
    }
    switch (_weekWorkouts.length) {
      case 0:
        return 'Ready when you are';
      case 1:
        return 'Warming up';
      case 2:
      case 3:
        return 'On track';
      default:
        return 'Killing it';
    }
  }

  void _openSettings() {
    HitHaptics.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GreetingHeader(
              subtitle: _verdict,
              onSettingsTap: _openSettings,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLG),
              child: SegmentSwitch(
                options: const ['Day', 'Week'],
                index: _view,
                onChanged: (i) => setState(() => _view = i),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_view),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.spaceLG,
                        AppTheme.spaceLG,
                        AppTheme.spaceLG,
                        96),
                    children: [
                      _buildChallengeBanner(),
                      const SizedBox(height: AppTheme.spaceLG),
                      WeekStrip(
                        weekStart: _weekStart,
                        markedDays: _activeWeekDays,
                      ),
                      const SizedBox(height: AppTheme.spaceLG),
                      _buildStatTiles(theme),
                      if (widget.onOpenTab != null) ...[
                        const SectionHeader('QUICK ACTIONS'),
                        _buildQuickActions(theme),
                      ],
                      const SectionHeader('TRAINING'),
                      _buildTrainingCard(theme),
                      const SectionHeader('MOVEMENT'),
                      _buildMovementCard(theme),
                      const SectionHeader('NUTRITION'),
                      _buildNutritionCard(theme),
                      const SectionHeader('BODY'),
                      _buildBodyCard(theme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeBanner() {
    final sessions = _weekWorkouts.length;
    return ChallengeBanner(
      subtitle: sessions == 0
          ? 'No sessions yet — start the streak'
          : '$sessions of 6 sessions done this week',
      progress: (sessions / 6).clamp(0.0, 1.0),
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Challenge locked in — 14 days of energy 🔥'),
          ),
        );
      },
    );
  }

  Widget _buildStatTiles(ThemeData theme) {
    final isDay = _view == 0;

    final daySteps = _dayWalks.fold(0, (a, w) => a + w.steps);
    final weekSteps = _weekWalks.fold(0, (a, w) => a + w.steps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDay
              ? DateFormat('EEEE, MMM d')
                  .format(DateTime.now())
                  .toUpperCase()
              : '${DateFormat('MMM d').format(_weekStart).toUpperCase()}'
                  ' — ${DateFormat('MMM d').format(_weekStart.add(const Duration(days: 6))).toUpperCase()}',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.fitness_center_rounded,
                value:
                    '${isDay ? _dayWorkouts.length : _weekWorkouts.length}',
                label: isDay ? 'WORKOUTS' : 'SESSIONS',
                color: AppTheme.lime,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: StatTile(
                icon: Icons.directions_walk_rounded,
                value: _fmtInt
                    .format(isDay ? daySteps : weekSteps),
                label: 'STEPS',
                color: AppTheme.coral,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: StatTile(
                icon: Icons.local_fire_department_rounded,
                value: _fmtInt.format(isDay
                    ? _todayKcal.round()
                    : _avgKcal.round()),
                label: isDay ? 'KCAL' : 'KCAL AVG',
                color: AppTheme.sky,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _actionCell(theme, 'WORKOUT',
                Icons.fitness_center_rounded, 0),
            _vd(),
            _actionCell(
                theme, 'WALK', Icons.directions_walk_rounded, 4),
            _vd(),
            _actionCell(theme, 'WEIGH-IN',
                Icons.monitor_weight_rounded, 3),
          ],
        ),
      ),
    );
  }

  Widget _actionCell(
      ThemeData theme, String label, IconData icon, int tabIndex) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HitHaptics.selectionClick();
          widget.onOpenTab?.call(tabIndex);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.lime.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppTheme.lime),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingCard(ThemeData theme) {
    final workouts = _view == 0 ? _dayWorkouts : _weekWorkouts;

    if (workouts.isEmpty) {
      return GlassCard(
        child: _emptyRow(
          theme,
          icon: Icons.fitness_center_rounded,
          text: _view == 0
              ? 'No workout today. The Train tab is ready when you are.'
              : 'No workouts this week yet — one session flips this card.',
        ),
      );
    }

    int sets = 0, minutes = 0;
    double? heaviest;
    for (final w in workouts) {
      sets += w.sets.length;
      minutes += w.duration.inMinutes;
      for (final s in w.sets) {
        final wt = s.setLog.weightKg;
        if (wt != null &&
            wt > 0 &&
            (heaviest == null || wt > heaviest)) {
          heaviest = wt;
        }
      }
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _cell('${workouts.length}', 'SESSIONS', lime: true),
            _vd(),
            _cell('$sets', 'SETS'),
            _vd(),
            _cell(
                heaviest != null ? _trim(heaviest) : '—',
                'TOP KG'),
            _vd(),
            _cell(_fmtMins(minutes), 'TIME'),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementCard(ThemeData theme) {
    final walks = _view == 0 ? _dayWalks : _weekWalks;

    if (walks.isEmpty) {
      return GlassCard(
        child: _emptyRow(
          theme,
          icon: Icons.directions_walk_rounded,
          text: _view == 0
              ? 'No tracked walks today. Steps tab → Start a Walk.'
              : 'No tracked walks this week yet.',
        ),
      );
    }

    final steps = walks.fold(0, (a, w) => a + w.steps);
    final meters =
        walks.fold(0.0, (a, w) => a + w.distanceMeters);
    final minutes =
        walks.fold(0, (a, w) => a + (w.durationSeconds ~/ 60));

    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _cell(_fmtInt.format(steps), 'STEPS', lime: true),
            _vd(),
            _cell('${walks.length}', 'WALKS'),
            _vd(),
            _cell(_fmtDistance(meters), 'DIST'),
            _vd(),
            _cell(_fmtMins(minutes), 'TIME'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(ThemeData theme) {
    if (_view == 0) {
      if (_todayFood.isEmpty) {
        return GlassCard(
          child: _emptyRow(
            theme,
            icon: Icons.restaurant_menu_rounded,
            text:
                'Nothing logged today. Body tab → Diet → Add Food.',
          ),
        );
      }

      final kcal = _todayKcal;
      final progress =
          (kcal / _goals.calories).clamp(0.0, 1.0);

      return GlassCard(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtInt.format(kcal.round()),
                  style:
                      theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.lime,
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '/ ${_fmtInt.format(_goals.calories)} kcal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_todayFood.length} ENTRIES',
                  style:
                      theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            GradientBar(progress: progress, height: 8),
            const SizedBox(height: AppTheme.spaceMD),
            _compactMacro(theme, 'Protein', _todayProtein,
                _goals.protein, _proteinColor),
            const SizedBox(height: 10),
            _compactMacro(theme, 'Carbs', _todayCarbs,
                _goals.carbs, _carbColor),
            const SizedBox(height: 10),
            _compactMacro(theme, 'Fat', _todayFat,
                _goals.fat, _fatColor),
          ],
        ),
      );
    }

    if (_weekFood.isEmpty) {
      return GlassCard(
        child: _emptyRow(
          theme,
          icon: Icons.restaurant_menu_rounded,
          text: 'No food logged this week yet. Body tab → Diet.',
        ),
      );
    }

    final kcalPerDay = _weekKcalPerDay;
    final todayIdx = _todayStart.weekday - 1;
    final maxVal = kcalPerDay.reduce((a, b) => a > b ? a : b);
    double maxY =
        (maxVal > _goals.calories ? maxVal : _goals.calories) *
            1.15;
    if (maxY <= 0) maxY = 1000;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtInt.format(_avgKcal.round()),
                style:
                    theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.lime,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'AVG KCAL / DAY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$_daysLogged/7 LOGGED',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1,
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),

          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 5,
                      height: 1.5,
                      margin: const EdgeInsets.only(
                          right: 2),
                      color: theme.colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                'GOAL ${_fmtInt.format(_goals.calories)} KCAL',
                style:
                    theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1,
                  color: theme
                      .colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),

          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _goals.calories.toDouble(),
                      color: theme
                          .colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                      strokeWidth: 1,
                      dashArray: const [5, 5],
                    ),
                  ],
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex,
                            rod, rodIndex) =>
                        BarTooltipItem(
                      '${rod.toY.round()} kcal',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        const labels = [
                          'M', 'T', 'W', 'T', 'F', 'S', 'S'
                        ];
                        final i = value.toInt();
                        if (i < 0 || i > 6) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding:
                              const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: theme
                                .textTheme.labelSmall
                                ?.copyWith(
                              fontSize: 10,
                              color: i == todayIdx
                                  ? AppTheme.lime
                                  : theme.colorScheme
                                      .onSurfaceVariant,
                              fontWeight: i == todayIdx
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < 7; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: kcalPerDay[i],
                          width: 16,
                          borderRadius:
                              const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                          color: i == todayIdx
                              ? AppTheme.lime
                              : theme.colorScheme
                                  .surfaceContainerHighest,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCard(ThemeData theme) {
    if (_weights.isEmpty) {
      return GlassCard(
        child: _emptyRow(
          theme,
          icon: Icons.scale_rounded,
          text:
              'No weigh-ins yet. Body tab → Weight → type & Log.',
        ),
      );
    }

    if (_view == 0) {
      final latest = _weights.first;
      final prev =
          _weights.length >= 2 ? _weights[1] : null;
      final delta = prev != null
          ? latest.weightKg - prev.weightKg
          : null;
      final isToday = !latest.date.isBefore(_todayStart);

      return GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_trim(latest.weightKg)} kg',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [
                        FontFeature.tabularFigures()
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isToday ? 'Today' : DateFormat('EEE, MMM d').format(latest.date).toUpperCase()}'
                    ' • ${_weights.length} ENTRIES',
                    style:
                        theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1,
                      color: theme.colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (delta != null) _deltaPill(theme, delta),
          ],
        ),
      );
    }

    final week = _weights
        .where((w) => !w.date.isBefore(_weekStart))
        .toList();

    if (week.isEmpty) {
      return GlassCard(
        child: _emptyRow(
          theme,
          icon: Icons.scale_rounded,
          text: 'No weigh-ins this week — one entry starts the story.',
        ),
      );
    }

    final latest = week.first;
    final earliest = week.last;
    final delta = week.length >= 2
        ? latest.weightKg - earliest.weightKg
        : null;

    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${_trim(latest.weightKg)} kg',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${week.length} ${week.length == 1 ? 'ENTRY' : 'ENTRIES'} THIS WEEK'
                  ' • LATEST ${DateFormat('EEE').format(latest.date).toUpperCase()}',
                  style:
                      theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color: theme.colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (delta != null) _deltaPill(theme, delta),
        ],
      ),
    );
  }

  Widget _emptyRow(ThemeData theme,
      {required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.lime.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: AppTheme.lime),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _deltaPill(ThemeData theme, double delta) {
    final isUp = delta >= 0;
    final color = isUp ? AppTheme.coral : AppTheme.mint;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactMacro(ThemeData theme, String label,
      double value, int goal, Color color) {
    final progress =
        goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${_trim(value)} / $goal g',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [
                  FontFeature.tabularFigures()
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        GradientBar(
          progress: progress,
          height: 5,
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.55), color],
          ),
        ),
      ],
    );
  }

  Widget _vd() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 14),
        color: AppTheme.hairlineDark,
      );

  Widget _cell(String value, String label, {bool lime = false}) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: lime ? AppTheme.lime : AppTheme.text,
                fontFeatures: const [
                  FontFeature.tabularFigures()
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _trim(double v) => v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1);

  String _fmtMins(int m) =>
      m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '${m}m';

  String _fmtDistance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)}km'
      : '${meters.round()}m';
}
