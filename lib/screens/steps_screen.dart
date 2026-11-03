import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/walk_models.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import 'walk_screen.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  final NumberFormat _fmtInt = NumberFormat('#,##0');

  // ─── Step sensor state ─────────────────────────────
  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _sensorTimeout;

  /// Pedometer reports steps since BOOT. We snapshot a baseline
  /// (boot count at first app-open today) in the database —
  /// today's steps = current − baseline, so the count survives
  /// tab switches and app restarts.
  int _baselineBootSteps = 0;
  String _baselineDay = '';
  bool _baselineReady = false;
  int _currentBootSteps = 0;
  bool _awaitingFirstEvent = true;

  bool _sensorAvailable = true;
  bool _permissionPermanentlyDenied = false;
  String? _sensorError;

  // ─── Walks + goal (from database) ──────────────────
  List<WalkSession> _walks = [];
  StreamSubscription<List<WalkSessionRow>>? _walksSub;
  int _stepGoal = 8000;
  StreamSubscription<int>? _goalSub;

  @override
  void initState() {
    super.initState();

    _walksSub =
        DatabaseProvider.instance.watchAllWalks().listen((rows) {
      if (mounted) {
        setState(() => _walks = rows.map(_toModel).toList());
      }
    });
    _goalSub = DatabaseProvider.instance.watchStepGoal().listen((goal) {
      if (mounted) setState(() => _stepGoal = goal);
    });

    _initPedometer();
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _sensorTimeout?.cancel();
    _walksSub?.cancel();
    _goalSub?.cancel();
    super.dispose();
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ═════════════════════════════════════════════════
  // SENSOR SETUP
  // ═════════════════════════════════════════════════

  Future<void> _initPedometer() async {
    if (!mounted) return;
    setState(() {
      _sensorAvailable = true;
      _sensorError = null;
      _permissionPermanentlyDenied = false;
      _awaitingFirstEvent = true;
    });

    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() {
        _sensorAvailable = false;
        _sensorError =
            'Step sensor not available on this platform.\n'
            'Use your Android phone for automatic counting — '
            'or log treadmill walks, which count everywhere.';
      });
      return;
    }

    // Android 10+: ACTIVITY_RECOGNITION is a RUNTIME permission.
    // Without it the step stream dies instantly — this was the
    // main reason the counter showed nothing.
    if (Platform.isAndroid) {
      var status = await Permission.activityRecognition.status;
      if (!status.isGranted) {
        status = await Permission.activityRecognition.request();
      }
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() {
          _sensorAvailable = false;
          _permissionPermanentlyDenied = status.isPermanentlyDenied;
          _sensorError = _permissionPermanentlyDenied
              ? 'Step counting was permanently denied.\n'
                  'Enable "Physical activity" for PulseTrack in '
                  'Settings, then tap Try again.'
              : 'PulseTrack needs the "Physical activity" '
                  'permission to count your steps.';
        });
        return;
      }
    }

    // Watchdog: if no first reading arrives in 6 s, the step
    // sensor is missing or wedged (happens on some phones).
    // GPS walks still work either way.
    _sensorTimeout?.cancel();
    _sensorTimeout = Timer(const Duration(seconds: 6), () {
      if (mounted && _awaitingFirstEvent) {
        setState(() {
          _sensorAvailable = false;
          _sensorError =
              'The step sensor isn\'t responding on this device.\n'
              'You can still track walks with GPS — steps are '
              'estimated from distance.';
        });
      }
    });

    _stepSubscription?.cancel();
    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepEvent,
      onError: (error) {
        _cancelWatchdog();
        if (!mounted) return;
        setState(() {
          _sensorAvailable = false;
          _sensorError = 'Step sensor error.\n'
              'GPS walks still count steps from distance.';
        });
      },
    );
  }

  void _cancelWatchdog() {
    _sensorTimeout?.cancel();
    _sensorTimeout = null;
  }

  Future<void> _onStepEvent(StepCount event) async {
    _awaitingFirstEvent = false;
    _cancelWatchdog();

    _currentBootSteps = event.steps;
    final today = DateTime.now();
    final todayKey = _dayKey(today);

    if (!_baselineReady) {
      final stored =
          await DatabaseProvider.instance.getStepBaseline();

      // Re-baseline when: nothing stored, a new day started, or
      // the phone rebooted (boot counter restarted lower).
      final needsReset = stored == null ||
          stored.day != todayKey ||
          event.steps < stored.bootSteps;

      if (needsReset) {
        _baselineDay = todayKey;
        _baselineBootSteps = event.steps;
        await DatabaseProvider.instance
            .setStepBaseline(today, event.steps);
      } else {
        _baselineDay = stored.day;
        _baselineBootSteps = stored.bootSteps;
      }
      _baselineReady = true;
    } else if (_baselineDay != todayKey) {
      // Midnight rolled over while the app stayed open
      _baselineDay = todayKey;
      _baselineBootSteps = event.steps;
      await DatabaseProvider.instance
          .setStepBaseline(today, event.steps);
    }

    if (mounted) setState(() {});
  }

  // ═════════════════════════════════════════════════
  // CALCULATIONS
  // ═════════════════════════════════════════════════

  int get _sensorSteps {
    if (!_sensorAvailable || !_baselineReady) return 0;
    return (_currentBootSteps - _baselineBootSteps)
        .clamp(0, 9999999);
  }

  /// Treadmill steps come from logged walks (sensor can't see
  /// them — phone sits on the console). GPS-walk steps are NOT
  /// added: the sensor already counts them (no double count).
  int get _treadmillStepsToday {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    return _walks
        .where((w) =>
            !w.date.isBefore(dayStart) &&
            w.mode == WalkMode.treadmill)
        .fold(0, (sum, w) => sum + w.steps);
  }

  int get _todaySteps => _sensorSteps + _treadmillStepsToday;

  double get _todayDistanceMeters => _todaySteps * 0.75;

  double get _progress => _stepGoal > 0
      ? (_todaySteps / _stepGoal).clamp(0.0, 1.0)
      : 0.0;

  WalkSession _toModel(WalkSessionRow row) {
    return WalkSession(
      date: row.startTime,
      duration: Duration(seconds: row.durationSeconds),
      mode: row.mode == 'treadmill'
          ? WalkMode.treadmill
          : WalkMode.gps,
      distanceMeters: row.distanceMeters,
      steps: row.steps,
      route: AppDatabase.parseRoute(row.routeJson)
          .map((p) => GeoPoint(p.lat, p.lng))
          .toList(),
    );
  }

  // ═════════════════════════════════════════════════
  // GOAL DIALOG
  // ═════════════════════════════════════════════════

  Future<void> _showGoalDialog() async {
    var tempGoal = _stepGoal;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Daily step goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmtInt.format(tempGoal),
                style:
                    Theme.of(dialogContext).textTheme.displaySmall,
              ),
              Text('steps per day',
                  style: Theme.of(dialogContext)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: Theme.of(dialogContext)
                            .colorScheme
                            .onSurfaceVariant,
                      )),
              const SizedBox(height: AppTheme.spaceMD),
              Slider(
                value: tempGoal.clamp(1000, 25000).toDouble(),
                min: 1000,
                max: 25000,
                divisions: 48,
                label: _fmtInt.format(tempGoal),
                onChanged: (v) =>
                    setDialogState(() => tempGoal = v.round()),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Wrap(
                spacing: AppTheme.spaceXS,
                runSpacing: AppTheme.spaceXS,
                alignment: WrapAlignment.center,
                children: [
                  for (final preset
                      in [5000, 8000, 10000, 12000, 15000])
                    () {
                      final selected = tempGoal == preset;
                      return ActionChip(
                        label: Text('${preset ~/ 1000}k'),
                        onPressed: () => setDialogState(
                            () => tempGoal = preset),
                        backgroundColor: selected
                            ? AppTheme.accent
                            : null,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : null,
                          fontWeight:
                              selected ? FontWeight.w700 : null,
                        ),
                      );
                    }(),
                ],
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
                Navigator.pop(dialogContext);
                DatabaseProvider.instance
                    .setSetting('step_goal', tempGoal.toString());
                // Goal stream refreshes the UI automatically.
              },
              child: const Text('Save goal'),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Steps')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceLG),
        children: [
          _buildHero(theme),
          if (!_sensorAvailable) ...[
            const SizedBox(height: AppTheme.spaceMD),
            _buildSensorCard(theme),
          ],
          const SizedBox(height: AppTheme.spaceLG),
          _buildStatStrip(theme),
          const SizedBox(height: 4),
          Text(
            'Counts from the first app open each day · '
            'treadmill walks add automatically',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant
                  .withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          FilledButton.icon(
            onPressed: _startWalk,
            icon: const Icon(Icons.directions_walk_rounded,
                size: 22),
            label: const Text('START A WALK'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          if (_walks.isNotEmpty) ...[
            _sectionLabel('RECENT WALKS'),
            ..._buildWalkCards(theme),
          ],
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  /// Editorial hero: pure typography + slim progress bar.
  Widget _buildHero(ThemeData theme) {
    final remaining = _stepGoal - _todaySteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          DateFormat('EEEE, MMM d')
              .format(DateTime.now())
              .toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 2.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
                       TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _todaySteps.toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text(
                _fmtInt.format(value.round()),
                style:
                    theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.8,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '/ ${_fmtInt.format(_stepGoal)}',
                style:
                    theme.textTheme.titleMedium?.copyWith(
                  color: theme
                      .colorScheme.onSurfaceVariant,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMD),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.accent),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          children: [
            Expanded(
              child: Text(
                _progress >= 1.0
                    ? 'Goal achieved.'
                    : '${_fmtInt.format(remaining)} steps to go.',
                style: theme.textTheme.labelMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: _showGoalDialog,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10),
              ),
              child: Text(
                'CHANGE GOAL',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.accent,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorCard(ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme
                      .colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                      AppTheme.radiusMD),
                ),
                child: Icon(Icons.sensors_off_rounded,
                    size: 19,
                    color: theme
                        .colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Text(
                  _sensorError ?? 'Sensor unavailable',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    if (_permissionPermanentlyDenied) {
                      await openAppSettings();
                    } else {
                      _initPedometer();
                    }
                  },
                  child: Text(
                    _permissionPermanentlyDenied
                        ? 'OPEN SETTINGS'
                        : 'GRANT ACCESS',
                    style:
                        theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.accent,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!_permissionPermanentlyDenied)
                  TextButton(
                    onPressed: _initPedometer,
                    child: Text(
                      'TRY AGAIN',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(
                        color: theme.colorScheme
                            .onSurfaceVariant,
                        letterSpacing: 1,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatStrip(ThemeData theme) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _cell(
              theme,
              _fmtInt.format(_todaySteps),
              'STEPS',
            ),
            _vd(theme),
            _cell(
              theme,
              _fmtDistance(_todayDistanceMeters),
              'EST. DISTANCE',
            ),
            _vd(theme),
            _cell(
              theme,
              '${(_progress * 100).round()}%',
              'OF GOAL',
            ),
          ],
        ),
      ),
    );
  }

  Widget _vd(ThemeData theme) => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 14),
        color: AppTheme.hairline(theme.brightness),
      );

  Widget _cell(ThemeData theme, String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style:
                  theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [
                  FontFeature.tabularFigures()
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style:
                  theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                letterSpacing: 1.5,
                color: theme.colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: AppTheme.spaceXL,
        bottom: AppTheme.spaceMD,
      ),
      child: Row(
        children: [
          Text(
            text,
            style:
                theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
              color:
                  theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.hairline(
                  theme.brightness),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWalkCards(ThemeData theme) {
    return [
      for (final walk in _walks.take(10))
        Padding(
          padding:
              const EdgeInsets.only(bottom: AppTheme.spaceSM),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMD,
              vertical: AppTheme.spaceMD,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusMD),
                  ),
                  child: Icon(
                    walk.mode == WalkMode.gps
                        ? Icons.map_rounded
                        : Icons.directions_run_rounded,
                    size: 20,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${walk.mode.label} · '
                        '${DateFormat('EEE, MMM d').format(walk.date).toUpperCase()}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_fmtDuration(walk.duration)} · '
                        '${_fmtInt.format(walk.steps)} steps',
                        style:
                            theme.textTheme.bodySmall
                                ?.copyWith(
                          color: theme.colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmtDistance(
                          walk.distanceMeters),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                        fontFeatures: const [
                          FontFeature
                              .tabularFigures()
                        ],
                      ),
                    ),
                    Text(
                      walk.formattedDistance
                              .contains('km')
                          ? 'distance'
                          : 'distance',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(
                        color: theme.colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Future<void> _startWalk() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<WalkSession>(
      context,
      MaterialPageRoute(
          builder: (context) => const WalkScreen()),
    );
    if (result == null || !mounted) return;

    await DatabaseProvider.instance.insertWalk(
      startTime: result.date,
      duration: result.duration,
      distanceMeters: result.distanceMeters,
      steps: result.steps,
      mode: result.mode.name,
      route: result.route
          .map((p) =>
              GeoPointData(lat: p.latitude, lng: p.longitude))
          .toList(),
    );
  }

  String _fmtDistance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(2)} km'
      : '${meters.round()} m';

  String _fmtDuration(Duration d) => d.inHours > 0
      ? '${d.inHours}h ${d.inMinutes.remainder(60)}m'
      : '${d.inMinutes}m';
}