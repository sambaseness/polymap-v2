import 'dart:math' as math;
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../data/models.dart';
import '../data/map_repository.dart';

/// Service for fetching routes via OpenRouteService API.
///
/// Falls back to pre-baked polylines when offline or when the
/// API key is not configured.
///
/// Setup: Add your ORS API key to [OpenRouteService.apiKey].
/// Free tier: 2,000 requests/day.
class RouteService {
  RouteService._();

  /// OpenRouteService API key (free at https://openrouteservice.org/).
  /// Set to null to use pre-baked fallback polylines.
  static String? apiKey;

  /// Base URL for ORS Directions API.
  static const String _baseUrl = 'https://api.openrouteservice.org/v2/directions/foot-walking';

  /// Fetch a walking route between two coordinates.
  ///
  /// Returns a list of [LatLng] points forming the route polyline,
  /// or null if the request fails (fallback to pre-baked data).
  static Future<List<LatLng>?> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    RouteMode mode = RouteMode.walk,
  }) async {
    // If no API key, return fallback polyline
    if (apiKey == null) {
      return _fallbackRoute(origin, destination, mode);
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': apiKey!,
          'Accept': 'application/json, application/geo+json',
        },
        body: jsonEncode({
          'coordinates': [
            [origin.longitude, origin.latitude],
            [destination.longitude, destination.latitude],
          ],
          'format': 'geojson',
          'preference': mode == RouteMode.accessible ? 'shortest' : 'recommended',
          'extra_info': ['steepness', 'waytypes'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        return coordinates
            .map((c) => LatLng(c[1] as double, c[0] as double))
            .toList();
      }
      // API returned error — fallback
      return _fallbackRoute(origin, destination, mode);
    } catch (_) {
      // Network error — fallback
      return _fallbackRoute(origin, destination, mode);
    }
  }

  /// Fetch route instructions from ORS.
  static Future<RouteInstructions?> fetchRouteInstructions({
    required LatLng origin,
    required LatLng destination,
    RouteMode mode = RouteMode.walk,
  }) async {
    if (apiKey == null) return null;

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': apiKey!,
          'Accept': 'application/json, application/geo+json',
        },
        body: jsonEncode({
          'coordinates': [
            [origin.longitude, origin.latitude],
            [destination.longitude, destination.latitude],
          ],
          'format': 'geojson',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final legs = data['features'][0]['properties']['segments'] as List;
        if (legs.isNotEmpty) {
          return RouteInstructions(
            distance: legs[0]['distance'] as double,
            duration: legs[0]['duration'] as double,
            steps: (legs[0]['steps'] as List)
                .map((s) => RouteStep(
                      instruction: s['instruction'] as String,
                      distance: (s['distance'] as num).toDouble(),
                      duration: (s['duration'] as num).toDouble(),
                    ))
                .toList(),
          );
        }
      }
    } catch (_) {
      // Ignore — return null
    }
    return null;
  }

  /// Fallback to pre-baked polyline data.
  static List<LatLng> _fallbackRoute(LatLng origin, LatLng destination, RouteMode mode) {
    // Find the closest matching route from CampusGps
    final routes = MapRepository.routeDefinitions;
    if (routes.isNotEmpty) {
      final base = routes[0]; // route1Walk as default
      return switch (mode) {
        RouteMode.walk => base,
        RouteMode.accessible => MapRepository.route1Accessible,
        RouteMode.shortest => MapRepository.route1Shortest,
      };
    }
    // Last resort — straight line
    return [origin, destination];
  }
}

/// Instructions returned from ORS.
class RouteInstructions {
  const RouteInstructions({
    required this.distance,
    required this.duration,
    required this.steps,
  });

  final double distance; // in meters
  final double duration; // in seconds
  final List<RouteStep> steps;
}

/// A single navigation step.
class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
  });

  final String instruction;
  final double distance;
  final double duration;
}

/// Calculates estimated distance between two LatLng points (Haversine).
/// Used as fallback when no routing API is available.
double calculateDistance(LatLng a, LatLng b) {
  const double earthRadius = 6371000; // meters
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final deltaLat = (b.latitude - a.latitude) * math.pi / 180;
  final deltaLon = (b.longitude - a.longitude) * math.pi / 180;

  final aVal = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(lat1) * math.cos(lat2) *
          math.sin(deltaLon / 2) * math.sin(deltaLon / 2);
  final c = 2 * math.atan2(math.sqrt(aVal), math.sqrt(1 - aVal));
  return earthRadius * c;
}

/// Estimates walking time from distance in meters.
/// Assumes 5 km/h walking speed.
int estimateWalkingTime(double distanceMeters) {
  return (distanceMeters / 5000 * 60).round(); // minutes
}
