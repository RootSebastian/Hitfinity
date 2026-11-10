import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/walk_models.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../widgets/hit_widgets.dart';
import 'walk_screen.dart';
import '../services/hit_settings.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  final NumberFormat _fmtInt = NumberFormat('#,##0');

  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _sensorTimeout;

  int _baselineBootSteps = 0;
  String _baselineDay = '';
  bool _baselineReady = false;
  int _currentBootSteps = 0;
  bool _awaitingFirstEvent = true;

  bool _sensorAvailable = true;
  bool _permissionPermanentlyDenied = false;
  String? _sensorError;

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
      _baselineDay = todayKey;
      _baselineBootSteps = event.steps;
      await DatabaseProvider.instance
          .setStepBaseline(today, event.steps);
    }

    if (mounted) setState(() {});
  }

  int get _sensorSteps {
    if (!_sensorAvailable || !_baselineReady) return 0;
    return (_currentBootSteps - _baselineBootSteps)
        .clamp(0, 9999999);
  }

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
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: AppTheme.text,
                  fontFeatures: [
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
               Text('steps per day',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  )),
              const SizedBox(height: AppTheme.spaceMD),
              Slider(
                value: tempGoal.clamp(1000, 25000).toDouble(),
                min: 1000,
                max: 25000,
                divisions: 48,
                activeColor: AppTheme.lime,
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
                            ? AppTheme.lime
                            : AppTheme.surfaceAlt,
                        side: const BorderSide(
                            color: AppTheme.hairlineDark),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppTheme.ink
                              : AppTheme.textMuted,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
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
              },
              child: const Text('Save goal'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLG),
          children: [
            _buildHero(),
            if (!_sensorAvailable) ...[
              const SizedBox(height: AppTheme.spaceMD),
              _buildSensorCard(),
            ],
            const SizedBox(height: AppTheme.spaceLG),
            _buildStatStrip(),
            const SizedBox(height: 4),
             Text(
              'Counts from the first app open each day · '
              'treadmill walks add automatically',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            _startWalkButton(),
            if (_walks.isNotEmpty) ...[
              const SectionHeader('RECENT WALKS'),
              ..._buildWalkCards(),
            ],
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final remaining = _stepGoal - _todaySteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spaceMD),
        Text(
          DateFormat('EEEE, MMM d')
              .format(DateTime.now())
              .toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
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
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.8,
                  color: AppTheme.text,
                  fontFeatures: [
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
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                  fontFeatures: [
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMD),

        GradientBar(
          progress: _progress,
          height: 8,
          gradient: AppTheme.heroGradient,
        ),

        const SizedBox(height: AppTheme.spaceSM),
        Row(
          children: [
            Expanded(
              child: Text(
                _progress >= 1.0
                    ? 'Goal achieved.'
                    : '${_fmtInt.format(remaining)} steps to go.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textMuted,
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
              child:       Text(
                'CHANGE GOAL',
                style: TextStyle(
                  color: AppTheme.lime,
                  fontSize: 10.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorCard() {
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
                  color: AppTheme.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                      BorderSide(color: AppTheme.hairlineDark)),
                ),
                child: Icon(Icons.sensors_off_rounded,
                    size: 19, color: AppTheme.textMuted),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Text(
                  _sensorError ?? 'Sensor unavailable',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.text,
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
                  child:       Text(
                    'OPEN SETTINGS',
                    style: TextStyle(
                      color: AppTheme.lime,
                      fontSize: 10.5,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!_permissionPermanentlyDenied)
                  TextButton(
                    onPressed: _initPedometer,
                    child: Text(
                      'TRY AGAIN',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
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

  Widget _buildStatStrip() {
    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: Icons.directions_walk_rounded,
            value: _fmtInt.format(_todaySteps),
            label: 'STEPS',
            color: AppTheme.lime,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: StatTile(
            icon: Icons.straighten_rounded,
            value: _fmtDistance(_todayDistanceMeters),
            label: 'EST. DISTANCE',
            color: AppTheme.mint,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: StatTile(
            icon: Icons.flag_rounded,
            value: '${(_progress * 100).round()}%',
            label: 'OF GOAL',
            color: AppTheme.sky,
          ),
        ),
      ],
    );
  }

  Widget _startWalkButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lime.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(AppTheme.radiusMD),
          onTap: _startWalk,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:       [
                Icon(Icons.directions_walk_rounded,
                    size: 24, color: AppTheme.ink),
                SizedBox(width: 8),
                Text(
                  'START A WALK',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWalkCards() {
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
                    color: (walk.mode == WalkMode.gps
                            ? AppTheme.mint
                            : AppTheme.sun)
                        .withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    walk.mode == WalkMode.gps
                        ? Icons.map_rounded
                        : Icons.directions_run_rounded,
                    size: 20,
                    color: walk.mode == WalkMode.gps
                        ? AppTheme.mint
                        : AppTheme.sun,
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
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.text,
                        ),
                      ),
                      Text(
                        '${_fmtDuration(walk.duration)} · '
                        '${_fmtInt.format(walk.steps)} steps',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _fmtDistance(walk.distanceMeters),
                  style:       TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.lime,
                    fontFeatures: [
                      FontFeature.tabularFigures()
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Future<void> _startWalk() async {
    HitHaptics.mediumImpact();
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
