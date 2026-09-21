import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/map_repository.dart';

/// Service for managing GPS location tracking.
///
/// Provides real-time position updates via [Geolocator]'s position stream.
/// Handles permission requests and accuracy settings.
class LocationService {
  LocationService._();

  /// Current position (last known).
  static Position? _currentPosition;

  /// Initialize location services and request permissions.
  /// Returns true if location is available, false otherwise.
  static Future<bool> initialize() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }
      if (permission == LocationPermission.deniedForever) return false;

      _currentPosition = await Geolocator.getLastKnownPosition();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Start listening to real-time position updates.
  static StreamSubscription<Position>? startTracking({
    required void Function(Position) onPositionUpdate,
    double distanceFilter = 10,
  }) {
    final stream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter.round(),
      ),
    );

    return stream.listen((position) {
      _currentPosition = position;
      onPositionUpdate(position);
    }, onError: (error) {
      debugPrint('Location tracking error: $error');
    });
  }

  /// Stop tracking.
  static void stopTracking() {
    // Tracking is stopped by cancelling the subscription returned by startTracking.
    // The subscription is managed by the caller.
  }

  /// Get the current position as a [LatLng].
  static LatLng? get currentPositionLatLng =>
      _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null;

  /// Get the accuracy string for display.
  static String getAccuracyString(LocationAccuracy accuracy) {
    return switch (accuracy) {
      LocationAccuracy.low => 'Low accuracy',
      LocationAccuracy.medium => 'Medium accuracy',
      LocationAccuracy.high => 'High accuracy',
      LocationAccuracy.best => 'Best accuracy',
      LocationAccuracy.bestForNavigation => 'Navigation grade',
      _ => 'Unknown',
    };
  }
}

/// Widget that shows the current GPS accuracy and location info.
class LocationInfoBar extends StatelessWidget {
  const LocationInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    final position = LocationService._currentPosition;
    if (position == null) {
      return const Text('Locating...', style: TextStyle(fontSize: 12));
    }
    return Text(
      '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
      style: const TextStyle(fontSize: 11, fontFamily: 'IBM Plex Mono'),
    );
  }
}

/// Determines the best initial map position.
/// Returns GPS position if available, otherwise campus center.
LatLng getInitialMapPosition() {
  final gps = LocationService.currentPositionLatLng;
  return gps ?? MapRepository.campusCenter;
}
