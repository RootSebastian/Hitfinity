import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/models.dart';
import '../models/workout_draft.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_library.dart';
import '../data/exercise_catalog.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutSessionWithSets? editingSession;

  const ActiveWorkoutScreen({super.key, this.editingSession});

  @override
  State<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  bool get _isEditing => widget.editingSession != null;

  // FIXED: was `late final` — final means "assign once," but the
  // draft restore assigns this a SECOND time after initState
  // already set it. That reassignment threw LateInitializationError,
  // which silently killed the restore. Plain `late` allows it.
  late DateTime _startTime;

  final List<SetLog> _sets = [];
  final Set<String> _expandedExercises = {};
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  // ─── Today's plan (live mode only) ─────────────────
  List<ScheduledExerciseRow> _todayPlan = [];
  StreamSubscription<List<ScheduledExerciseRow>>? _planSub;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final s = widget.editingSession!;
      _startTime = s.startTime;
      _elapsed = s.duration;
      for (final item in s.sets) {
        _sets.add(SetLog(
          exercise: ExerciseCatalog.exerciseByName(item.exercise.name),
          setNumber: item.setLog.setNumber,
          reps: item.setLog.reps,
          weightKg: item.setLog.weightKg,
        ));
      }
    } else {
      _startTime = DateTime.now();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _elapsed = DateTime.now().difference(_startTime);
          });
        }
      });

      _planSub = DatabaseProvider.instance
          .watchScheduledForDay(DateTime.now().weekday)
          .listen((rows) {
        if (mounted) setState(() => _todayPlan = rows);
      });

      _loadDraft();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _planSub?.cancel();
    super.dispose();
  }

  /// Restores a draft workout (app was closed mid-session).
  /// Sets + the original start time come back; the wall-clock
  /// timer picks up right where it left off.
  Future<void> _loadDraft() async {
    final draft = await DatabaseProvider.instance.getWorkoutDraft();
    if (!mounted || draft == null || draft.sets.isEmpty) return;
    setState(() {
      _startTime = draft.startTime;
      _elapsed = DateTime.now().difference(draft.startTime);
      _sets
        ..clear()
        ..addAll(draft.sets.map((d) => SetLog(
              exercise: ExerciseCatalog.exerciseByName(d.exerciseName),
              setNumber: d.setNumber,
              reps: d.reps,
              weightKg: d.weightKg,
            )));
    });
  }

  Future<void> _persistDraft() async {
    if (_isEditing) return;
    final db = DatabaseProvider.instance;
    if (_sets.isEmpty) {
      await db.clearWorkoutDraft();
      return;
    }
    await db.saveWorkoutDraft(WorkoutDraft(
      startTime: _startTime,
      sets: _sets
          .map((s) => DraftSet(
                exerciseName: s.exercise.name,
                setNumber: s.setNumber,
                reps: s.reps,
                weightKg: s.weightKg,
              ))
          .toList(),
    ));
  }

  String get _formattedElapsed {
    final m =
        _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s =
        _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (_elapsed.inHours > 0) {
      final h = _elapsed.inHours.toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  double? get _maxWeight {
    double? max;
    for (final s in _sets) {
      final w = s.weightKg;
      if (w != null && w > 0 && (max == null || w > max)) {
        max = w;
      }
    }
    return max;
  }

  Map<String, int> get _doneCounts {
    final counts = <String, int>{};
    for (final s in _sets) {
      counts[s.exercise.name] = (counts[s.exercise.name] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, List<SetLog>> get _setsByExercise {
    final map = <String, List<SetLog>>{};
    for (final s in _sets) {
      map.putIfAbsent(s.exercise.name, () => []).add(s);
    }
    return map;
  }

  int get _planRemaining {
    var n = 0;
    for (final p in _todayPlan) {
      if (!(_doneCounts[p.exerciseName] != null &&
          _doneCounts[p.exerciseName]! > 0)) {
        n++;
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Session' : 'Active Workout'),
        automaticallyImplyLeading: _isEditing,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Discard session',
              onPressed: _confirmDiscard,
            ),
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spaceSM),
            child: FilledButton.tonal(
              onPressed: _sets.isEmpty ? null : _confirmFinish,
              child: Text(_isEditing ? 'Save' : 'Finish'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spaceLG,
              horizontal: AppTheme.spaceMD,
            ),
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
            ),
            child: Column(
              children: [
                Text(
                  _formattedElapsed,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'EDITING • '
                    '${DateFormat('EEE, MMM d • HH:mm').format(_startTime)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spaceMD),
                Row(
                  children: [
                    _heroStat('${_sets.length}', 'SETS', Icons.repeat),
                    _heroStat('${_setsByExercise.length}',
                        'EXERCISES', Icons.list),
                    _heroStat(
                        '${_sets.fold(0, (a, b) => a + b.reps)}',
                        'REPS',
                        Icons.tag),
                    _heroStat(
                      _maxWeight != null
                          ? _fmtWeight(_maxWeight!)
                          : '—',
                      'HEAVIEST KG',
                      Icons.monitor_weight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceXL),
              children: [
                // ── TODAY'S PLAN (quick-log chips) ──
                if (!_isEditing && _todayPlan.isNotEmpty) ...[
                  _sectionTitle(
                    'TODAY\'S PLAN',
                    _planRemaining > 0
                        ? '$_planRemaining left • tap to log'
                        : 'all done ✓',
                  ),
                  _buildPlanChips(theme),
                  const SizedBox(height: AppTheme.spaceMD),
                ],

                if (_sets.isNotEmpty) ...[
                  _sectionTitle(
                    _isEditing
                        ? 'SESSION EXERCISES'
                        : 'TODAY\'S EXERCISES',
                    _isEditing
                        ? 'tap a set to edit it'
                        : '${_setsByExercise.length} done',
                  ),
                  ..._buildTodayCards(),
                  const SizedBox(height: AppTheme.spaceMD),
                ] else
                  _buildFirstSetHint(),
                _sectionTitle('EXERCISE LIBRARY', 'tap to log a set'),
                const SizedBox(height: AppTheme.spaceSM),
                ExerciseLibrary(
                  doneCounts: _doneCounts,
                  onSelect: (ex) => _showLogSetDialog(ex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanChips(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in _todayPlan)
            _planChip(theme, item),
        ],
      ),
    );
  }

  Widget _planChip(ThemeData theme, ScheduledExerciseRow item) {
    final exercise =
        ExerciseCatalog.exerciseByName(item.exerciseName);
    final done = _doneCounts[exercise.name] ?? 0;
    final color =
        ExerciseCatalog.colorFor(exercise.muscleGroup);
    final isDone = done > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      onTap: () {
        HapticFeedback.lightImpact();
        _showLogSetDialog(exercise);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isDone
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isDone
                ? AppTheme.accent
                : AppTheme.hairline(theme.brightness),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(exercise.icon,
                size: 15, color: isDone ? AppTheme.accent : color),
            const SizedBox(width: 7),
            Text(
              exercise.name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDone
                    ? AppTheme.accent
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (isDone) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_rounded,
                  size: 13, color: AppTheme.accent),
              const SizedBox(width: 2),
              Text(
                '$done',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.8)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLG, vertical: AppTheme.spaceSM),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(
              '• $subtitle',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstSetHint() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMD),
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app, color: AppTheme.accent, size: 32),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Text(
              _isEditing
                  ? 'All sets were removed. Pick exercises below to rebuild this session.'
                  : 'Timer is running! Tap your plan above, or any exercise below, to log your first set.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTodayCards() {
    final byExercise = _setsByExercise;
    final theme = Theme.of(context);

    final order = <String>[];
    for (final s in _sets) {
      if (!order.contains(s.exercise.name)) {
        order.add(s.exercise.name);
      }
    }

    return order.map((name) {
      final sets = byExercise[name]!;
      final exercise = sets.first.exercise;
      final color = ExerciseCatalog.colorFor(exercise.muscleGroup);
      final isExpanded = _expandedExercises.contains(name);

      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD,
          vertical: AppTheme.spaceXS,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color:
                theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusMD),
              onTap: () => setState(() {
                isExpanded
                    ? _expandedExercises.remove(name)
                    : _expandedExercises.add(name);
              }),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusSM),
                      ),
                      child: Icon(exercise.icon,
                          color: color, size: 20),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style:
                                theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _exerciseWeightsLabel(sets),
                            style:
                                theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle,
                          color: AppTheme.accent),
                      onPressed: () =>
                          _showLogSetDialog(exercise),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color:
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              ...sets.map((set) {
                final globalIndex = _sets.indexOf(set);
                return Container(
                  margin: const EdgeInsets.only(
                    left: AppTheme.spaceMD,
                    right: AppTheme.spaceMD,
                    bottom: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme
                        .colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusSM),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusSM),
                    onTap: () => _showLogSetDialog(
                      set.exercise,
                      editingSet: set,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceSM,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${set.setNumber}',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              set.weightKg != null &&
                                      set.weightKg! > 0
                                  ? '${set.reps} reps × ${_fmtWeight(set.weightKg!)} kg'
                                  : '${set.reps} reps',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                size: 16,
                                color: theme.colorScheme
                                    .onSurfaceVariant),
                            onPressed: () =>
                                _removeSet(globalIndex),
                            visualDensity:
                                VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            if (isExpanded)
              const SizedBox(height: AppTheme.spaceSM),
          ],
        ),
      );
    }).toList();
  }

  String _exerciseWeightsLabel(List<SetLog> sets) {
    final weights = sets
        .map((s) => s.weightKg)
        .whereType<double>()
        .where((w) => w > 0)
        .toList();
    final prefix = '${sets.length} sets • ';
    if (weights.isEmpty) return '${prefix}bodyweight';
    return '$prefix${weights.map(_fmtWeight).join(', ')} kg';
  }

  String _fmtWeight(double w) => w == w.roundToDouble()
      ? w.round().toString()
      : w.toStringAsFixed(1);

  void _removeSet(int index) {
    setState(() => _sets.removeAt(index));
    _renumberSets();
    _persistDraft();
  }

  void _renumberSets() {
    final counters = <String, int>{};
    final updated = <SetLog>[];
    for (final set in _sets) {
      counters[set.exercise.name] =
          (counters[set.exercise.name] ?? 0) + 1;
      updated.add(SetLog(
        exercise: set.exercise,
        setNumber: counters[set.exercise.name]!,
        reps: set.reps,
        weightKg: set.weightKg,
      ));
    }
    _sets
      ..clear()
      ..addAll(updated);
  }

  Future<void> _showLogSetDialog(
    Exercise exercise, {
    SetLog? editingSet,
  }) async {
    final repsCtrl = TextEditingController();
    final weightCtrl = TextEditingController();

    if (editingSet != null) {
      repsCtrl.text = editingSet.reps.toString();
      if (editingSet.weightKg != null) {
        weightCtrl.text = _fmtWeight(editingSet.weightKg!);
      }
    } else {
      final lastSets = _sets
          .where((s) => s.exercise.name == exercise.name)
          .toList();
      if (lastSets.isNotEmpty) {
        repsCtrl.text = lastSets.last.reps.toString();
        if (lastSets.last.weightKg != null) {
          weightCtrl.text =
              _fmtWeight(lastSets.last.weightKg!);
        }
      }
    }

    final setLog = await showDialog<SetLog>(
      context: context,
      builder: (dialogContext) {
        final color =
            ExerciseCatalog.colorFor(exercise.muscleGroup);
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSM),
                ),
                child:
                    Icon(exercise.icon, color: color, size: 18),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Text(
                  editingSet != null
                      ? 'Set ${editingSet.setNumber} • ${exercise.name}'
                      : exercise.name,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  hintText: '10',
                  prefixIcon: Icon(Icons.repeat),
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppTheme.spaceMD),
              if (exercise.allowsWeightEntry)
                TextField(
                  controller: weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: exercise.weightLabel,
                    hintText: '60',
                    prefixIcon:
                        const Icon(Icons.monitor_weight_outlined),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reps = int.tryParse(repsCtrl.text);
                final weight =
                    double.tryParse(weightCtrl.text);

                if (reps == null || reps <= 0) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please enter valid reps'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final setNumber = editingSet != null
                    ? editingSet.setNumber
                    : _sets
                            .where((s) => s.exercise.name ==
                                exercise.name)
                            .length +
                        1;

                Navigator.pop(
                  dialogContext,
                  SetLog(
                    exercise: exercise,
                    setNumber: setNumber,
                    reps: reps,
                    weightKg: exercise.allowsWeightEntry
                        ? (weight ?? 0)
                        : null,
                  ),
                );
              },
              child: Text(editingSet != null
                  ? 'Update Set'
                  : 'Log Set'),
            ),
          ],
        );
      },
    );

    if (setLog != null && mounted) {
      setState(() {
        if (editingSet != null) {
          final idx = _sets.indexOf(editingSet);
          if (idx >= 0) _sets[idx] = setLog;
        } else {
          _sets.add(setLog);
        }
      });
      _persistDraft();
    }
  }

  void _confirmDiscard() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard session?'),
        content: Text(
          _sets.isEmpty
              ? 'Exit the workout screen? Nothing was logged.'
              : 'This session and its ${_sets.length} sets will be deleted.\nThe timer stops.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseProvider.instance
                  .clearWorkoutDraft();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmFinish() async {
    final setCount = _sets.length;
    final exerciseCount = _setsByExercise.length;
    final totalReps = _sets.fold(0, (a, b) => a + b.reps);
    final heaviestText = _maxWeight != null
        ? ' • heaviest ${_fmtWeight(_maxWeight!)} kg'
        : '';

    final db = DatabaseProvider.instance;
    final newSets = <NewSetLog>[];
    for (final set in _sets) {
      final exerciseId =
          await db.exerciseIdByName(set.exercise.name);
      newSets.add(NewSetLog(
        exerciseId: exerciseId,
        setNumber: set.setNumber,
        reps: set.reps,
        weightKg: set.weightKg,
      ));
    }

    if (!mounted) return;

    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            _isEditing ? 'Save Changes?' : 'Finish Workout?'),
        content: Text(
          '$setCount sets • $exerciseCount exercises\n'
          '$totalReps reps$heaviestText\n'
          '${_isEditing ? 'Original duration kept: $_formattedElapsed' : 'Duration: $_formattedElapsed'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                _isEditing ? 'Keep Editing' : 'Keep Logging'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!_isEditing) {
                await DatabaseProvider.instance
                    .clearWorkoutDraft();
              }
              if (mounted) {
                Navigator.pop(
                  context,
                  WorkoutResult(
                    startTime: _startTime,
                    duration: _elapsed,
                    sets: newSets,
                    sessionId: widget.editingSession?.id,
                  ),
                );
              }
            },
            child: Text(_isEditing
                ? 'Save Changes'
                : 'Save & Finish'),
          ),
        ],
      ),
    );
  }
}

class WorkoutResult {
  final DateTime startTime;
  final Duration duration;
  final List<NewSetLog> sets;
  final int? sessionId;

  WorkoutResult({
    required this.startTime,
    required this.duration,
    required this.sets,
    this.sessionId,
  });
}