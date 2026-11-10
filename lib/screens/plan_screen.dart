import 'dart:async';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../data/exercise_catalog.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../widgets/hit_widgets.dart';
import '../widgets/exercise_library.dart';
import '../services/hit_settings.dart';

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

  late int _selectedDay;
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
    HitHaptics.selectionClick();
    setState(() => _selectedDay = day);
    _listen();
  }

  Future<void> _showExercisePicker() async {
    HitHaptics.mediumImpact();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final existing = {
          for (final i in _items) i.exerciseName: 1,
        };

        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.85,
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radius2XL)),
            border: Border(
              top: BorderSide(color: AppTheme.hairlineDark),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.track,
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.text,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: AppTheme.textMuted),
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
                        HitHaptics.lightImpact();
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
    final today = DateTime.now().weekday;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLG),
          children: [
            const SizedBox(height: AppTheme.spaceMD),
            const ScreenTitle('Plan',
                subtitle: 'YOUR WEEKLY SPLIT'),

            const SizedBox(height: AppTheme.spaceMD),
            Row(
              children: [
                for (var d = 1; d <= 7; d++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _selectDay(d),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 2),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(
                                  milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: d == _selectedDay
                                    ? AppTheme.lime
                                    : AppTheme.surfaceAlt,
                                border: d == today
                                    ? Border.all(
                                        color:
                                            AppTheme.limeSoft,
                                        width: 1.5)
                                    : Border.all(
                                        color: AppTheme
                                            .hairlineDark,
                                        width: 1),
                                boxShadow: d == _selectedDay
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.lime
                                              .withValues(
                                                  alpha: 0.25),
                                          blurRadius: 10,
                                          offset:
                                              const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  _dayLetters[d - 1],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w800,
                                    color: d == _selectedDay
                                        ? AppTheme.ink
                                        : (d == today
                                            ? AppTheme.lime
                                            : AppTheme
                                                .textMuted),
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

            Padding(
              padding: const EdgeInsets.only(
                  top: AppTheme.spaceLG,
                  bottom: AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dayNames[_selectedDay - 1].toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppTheme.text,
                    ),
                  ),
                  Text(
                    _items.isEmpty
                        ? _selectedDay == today
                            ? 'Nothing planned for today.'
                            : 'Rest day — or tap below to plan it.'
                        : '${_items.length} exercises planned',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            ..._buildPlanList(),

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
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlanList() {
    if (_items.isEmpty) {
      return [
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                      BorderSide(color: AppTheme.hairlineDark)),
                ),
                child: Icon(
                    Icons.event_available_outlined,
                    size: 19,
                    color: AppTheme.textMuted),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Text(
                  'Plan your split once — every ${_dayNames[_selectedDay - 1]}, '
                  'your list is waiting on the workout screen.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
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
        _buildPlanRow(_items[i], i + 1),
    ];
  }

  Widget _buildPlanRow(ScheduledExerciseRow item, int index) {
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
          HitHaptics.lightImpact();
          DatabaseProvider.instance
              .deleteScheduledExercise(item.id);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding:
              const EdgeInsets.only(right: AppTheme.spaceLG),
          decoration: BoxDecoration(
            color: AppTheme.coral,
            borderRadius:
                BorderRadius.circular(AppTheme.radiusXL),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: Colors.white),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    fontFeatures: [
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
                  color: color.withValues(alpha: 0.15),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text,
                      ),
                    ),
                    Text(
                      exercise.muscleGroup,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
               Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
