import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../data/exercise_catalog.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../widgets/exercise_library.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  static const _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  late int _selectedDay; // 1 = Mon … 7 = Sun
  List<ScheduledExerciseRow> _items = [];
  StreamSubscription<List<ScheduledExerciseRow>>? _sub;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday;
    _listen();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listen() {
    _sub?.cancel();
    _sub = DatabaseProvider.instance
        .watchScheduledForDay(_selectedDay)
        .listen((rows) {
      if (mounted) setState(() => _items = rows);
    });
  }

  void _selectDay(int day) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDay = day);
    _listen();
  }

  Future<void> _showExercisePicker() async {
    HapticFeedback.mediumImpact();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        // Mark exercises already on this day — tapping one of
        // those REMOVES it (toggle), tapping a new one ADDS it.
        final existing = {
          for (final i in _items) i.exerciseName: 1,
        };

        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.85,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                  color: AppTheme.hairline(theme.brightness)),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMD,
                    AppTheme.spaceMD,
                    AppTheme.spaceSM,
                    AppTheme.spaceSM),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Plan ${_dayNames[_selectedDay - 1]}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
                            Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                      bottom: AppTheme.spaceMD),
                  children: [
                    ExerciseLibrary(
                      doneCounts: existing,
                      onSelect: (exercise) async {
                        HapticFeedback.lightImpact();
                        if (existing.containsKey(
                            exercise.name)) {
                          await DatabaseProvider.instance
                              .deleteScheduledByName(
                                  _selectedDay,
                                  exercise.name);
                        } else {
                          await DatabaseProvider.instance
                              .insertScheduledExercise(
                            dayOfWeek: _selectedDay,
                            exerciseName: exercise.name,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceLG),
        children: [
          // ─── Day selector ──────────────────────────
          Row(
            children: [
              for (var d = 1; d <= 7; d++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDay(d),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      child: Column(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: d == _selectedDay
                                  ? AppTheme.accent
                                  : theme.colorScheme
                                      .surfaceContainerHighest,
                              border: d == today
                                  ? Border.all(
                                      color: AppTheme.accent,
                                      width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                _dayLetters[d - 1],
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: d == _selectedDay
                                      ? Colors.white
                                      : theme.colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ─── Day header ────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
                top: AppTheme.spaceLG, bottom: AppTheme.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayNames[_selectedDay - 1].toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  _items.isEmpty
                      ? _selectedDay == today
                          ? 'Nothing planned for today.'
                          : 'Rest day — or tap below to plan it.'
                      : '${_items.length} exercises planned',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ─── Planned exercises ─────────────────────
          ..._buildPlanList(theme),

          const SizedBox(height: AppTheme.spaceMD),
          FilledButton.icon(
            onPressed: _showExercisePicker,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(_items.isEmpty
                ? 'ADD EXERCISES'
                : 'ADD / REMOVE'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),

          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tap a listed exercise in the picker again to remove it.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant
                    .withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  List<Widget> _buildPlanList(ThemeData theme) {
    if (_items.isEmpty) {
      return [
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                      AppTheme.radiusMD),
                ),
                child: Icon(Icons.event_available_outlined,
                    size: 19,
                    color:
                        theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Text(
                  'Plan your split once — every ${_dayNames[_selectedDay - 1]}, '
                  'your list is waiting on the workout screen.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      for (var i = 0; i < _items.length; i++)
        _buildPlanRow(theme, _items[i], i + 1),
    ];
  }

  Widget _buildPlanRow(
      ThemeData theme, ScheduledExerciseRow item, int index) {
    final exercise =
        ExerciseCatalog.exerciseByName(item.exerciseName);
    final color =
        ExerciseCatalog.colorFor(exercise.muscleGroup);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Dismissible(
        key: ValueKey('plan-${item.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          HapticFeedback.lightImpact();
          DatabaseProvider.instance
              .deleteScheduledExercise(item.id);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding:
              const EdgeInsets.only(right: AppTheme.spaceLG),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius:
                BorderRadius.circular(AppTheme.radiusLG),
          ),
          child: Icon(Icons.delete_outline,
              color: theme.colorScheme.onErrorContainer),
        ),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMD,
            vertical: AppTheme.spaceMD,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '$index',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color:
                        theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(
                      AppTheme.radiusSM),
                ),
                child: Icon(exercise.icon,
                    color: color, size: 19),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      exercise.muscleGroup,
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant
                    .withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}