import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/walk_models.dart';
import '../theme/app_theme.dart';

class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen>
    with WidgetsBindingObserver {
  WalkMode _mode = WalkMode.gps;

  /// Average stride length — used to estimate steps from
  /// GPS/treadmill distance (~1,300 steps per km).
  static const double _metersPerStep = 0.75;

  // ─── Common state ─────────────────────────────────────
  final DateTime _startTime = DateTime.now();

  /// Time banked from earlier running segments.
  Duration _banked = Duration.zero;

  /// When the current running segment began (null = paused).
  DateTime? _segmentStart;

  late Timer _timer;

  /// True while actively tracking.
  bool get _isRunning => _segmentStart != null;

  /// Total ACTIVE time. Pauses are excluded, but backgrounding
  /// is included — because it's computed from the wall clock,
  /// not by counting ticks, it's correct even after the app
  /// sits in the background for an hour.
  Duration get _elapsed => _banked +
      (_segmentStart != null
          ? DateTime.now().difference(_segmentStart!)
          : Duration.zero);

  /// Anything worth saving yet?
  bool get _hasData =>
      _gpsDistanceMeters > 0 ||
      _routePoints.length >= 2 ||
      (double.tryParse(_treadmillDistanceCtrl.text) ?? 0) > 0;

  // ─── GPS state ────────────────────────────────────────
  StreamSubscription<Position>? _positionSubscription;
  final List<LatLng> _routePoints = [];
  double _gpsDistanceMeters = 0;
  Position? _lastPosition;
  double? _gpsAccuracy;
  String? _gpsError;
  final MapController _mapController = MapController();

  /// Whether the map auto-follows you. Turns itself off the
  /// moment you pan the map manually (so it stops fighting you).
  bool _followUser = true;

  // ─── Treadmill state ──────────────────────────────────
  final _treadmillDistanceCtrl = TextEditingController();
  final _treadmillStepsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The tick only refreshes the display — the elapsed value
    // itself is derived from the wall clock on every build.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRunning) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from another app: repaint with everything
    // the foreground service recorded while we were away.
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _positionSubscription?.cancel();
    _treadmillDistanceCtrl.dispose();
    _treadmillStepsCtrl.dispose();
    super.dispose();
  }

  String get _formattedElapsed {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m =
        _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s =
        _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  double get _currentDistance {
    if (_mode == WalkMode.gps) return _gpsDistanceMeters;
    return double.tryParse(_treadmillDistanceCtrl.text) ?? 0;
  }

  int get _currentSteps {
    if (_mode == WalkMode.treadmill) {
      final typed = int.tryParse(_treadmillStepsCtrl.text);
      if (typed != null && typed > 0) return typed;
    }
    return (_currentDistance / _metersPerStep).round();
  }

  // ─── GPS Methods ──────────────────────────────────────

  Future<void> _startGpsTracking() async {
    // 1. Location services on?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _gpsError =
          'Location services are disabled. Enable them in Settings.');
      return;
    }

    // 2. Android-specific permissions:
    //    - Notification (Android 13+, so the tracking
    //      notification is visible)
    //    - Battery-optimization exemption (Samsung/Xiaomi/OnePlus
    //      aggressively kill backgrounded apps — this one-time
    //      "Allow" is what keeps long walks alive on them)
    if (Platform.isAndroid) {
      await Permission.notification.request();
      final battery =
          await Permission.ignoreBatteryOptimizations.status;
      if (battery.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }

    // 3. Location permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _gpsError = 'Location permission denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _gpsError =
          'Location permission permanently denied. Enable it in app settings.');
      return;
    }

    // 4. THE KEY CHANGE: on Android, attach a foreground-service
    //    notification. Geolocator promotes itself to a foreground
    //    service, so the GPS stream keeps flowing while you use
    //    other apps or lock the screen.
    final LocationSettings locationSettings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
            foregroundNotificationConfig:
                const ForegroundNotificationConfig(
              notificationTitle: 'PulseTrack',
              notificationText:
                  'Walk in progress — route & distance keep recording',
              enableWakeLock: true,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        // While backgrounded, this listener keeps firing (the
        // foreground service holds the process alive); data piles
        // up in state and the map catches up on return.
        if (!mounted || !_isRunning) return;

        setState(() {
          _gpsAccuracy = position.accuracy;
          final here = LatLng(position.latitude, position.longitude);

          if (_lastPosition != null) {
            final segmentMeters = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              position.latitude,
              position.longitude,
            );
            // Ignore GPS drift (< 2m jumps while standing still)
            if (segmentMeters >= 2) {
              _gpsDistanceMeters += segmentMeters;
              _routePoints.add(here);
              if (_followUser && _routePoints.length > 1) {
                _mapController.move(
                    here, _mapController.camera.zoom);
              }
            }
          } else {
            // First fix — center map here
            _routePoints.add(here);
            _mapController.move(here, 16.0);
          }
          _lastPosition = position;
        });
      },
      onError: (error) {
        setState(() => _gpsError = 'GPS error: $error');
      },
    );
  }

  void _stopGpsTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // ─── Control ──────────────────────────────────────────

  void _toggleStart() {
    if (_isRunning) {
      // Pause: bank active time so it doesn't keep growing
      setState(() {
        _banked = _elapsed;
        _segmentStart = null;
      });
      HapticFeedback.selectionClick();
      if (_mode == WalkMode.gps) _stopGpsTracking();
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _segmentStart = DateTime.now();
        _gpsError = null;
      });
      if (_mode == WalkMode.gps) {
        if (!Platform.isAndroid && !Platform.isIOS) {
          setState(() => _gpsError =
              'GPS tracking requires an Android/iOS device.');
          return;
        }
        _startGpsTracking();
      }
    }
  }

  void _finishWalk() {
    if (!_hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to save yet — start tracking first!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final session = WalkSession(
      date: _startTime,
      duration: _elapsed,
      mode: _mode,
      distanceMeters: _currentDistance,
      steps: _currentSteps,
      route: _routePoints
          .map((p) => GeoPoint(p.latitude, p.longitude))
          .toList(),
    );

    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Walk?'),
        content: Text(
          '${session.formattedDistance} • ${_currentSteps} steps\n'
          'Active time: ${_formattedElapsed}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Going'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, session);
            },
            child: const Text('Save Walk'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(_mode == WalkMode.gps ? 'GPS Walk' : 'Treadmill Walk'),
      ),
      body: Column(
        children: [
          // Mode selector hides permanently once tracking began —
          // no switching modes mid-walk anymore.
          if (!_isRunning && _banked == Duration.zero)
            _buildModeSelector(theme),

          _buildStatsBar(theme),

          Expanded(
            child: _mode == WalkMode.gps
                ? _buildGpsContent(theme)
                : _buildTreadmillContent(theme),
          ),

          _buildControls(theme),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMD),
      padding: const EdgeInsets.all(AppTheme.spaceXS),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              theme,
              mode: WalkMode.gps,
              icon: Icons.map,
              label: 'GPS Walk',
              subtitle: 'Outdoor',
            ),
          ),
          Expanded(
            child: _modeButton(
              theme,
              mode: WalkMode.treadmill,
              icon: Icons.directions_run,
              label: 'Treadmill',
              subtitle: 'Indoor',
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    ThemeData theme, {
    required WalkMode mode,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _mode == mode;
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXS),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _mode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding:
              const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.heroGradient : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color:
                      isSelected ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? Colors.white.withOpacity(0.7)
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats strip (hero gradient) ─────────────────────

  Widget _buildStatsBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spaceMD,
        horizontal: AppTheme.spaceMD,
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat(_formattedElapsed, 'TIME', Icons.timer_outlined),
          _stat(_formatDistance(_currentDistance), 'DISTANCE',
              Icons.straighten),
          _stat(_currentSteps.toString(), 'STEPS',
              Icons.directions_walk),
          if (_mode == WalkMode.gps && _gpsAccuracy != null)
            _stat('±${_gpsAccuracy!.round()}m', 'GPS',
                Icons.satellite_alt_outlined),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 15, color: Colors.white.withOpacity(0.8)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ─── GPS mode UI ──────────────────────────────────────

  Widget _buildGpsContent(ThemeData theme) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _buildPlatformWarning(theme);
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                const LatLng(51.5074, -0.1278), // Default: London
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            // You panned the map yourself → stop auto-following,
            // show the recenter button instead of fighting you.
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture && _followUser && mounted) {
                setState(() => _followUser = false);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pulsetrack.app',
            ),
            if (_routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5,
                    color: theme.colorScheme.primary,
                    borderStrokeWidth: 9,
                    borderColor: Colors.white,
                  ),
                ],
              ),
            if (_lastPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      _lastPosition!.latitude,
                      _lastPosition!.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: _buildPositionDot(theme),
                  ),
                ],
              ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),

        // ─── Recenter button (appears after you pan away) ─
        if (!_followUser && _lastPosition != null)
          Positioned(
            right: AppTheme.spaceMD,
            bottom: AppTheme.spaceMD,
            child: _buildRecenterButton(theme),
          ),

        // ─── Error overlay ──────────────────────────────
        if (_gpsError != null)
          Positioned(
            top: AppTheme.spaceMD,
            left: AppTheme.spaceMD,
            right: AppTheme.spaceMD,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: AppTheme.spaceSM),
                  Expanded(
                    child: Text(
                      _gpsError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ─── Waiting for GPS fix ─────────────────────────
        if (_isRunning && _routePoints.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Text(
                    'Getting GPS fix…\nGo outside for best signal',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPositionDot(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withOpacity(0.25),
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecenterButton(ThemeData theme) {
    return Material(
      color: theme.colorScheme.surface,
      elevation: 4,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _followUser = true);
          _mapController.move(
            LatLng(_lastPosition!.latitude,
                _lastPosition!.longitude),
            _mapController.camera.zoom < 15
                ? 16.0
                : _mapController.camera.zoom,
          );
        },
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.my_location, size: 22),
        ),
      ),
    );
  }

  Widget _buildPlatformWarning(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_android,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'GPS tracking needs your phone',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Run this app on your Android device to use\n'
              'GPS tracking and automatic step counting.\n\n'
              'Treadmill mode works everywhere.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Treadmill mode UI ─────────────────────────────────

  Widget _buildTreadmillContent(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius:
                BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text(
                  'GPS can\'t track you indoors. Enter what your '
                  'treadmill displays — it\'s more accurate than '
                  'any sensor.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceLG),

        _sectionLabel(theme, 'DISTANCE (KM)'),
        const SizedBox(height: AppTheme.spaceSM),
        TextField(
          controller: _treadmillDistanceCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'e.g., 3.5',
            suffixText: 'km',
            prefixIcon: Icon(Icons.straighten),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppTheme.spaceLG),

        _sectionLabel(theme, 'STEPS (OPTIONAL)'),
        const SizedBox(height: AppTheme.spaceSM),
        TextField(
          controller: _treadmillStepsCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g., 4500 (from treadmill display)',
            prefixIcon: Icon(Icons.directions_walk),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          'Leave steps empty to estimate from distance '
          '(~1,300 steps per km).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  // ─── Bottom controls ───────────────────────────────────

  Widget _buildControls(ThemeData theme) {
    final started = _isRunning || _banked > Duration.zero;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceMD,
          AppTheme.spaceSM, AppTheme.spaceMD, AppTheme.spaceMD),
      child: Row(
        children: [
          Expanded(
            child: _bigButton(
              label: _isRunning
                  ? 'Pause'
                  : (started ? 'Resume' : 'Start'),
              icon: _isRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              onPressed: _toggleStart,
              gradient:
                  !_isRunning ? AppTheme.heroGradient : null,
            ),
          ),
          if (started) ...[
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: _bigButton(
                label: 'Finish',
                icon: Icons.flag_rounded,
                onPressed: _finishWalk,
                gradient: AppTheme.heroGradient,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bigButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Gradient? gradient,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isGradient = gradient != null;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        color: isGradient ? null : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: isGradient
            ? null
            : Border.all(
                color: scheme.outlineVariant.withOpacity(0.3)),
        boxShadow: isGradient
            ? [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isGradient ? Colors.white : scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color:
                        isGradient ? Colors.white : scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.round()} m';
  }
}