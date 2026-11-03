import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../data/exercise_catalog.dart';
import '../models/workout_draft.dart';
import '../theme/app_theme.dart';
import '../theme/aurora_background.dart';
import '../theme/glass_card.dart';
import 'active_workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<WorkoutSessionWithSets>> _workoutsStream =
      DatabaseProvider.instance.watchAllWorkouts();

  // ─── Live session draft (survives app kill) ────────
  WorkoutDraft? _draft;
  StreamSubscription<WorkoutDraft?>? _draftSub;
  Timer? _draftTick;

  @override
  void initState() {
    super.initState();
    _draftSub =
        DatabaseProvider.instance.watchWorkoutDraft().listen((d) {
      if (mounted) {
        setState(() => _draft = d);
        _syncTicker();
      }
    });
  }

  @override
  void dispose() {
    _draftSub?.cancel();
    _draftTick?.cancel();
    super.dispose();
  }

  /// Keeps the banner's elapsed time fresh while a session
  /// is live.
  void _syncTicker() {
    if (_draft != null && _draftTick == null) {
      _draftTick = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) setState(() {});
      });
    } else if (_draft == null && _draftTick != null) {
      _draftTick?.cancel();
      _draftTick = null;
    }
  }

  String _fmtElapsed(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
    }
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: StreamBuilder<List<WorkoutSessionWithSets>>(
        stream: _workoutsStream,
        builder: (context, snapshot) {
          final workouts = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AuroraBackground(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spaceLG,
                      MediaQuery.paddingOf(context).top +
                          AppTheme.spaceXL,
                      AppTheme.spaceLG,
                      AppTheme.spaceLG,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMMM d')
                              .format(DateTime.now())
                              .toUpperCase(),
                          style:
                              theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 2.5,
                            color: theme
                                .colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceMD),
                                                Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: _draft != null
                                      ? 'Back to\n'
                                      : 'Ready to\n'),
                              TextSpan(
                                  text: _draft != null
                                      ? 'training'
                                      : 'train'),
                              TextSpan(
                                text: '.',
                                style: const TextStyle(
                                    color: AppTheme.accent),
                              ),
                            ],
                          ),
                          style: theme.textTheme.displayMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.8,
                            height: 1.02,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXL),
                        _WeekStrip(workouts: workouts),
                        const SizedBox(height: AppTheme.spaceLG),
                        _WeekStats(workouts: workouts),
                      ],
                    ),
                  ),
                ),
              ),

              // ═══ Primary action: Resume OR Start ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceLG),
                  child: _draft != null
                      ? _ResumeCard(
                          draft: _draft!,
                          onResume: _resumeWorkout,
                          onDiscard: _discardWorkout,
                          fmtElapsed: _fmtElapsed,
                        )
                      : _StartButton(onTap: _startNewWorkout),
                ),
              ),

              if (workouts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spaceXL),
                    child: _EmptyState(),
                  ),
                )
              else ...[
                const SliverToBoxAdapter(
                  child: _SectionLabel('RECENT'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceLG,
                    0,
                    AppTheme.spaceLG,
                    140,
                  ),
                  sliver: SliverList.builder(
                    itemCount:
                        workouts.length > 10 ? 10 : workouts.length,
                    itemBuilder: (_, i) => _SessionCard(
                      session: workouts[i],
                      onEdit: () => _editWorkout(workouts[i]),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _startNewWorkout() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<WorkoutResult>(
      context,
      MaterialPageRoute(
          builder: (_) => const ActiveWorkoutScreen()),
    );
    await _saveResult(result);
  }

  Future<void> _resumeWorkout() async {
    HapticFeedback.mediumImpact();
    // No editingSession — the screen auto-loads the draft.
    final result = await Navigator.push<WorkoutResult>(
      context,
      MaterialPageRoute(
          builder: (_) => const ActiveWorkoutScreen()),
    );
    await _saveResult(result);
  }

  Future<void> _saveResult(WorkoutResult? result) async {
    if (result == null || !mounted) return;
    await DatabaseProvider.instance.insertWorkoutWithSets(
      startTime: result.startTime,
      duration: result.duration,
      sets: result.sets,
    );
    if (mounted) HapticFeedback.heavyImpact();
  }

  Future<void> _discardWorkout() async {
    HapticFeedback.lightImpact();
    await DatabaseProvider.instance.clearWorkoutDraft();
  }

  Future<void> _editWorkout(WorkoutSessionWithSets session) async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push<WorkoutResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ActiveWorkoutScreen(editingSession: session),
      ),
    );
    if (result == null || !mounted) return;
    await DatabaseProvider.instance.updateWorkoutSets(
      sessionId: session.id,
      sets: result.sets,
    );
    if (mounted) HapticFeedback.mediumImpact();
  }
}

// ═══════════════ Sub-widgets ═══════════════

class _WeekStrip extends StatelessWidget {
  final List<WorkoutSessionWithSets> workouts;
  const _WeekStrip({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today
        .subtract(Duration(days: today.weekday - 1));

    final trainedDays = <int>{};
    for (final w in workouts) {
      final i = w.startTime.difference(weekStart).inDays;
      if (i >= 0 && i < 7) trainedDays.add(i);
    }

    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: trainedDays.contains(i)
                        ? AppTheme.accent
                        : theme.colorScheme
                            .surfaceContainerHighest,
                    border: i == today.weekday - 1
                        ? Border.all(color: AppTheme.accent, width: 1.5)
                        : null,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  letters[i],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    letterSpacing: 0.5,
                    color: i == today.weekday - 1
                        ? AppTheme.accent
                        : theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.6),
                    fontWeight: i == today.weekday - 1
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WeekStats extends StatelessWidget {
  final List<WorkoutSessionWithSets> workouts;
  const _WeekStats({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart =
        today.subtract(Duration(days: today.weekday - 1));

    final week = workouts
        .where((w) => !w.startTime.isBefore(weekStart))
        .toList();

    int sets = 0;
    double? heaviest;
    for (final w in week) {
      sets += w.sets.length;
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
            _cell(context, '${week.length}', 'SESSIONS'),
            _divider(context),
            _cell(context, '$sets', 'SETS'),
            _divider(context),
            _cell(
              context,
              heaviest != null
                  ? (heaviest == heaviest!.roundToDouble()
                      ? heaviest!.round().toString()
                      : heaviest!.toStringAsFixed(1))
                  : '—',
              'TOP KG',
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(
      width: 1,
      color: AppTheme.hairline(Theme.of(context).brightness));

  Widget _cell(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Replaces the Start button while a live session exists.
class _ResumeCard extends StatelessWidget {
  final WorkoutDraft draft;
  final VoidCallback onResume;
  final VoidCallback onDiscard;
  final String Function(Duration) fmtElapsed;

  const _ResumeCard({
    required this.draft,
    required this.onResume,
    required this.onDiscard,
    required this.fmtElapsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elapsed =
        DateTime.now().difference(draft.startTime);

    return GlassCard(
      onTap: onResume,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SESSION IN PROGRESS',
                      style:
                          theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fmtElapsed(elapsed),
                      style:
                          theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        fontFeatures: const [
                          FontFeature.tabularFigures()
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${draft.sets.length} sets logged — tap to resume',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant),
              onPressed: onDiscard,
              tooltip: 'Discard session',
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.accent,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceLG),
            child: Row(
              children: [
                Text(
                  'START SESSION',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceLG,
        AppTheme.spaceXL,
        AppTheme.spaceLG,
        AppTheme.spaceMD,
      ),
      child: Row(
        children: [
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.hairline(theme.brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Day one'),
              TextSpan(
                  text: '.',
                  style:
                      TextStyle(color: AppTheme.accent)),
            ],
          ),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          'Your first session writes the opening line.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final WorkoutSessionWithSets session;
  final VoidCallback onEdit;
  const _SessionCard({required this.session, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final weightsByEx = <String, List<double>>{};
    final dotsByEx = <String, Color>{};
    final order = <String>[];
    for (final s in session.sets) {
      final n = s.exercise.name;
      if (!order.contains(n)) {
        order.add(n);
        dotsByEx[n] = ExerciseCatalog.colorFor(
            s.exercise.muscleGroup);
      }
      final w = s.setLog.weightKg;
      if (w != null && w > 0) {
        weightsByEx.putIfAbsent(n, () => []).add(w);
      }
    }

    int reps = 0;
    for (final s in session.sets) {
      reps += s.setLog.reps;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Dismissible(
        key: ValueKey('workout-${session.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          DatabaseProvider.instance.deleteWorkout(session.id);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius:
                BorderRadius.circular(AppTheme.radiusLG),
          ),
          child: Icon(Icons.delete_outline,
              color: theme.colorScheme.onErrorContainer),
        ),
        child: GlassCard(
          onTap: onEdit,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMD,
                  AppTheme.spaceMD,
                  AppTheme.spaceSM,
                  AppTheme.spaceMD,
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat('EEE, MMM d')
                          .format(session.startTime)
                          .toUpperCase(),
                      style:
                          theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      DateFormat('HH:mm')
                          .format(session.startTime),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(
                        color: theme
                            .colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: theme
                          .colorScheme.onSurfaceVariant
                          .withOpacity(0.6),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: AppTheme.hairline(
                      theme.brightness)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMD,
                  vertical: AppTheme.spaceMD,
                ),
                child: Column(
                  children: [
                    for (final name in order.take(3))
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dotsByEx[name],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: theme
                                    .textTheme.bodyMedium
                                    ?.copyWith(
                                  color: theme.colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              _w(weightsByEx[name]),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature
                                      .tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (order.length > 3)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 14),
                        child: Row(
                          children: [
                            Text(
                              '+${order.length - 3} more',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                color: theme
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: AppTheme.hairline(
                      theme.brightness)),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMD),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _mini(context, '${order.length}',
                          'EXERCISES'),
                      _vd(context),
                      _mini(context,
                          '${session.sets.length}', 'SETS'),
                      _vd(context),
                      _mini(context, '$reps', 'REPS'),
                      _vd(context),
                      _mini(
                          context,
                          '${session.duration.inMinutes}m',
                          'TIME'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  String _w(List<double>? ws) => (ws == null || ws.isEmpty)
      ? 'bodyweight'
      : '${ws.map(_f).join(' · ')} kg';
  String _f(double w) => w == w.roundToDouble()
      ? w.round().toString()
      : w.toStringAsFixed(1);

  Widget _vd(BuildContext context) => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: AppTheme.hairline(
            Theme.of(context).brightness),
      );

  Widget _mini(BuildContext context, String v, String l) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              v,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [
                  FontFeature.tabularFigures()
                ],
              ),
            ),
            Text(
              l,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8.5,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}