import 'package:flutter/material.dart';

enum WalkMode { gps, treadmill }

extension WalkModeX on WalkMode {
  String get label => this == WalkMode.gps ? 'GPS Walk' : 'Treadmill';
  IconData get icon =>
      this == WalkMode.gps ? Icons.map : Icons.directions_run;
}

/// A completed walking session (from GPS or treadmill).
class WalkSession {
  final DateTime date;
  final Duration duration;
  final WalkMode mode;

  /// Meters walked (GPS-measured or manually entered).
  final double distanceMeters;

  /// Steps (treadmill-reported, or estimated from distance in GPS mode).
  final int steps;

  /// GPS route points — empty for treadmill sessions.
  final List<GeoPoint> route;

  WalkSession({
    required this.date,
    required this.duration,
    required this.mode,
    required this.distanceMeters,
    required this.steps,
    this.route = const [],
  });

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${distanceMeters.round()} m';
  }
}

/// One GPS coordinate in a route.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);
}