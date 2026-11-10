import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/walk_models.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../widgets/hit_widgets.dart';
import '../services/hit_settings.dart';

class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen>
    with WidgetsBindingObserver {
  WalkMode _mode = WalkMode.gps;

  static const double _metersPerStep = 0.75;

  final DateTime _startTime = DateTime.now();

  Duration _banked = Duration.zero;

  DateTime? _segmentStart;

  late Timer _timer;

  bool get _isRunning => _segmentStart != null;

  Duration get _elapsed => _banked +
      (_segmentStart != null
          ? DateTime.now().difference(_segmentStart!)
          : Duration.zero);

  bool get _hasData =>
      _gpsDistanceMeters > 0 ||
      _routePoints.length >= 2 ||
      (double.tryParse(_treadmillDistanceCtrl.text) ?? 0) > 0;

  StreamSubscription<Position>? _positionSubscription;
  final List<LatLng> _routePoints = [];
  double _gpsDistanceMeters = 0;
  Position? _lastPosition;
  double? _gpsAccuracy;
  String? _gpsError;
  final MapController _mapController = MapController();

  bool _followUser = true;

  final _treadmillDistanceCtrl = TextEditingController();
  final _treadmillStepsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRunning) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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

  Future<void> _startGpsTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _gpsError =
          'Location services are disabled. Enable them in Settings.');
      return;
    }

    if (Platform.isAndroid) {
      await Permission.notification.request();
      final battery =
          await Permission.ignoreBatteryOptimizations.status;
      if (battery.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }

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

    final LocationSettings locationSettings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
            foregroundNotificationConfig:
                const ForegroundNotificationConfig(
              notificationTitle: 'Hitfinity',
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
            if (segmentMeters >= 2) {
              _gpsDistanceMeters += segmentMeters;
              _routePoints.add(here);
              if (_followUser && _routePoints.length > 1) {
                _mapController.move(
                    here, _mapController.camera.zoom);
              }
            }
          } else {
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

  void _toggleStart() {
    if (_isRunning) {
      setState(() {
        _banked = _elapsed;
        _segmentStart = null;
      });
      HitHaptics.selectionClick();
      if (_mode == WalkMode.gps) _stopGpsTracking();
    } else {
      HitHaptics.mediumImpact();
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
          content:
              Text('Nothing to save yet — start tracking first!'),
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

    HitHaptics.heavyImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finish Walk?'),
        content: Text(
          '${session.formattedDistance} • $_currentSteps steps\n'
          'Active time: $_formattedElapsed',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Going'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context, session);
            },
            child: const Text('Save Walk'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            if (!_isRunning && _banked == Duration.zero)
              _buildModeSelector(),

            _buildStatsBar(),

            Expanded(
              child: _mode == WalkMode.gps
                  ? _buildGpsContent()
                  : _buildTreadmillContent(),
            ),

            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMD, AppTheme.spaceSM, AppTheme.spaceLG, 0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.hairlineDark),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppTheme.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRunning || _banked > Duration.zero
                      ? (_mode == WalkMode.gps
                          ? 'GPS Walk'
                          : 'Treadmill Walk')
                      : 'New Walk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Track your session',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          _statusPill(),
        ],
      ),
    );
  }

  Widget _statusPill() {
    final live = _isRunning;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: live ? AppTheme.lime : AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              live ? Colors.transparent : AppTheme.hairlineDark,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: live ? AppTheme.ink : AppTheme.lime,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            live ? 'LIVE' : 'READY',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: live ? AppTheme.ink : AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG, AppTheme.spaceMD, AppTheme.spaceLG, 0),
      child: Row(
        children: [
          Expanded(
            child: _modeCard(
              mode: WalkMode.gps,
              icon: Icons.map_rounded,
              label: 'GPS Walk',
              subtitle: 'Outdoor',
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: _modeCard(
              mode: WalkMode.treadmill,
              icon: Icons.directions_run_rounded,
              label: 'Treadmill',
              subtitle: 'Indoor',
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeCard({
    required WalkMode mode,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _mode == mode;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HitHaptics.selectionClick();
        setState(() => _mode = mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spaceMD),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.heroGradient : null,
          color: isSelected ? null : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: isSelected
              ? null
              : Border.all(color: AppTheme.hairlineDark),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.lime.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppTheme.ink
                  : AppTheme.lime.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w700,
                letterSpacing: -0.2,
                color: isSelected ? AppTheme.ink : AppTheme.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.ink.withValues(alpha: 0.62)
                    : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.spaceLG,
          AppTheme.spaceMD, AppTheme.spaceLG, AppTheme.spaceMD),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spaceMD,
        horizontal: AppTheme.spaceMD,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.hairlineDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat(
              _formattedElapsed, 'TIME', Icons.timer_rounded,
              hero: true),
          _statDivider(),
          _stat(_formatDistance(_currentDistance), 'DISTANCE',
              Icons.straighten_rounded),
          _statDivider(),
          _stat(_currentSteps.toString(), 'STEPS',
              Icons.directions_walk_rounded),
          if (_mode == WalkMode.gps && _gpsAccuracy != null) ...[
            _statDivider(),
            _stat('±${_gpsAccuracy!.round()}m', 'GPS',
                Icons.satellite_alt_rounded),
          ],
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppTheme.hairlineDark,
    );
  }

  Widget _stat(String value, String label, IconData icon,
      {bool hero = false}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 15,
          color: AppTheme.lime.withValues(alpha: hero ? 1 : 0.7),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: hero ? 18 : 16.5,
            fontWeight: FontWeight.w800,
            color: hero ? AppTheme.lime : AppTheme.text,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildGpsContent() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _buildPlatformWarning();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG, 0, AppTheme.spaceLG, 0),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.hairlineDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                const LatLng(51.5074, -0.1278),
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
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
              userAgentPackageName: 'com.hitfinity.app',
            ),
            if (_routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5,
                    color: AppTheme.lime,
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
                    child: _buildPositionDot(),
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

        if (!_followUser && _lastPosition != null)
          Positioned(
            right: AppTheme.spaceMD,
            bottom: AppTheme.spaceMD,
            child: _buildRecenterButton(),
          ),

        if (_gpsError != null)
          Positioned(
            top: AppTheme.spaceMD,
            left: AppTheme.spaceMD,
            right: AppTheme.spaceMD,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.coral.withValues(alpha: 0.14),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                    color: AppTheme.coral.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppTheme.coral),
                  const SizedBox(width: AppTheme.spaceSM),
                  Expanded(
                    child: Text(
                      _gpsError!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_isRunning && _routePoints.isEmpty)
          Center(
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                        SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      color: AppTheme.lime,
                      strokeWidth: 3.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                   Text(
                    'Getting GPS fix…',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space2XS),
                   Text(
                    'Go outside for best signal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
      ),
    );
  }

  Widget _buildPositionDot() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.lime.withValues(alpha: 0.25),
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.lime,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Material(
      color: AppTheme.surfaceAlt,
      elevation: 4,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HitHaptics.selectionClick();
          setState(() => _followUser = true);
          _mapController.move(
            LatLng(_lastPosition!.latitude,
                _lastPosition!.longitude),
            _mapController.camera.zoom < 15
                ? 16.0
                : _mapController.camera.zoom,
          );
        },
        child:       Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.my_location_rounded,
              size: 22, color: AppTheme.lime),
        ),
      ),
    );
  }

  Widget _buildPlatformWarning() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.hairlineDark),
              ),
              child: Icon(
                Icons.phone_android_rounded,
                size: 30,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
             Text(
              'GPS tracking needs your phone',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
             Text(
              'Run this app on your Android device to use\n'
              'GPS tracking and automatic step counting.\n\n'
              'Treadmill mode works everywhere.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreadmillContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG, AppTheme.spaceSM, AppTheme.spaceLG, 0),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.lime.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child:       Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.lime,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
               Expanded(
                child: Text(
                  'GPS can\'t track you indoors. Enter what your '
                  'treadmill displays — it\'s more accurate than '
                  'any sensor.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textMuted,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMD),

        const SectionHeader('DISTANCE (KM)'),
        TextField(
          controller: _treadmillDistanceCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'e.g., 3.5',
            suffixText: 'km',
            prefixIcon: Icon(Icons.straighten_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppTheme.spaceXL),

        const SectionHeader('STEPS (OPTIONAL)'),
        TextField(
          controller: _treadmillStepsCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g., 4500 (from treadmill display)',
            prefixIcon: Icon(Icons.directions_walk_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppTheme.spaceSM),
         Text(
          'Leave steps empty to estimate from distance '
          '(~1,300 steps per km).',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    final started = _isRunning || _banked > Duration.zero;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG,
          AppTheme.spaceMD, AppTheme.spaceLG, AppTheme.spaceLG),
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
              hero: !_isRunning,
            ),
          ),
          if (started) ...[
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: _bigButton(
                label: 'Finish',
                icon: Icons.flag_rounded,
                onPressed: _finishWalk,
                hero: true,
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
    bool hero = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: hero ? AppTheme.heroGradient : null,
        color: hero ? null : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: hero
            ? null
            : Border.all(color: AppTheme.hairlineDark),
        boxShadow: hero
            ? [
                BoxShadow(
                  color: AppTheme.lime.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: hero ? AppTheme.ink : AppTheme.lime,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: hero ? AppTheme.ink : AppTheme.text,
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

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.round()} m';
  }
}
